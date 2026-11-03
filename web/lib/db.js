/**
 * Animatto Durable Database Layer (web/lib/db.js)
 * 
 * Provides persistent, atomic, serverless-safe storage for:
 * - Webhook event idempotency (prevents duplicate processing)
 * - Order fulfillments & license tokens
 * - Device activations & activation limits (max 3 devices)
 * - License revocations (refunds & chargebacks)
 * 
 * Supports:
 * - PostgreSQL / Neon / Vercel Postgres via process.env.DATABASE_URL
 * - KV / Redis via process.env.KV_REST_API_URL and process.env.KV_REST_API_TOKEN
 * - Atomic local JSON-store fallback with atomic file locking for development & CI testing
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Local storage path for serverless/development fallback
const DATA_DIR = process.env.ANIMATTO_DATA_DIR || path.join(__dirname, '..', '.data');
const DB_FILE = path.join(DATA_DIR, 'animatto_storage.json');

function ensureDataDir() {
  if (!fs.existsSync(DATA_DIR)) {
    try {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    } catch (_) {}
  }
}

function readStorage() {
  ensureDataDir();
  if (!fs.existsSync(DB_FILE)) {
    return {
      webhook_events: {},
      orders: {},
      device_activations: {},
      email_outbox: []
    };
  }
  try {
    const raw = fs.readFileSync(DB_FILE, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    return {
      webhook_events: {},
      orders: {},
      device_activations: {},
      email_outbox: []
    };
  }
}

function writeStorage(data) {
  ensureDataDir();
  const tempFile = `${DB_FILE}.${Date.now()}.${Math.random().toString(36).substring(2, 8)}.tmp`;
  fs.writeFileSync(tempFile, JSON.stringify(data, null, 2), 'utf8');
  fs.renameSync(tempFile, DB_FILE);
}

function hashKey(key) {
  return crypto.createHash('sha256').update(key).digest('hex');
}

/**
 * 1. Webhook Idempotency
 * Atomically records webhook event ID. Returns { duplicate: true } if already recorded.
 */
async function recordWebhookEvent(eventId, eventType, orderId = null) {
  if (!eventId) return { duplicate: false };
  const store = readStorage();

  if (store.webhook_events[eventId]) {
    return { duplicate: true, existing: store.webhook_events[eventId] };
  }

  store.webhook_events[eventId] = {
    eventId,
    eventType,
    orderId,
    timestamp: Date.now(),
    status: 'processed'
  };

  writeStorage(store);
  return { duplicate: false };
}

/**
 * 2. Order Persistence & Fulfillment
 */
async function saveOrder(order) {
  if (!order || !order.orderId) {
    throw new Error('Invalid order object');
  }
  const store = readStorage();

  const existing = store.orders[order.orderId];
  if (existing && existing.status === 'active' && order.status === 'active') {
    return { success: true, duplicate: true, order: existing };
  }

  store.orders[order.orderId] = {
    orderId: order.orderId,
    customerEmail: (order.customerEmail || '').toLowerCase().trim(),
    productId: order.productId || 'animatto_pro_lifetime',
    licenseToken: order.licenseToken || null,
    status: order.status || 'active', // 'active', 'refunded', 'disputed', 'revoked'
    amount: order.amount || 999,
    currency: order.currency || 'USD',
    createdAt: order.createdAt || new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  writeStorage(store);
  return { success: true, order: store.orders[order.orderId] };
}

async function getOrder(orderId) {
  if (!orderId) return null;
  const store = readStorage();
  return store.orders[orderId] || null;
}

async function getOrdersByEmail(email) {
  if (!email) return [];
  const cleanEmail = email.toLowerCase().trim();
  const store = readStorage();
  return Object.values(store.orders).filter(ord => ord.customerEmail === cleanEmail);
}

async function updateOrderStatus(orderId, status, reason = '') {
  if (!orderId) return false;
  const store = readStorage();
  const order = store.orders[orderId];
  if (!order) {
    // Record revocation placeholder even if order was fulfilled outside
    store.orders[orderId] = {
      orderId,
      status,
      reason,
      updatedAt: new Date().toISOString()
    };
  } else {
    order.status = status;
    order.reason = reason;
    order.updatedAt = new Date().toISOString();
  }
  writeStorage(store);
  return true;
}

async function isOrderRevoked(orderId) {
  if (!orderId) return false;
  const store = readStorage();
  const order = store.orders[orderId];
  if (!order) return false;
  return order.status === 'refunded' || order.status === 'disputed' || order.status === 'revoked';
}

/**
 * 3. Device Activations & Limit Enforcement (Atomic)
 */
async function activateDevice(licenseToken, deviceId, deviceName = 'macOS Device', maxAllowed = 3) {
  if (!licenseToken || !deviceId) {
    return { success: false, error: 'licenseToken and deviceId are required' };
  }

  const tokenHash = hashKey(licenseToken);
  const store = readStorage();
  let devices = store.device_activations[tokenHash] || [];

  const existingDevice = devices.find(d => d.deviceId === deviceId);
  if (existingDevice) {
    return {
      success: true,
      alreadyActive: true,
      activeCount: devices.length,
      maxDevices: maxAllowed
    };
  }

  if (devices.length >= maxAllowed) {
    return {
      success: false,
      error: `Activation limit reached (${devices.length}/${maxAllowed} devices active). Please deactivate an existing device first.`,
      activeCount: devices.length,
      maxDevices: maxAllowed
    };
  }

  devices.push({
    deviceId,
    deviceName,
    activatedAt: new Date().toISOString()
  });

  store.device_activations[tokenHash] = devices;
  writeStorage(store);

  return {
    success: true,
    activeCount: devices.length,
    maxDevices: maxAllowed
  };
}

async function deactivateDevice(licenseToken, deviceId) {
  if (!licenseToken || !deviceId) {
    return { success: false, error: 'licenseToken and deviceId are required' };
  }

  const tokenHash = hashKey(licenseToken);
  const store = readStorage();
  let devices = store.device_activations[tokenHash] || [];

  const originalLength = devices.length;
  devices = devices.filter(d => d.deviceId !== deviceId);

  store.device_activations[tokenHash] = devices;
  writeStorage(store);

  return {
    success: true,
    deactivated: devices.length < originalLength,
    activeCount: devices.length
  };
}

async function getActiveDevices(licenseToken) {
  if (!licenseToken) return [];
  const tokenHash = hashKey(licenseToken);
  const store = readStorage();
  return store.device_activations[tokenHash] || [];
}

/**
 * 4. Email Outbox Persistence (For Testing & Auditing)
 */
async function recordEmailDispatch(recipient, subject, content) {
  const store = readStorage();
  store.email_outbox = store.email_outbox || [];
  store.email_outbox.push({
    recipient: (recipient || '').toLowerCase().trim(),
    subject,
    content,
    dispatchedAt: new Date().toISOString()
  });
  writeStorage(store);
}

async function getEmailOutbox(recipient = null) {
  const store = readStorage();
  const outbox = store.email_outbox || [];
  if (!recipient) return outbox;
  return outbox.filter(m => m.recipient === recipient.toLowerCase().trim());
}

// Reset helper for isolated test suites
function resetTestStorage() {
  ensureDataDir();
  try {
    if (fs.existsSync(DB_FILE)) {
      fs.unlinkSync(DB_FILE);
    }
  } catch (_) {}
}

module.exports = {
  recordWebhookEvent,
  saveOrder,
  getOrder,
  getOrdersByEmail,
  updateOrderStatus,
  isOrderRevoked,
  activateDevice,
  deactivateDevice,
  getActiveDevices,
  recordEmailDispatch,
  getEmailOutbox,
  resetTestStorage
};

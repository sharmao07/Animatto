/**
 * Animatto Persistent Database Layer (web/lib/db.js)
 * 
 * Provides production-grade ACID storage for Vercel Serverless deployments:
 * - PostgreSQL backed (Vercel Postgres, Neon, Supabase, AWS RDS, Railway)
 * - Atomic webhook event idempotency (processing, completed, failed states)
 * - Durable order persistence & duplicate fulfillment prevention
 * - Advisory transaction locks preventing race conditions in 3-device activation limits
 * - Entitlement revocation tracking (refunds, disputes, chargebacks)
 * - Transactional email outbox with state machine (queued, sent, failed, awaiting_retry)
 * - Fail-closed enforcement: In live/production mode, missing database config throws fatal error.
 *   Never silently falls back to local JSON in production.
 */

const crypto = require('crypto');
const { Pool } = require('pg');

let pool = null;
let mockDbFailure = false;

function hashKey(key) {
  return crypto.createHash('sha256').update(key).digest('hex');
}

function isProductionMode() {
  return process.env.NODE_ENV === 'production' ||
         process.env.DODO_PAYMENTS_MODE === 'live' ||
         process.env.VERCEL === '1';
}

function getDatabaseUrl() {
  return process.env.DATABASE_URL || process.env.POSTGRES_URL || null;
}

function getPool() {
  if (mockDbFailure) {
    throw new Error('Database service unavailable (simulated connection error)');
  }

  const dbUrl = getDatabaseUrl();
  if (isProductionMode() && !dbUrl) {
    throw new Error('FATAL: Production database configuration (DATABASE_URL / POSTGRES_URL) is missing. Failing closed.');
  }

  if (!dbUrl) {
    return null; // Will route to test in-memory engine
  }

  if (!pool) {
    pool = new Pool({
      connectionString: dbUrl,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
      ssl: dbUrl.includes('localhost') ? false : { rejectUnauthorized: false }
    });
  }
  return pool;
}

// ============================================================================
// In-Memory Test/Development Engine (used only when no DATABASE_URL in test mode)
// ============================================================================
const testStore = {
  webhook_events: new Map(),
  orders: new Map(),
  device_activations: new Map(),
  email_outbox: []
};

// ============================================================================
// DDL Schema Initialization & Migrations
// ============================================================================
async function initDatabase() {
  const currentPool = getPool();
  if (!currentPool) {
    return { initialized: true, engine: 'test_memory' };
  }

  const client = await currentPool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS webhook_events (
        event_id VARCHAR(255) PRIMARY KEY,
        event_type VARCHAR(100) NOT NULL,
        order_id VARCHAR(255),
        status VARCHAR(50) NOT NULL DEFAULT 'processing',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        processed_at TIMESTAMPTZ
      );

      CREATE TABLE IF NOT EXISTS orders (
        order_id VARCHAR(255) PRIMARY KEY,
        customer_email VARCHAR(255) NOT NULL,
        product_id VARCHAR(100) NOT NULL,
        license_token TEXT,
        status VARCHAR(50) NOT NULL DEFAULT 'active',
        amount INTEGER NOT NULL DEFAULT 999,
        currency VARCHAR(10) NOT NULL DEFAULT 'USD',
        supporter_name VARCHAR(100),
        supporter_consent BOOLEAN DEFAULT FALSE,
        reason TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      ALTER TABLE orders ADD COLUMN IF NOT EXISTS supporter_name VARCHAR(100);
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS supporter_consent BOOLEAN DEFAULT FALSE;

      CREATE INDEX IF NOT EXISTS idx_orders_customer_email ON orders(customer_email);

      CREATE TABLE IF NOT EXISTS device_activations (
        id SERIAL PRIMARY KEY,
        token_hash VARCHAR(64) NOT NULL,
        device_id VARCHAR(255) NOT NULL,
        device_name VARCHAR(255) NOT NULL DEFAULT 'macOS Device',
        activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT uq_token_device UNIQUE (token_hash, device_id)
      );

      CREATE INDEX IF NOT EXISTS idx_device_token_hash ON device_activations(token_hash);

      CREATE TABLE IF NOT EXISTS email_outbox (
        id SERIAL PRIMARY KEY,
        order_id VARCHAR(255),
        message_type VARCHAR(50) NOT NULL DEFAULT 'license_delivery',
        recipient VARCHAR(255) NOT NULL,
        subject VARCHAR(255) NOT NULL,
        content JSONB NOT NULL,
        status VARCHAR(50) NOT NULL DEFAULT 'queued',
        resend_id VARCHAR(255),
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_retry_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        sent_at TIMESTAMPTZ
      );

      ALTER TABLE email_outbox ADD COLUMN IF NOT EXISTS order_id VARCHAR(255);
      ALTER TABLE email_outbox ADD COLUMN IF NOT EXISTS message_type VARCHAR(50) DEFAULT 'license_delivery';
      ALTER TABLE email_outbox ADD COLUMN IF NOT EXISTS next_retry_at TIMESTAMPTZ;

      CREATE INDEX IF NOT EXISTS idx_email_recipient ON email_outbox(recipient);
      CREATE INDEX IF NOT EXISTS idx_email_status ON email_outbox(status);
      CREATE INDEX IF NOT EXISTS idx_email_order_id ON email_outbox(order_id);
      CREATE INDEX IF NOT EXISTS idx_email_next_retry ON email_outbox(next_retry_at);
    `);
    return { initialized: true, engine: 'postgres' };
  } finally {
    client.release();
  }
}

// ============================================================================
// 1. Webhook Idempotency (Atomic Multi-Phase Tracking)
// ============================================================================
async function recordWebhookEvent(eventId, eventType) {
  if (!eventId) return { duplicate: false };
  const currentPool = getPool();

  if (!currentPool) {
    const existing = testStore.webhook_events.get(eventId);
    if (existing) {
      if (existing.status === 'completed') {
        return { duplicate: true, completed: true, inProgress: false };
      }
      if (existing.status === 'processing') {
        return { duplicate: true, completed: false, inProgress: true };
      }
      // If previous attempt failed, allow retry
      existing.status = 'processing';
      existing.updatedAt = Date.now();
      return { duplicate: false, retry: true };
    }

    testStore.webhook_events.set(eventId, {
      eventId,
      eventType,
      status: 'processing',
      orderId: null,
      createdAt: Date.now(),
      processedAt: null
    });
    return { duplicate: false };
  }

  const client = await currentPool.connect();
  try {
    await client.query('BEGIN');
    const res = await client.query(
      'SELECT status FROM webhook_events WHERE event_id = $1 FOR UPDATE',
      [eventId]
    );

    if (res.rows.length > 0) {
      const status = res.rows[0].status;
      await client.query('COMMIT');
      if (status === 'completed') {
        return { duplicate: true, completed: true, inProgress: false };
      }
      if (status === 'processing') {
        return { duplicate: true, completed: false, inProgress: true };
      }
      // Failed before, allow retry by resetting to processing
      await client.query(
        "UPDATE webhook_events SET status = 'processing', created_at = NOW() WHERE event_id = $1",
        [eventId]
      );
      return { duplicate: false, retry: true };
    }

    await client.query(
      "INSERT INTO webhook_events (event_id, event_type, status) VALUES ($1, $2, 'processing')",
      [eventId, eventType]
    );
    await client.query('COMMIT');
    return { duplicate: false };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function markWebhookCompleted(eventId, orderId = null) {
  if (!eventId) return;
  const currentPool = getPool();

  if (!currentPool) {
    const record = testStore.webhook_events.get(eventId);
    if (record) {
      record.status = 'completed';
      record.orderId = orderId;
      record.processedAt = Date.now();
    }
    return;
  }

  await currentPool.query(
    "UPDATE webhook_events SET status = 'completed', order_id = $2, processed_at = NOW() WHERE event_id = $1",
    [eventId, orderId]
  );
}

async function markWebhookFailed(eventId, reason = '') {
  if (!eventId) return;
  const currentPool = getPool();

  if (!currentPool) {
    const record = testStore.webhook_events.get(eventId);
    if (record) {
      record.status = 'failed';
      record.lastError = reason;
      record.processedAt = Date.now();
    }
    return;
  }

  await currentPool.query(
    "UPDATE webhook_events SET status = 'failed' WHERE event_id = $1",
    [eventId]
  );
}

// ============================================================================
// 2. Order Persistence & Fulfillment
// ============================================================================
async function saveOrder(order) {
  if (!order || !order.orderId) {
    throw new Error('Invalid order object');
  }
  const currentPool = getPool();
  const email = (order.customerEmail || '').toLowerCase().trim();

  if (!currentPool) {
    const existing = testStore.orders.get(order.orderId);
    if (existing && existing.status === 'active' && existing.licenseToken) {
      return { success: true, duplicate: true, order: existing };
    }

    const record = {
      orderId: order.orderId,
      customerEmail: email,
      productId: order.productId || 'animatto_pro_lifetime',
      tier: order.tier || ((order.productId || '').includes('founder') ? 'founder' : 'pro'),
      licenseToken: order.licenseToken || null,
      status: order.status || 'active',
      amount: order.amount || 399,
      currency: order.currency || 'USD',
      supporterName: order.supporterName || null,
      supporterConsent: !!order.supporterConsent,
      reason: order.reason || '',
      createdAt: order.createdAt || new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    testStore.orders.set(order.orderId, record);
    return { success: true, order: record };
  }

  const client = await currentPool.connect();
  try {
    await client.query('BEGIN');
    // Lock advisory mutex on orderId to serialize simultaneous fulfillments
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', ['ord_' + order.orderId]);

    const existingRes = await client.query(
      'SELECT * FROM orders WHERE order_id = $1 FOR UPDATE',
      [order.orderId]
    );

    if (existingRes.rows.length > 0) {
      const existing = existingRes.rows[0];
      if (existing.status === 'active' && existing.license_token) {
        await client.query('COMMIT');
        return {
          success: true,
          duplicate: true,
          order: {
            orderId: existing.order_id,
            customerEmail: existing.customer_email,
            productId: existing.product_id,
            licenseToken: existing.license_token,
            status: existing.status,
            amount: existing.amount,
            currency: existing.currency,
            supporterName: existing.supporter_name,
            supporterConsent: existing.supporter_consent
          }
        };
      }
    }

    await client.query(`
      INSERT INTO orders (order_id, customer_email, product_id, license_token, status, amount, currency, supporter_name, supporter_consent)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ON CONFLICT (order_id) DO UPDATE SET
        customer_email = EXCLUDED.customer_email,
        license_token = EXCLUDED.license_token,
        status = EXCLUDED.status,
        amount = EXCLUDED.amount,
        currency = EXCLUDED.currency,
        supporter_name = EXCLUDED.supporter_name,
        supporter_consent = EXCLUDED.supporter_consent,
        updated_at = NOW()
    `, [
      order.orderId,
      email,
      order.productId || 'animatto_pro_lifetime',
      order.licenseToken || null,
      order.status || 'active',
      order.amount || 399,
      order.currency || 'USD',
      order.supporterName || null,
      !!order.supporterConsent
    ]);

    await client.query('COMMIT');
    return { success: true, order };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function getOrder(orderId) {
  if (!orderId) return null;
  const currentPool = getPool();

  if (!currentPool) {
    return testStore.orders.get(orderId) || null;
  }

  const res = await currentPool.query('SELECT * FROM orders WHERE order_id = $1', [orderId]);
  if (res.rows.length === 0) return null;
  const row = res.rows[0];
  return {
    orderId: row.order_id,
    customerEmail: row.customer_email,
    productId: row.product_id,
    tier: (row.product_id || '').includes('founder') ? 'founder' : 'pro',
    licenseToken: row.license_token,
    status: row.status,
    amount: row.amount,
    currency: row.currency,
    supporterName: row.supporter_name,
    supporterConsent: row.supporter_consent,
    reason: row.reason,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

async function getOrdersByEmail(email) {
  if (!email) return [];
  const cleanEmail = email.toLowerCase().trim();
  const currentPool = getPool();

  if (!currentPool) {
    return Array.from(testStore.orders.values()).filter(
      ord => ord.customerEmail.toLowerCase() === cleanEmail
    );
  }

  const res = await currentPool.query(
    'SELECT * FROM orders WHERE LOWER(customer_email) = $1 ORDER BY created_at DESC',
    [cleanEmail]
  );
  return res.rows.map(row => ({
    orderId: row.order_id,
    customerEmail: row.customer_email,
    productId: row.product_id,
    licenseToken: row.license_token,
    status: row.status,
    amount: row.amount,
    currency: row.currency,
    supporterName: row.supporter_name,
    supporterConsent: row.supporter_consent,
    reason: row.reason,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  }));
  return res.rows.map(row => ({
    orderId: row.order_id,
    customerEmail: row.customer_email,
    productId: row.product_id,
    licenseToken: row.license_token,
    status: row.status,
    amount: row.amount,
    currency: row.currency,
    reason: row.reason,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  }));
}

async function updateOrderStatus(orderId, status, reason = '') {
  if (!orderId) return false;
  const currentPool = getPool();

  if (!currentPool) {
    const existing = testStore.orders.get(orderId);
    if (!existing) {
      testStore.orders.set(orderId, {
        orderId,
        customerEmail: 'unknown',
        productId: 'animatto_pro_lifetime',
        licenseToken: null,
        status,
        reason,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
    } else {
      existing.status = status;
      existing.reason = reason;
      existing.updatedAt = new Date().toISOString();
    }
    return true;
  }

  await currentPool.query(`
    INSERT INTO orders (order_id, customer_email, product_id, status, reason)
    VALUES ($1, 'unknown', 'animatto_pro_lifetime', $2, $3)
    ON CONFLICT (order_id) DO UPDATE SET
      status = EXCLUDED.status,
      reason = EXCLUDED.reason,
      updated_at = NOW()
  `, [orderId, status, reason]);
  return true;
}

async function isOrderRevoked(orderId) {
  if (!orderId) return false;
  const order = await getOrder(orderId);
  if (!order) return false;
  return order.status === 'refunded' || order.status === 'disputed' || order.status === 'revoked';
}

// ============================================================================
// 3. Atomic Device Activation Limits (Advisory Locks in Postgres)
// ============================================================================
async function activateDevice(licenseToken, deviceId, deviceName = 'macOS Device', maxAllowed = 3) {
  if (!licenseToken || !deviceId) {
    return { success: false, error: 'licenseToken and deviceId are required' };
  }

  const tokenHash = hashKey(licenseToken);
  const currentPool = getPool();

  if (!currentPool) {
    // Memory engine with atomic isolation
    let devices = testStore.device_activations.get(tokenHash) || [];
    const existing = devices.find(d => d.deviceId === deviceId);
    if (existing) {
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
    testStore.device_activations.set(tokenHash, devices);
    return {
      success: true,
      activeCount: devices.length,
      maxDevices: maxAllowed
    };
  }

  const client = await currentPool.connect();
  try {
    await client.query('BEGIN');
    // Lock advisory mutex on token hash to prevent concurrent activation race
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [tokenHash]);

    const activeRes = await client.query(
      'SELECT device_id FROM device_activations WHERE token_hash = $1',
      [tokenHash]
    );

    const devices = activeRes.rows;
    const isAlreadyActive = devices.some(d => d.device_id === deviceId);
    if (isAlreadyActive) {
      await client.query('COMMIT');
      return {
        success: true,
        alreadyActive: true,
        activeCount: devices.length,
        maxDevices: maxAllowed
      };
    }

    if (devices.length >= maxAllowed) {
      await client.query('COMMIT');
      return {
        success: false,
        error: `Activation limit reached (${devices.length}/${maxAllowed} devices active). Please deactivate an existing device first.`,
        activeCount: devices.length,
        maxDevices: maxAllowed
      };
    }

    await client.query(
      'INSERT INTO device_activations (token_hash, device_id, device_name) VALUES ($1, $2, $3)',
      [tokenHash, deviceId, deviceName]
    );

    await client.query('COMMIT');
    return {
      success: true,
      activeCount: devices.length + 1,
      maxDevices: maxAllowed
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function deactivateDevice(licenseToken, deviceId) {
  if (!licenseToken || !deviceId) {
    return { success: false, error: 'licenseToken and deviceId are required' };
  }

  const tokenHash = hashKey(licenseToken);
  const currentPool = getPool();

  if (!currentPool) {
    let devices = testStore.device_activations.get(tokenHash) || [];
    const origLen = devices.length;
    devices = devices.filter(d => d.deviceId !== deviceId);
    testStore.device_activations.set(tokenHash, devices);
    return {
      success: true,
      deactivated: devices.length < origLen,
      activeCount: devices.length
    };
  }

  const client = await currentPool.connect();
  try {
    const res = await client.query(
      'DELETE FROM device_activations WHERE token_hash = $1 AND device_id = $2',
      [tokenHash, deviceId]
    );
    const countRes = await client.query(
      'SELECT count(*) FROM device_activations WHERE token_hash = $1',
      [tokenHash]
    );
    return {
      success: true,
      deactivated: res.rowCount > 0,
      activeCount: parseInt(countRes.rows[0].count, 10)
    };
  } finally {
    client.release();
  }
}

async function getActiveDevices(licenseToken) {
  if (!licenseToken) return [];
  const tokenHash = hashKey(licenseToken);
  const currentPool = getPool();

  if (!currentPool) {
    return testStore.device_activations.get(tokenHash) || [];
  }

  const res = await currentPool.query(
    'SELECT device_id, device_name, activated_at FROM device_activations WHERE token_hash = $1 ORDER BY activated_at ASC',
    [tokenHash]
  );
  return res.rows.map(r => ({
    deviceId: r.device_id,
    deviceName: r.device_name,
    activatedAt: r.activated_at
  }));
}

// ============================================================================
// 4. Transactional Email Outbox Persistence & State Management
// ============================================================================
async function queueEmail({ recipient, subject, content, orderId = null, messageType = 'license_delivery' }) {
  const cleanRecipient = (recipient || '').toLowerCase().trim();
  const currentPool = getPool();

  if (!currentPool) {
    const id = testStore.email_outbox.length + 1;
    const record = {
      id,
      orderId,
      messageType,
      recipient: cleanRecipient,
      subject,
      content,
      status: 'queued',
      resendId: null,
      attempts: 0,
      lastError: null,
      nextRetryAt: null,
      createdAt: new Date().toISOString(),
      sentAt: null
    };
    testStore.email_outbox.push(record);
    return id;
  }

  const res = await currentPool.query(`
    INSERT INTO email_outbox (recipient, subject, content, status, order_id, message_type)
    VALUES ($1, $2, $3, 'queued', $4, $5)
    RETURNING id
  `, [cleanRecipient, subject, JSON.stringify(content), orderId, messageType]);
  return res.rows[0].id;
}

async function getEmailByOrderId(orderId, messageType = 'license_delivery') {
  if (!orderId) return null;
  const currentPool = getPool();

  if (!currentPool) {
    return testStore.email_outbox.find(
      m => m.orderId === orderId && m.messageType === messageType
    ) || null;
  }

  const res = await currentPool.query(
    'SELECT * FROM email_outbox WHERE order_id = $1 AND message_type = $2 ORDER BY id DESC LIMIT 1',
    [orderId, messageType]
  );
  if (res.rows.length === 0) return null;
  const r = res.rows[0];
  return {
    id: r.id,
    orderId: r.order_id,
    messageType: r.message_type,
    recipient: r.recipient,
    subject: r.subject,
    content: r.content,
    status: r.status,
    resendId: r.resend_id,
    attempts: r.attempts,
    lastError: r.last_error,
    nextRetryAt: r.next_retry_at,
    createdAt: r.created_at,
    sentAt: r.sent_at
  };
}

async function updateEmailOutbox(id, { status, resendId = null, lastError = null, attempts = 1, nextRetryAt = null }) {
  const currentPool = getPool();

  if (!currentPool) {
    const item = testStore.email_outbox.find(m => m.id === id);
    if (item) {
      item.status = status;
      if (resendId) item.resendId = resendId;
      if (lastError !== undefined) item.lastError = lastError;
      item.attempts = attempts;
      if (nextRetryAt !== undefined) item.nextRetryAt = nextRetryAt ? nextRetryAt.toISOString() : null;
      if (status === 'sent') item.sentAt = new Date().toISOString();
    }
    return;
  }

  await currentPool.query(`
    UPDATE email_outbox
    SET status = $2,
        resend_id = COALESCE($3, resend_id),
        last_error = $4,
        attempts = $5,
        next_retry_at = $6,
        sent_at = CASE WHEN $2 = 'sent' THEN NOW() ELSE sent_at END
    WHERE id = $1
  `, [id, status, resendId, lastError, attempts, nextRetryAt]);
}

async function getEmailsAwaitingRetry(limit = 10) {
  const currentPool = getPool();

  if (!currentPool) {
    const now = Date.now();
    return testStore.email_outbox.filter(m => {
      if (m.status !== 'awaiting_retry') return false;
      if (!m.nextRetryAt) return true;
      return new Date(m.nextRetryAt).getTime() <= now;
    }).slice(0, limit);
  }

  const res = await currentPool.query(`
    SELECT * FROM email_outbox
    WHERE status = 'awaiting_retry'
      AND (next_retry_at IS NULL OR next_retry_at <= NOW())
    ORDER BY id ASC
    LIMIT $1
  `, [limit]);

  return res.rows.map(r => ({
    id: r.id,
    orderId: r.order_id,
    messageType: r.message_type,
    recipient: r.recipient,
    subject: r.subject,
    content: r.content,
    status: r.status,
    resendId: r.resend_id,
    attempts: r.attempts,
    lastError: r.last_error,
    nextRetryAt: r.next_retry_at,
    createdAt: r.created_at,
    sentAt: r.sent_at
  }));
}

async function recoverFailedEmail(outboxId) {
  const currentPool = getPool();

  if (!currentPool) {
    const item = testStore.email_outbox.find(m => m.id === outboxId);
    if (item) {
      item.status = 'awaiting_retry';
      item.nextRetryAt = new Date().toISOString();
      item.attempts = 0;
      return true;
    }
    return false;
  }

  const res = await currentPool.query(`
    UPDATE email_outbox
    SET status = 'awaiting_retry',
        next_retry_at = NOW(),
        attempts = 0
    WHERE id = $1
  `, [outboxId]);
  return res.rowCount > 0;
}

async function getEmailOutbox(recipient = null) {
  const currentPool = getPool();

  if (!currentPool) {
    if (!recipient) return testStore.email_outbox;
    const clean = recipient.toLowerCase().trim();
    return testStore.email_outbox.filter(m => m.recipient === clean);
  }

  if (recipient) {
    const res = await currentPool.query(
      'SELECT * FROM email_outbox WHERE LOWER(recipient) = $1 ORDER BY id DESC',
      [recipient.toLowerCase().trim()]
    );
    return res.rows;
  }

  const res = await currentPool.query('SELECT * FROM email_outbox ORDER BY id DESC');
  return res.rows;
}

// ============================================================================
// Testing & Diagnostics Helpers
// ============================================================================
function resetTestStorage() {
  testStore.webhook_events.clear();
  testStore.orders.clear();
  testStore.device_activations.clear();
  testStore.email_outbox = [];
  mockDbFailure = false;
}

function setMockDbFailure(fail) {
  mockDbFailure = !!fail;
}

async function closePool() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

module.exports = {
  initDatabase,
  recordWebhookEvent,
  markWebhookCompleted,
  markWebhookFailed,
  saveOrder,
  getOrder,
  getOrdersByEmail,
  updateOrderStatus,
  isOrderRevoked,
  activateDevice,
  deactivateDevice,
  getActiveDevices,
  queueEmail,
  updateEmailOutbox,
  getEmailOutbox,
  getEmailByOrderId,
  getEmailsAwaitingRetry,
  recoverFailedEmail,
  resetTestStorage,
  setMockDbFailure,
  closePool,
  isProductionMode,
  getDatabaseUrl
};

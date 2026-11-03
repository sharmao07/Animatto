/**
 * Animatto License Validation, Activation & Recovery API (/api/license)
 * 
 * Public API for desktop app activation checks, 3-device limits, and license recovery.
 * Fully supports offline operation; online verification is optional and additive.
 * 
 * Production Security:
 * - Backed by durable atomic database layer (web/lib/db.js)
 * - Verifies revocation state against persisted orders (refunds & chargebacks)
 * - Restricts CORS to verified domains
 * - Dispatches recovery emails via transactional email provider (web/lib/email.js)
 * - Rate limited and protected against parameter tampering
 */

const { verifyLicenseToken } = require('../lib/crypto');
const db = require('../lib/db');
const emailHelper = require('../lib/email');

// Rate limiting map (sliding window)
const requestTracker = new Map();
const MAX_REQUESTS_PER_MINUTE = 40;
const MAX_BODY_BYTES = 16 * 1024; // 16 KB

function isRateLimited(ip) {
  const now = Date.now();
  const windowMs = 60 * 1000;
  const history = (requestTracker.get(ip) || []).filter(t => now - t < windowMs);
  if (history.length >= MAX_REQUESTS_PER_MINUTE) return true;
  history.push(now);
  requestTracker.set(ip, history);
  return false;
}

// CORS Origin Validation
function setCorsHeaders(req, res) {
  const origin = req.headers.origin;
  const allowedOriginPattern = /^(https:\/\/([a-z0-9-]+\.)?animatto\.app|https:\/\/[a-z0-9-]+\.vercel\.app|http:\/\/localhost(:\d+)?|http:\/\/127\.0\.0\.1(:\d+)?)$/;

  if (origin && allowedOriginPattern.test(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  } else {
    res.setHeader('Access-Control-Allow-Origin', 'https://animatto.app');
  }

  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

module.exports = async function handler(req, res) {
  setCorsHeaders(req, res);

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  if (isRateLimited(clientIp)) {
    return res.status(429).json({ error: 'Too many requests. Please retry in 1 minute.' });
  }

  // Request size limit
  let rawBodyLength = 0;
  if (typeof req.body === 'string') {
    rawBodyLength = Buffer.byteLength(req.body);
  } else if (Buffer.isBuffer(req.body)) {
    rawBodyLength = req.body.length;
  } else if (req.body && typeof req.body === 'object') {
    rawBodyLength = Buffer.byteLength(JSON.stringify(req.body));
  }
  if (rawBodyLength > MAX_BODY_BYTES) {
    return res.status(413).json({ error: 'Request body exceeds maximum size' });
  }

  const reqBody = (req.body && typeof req.body === 'object') ? req.body : {};
  const action = req.query.action || reqBody.action || 'validate';
  const licenseKey = (req.query.key || reqBody.license_key || reqBody.licenseKey || '').trim();

  switch (action) {
    case 'validate': {
      if (!licenseKey) {
        return res.status(400).json({ valid: false, error: 'License key is required' });
      }

      const result = verifyLicenseToken(licenseKey);
      if (!result.valid) {
        return res.status(200).json({ valid: false, error: result.error });
      }

      // Check durable storage for revocation (refund or dispute)
      const orderId = result.payload.orderId;
      if (orderId) {
        const isRevoked = await db.isOrderRevoked(orderId);
        if (isRevoked) {
          return res.status(200).json({
            valid: false,
            revoked: true,
            error: 'License has been revoked due to refund or chargeback.'
          });
        }
      }

      const devices = await db.getActiveDevices(licenseKey);
      return res.status(200).json({
        valid: true,
        tier: result.payload.tier,
        order_id: result.payload.orderId,
        max_devices: result.payload.maxDevices,
        active_devices_count: devices.length,
        entitlements: result.payload.entitlements,
        issued_at: result.payload.issuedAt,
        expires_at: result.payload.expiresAt
      });
    }

    case 'activate': {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method Not Allowed. Use POST.' });
      }

      const deviceId = (reqBody.device_id || reqBody.deviceId || '').trim();
      const deviceName = (reqBody.device_name || reqBody.deviceName || 'macOS Device').trim();

      if (!licenseKey || !deviceId) {
        return res.status(400).json({ success: false, error: 'license_key and device_id are required' });
      }

      const verification = verifyLicenseToken(licenseKey);
      if (!verification.valid) {
        return res.status(400).json({ success: false, error: verification.error });
      }

      // Check durable storage for revocation
      const orderId = verification.payload.orderId;
      if (orderId) {
        const isRevoked = await db.isOrderRevoked(orderId);
        if (isRevoked) {
          return res.status(403).json({
            success: false,
            revoked: true,
            error: 'License has been revoked due to refund or chargeback.'
          });
        }
      }

      const maxAllowed = verification.payload.maxDevices || 3;
      const activation = await db.activateDevice(licenseKey, deviceId, deviceName, maxAllowed);

      if (!activation.success) {
        return res.status(403).json({
          success: false,
          error: activation.error,
          active_devices_count: activation.activeCount,
          max_devices: activation.maxDevices
        });
      }

      return res.status(200).json({
        success: true,
        activated: true,
        already_active: !!activation.alreadyActive,
        device_id: deviceId,
        device_name: deviceName,
        active_devices_count: activation.activeCount,
        max_devices: activation.maxDevices
      });
    }

    case 'deactivate': {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method Not Allowed. Use POST.' });
      }

      const deviceId = (reqBody.device_id || reqBody.deviceId || '').trim();
      if (!licenseKey || !deviceId) {
        return res.status(400).json({ success: false, error: 'license_key and device_id are required' });
      }

      const result = await db.deactivateDevice(licenseKey, deviceId);
      return res.status(200).json({
        success: true,
        deactivated: result.deactivated,
        device_id: deviceId,
        active_devices_count: result.activeCount
      });
    }

    case 'recover': {
      const email = (req.query.email || reqBody.email || '').trim().toLowerCase();
      if (!email || !email.includes('@') || email.length > 254) {
        return res.status(400).json({ success: false, error: 'Valid email address is required' });
      }

      // Retrieve orders linked to email from durable storage
      const orders = await db.getOrdersByEmail(email);

      // Dispatch recovery email
      try {
        await emailHelper.sendRecoveryEmail({ email, orders });
      } catch (err) {
        console.error('[License API] Failed to dispatch recovery email:', err.message);
      }

      // Constant response prevents email scraping/enumeration
      return res.status(200).json({
        success: true,
        message: `If an Animatto Pro purchase is linked to ${email}, a license recovery email has been sent with activation instructions.`
      });
    }

    default:
      return res.status(400).json({ error: `Unknown action: ${action}` });
  }
};

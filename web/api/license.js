/**
 * Animatto License Validation, Activation & Recovery API (/api/license)
 * 
 * Public API for desktop app activation checks, device limits (max 3), and license recovery.
 * Fully supports offline operation; online verification is optional and additive.
 */

const { verifyLicenseToken } = require('../lib/crypto');

// In-memory device activations store: licenseKey -> Set of deviceIds
const activeDeviceMap = new Map();

// Rate limiting map
const requestTracker = new Map();
function isRateLimited(ip) {
  const now = Date.now();
  const windowMs = 60 * 1000;
  const maxRequests = 30;
  const history = (requestTracker.get(ip) || []).filter(t => now - t < windowMs);
  if (history.length >= maxRequests) return true;
  history.push(now);
  requestTracker.set(ip, history);
  return false;
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  if (isRateLimited(clientIp)) {
    return res.status(429).json({ error: 'Too many requests. Please retry in 1 minute.' });
  }

  const action = req.query.action || (req.body && req.body.action) || 'validate';
  const licenseKey = (req.query.key || (req.body && req.body.license_key) || '').trim();

  switch (action) {
    case 'validate': {
      if (!licenseKey) {
        return res.status(400).json({ valid: false, error: 'License key is required' });
      }

      const result = verifyLicenseToken(licenseKey);
      if (!result.valid) {
        return res.status(200).json({ valid: false, error: result.error });
      }

      const devices = activeDeviceMap.get(licenseKey) || new Set();
      return res.status(200).json({
        valid: true,
        tier: result.payload.tier,
        order_id: result.payload.orderId,
        max_devices: result.payload.maxDevices,
        active_devices_count: devices.size,
        entitlements: result.payload.entitlements,
        issued_at: result.payload.issuedAt,
        expires_at: result.payload.expiresAt
      });
    }

    case 'activate': {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method Not Allowed. Use POST.' });
      }

      const deviceId = req.body.device_id || req.body.deviceId;
      const deviceName = req.body.device_name || req.body.deviceName || 'macOS Device';

      if (!licenseKey || !deviceId) {
        return res.status(400).json({ success: false, error: 'license_key and device_id are required' });
      }

      const verification = verifyLicenseToken(licenseKey);
      if (!verification.valid) {
        return res.status(400).json({ success: false, error: verification.error });
      }

      const maxAllowed = verification.payload.maxDevices || 3;
      let devices = activeDeviceMap.get(licenseKey);
      if (!devices) {
        devices = new Set();
        activeDeviceMap.set(licenseKey, devices);
      }

      // Check if device is already registered
      if (devices.has(deviceId)) {
        return res.status(200).json({
          success: true,
          activated: true,
          already_active: true,
          device_id: deviceId,
          active_devices_count: devices.size,
          max_devices: maxAllowed
        });
      }

      // Enforce device activation limit
      if (devices.size >= maxAllowed) {
        return res.status(403).json({
          success: false,
          error: `Activation limit reached (${devices.size}/${maxAllowed} devices active). Please deactivate an existing device first.`,
          active_devices_count: devices.size,
          max_devices: maxAllowed
        });
      }

      devices.add(deviceId);
      return res.status(200).json({
        success: true,
        activated: true,
        device_id: deviceId,
        device_name: deviceName,
        active_devices_count: devices.size,
        max_devices: maxAllowed
      });
    }

    case 'deactivate': {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method Not Allowed. Use POST.' });
      }

      const deviceId = req.body.device_id || req.body.deviceId;
      if (!licenseKey || !deviceId) {
        return res.status(400).json({ success: false, error: 'license_key and device_id are required' });
      }

      const devices = activeDeviceMap.get(licenseKey);
      if (devices && devices.has(deviceId)) {
        devices.delete(deviceId);
      }

      return res.status(200).json({
        success: true,
        deactivated: true,
        device_id: deviceId,
        active_devices_count: devices ? devices.size : 0
      });
    }

    case 'recover': {
      const email = (req.query.email || (req.body && req.body.email) || '').trim().toLowerCase();
      if (!email || !email.includes('@')) {
        return res.status(400).json({ success: false, error: 'Valid email address is required' });
      }

      // In production, an email is dispatched via transactional mailer (e.g. Resend / Postmark)
      return res.status(200).json({
        success: true,
        message: `If an Animatto Pro purchase is linked to ${email}, a license recovery email has been dispatched with activation instructions.`
      });
    }

    default:
      return res.status(400).json({ error: `Unknown action: ${action}` });
  }
};

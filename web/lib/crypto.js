/**
 * Animatto Licensing Cryptography & Webhook Verification
 * 
 * Uses standard Node.js crypto (zero external dependencies).
 * Implements:
 * - Ed25519 cryptographic license token signing and verification
 * - Standard Webhooks HMAC-SHA256 signature verification
 * - Base64URL encoding / decoding
 */

const crypto = require('crypto');

// Official Animatto Public Key (bundled in macOS client app)
const OFFICIAL_PUBLIC_KEY_BASE64 = 'CqNYSSbL+GQhajYLCs3NBsqtS5PdRlknpmSRA6OjgUc=';

// Base64URL Helpers
function base64UrlEncode(buffer) {
  return buffer.toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function base64UrlDecode(str) {
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4 !== 0) {
    base64 += '=';
  }
  return Buffer.from(base64, 'base64');
}

/**
 * Creates a Node crypto PrivateKey object from an Ed25519 32-byte seed in Base64
 */
function createPrivateKeyFromSeed(seedBase64) {
  const seed = Buffer.from(seedBase64, 'base64');
  if (seed.length !== 32) {
    throw new Error(`Invalid Ed25519 private key seed length: ${seed.length} (expected 32)`);
  }
  // PKCS#8 prefix for Ed25519 (RFC 8410)
  const pkcs8Prefix = Buffer.from('302e020100300506032b657004220420', 'hex');
  return crypto.createPrivateKey({
    key: Buffer.concat([pkcs8Prefix, seed]),
    format: 'der',
    type: 'pkcs8'
  });
}

/**
 * Creates a Node crypto PublicKey object from an Ed25519 32-byte raw public key in Base64
 */
function createPublicKeyFromRaw(rawBase64) {
  const raw = Buffer.from(rawBase64, 'base64');
  if (raw.length !== 32) {
    throw new Error(`Invalid Ed25519 public key raw length: ${raw.length} (expected 32)`);
  }
  // SPKI prefix for Ed25519
  const spkiPrefix = Buffer.from('302a300506032b6570032100', 'hex');
  return crypto.createPublicKey({
    key: Buffer.concat([spkiPrefix, raw]),
    format: 'der',
    type: 'spki'
  });
}

/**
 * Generates a signed license token string:
 * Format: ANIM-PRO-<BASE64URL_JSON_PAYLOAD>.<BASE64URL_ED25519_SIGNATURE>
 */
function generateLicenseToken(payload, privateKeySeedBase64) {
  const privateKey = createPrivateKeyFromSeed(privateKeySeedBase64);
  
  // Canonical JSON representation
  const canonicalJson = JSON.stringify({
    orderId: String(payload.orderId || ''),
    customerEmail: String(payload.customerEmail || '').toLowerCase().trim(),
    productId: String(payload.productId || 'animatto_pro_lifetime'),
    tier: String(payload.tier || 'pro'),
    maxDevices: Number(payload.maxDevices || 3),
    issuedAt: Number(payload.issuedAt || Math.floor(Date.now() / 1000)),
    expiresAt: payload.expiresAt ? Number(payload.expiresAt) : null,
    entitlements: Array.isArray(payload.entitlements) ? payload.entitlements : [
      'pro_sound_studio',
      'pro_custom_palettes',
      'aquarium_pro',
      'multi_device_3'
    ]
  });

  const payloadBuffer = Buffer.from(canonicalJson, 'utf8');
  const signature = crypto.sign(null, payloadBuffer, privateKey);

  const payloadB64Url = base64UrlEncode(payloadBuffer);
  const signatureB64Url = base64UrlEncode(signature);

  return `ANIM-PRO-${payloadB64Url}.${signatureB64Url}`;
}

/**
 * Verifies a signed license token string
 */
function verifyLicenseToken(token, publicKeyBase64 = OFFICIAL_PUBLIC_KEY_BASE64) {
  if (!token || typeof token !== 'string' || !token.startsWith('ANIM-PRO-')) {
    return { valid: false, error: 'Invalid license format prefix' };
  }

  const rawToken = token.slice('ANIM-PRO-'.length);
  const parts = rawToken.split('.');
  if (parts.length !== 2) {
    return { valid: false, error: 'Malformed token structure' };
  }

  try {
    const payloadBuffer = base64UrlDecode(parts[0]);
    const signatureBuffer = base64UrlDecode(parts[1]);

    if (signatureBuffer.length !== 64) {
      return { valid: false, error: 'Invalid signature length' };
    }

    const publicKey = createPublicKeyFromRaw(publicKeyBase64);
    const isSignatureValid = crypto.verify(null, payloadBuffer, publicKey, signatureBuffer);

    if (!isSignatureValid) {
      return { valid: false, error: 'Cryptographic signature mismatch' };
    }

    const payload = JSON.parse(payloadBuffer.toString('utf8'));

    // Check expiration
    if (payload.expiresAt && payload.expiresAt < Math.floor(Date.now() / 1000)) {
      return { valid: false, error: 'License expired', payload };
    }

    return { valid: true, payload };
  } catch (err) {
    return { valid: false, error: err.message };
  }
}

/**
 * Verifies Dodo Payments / Standard Webhooks HMAC-SHA256 signature
 * Headers: webhook-id, webhook-timestamp, webhook-signature
 * Secret: string (or with 'whsec_' prefix)
 */
function verifyWebhookSignature(rawBody, headers, webhookSecret) {
  if (!webhookSecret) {
    throw new Error('Webhook secret is required for verification');
  }

  const id = headers['webhook-id'] || headers['Webhook-Id'];
  const timestamp = headers['webhook-timestamp'] || headers['Webhook-Timestamp'];
  const signatureHeader = headers['webhook-signature'] || headers['Webhook-Signature'];

  if (!id || !timestamp || !signatureHeader) {
    return { valid: false, reason: 'Missing required webhook verification headers' };
  }

  // Prevent replay attacks (tolerance: 5 minutes)
  const now = Math.floor(Date.now() / 1000);
  const tsNum = parseInt(timestamp, 10);
  if (isNaN(tsNum) || Math.abs(now - tsNum) > 300) {
    return { valid: false, reason: 'Webhook timestamp outside 5-minute replay tolerance window' };
  }

  // Strip 'whsec_' prefix if present
  let cleanSecret = webhookSecret;
  if (cleanSecret.startsWith('whsec_')) {
    cleanSecret = cleanSecret.slice('whsec_'.length);
  }
  const secretBytes = Buffer.from(cleanSecret, 'base64');

  // Payload to sign according to Standard Webhooks specification: `${id}.${timestamp}.${rawBody}`
  const toSign = `${id}.${timestamp}.${rawBody}`;
  const computedHmac = crypto.createHmac('sha256', secretBytes)
    .update(toSign)
    .digest('base64');

  // The webhook-signature header may contain multiple signatures separated by space, e.g. "v1,g0hM9Sv... v1,..."
  const signatureCandidates = signatureHeader.split(' ');
  for (const candidate of signatureCandidates) {
    let sig = candidate;
    if (sig.startsWith('v1,')) {
      sig = sig.slice(3);
    }
    
    // Constant-time comparison
    const sigBuf = Buffer.from(sig);
    const compBuf = Buffer.from(computedHmac);
    if (sigBuf.length === compBuf.length && crypto.timingSafeEqual(sigBuf, compBuf)) {
      return { valid: true, id, timestamp: tsNum };
    }
  }

  return { valid: false, reason: 'HMAC-SHA256 signature mismatch' };
}

module.exports = {
  OFFICIAL_PUBLIC_KEY_BASE64,
  base64UrlEncode,
  base64UrlDecode,
  generateLicenseToken,
  verifyLicenseToken,
  verifyWebhookSignature
};

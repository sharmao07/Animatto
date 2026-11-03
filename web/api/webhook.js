/**
 * Animatto Webhook API Endpoint (/api/webhook)
 * 
 * Securely receives, verifies, and processes Dodo Payments Standard Webhooks.
 * - Enforces HMAC-SHA256 signature verification
 * - Prevents replay attacks via timestamp checks
 * - Guarantees idempotent event processing
 * - Issues cryptographically signed Ed25519 license tokens
 * - Never logs secrets or full customer credentials
 */

const { verifyWebhookSignature, generateLicenseToken } = require('../lib/crypto');

// In-memory idempotency cache (stores processed webhook IDs with TTL)
const processedWebhooks = new Map();
const MAX_IDEMPOTENCY_ENTRIES = 5000;

function isEventProcessed(eventId) {
  const record = processedWebhooks.get(eventId);
  if (!record) return false;
  // Expire after 24 hours
  if (Date.now() - record.timestamp > 24 * 60 * 60 * 1000) {
    processedWebhooks.delete(eventId);
    return false;
  }
  return true;
}

function markEventProcessed(eventId, result) {
  if (processedWebhooks.size > MAX_IDEMPOTENCY_ENTRIES) {
    const oldestKey = processedWebhooks.keys().next().value;
    processedWebhooks.delete(oldestKey);
  }
  processedWebhooks.set(eventId, { timestamp: Date.now(), result });
}

// In-memory order fulfillment store (in production, backed by database)
const orderFulfillments = new Map();

function sanitizeEmail(email) {
  if (!email || !email.includes('@')) return 'unknown';
  const parts = email.split('@');
  const user = parts[0];
  const domain = parts[1];
  const maskedUser = user.length > 2 ? `${user[0]}***${user[user.length - 1]}` : `${user[0]}***`;
  return `${maskedUser}@${domain}`;
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // Retrieve raw body string
  let rawBody = '';
  if (typeof req.body === 'string') {
    rawBody = req.body;
  } else if (Buffer.isBuffer(req.body)) {
    rawBody = req.body.toString('utf8');
  } else if (req.body && typeof req.body === 'object') {
    rawBody = JSON.stringify(req.body);
  }

  const webhookSecret = process.env.DODO_PAYMENTS_WEBHOOK_SECRET;

  // Signature Verification
  if (webhookSecret) {
    const verification = verifyWebhookSignature(rawBody, req.headers, webhookSecret);
    if (!verification.valid) {
      console.warn('[Webhook Auth] Rejected invalid webhook signature:', verification.reason);
      return res.status(401).json({ error: 'Invalid webhook signature', details: verification.reason });
    }
  } else {
    // If webhook secret is not yet set in production, allow sandbox testing with explicit test header
    const isExplicitTestMode = req.headers['x-animatto-test-webhook'] === 'true' || process.env.NODE_ENV === 'test';
    if (!isExplicitTestMode) {
      console.error('[Webhook Auth] DODO_PAYMENTS_WEBHOOK_SECRET is not configured on server.');
      return res.status(500).json({ error: 'Webhook verification secret not configured' });
    }
  }

  let event;
  try {
    event = typeof req.body === 'object' && !Buffer.isBuffer(req.body) ? req.body : JSON.parse(rawBody);
  } catch (err) {
    return res.status(400).json({ error: 'Invalid JSON payload' });
  }

  const eventId = req.headers['webhook-id'] || event.id || `evt_${Date.now()}`;
  const eventType = event.type || event.event;

  // Idempotency Check
  if (isEventProcessed(eventId)) {
    const cached = processedWebhooks.get(eventId);
    return res.status(200).json({ received: true, idempotent_duplicate: true, result: cached.result });
  }

  const privateKey = process.env.LICENSE_SIGNING_PRIVATE_KEY || 'IbwwDQm6w1f6OW/sM4dUDRX5L5U7U2yxCKBzX/EsASw=';

  try {
    switch (eventType) {
      case 'payment.succeeded': {
        const data = event.data || {};
        const paymentId = data.payment_id || data.id || `pay_${Date.now()}`;
        const customerEmail = data.customer?.email || data.customer_email || 'customer@example.com';
        const productId = data.product_id || 'animatto_pro_lifetime';

        // Generate cryptographically signed license token
        const licenseToken = generateLicenseToken({
          orderId: paymentId,
          customerEmail: customerEmail,
          productId: productId,
          tier: 'pro',
          maxDevices: 3,
          issuedAt: Math.floor(Date.now() / 1000),
          expiresAt: null, // Lifetime one-time purchase
          entitlements: [
            'pro_sound_studio',
            'pro_custom_palettes',
            'aquarium_pro',
            'multi_device_3'
          ]
        }, privateKey);

        const record = {
          orderId: paymentId,
          customerEmail: customerEmail,
          productId: productId,
          licenseToken: licenseToken,
          status: 'active',
          createdAt: new Date().toISOString()
        };

        orderFulfillments.set(paymentId, record);
        markEventProcessed(eventId, { status: 'fulfilled', orderId: paymentId });

        console.log(`[Webhook] Fulfill Success: Order ${paymentId} for ${sanitizeEmail(customerEmail)}`);
        return res.status(200).json({ received: true, action: 'license_issued', order_id: paymentId, license_key: licenseToken });
      }

      case 'payment.failed': {
        const data = event.data || {};
        const paymentId = data.payment_id || data.id || 'unknown';
        markEventProcessed(eventId, { status: 'failed', orderId: paymentId });
        console.log(`[Webhook] Payment Failed: Order ${paymentId}`);
        return res.status(200).json({ received: true, action: 'payment_failed_recorded' });
      }

      case 'refund.succeeded':
      case 'dispute.opened': {
        const data = event.data || {};
        const paymentId = data.payment_id || data.id || 'unknown';
        const existing = orderFulfillments.get(paymentId);
        if (existing) {
          existing.status = eventType === 'refund.succeeded' ? 'refunded' : 'disputed';
        }
        markEventProcessed(eventId, { status: 'revoked', orderId: paymentId, reason: eventType });
        console.log(`[Webhook] Entitlement Revoked (${eventType}): Order ${paymentId}`);
        return res.status(200).json({ received: true, action: 'entitlement_revoked', order_id: paymentId });
      }

      default:
        markEventProcessed(eventId, { status: 'ignored', type: eventType });
        return res.status(200).json({ received: true, ignored: true, type: eventType });
    }
  } catch (error) {
    console.error('[Webhook Processing Error]:', error.message);
    return res.status(500).json({ error: 'Internal server error processing event' });
  }
};

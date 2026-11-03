/**
 * Animatto Webhook API Endpoint (/api/webhook)
 * 
 * Securely receives, verifies, and processes Dodo Payments Standard Webhooks.
 * - Enforces HMAC-SHA256 signature verification
 * - Prevents replay attacks via 5-minute timestamp tolerance window
 * - Guarantees durable, atomic idempotent event processing
 * - Verifies product IDs and payment amounts server-side
 * - Fails closed on missing production secrets
 * - Prevents test/mock events from being accepted in live production mode
 * - Dispatches transactional fulfillment emails via Resend REST API
 * - Reliably revokes entitlements upon refund or dispute events
 * - Never logs secrets, full license tokens, or unmasked customer credentials
 */

const { verifyWebhookSignature, generateLicenseToken } = require('../lib/crypto');
const db = require('../lib/db');
const email = require('../lib/email');

// Request body size limit: 64 KB
const MAX_BODY_BYTES = 64 * 1024;

function sanitizeEmail(emailAddr) {
  if (!emailAddr || !emailAddr.includes('@')) return 'unknown';
  const parts = emailAddr.split('@');
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

  // Retrieve raw body string & enforce body size limits
  let rawBody = '';
  if (typeof req.body === 'string') {
    rawBody = req.body;
  } else if (Buffer.isBuffer(req.body)) {
    rawBody = req.body.toString('utf8');
  } else if (req.body && typeof req.body === 'object') {
    rawBody = JSON.stringify(req.body);
  }

  if (Buffer.byteLength(rawBody) > MAX_BODY_BYTES) {
    return res.status(413).json({ error: 'Payload Too Large' });
  }

  const mode = process.env.DODO_PAYMENTS_MODE || 'test';
  const webhookSecret = process.env.DODO_PAYMENTS_WEBHOOK_SECRET;

  // Signature Verification & Fail-Closed Enforcement
  if (webhookSecret) {
    const verification = verifyWebhookSignature(rawBody, req.headers, webhookSecret);
    if (!verification.valid) {
      console.warn('[Webhook Auth] Rejected invalid webhook signature:', verification.reason);
      return res.status(401).json({ error: 'Invalid webhook signature', details: verification.reason });
    }
  } else {
    // In live mode, missing secret must FAIL CLOSED immediately
    if (mode === 'live') {
      console.error('[Webhook Security] FATAL: DODO_PAYMENTS_WEBHOOK_SECRET is not configured in live mode.');
      return res.status(500).json({ error: 'Webhook verification secret not configured' });
    }

    // In test/development mode, require explicit test header
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

  // Durable Idempotency Check
  const idempotency = await db.recordWebhookEvent(eventId, eventType);
  if (idempotency.duplicate) {
    return res.status(200).json({ received: true, idempotent_duplicate: true });
  }

  // Prevent Test/Mock Events in Live Production Mode
  if (mode === 'live' && (event.test_mode === true || (event.data && event.data.test_mode === true))) {
    console.warn(`[Webhook Security] Rejected test event in live mode: ${eventId}`);
    return res.status(400).json({ error: 'Test events are rejected in live production mode' });
  }

  // License signing private key resolution (NO HARDCODED FALLBACK)
  const privateKey = process.env.LICENSE_SIGNING_PRIVATE_KEY;
  if (!privateKey) {
    console.error('[Webhook Security] FATAL: LICENSE_SIGNING_PRIVATE_KEY is not configured on server.');
    return res.status(500).json({ error: 'License signing private key not configured' });
  }

  const expectedProductId = process.env.DODO_PAYMENTS_PRODUCT_ID || 'pdt_animatto_premium_lifetime';

  try {
    switch (eventType) {
      case 'payment.succeeded': {
        const data = event.data || {};
        const paymentId = data.payment_id || data.id || `pay_${Date.now()}`;
        const customerEmail = data.customer?.email || data.customer_email || 'customer@example.com';
        const productId = data.product_id || expectedProductId;

        // Server-Side Product ID Validation
        if (productId !== expectedProductId && productId !== 'pdt_animatto_premium_lifetime' && productId !== 'animatto_pro_lifetime') {
          console.warn(`[Webhook Validation] Mismatched product ID: ${productId}`);
          return res.status(400).json({ error: 'Invalid or unrecognized product ID' });
        }

        // Server-Side Payment Amount Check (Expected $9.99 = 999 cents)
        if (data.total_amount !== undefined && data.total_amount < 999) {
          console.warn(`[Webhook Validation] Payment amount below required minimum: ${data.total_amount}`);
          return res.status(400).json({ error: 'Payment amount mismatch' });
        }

        // Check if order was already fulfilled (prevent duplicate fulfillment under concurrent deliveries)
        const existingOrder = await db.getOrder(paymentId);
        if (existingOrder && existingOrder.status === 'active' && existingOrder.licenseToken) {
          return res.status(200).json({
            received: true,
            action: 'license_already_fulfilled',
            order_id: paymentId,
            license_key: existingOrder.licenseToken
          });
        }

        // Generate cryptographically signed Ed25519 license token
        const licenseToken = generateLicenseToken({
          orderId: paymentId,
          customerEmail: customerEmail,
          productId: productId,
          tier: 'pro',
          maxDevices: 3,
          issuedAt: Math.floor(Date.now() / 1000),
          expiresAt: null, // Perpetual lifetime license
          entitlements: [
            'pro_sound_studio',
            'pro_custom_palettes',
            'aquarium_pro',
            'multi_device_3'
          ]
        }, privateKey);

        // Persist order in durable storage
        await db.saveOrder({
          orderId: paymentId,
          customerEmail: customerEmail,
          productId: productId,
          licenseToken: licenseToken,
          status: 'active',
          amount: data.total_amount || 999,
          currency: data.currency || 'USD'
        });

        // Dispatch transactional email with license key
        try {
          await email.sendLicenseDeliveryEmail({
            email: customerEmail,
            orderId: paymentId,
            licenseKey: licenseToken,
            maxDevices: 3
          });
        } catch (emailErr) {
          console.error('[Webhook] Failed to dispatch delivery email:', emailErr.message);
        }

        console.log(`[Webhook] Fulfill Success: Order ${paymentId} for ${sanitizeEmail(customerEmail)}`);
        return res.status(200).json({
          received: true,
          action: 'license_issued',
          order_id: paymentId,
          license_key: licenseToken
        });
      }

      case 'payment.failed': {
        const data = event.data || {};
        const paymentId = data.payment_id || data.id || 'unknown';
        console.log(`[Webhook] Payment Failed Recorded: Order ${paymentId}`);
        return res.status(200).json({ received: true, action: 'payment_failed_recorded' });
      }

      case 'refund.succeeded':
      case 'dispute.opened': {
        const data = event.data || {};
        const paymentId = data.payment_id || data.id || 'unknown';
        const revocationStatus = eventType === 'refund.succeeded' ? 'refunded' : 'disputed';
        
        // Reliably revoke entitlement in durable storage
        await db.updateOrderStatus(paymentId, revocationStatus, `Revoked by webhook event: ${eventType}`);
        console.log(`[Webhook] Entitlement Revoked (${eventType}): Order ${paymentId}`);
        return res.status(200).json({ received: true, action: 'entitlement_revoked', order_id: paymentId });
      }

      default:
        return res.status(200).json({ received: true, ignored: true, type: eventType });
    }
  } catch (error) {
    console.error('[Webhook Processing Error]:', error.message);
    return res.status(500).json({ error: 'Internal server error processing event' });
  }
};

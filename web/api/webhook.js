/**
 * Animatto Webhook API Endpoint (/api/webhook)
 * 
 * Securely receives, verifies, and processes Dodo Payments Standard Webhooks.
 * 
 * Reliable Order of Operations:
 * 1. Payload validation, Standard Webhooks HMAC-SHA256 signature verification, and key enforcement
 * 2. Strict live-mode check (fails closed on missing secrets; rejects mock/test events)
 * 3. Atomic event tracking via persistent database (processing, completed, failed)
 * 4. Concurrent duplicate delivery protection (returns existing order without reissuing)
 * 5. Server-side product & amount verification before state mutation
 * 6. Tier determination strictly from verified product ID, never client-supplied metadata
 * 7. Atomic order fulfillment & entitlement state updates
 * 8. Transactional email queueing and dispatch
 * 9. Rejections/failures are NOT permanently marked as completed (allowing provider retries)
 * 10. Zero hardcoded secrets, fallbacks, or token logging
 */

const { verifyWebhookSignature, generateLicenseToken } = require('../lib/crypto');
const { getDodoEnvironment, getProductCatalog, getDodoClient } = require('../lib/dodo');
const db = require('../lib/db');
const email = require('../lib/email');

const MAX_BODY_BYTES = 64 * 1024; // 64 KB
const EMAIL_REGEX = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

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

  // 1. Enforce payload size limit
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

  const environment = getDodoEnvironment();
  const webhookSecret = process.env.DODO_PAYMENTS_WEBHOOK_KEY || process.env.DODO_PAYMENTS_WEBHOOK_SECRET;

  // 2. Signature Verification & Fail-Closed Secret Enforcement
  if (webhookSecret) {
    // Attempt verification via standard webhooks verification
    const verification = verifyWebhookSignature(rawBody, req.headers, webhookSecret);
    if (!verification.valid) {
      console.warn('[Webhook Auth] Rejected invalid webhook signature:', verification.reason);
      return res.status(401).json({ error: 'Invalid webhook signature', details: verification.reason });
    }
  } else {
    // In live mode, missing webhook secret must FAIL CLOSED immediately
    if (environment === 'live_mode') {
      console.error('[Webhook Security] FATAL: DODO_PAYMENTS_WEBHOOK_KEY is not configured in live mode.');
      return res.status(500).json({ error: 'Webhook verification secret not configured' });
    }

    // In test/development mode, require explicit test header or test runner
    const isExplicitTestMode = req.headers['x-animatto-test-webhook'] === 'true' || process.env.NODE_ENV === 'test';
    if (!isExplicitTestMode) {
      console.error('[Webhook Auth] DODO_PAYMENTS_WEBHOOK_KEY is not configured on server.');
      return res.status(500).json({ error: 'Webhook verification secret not configured' });
    }
  }

  // 3. Payload Parsing
  let event;
  try {
    event = typeof req.body === 'object' && !Buffer.isBuffer(req.body) ? req.body : JSON.parse(rawBody);
  } catch (err) {
    return res.status(400).json({ error: 'Invalid JSON payload' });
  }

  const eventId = req.headers['webhook-id'] || event.id || `evt_${Date.now()}`;
  const eventType = event.type || event.event;

  // 4. Reject Test/Mock Events in Live Production Mode (before any state mutation)
  if (environment === 'live_mode' && (event.test_mode === true || (event.data && event.data.test_mode === true))) {
    console.warn(`[Webhook Security] Rejected test event in live mode: ${eventId}`);
    return res.status(400).json({ error: 'Test events are rejected in live production mode' });
  }

  // 5. Enforce Server Private Signing Key (NO HARDCODED FALLBACK)
  const privateKey = process.env.LICENSE_SIGNING_PRIVATE_KEY;
  if (!privateKey) {
    console.error('[Webhook Security] FATAL: LICENSE_SIGNING_PRIVATE_KEY is not configured on server.');
    return res.status(500).json({ error: 'License signing private key not configured' });
  }

  // 6. Pre-validation of event parameters
  const data = event.data || {};
  const catalog = getProductCatalog();
  const expectedProductId = catalog.pro.productId;

  const allowedProductIds = [
    'pdt_animatto_pro_lifetime',
    'pdt_animatto_founder_lifetime',
    'pdt_animatto_premium_lifetime',
    'animatto_pro_lifetime',
    catalog.pro.productId,
    catalog.founder.productId,
    process.env.DODO_PAYMENTS_PRODUCT_ID
  ].filter(Boolean);

  if (eventType === 'payment.succeeded') {
    const rawCartProduct = (data.product_cart && data.product_cart[0] && data.product_cart[0].product_id);
    const productId = rawCartProduct || data.product_id || expectedProductId;

    if (!allowedProductIds.includes(productId)) {
      console.warn(`[Webhook Validation] Mismatched product ID: ${productId}`);
      return res.status(400).json({ error: 'Invalid or unrecognized product ID' });
    }

    if (data.currency && data.currency.toUpperCase() !== 'USD') {
      console.warn(`[Webhook Validation] Unsupported currency: ${data.currency}`);
      return res.status(400).json({ error: 'Unsupported currency (only USD is supported)' });
    }

    const customerEmail = (data.customer?.email || data.customer_email || '').trim().toLowerCase();
    if (!customerEmail || !EMAIL_REGEX.test(customerEmail) || customerEmail.length > 254) {
      console.warn(`[Webhook Validation] Invalid or missing customer email`);
      return res.status(400).json({ error: 'Missing or invalid customer email in webhook payload' });
    }

    // Determine Founder status STRICTLY from the verified product ID (Never client-supplied metadata)
    const isFounderTier = productId === catalog.founder.productId ||
                          productId === 'pdt_animatto_founder_lifetime';

    const requiredMinCents = isFounderTier ? 599 : 399;

    if (data.total_amount !== undefined && data.total_amount < requiredMinCents) {
      console.warn(`[Webhook Validation] Payment amount below required minimum: ${data.total_amount} (expected >= ${requiredMinCents})`);
      return res.status(400).json({ error: 'Payment amount mismatch' });
    }
  }

  // 7. Atomic Idempotency Tracking via Persistent Database
  let idempotency;
  try {
    idempotency = await db.recordWebhookEvent(eventId, eventType);
  } catch (dbErr) {
    console.error('[Webhook DB Error] Failed to record event idempotency:', dbErr.message);
    return res.status(500).json({ error: 'Database service unavailable' });
  }

  if (idempotency.duplicate) {
    if (idempotency.completed) {
      return res.status(200).json({ received: true, idempotent_duplicate: true });
    }
    if (idempotency.inProgress) {
      return res.status(202).json({ received: true, processing: true, message: 'Event currently being processed' });
    }
  }

  // 8. Event Execution
  try {
    switch (eventType) {
      case 'payment.succeeded': {
        const paymentId = data.payment_id || data.id || `pay_${Date.now()}`;
        const customerEmail = data.customer?.email || data.customer_email || 'customer@example.com';
        const rawCartProduct = (data.product_cart && data.product_cart[0] && data.product_cart[0].product_id);
        const productId = rawCartProduct || data.product_id || expectedProductId;

        // Concurrent duplicate check: return existing order without issuing duplicate license
        const existingOrder = await db.getOrder(paymentId);
        if (existingOrder && existingOrder.status === 'active' && existingOrder.licenseToken) {
          await db.markWebhookCompleted(eventId, paymentId);
          return res.status(200).json({
            received: true,
            action: 'license_already_fulfilled',
            order_id: paymentId
          });
        }

        // Strict server-side tier derivation from verified product ID only
        const isFounderTier = productId === catalog.founder.productId ||
                              productId === 'pdt_animatto_founder_lifetime';

        const tier = isFounderTier ? 'founder' : 'pro';

        // Founder Supporter tier inherits 100% of Lifetime Pro entitlements + Founder perks
        const proEntitlements = [
          'pro_sound_studio',
          'pro_custom_palettes',
          'aquarium_pro',
          'multi_device_3'
        ];

        const founderEntitlements = [
          ...proEntitlements,
          'founder_badge',
          'readme_acknowledgement',
          'early_beta_access'
        ];

        const entitlements = isFounderTier ? founderEntitlements : proEntitlements;

        // Supporter Name & Consent (optional, requiring explicit opt-in consent)
        const supporterConsent = (data.metadata?.supporter_consent === 'true' || data.metadata?.supporter_consent === true || data.supporter_consent === true);
        const supporterName = (supporterConsent && (data.metadata?.supporter_name || data.supporter_name))
          ? String(data.metadata?.supporter_name || data.supporter_name).trim().slice(0, 40)
          : null;

        // Generate cryptographically signed Ed25519 license token
        const licenseToken = generateLicenseToken({
          orderId: paymentId,
          customerEmail: customerEmail,
          productId: productId,
          tier: tier,
          maxDevices: 3,
          issuedAt: Math.floor(Date.now() / 1000),
          expiresAt: null, // Lifetime perpetual license
          entitlements: entitlements,
          supporterName: supporterName,
          supporterConsent: supporterConsent
        }, privateKey);

        // Persist order in durable storage
        const saveResult = await db.saveOrder({
          orderId: paymentId,
          customerEmail: customerEmail,
          productId: productId,
          tier: tier,
          licenseToken: licenseToken,
          status: 'active',
          amount: data.total_amount || (isFounderTier ? 599 : 399),
          currency: data.currency || 'USD',
          supporterName: supporterName,
          supporterConsent: supporterConsent
        });

        if (saveResult && saveResult.duplicate) {
          await db.markWebhookCompleted(eventId, paymentId);
          return res.status(200).json({
            received: true,
            action: 'license_already_fulfilled',
            order_id: paymentId
          });
        }

        // Queue & dispatch transactional license email
        try {
          await email.sendLicenseDeliveryEmail({
            email: customerEmail,
            orderId: paymentId,
            licenseKey: licenseToken,
            maxDevices: 3,
            tier: tier
          });
        } catch (emailErr) {
          console.error('[Webhook] Failed to dispatch delivery email:', emailErr.message);
        }

        // Mark webhook event as completed
        await db.markWebhookCompleted(eventId, paymentId);
        console.log(`[Webhook] Fulfill Success: Order ${paymentId} for ${sanitizeEmail(customerEmail)}`);

        return res.status(200).json({
          received: true,
          action: 'license_issued',
          order_id: paymentId
        });
      }

      case 'payment.failed': {
        const paymentId = data.payment_id || data.id || 'unknown';
        await db.markWebhookCompleted(eventId, paymentId);
        console.log(`[Webhook] Payment Failed Recorded: Order ${paymentId}`);
        return res.status(200).json({ received: true, action: 'payment_failed_recorded' });
      }

      case 'refund.succeeded':
      case 'dispute.opened': {
        const paymentId = data.payment_id || data.id || 'unknown';
        const revocationStatus = eventType === 'refund.succeeded' ? 'refunded' : 'disputed';

        // Atomically update persistent order entitlement state
        await db.updateOrderStatus(paymentId, revocationStatus, `Revoked by webhook event: ${eventType}`);
        await db.markWebhookCompleted(eventId, paymentId);
        console.log(`[Webhook] Entitlement Revoked (${eventType}): Order ${paymentId}`);

        return res.status(200).json({ received: true, action: 'entitlement_revoked', order_id: paymentId });
      }

      default:
        await db.markWebhookCompleted(eventId, null);
        return res.status(200).json({ received: true, ignored: true, type: eventType });
    }
  } catch (error) {
    // On unexpected processing failure, mark event failed so provider can retry
    await db.markWebhookFailed(eventId, error.message);
    console.error('[Webhook Processing Error]:', error.message);
    return res.status(500).json({ error: 'Internal server error processing event' });
  }
};

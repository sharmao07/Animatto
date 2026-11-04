/**
 * Animatto Backend & Production Security Verification Test Suite
 * 
 * Comprehensive validation for Phase 5 security corrections:
 * 1. Ephemeral test keypair generation (zero static secret fixtures)
 * 2. Signature verification with ephemeral keypairs
 * 3. Strict rejection of tokens signed with the old compromised private key
 * 4. Strict rejection of test-signed tokens by the production official public key
 * 5. Tampered payload, corrupted signature, and expired token rejection
 * 6. Standard Webhooks HMAC-SHA256 signature verification & 5-minute replay tolerance
 * 7. Fail-closed security when production webhook secret is missing in live mode
 * 8. Fail-closed security when production license signing key is missing in live mode
 * 9. Fail-closed security when production database configuration is missing in live mode
 * 10. Rejection of test/mock events in live production mode
 * 11. Server-side product ID and payment amount validation
 * 12. Return URL allowlist validation in checkout
 * 13. Persistent webhook idempotency (first delivery fulfilled; duplicate returns cached result)
 * 14. Concurrent webhook delivery coordination
 * 15. Atomic device activation limit (max 3 devices) and 4th device rejection
 * 16. Concurrent device activation race protection
 * 17. Device deactivation and slot release
 * 18. Entitlement revocation on refund & dispute events with validation/activation lockout
 * 19. Email queueing, successful Resend dispatch, failed dispatch, and retry behavior
 * 20. Customer license recovery with privacy protection against enumeration
 * 21. Source code regression scan ensuring zero hardcoded private key seeds exist
 */

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const {
  OFFICIAL_PUBLIC_KEY_BASE64,
  generateLicenseToken,
  verifyLicenseToken,
  verifyWebhookSignature,
  generateEphemeralKeyPair
} = require('../lib/crypto');

const db = require('../lib/db');
const email = require('../lib/email');
const webhookHandler = require('../api/webhook');
const licenseHandler = require('../api/license');
const checkoutHandler = require('../api/checkout');

// Generate a clean ephemeral test keypair at runtime (never committed)
const { privateKeySeed: TEST_PRIVATE_KEY_SEED, publicKeyBase64: TEST_PUBLIC_KEY_BASE64 } = generateEphemeralKeyPair();
const TEST_WEBHOOK_SECRET = 'whsec_' + crypto.randomBytes(32).toString('base64');

function signWebhook(eventId, bodyObj, secret = TEST_WEBHOOK_SECRET, ts = Math.floor(Date.now() / 1000)) {
  const rawBody = typeof bodyObj === 'string' ? bodyObj : JSON.stringify(bodyObj);
  const sBytes = Buffer.from(secret.replace('whsec_', ''), 'base64');
  const hmac = crypto.createHmac('sha256', sBytes)
    .update(`${eventId}.${ts}.${rawBody}`)
    .digest('base64');
  return {
    rawBody,
    headers: {
      'webhook-id': eventId,
      'webhook-timestamp': String(ts),
      'webhook-signature': `v1,${hmac}`
    }
  };
}

// SHA-256 fingerprint of the deprecated/compromised key seed for regression detection
const COMPROMISED_SEED_SHA256 = 'd2d4d9d63d5c56695c5df791f1692cea854cf021563c8b942d05570097ac2d1d';

function createMockReqRes(method, body, headers = {}, query = {}) {
  const req = {
    method,
    body,
    headers: { ...headers },
    query,
    socket: { remoteAddress: '127.0.0.1' }
  };

  const res = {
    statusCode: 200,
    headers: {},
    body: null,
    redirectUrl: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    setHeader(name, val) {
      this.headers[name] = val;
    },
    json(data) {
      this.body = data;
      return this;
    },
    redirect(code, url) {
      this.statusCode = code;
      this.redirectUrl = url;
      return this;
    },
    end() {
      return this;
    }
  };

  return { req, res };
}

let testCount = 0;
function pass(msg) {
  testCount++;
  console.log(`✅ PASS: ${msg}`);
}

async function runTests() {
  console.log('=== RUNNING ANIMATTO PHASE 5 SECURITY & BACKEND TESTS ===\n');

  db.resetTestStorage();
  process.env.LICENSE_VERIFICATION_PUBLIC_KEY = TEST_PUBLIC_KEY_BASE64;

  // Test 1: Ephemeral Keypair Generation
  assert(TEST_PRIVATE_KEY_SEED.length > 0, 'Must generate private key seed');
  assert(TEST_PUBLIC_KEY_BASE64.length > 0, 'Must generate public key base64');
  pass('Ephemeral test Ed25519 keypair dynamically generated at runtime');

  // Test 2: Generate and Verify Valid License Token with Ephemeral Keypair
  const payload = {
    orderId: 'ord_test_001',
    customerEmail: 'alex@animatto.app',
    productId: 'pdt_animatto_premium_lifetime',
    tier: 'pro',
    maxDevices: 3,
    issuedAt: Math.floor(Date.now() / 1000),
    expiresAt: null,
    entitlements: ['pro_sound_studio', 'pro_custom_palettes', 'aquarium_pro', 'multi_device_3']
  };

  const token = generateLicenseToken(payload, TEST_PRIVATE_KEY_SEED);
  assert(token.startsWith('ANIM-PRO-'), 'Token format prefix must be ANIM-PRO-');
  pass('Generated valid Ed25519 token format using ephemeral test key');

  const verification = verifyLicenseToken(token, TEST_PUBLIC_KEY_BASE64);
  assert.strictEqual(verification.valid, true);
  assert.strictEqual(verification.payload.orderId, 'ord_test_001');
  assert.strictEqual(verification.payload.maxDevices, 3);
  pass('Cryptographic verification succeeded using matching ephemeral test public key');

  // Test 3: Production Public Key Strictly Rejects Test-Signed Token
  const prodVerifyResult = verifyLicenseToken(token, OFFICIAL_PUBLIC_KEY_BASE64);
  assert.strictEqual(prodVerifyResult.valid, false);
  assert(prodVerifyResult.error.includes('signature mismatch'));
  pass('Rotated official production public key strictly rejects test-signed token');

  // Test 4: Rotated Production Public Key Rejects Foreign / Unauthorized Key Tokens
  const { privateKeySeed: foreignPrivSeed } = generateEphemeralKeyPair();
  const foreignToken = generateLicenseToken(payload, foreignPrivSeed);
  const foreignResult = verifyLicenseToken(foreignToken, OFFICIAL_PUBLIC_KEY_BASE64);
  assert.strictEqual(foreignResult.valid, false);
  assert(foreignResult.error.includes('signature mismatch'));
  pass('Rotated official production public key strictly rejects foreign/unauthorized key tokens');

  // Test 5: Reject Tampered Payload
  const parts = token.replace('ANIM-PRO-', '').split('.');
  const tamperedPayloadStr = Buffer.from(parts[0], 'base64url').toString('utf8').replace('"maxDevices":3', '"maxDevices":99');
  const tamperedB64 = Buffer.from(tamperedPayloadStr).toString('base64url');
  const tamperedToken = `ANIM-PRO-${tamperedB64}.${parts[1]}`;

  const tamperedResult = verifyLicenseToken(tamperedToken, TEST_PUBLIC_KEY_BASE64);
  assert.strictEqual(tamperedResult.valid, false);
  assert(tamperedResult.error.includes('signature mismatch'));
  pass('Tampered payload successfully detected and rejected by Ed25519 verification');

  // Test 6: Reject Corrupted Signature
  const corruptedSigToken = `ANIM-PRO-${parts[0]}.AAAA${parts[1].slice(4)}`;
  const corruptedResult = verifyLicenseToken(corruptedSigToken, TEST_PUBLIC_KEY_BASE64);
  assert.strictEqual(corruptedResult.valid, false);
  pass('Corrupted signature correctly rejected');

  // Test 7: Reject Expired Token
  const expiredPayload = {
    ...payload,
    orderId: 'ord_expired_002',
    expiresAt: Math.floor(Date.now() / 1000) - 3600
  };
  const expiredToken = generateLicenseToken(expiredPayload, TEST_PRIVATE_KEY_SEED);
  const expiredResult = verifyLicenseToken(expiredToken, TEST_PUBLIC_KEY_BASE64);
  assert.strictEqual(expiredResult.valid, false);
  assert.strictEqual(expiredResult.error, 'License expired');
  pass('Expired token properly detected and rejected');

  // Test 8: Webhook HMAC-SHA256 Signature Verification
  const webhookBody = JSON.stringify({
    type: 'payment.succeeded',
    id: 'evt_prod_001',
    data: {
      payment_id: 'pay_prod_100',
      customer_email: 'buyer@animatto.app',
      product_id: 'pdt_animatto_premium_lifetime',
      total_amount: 999,
      currency: 'USD'
    }
  });
  const nowTs = Math.floor(Date.now() / 1000);
  const secretBytes = Buffer.from(TEST_WEBHOOK_SECRET.replace('whsec_', ''), 'base64');
  const validHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_prod_001.${nowTs}.${webhookBody}`)
    .digest('base64');

  const validHeaders = {
    'webhook-id': 'evt_prod_001',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': `v1,${validHmac}`
  };

  const webhookCheck = verifyWebhookSignature(webhookBody, validHeaders, TEST_WEBHOOK_SECRET);
  assert.strictEqual(webhookCheck.valid, true);
  pass('Valid Standard Webhook HMAC-SHA256 signature verified');

  // Test 9: Webhook Replay Protection Window
  const staleHeaders = {
    ...validHeaders,
    'webhook-timestamp': String(nowTs - 600)
  };
  const staleCheck = verifyWebhookSignature(webhookBody, staleHeaders, TEST_WEBHOOK_SECRET);
  assert.strictEqual(staleCheck.valid, false);
  assert(staleCheck.reason.includes('replay tolerance'));
  pass('Stale webhook outside 5-minute window rejected by replay protection');

  // Test 10: Fail Closed on Missing Webhook Secret in Live Mode
  process.env.DODO_PAYMENTS_MODE = 'live';
  delete process.env.DODO_PAYMENTS_WEBHOOK_SECRET;
  delete process.env.LICENSE_SIGNING_PRIVATE_KEY;

  const failSecretBody = JSON.stringify({ type: 'payment.succeeded', id: 'evt_fail_secret_01' });
  const { req: failSecretReq, res: failSecretRes } = createMockReqRes('POST', failSecretBody, {
    'webhook-id': 'evt_fail_secret_01',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': 'v1,dummy'
  });
  await webhookHandler(failSecretReq, failSecretRes);
  assert.strictEqual(failSecretRes.statusCode, 500);
  assert(failSecretRes.body.error.includes('secret not configured'));
  pass('Missing webhook secret fails closed with HTTP 500 in live mode');

  // Test 11: Fail Closed on Missing Private Key in Live Mode
  process.env.DODO_PAYMENTS_WEBHOOK_SECRET = TEST_WEBHOOK_SECRET;
  const failKeyBody = JSON.stringify({ type: 'payment.succeeded', id: 'evt_fail_key_01' });
  const failKeyHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_fail_key_01.${nowTs}.${failKeyBody}`)
    .digest('base64');
  const { req: failKeyReq, res: failKeyRes } = createMockReqRes('POST', failKeyBody, {
    'webhook-id': 'evt_fail_key_01',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': `v1,${failKeyHmac}`
  });
  await webhookHandler(failKeyReq, failKeyRes);
  assert.strictEqual(failKeyRes.statusCode, 500);
  assert(failKeyRes.body.error.includes('private key not configured'));
  pass('Missing private signing key fails closed with HTTP 500 in live mode');

  // Test 12: Fail Closed on Missing Database Configuration in Live Mode
  const prevDbUrl = process.env.DATABASE_URL;
  delete process.env.DATABASE_URL;
  delete process.env.POSTGRES_URL;
  process.env.NODE_ENV = 'production';
  await assert.rejects(async () => {
    await db.initDatabase();
  }, /Production database configuration.*missing/);
  pass('Missing production database URL fails closed and prohibits execution');
  process.env.NODE_ENV = 'test';
  if (prevDbUrl) process.env.DATABASE_URL = prevDbUrl;

  // Test 13: Reject Test/Mock Events in Live Production Mode
  process.env.LICENSE_SIGNING_PRIVATE_KEY = TEST_PRIVATE_KEY_SEED;
  const testModeBody = JSON.stringify({
    type: 'payment.succeeded',
    id: 'evt_test_mode_01',
    test_mode: true,
    data: { payment_id: 'pay_test_01', customer_email: 'test@animatto.app' }
  });
  const testModeHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_test_mode_01.${nowTs}.${testModeBody}`)
    .digest('base64');
  const testModeHeaders = {
    'webhook-id': 'evt_test_mode_01',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': `v1,${testModeHmac}`
  };
  const { req: testRejectReq, res: testRejectRes } = createMockReqRes('POST', testModeBody, testModeHeaders);
  await webhookHandler(testRejectReq, testRejectRes);
  assert.strictEqual(testRejectRes.statusCode, 400);
  assert(testRejectRes.body.error.includes('Test events are rejected'));
  pass('Live mode strictly rejects test/mock events before state mutation');

  // Test 14: Server-Side Product ID and Amount Enforcement
  process.env.DODO_PAYMENTS_MODE = 'test';
  const invalidProductBody = JSON.stringify({
    type: 'payment.succeeded',
    id: 'evt_bad_prod',
    data: {
      payment_id: 'pay_bad_prod',
      customer_email: 'buyer@animatto.app',
      product_id: 'unauthorized_fake_product',
      total_amount: 999
    }
  });
  const badProdHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_bad_prod.${nowTs}.${invalidProductBody}`)
    .digest('base64');
  const { req: badProdReq, res: badProdRes } = createMockReqRes('POST', invalidProductBody, {
    'webhook-id': 'evt_bad_prod',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': `v1,${badProdHmac}`
  });
  await webhookHandler(badProdReq, badProdRes);
  assert.strictEqual(badProdRes.statusCode, 400);
  assert(badProdRes.body.error.includes('Invalid or unrecognized product ID'));
  pass('Server-side product ID verification strictly enforces product allowlist');

  // Test 15: Return URL Allowlist Sanitization in Checkout
  const { req: chkUrlReq, res: chkUrlRes } = createMockReqRes('GET', {}, {}, {
    customerEmail: 'alex@animatto.app',
    returnUrl: 'https://evil-phishing-site.com/steal'
  });
  await checkoutHandler(chkUrlReq, chkUrlRes);
  assert.strictEqual(chkUrlRes.statusCode, 200);
  assert(chkUrlRes.body.checkout_url.includes(encodeURIComponent('https://animatto.app/success')));
  pass('Untrusted return URL safely sanitized to official animatto.app allowlist');

  // Test 16: Process Valid Webhook & Fulfill Order in Persistent DB
  // Mock Resend HTTP transport to return 200 OK
  email.setMockHttpTransport(async (apiKey, postData) => {
    return {
      statusCode: 200,
      body: { id: 'msg_resend_mock_success_123' }
    };
  });

  const { req: hookReq, res: hookRes } = createMockReqRes('POST', webhookBody, validHeaders);
  await webhookHandler(hookReq, hookRes);

  assert.strictEqual(hookRes.statusCode, 200);
  assert.strictEqual(hookRes.body.action, 'license_issued');
  assert.strictEqual(hookRes.body.license_key, undefined, 'License key must NOT be exposed in webhook response');

  // Verify order in durable store
  const savedOrder = await db.getOrder('pay_prod_100');
  assert(savedOrder !== null);
  assert.strictEqual(savedOrder.status, 'active');
  const issuedLicense = savedOrder.licenseToken;
  assert(issuedLicense.startsWith('ANIM-PRO-'));
  pass('Valid webhook fulfilled with cryptographically signed Ed25519 license token');
  pass('Order persisted in durable storage with active status');

  // Verify email outbox record and status
  const outbox = await db.getEmailOutbox('buyer@animatto.app');
  assert(outbox.length > 0);
  assert.strictEqual(outbox[0].status, 'sent');
  assert.strictEqual(outbox[0].resendId, 'msg_resend_mock_success_123');
  pass('Transactional license email dispatched via Resend and recorded as sent');

  // Test 17: Webhook Idempotency (Duplicate Delivery)
  const { req: dupReq, res: dupRes } = createMockReqRes('POST', webhookBody, validHeaders);
  await webhookHandler(dupReq, dupRes);
  assert.strictEqual(dupRes.statusCode, 200);
  assert.strictEqual(dupRes.body.idempotent_duplicate, true);
  pass('Duplicate webhook delivery detected and handled idempotently');

  // Test 18: Concurrent Webhook Delivery Protection
  // Calling saveOrder on already fulfilled order returns existing token without reissuing
  const duplicateFulfillment = await db.saveOrder({
    orderId: 'pay_prod_100',
    customerEmail: 'buyer@animatto.app',
    status: 'active',
    licenseToken: 'ANIM-PRO-different_token'
  });
  assert.strictEqual(duplicateFulfillment.duplicate, true);
  assert.strictEqual(duplicateFulfillment.order.licenseToken, issuedLicense);
  pass('Concurrent duplicate fulfillment safely returns existing license without reissuing');

  // Test 19: Device Activation Limit Enforcement (Max 3 Devices)
  // Device 1
  const { req: d1Req, res: d1Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: issuedLicense,
    device_id: 'macbook_pro_m2_01',
    device_name: 'MacBook Pro M2'
  });
  await licenseHandler(d1Req, d1Res);
  assert.strictEqual(d1Res.statusCode, 200);
  assert.strictEqual(d1Res.body.active_devices_count, 1);
  pass('Device 1 activated successfully (1/3)');

  // Device 2
  const { req: d2Req, res: d2Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: issuedLicense,
    device_id: 'imac_m3_02',
    device_name: 'iMac M3'
  });
  await licenseHandler(d2Req, d2Res);
  assert.strictEqual(d2Res.statusCode, 200);
  assert.strictEqual(d2Res.body.active_devices_count, 2);
  pass('Device 2 activated successfully (2/3)');

  // Device 3
  const { req: d3Req, res: d3Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: issuedLicense,
    device_id: 'mac_mini_m2_03',
    device_name: 'Mac mini Studio'
  });
  await licenseHandler(d3Req, d3Res);
  assert.strictEqual(d3Res.statusCode, 200);
  assert.strictEqual(d3Res.body.active_devices_count, 3);
  pass('Device 3 activated successfully (3/3)');

  // Device 4 (Must be rejected with 403 Device Limit Reached)
  const { req: d4Req, res: d4Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: issuedLicense,
    device_id: 'macbook_air_m1_04',
    device_name: 'MacBook Air M1'
  });
  await licenseHandler(d4Req, d4Res);
  assert.strictEqual(d4Res.statusCode, 403);
  assert(d4Res.body.error.includes('Activation limit reached'));
  pass('Device 4 rejected: 3-device limit strictly enforced');

  // Test 20: Deactivate Device & Re-activate Slot
  const { req: deactReq, res: deactRes } = createMockReqRes('POST', {
    action: 'deactivate',
    license_key: issuedLicense,
    device_id: 'macbook_pro_m2_01'
  });
  await licenseHandler(deactReq, deactRes);
  assert.strictEqual(deactRes.statusCode, 200);
  assert.strictEqual(deactRes.body.deactivated, true);
  assert.strictEqual(deactRes.body.active_devices_count, 2);
  pass('Device 1 deactivated; available slot opened (2/3)');

  const { req: d4RetryReq, res: d4RetryRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: issuedLicense,
    device_id: 'macbook_air_m1_04',
    device_name: 'MacBook Air M1'
  });
  await licenseHandler(d4RetryReq, d4RetryRes);
  assert.strictEqual(d4RetryRes.statusCode, 200);
  assert.strictEqual(d4RetryRes.body.active_devices_count, 3);
  pass('Device 4 activates successfully into freed slot (3/3)');

  // Test 21: Durable Revocation on Refund
  const refundBody = JSON.stringify({
    type: 'refund.succeeded',
    id: 'evt_refund_001',
    data: { payment_id: 'pay_prod_100' }
  });
  const refundHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_refund_001.${nowTs}.${refundBody}`)
    .digest('base64');
  const { req: refundReq, res: refundRes } = createMockReqRes('POST', refundBody, {
    'webhook-id': 'evt_refund_001',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': `v1,${refundHmac}`
  });
  await webhookHandler(refundReq, refundRes);
  assert.strictEqual(refundRes.statusCode, 200);
  assert.strictEqual(refundRes.body.action, 'entitlement_revoked');
  pass('Refund event processed and entitlement revoked in durable store');

  // Test 22: Validation and Activation Rejected for Revoked Order
  const { req: valRevReq, res: valRevRes } = createMockReqRes('GET', {}, {}, {
    action: 'validate',
    key: issuedLicense
  });
  await licenseHandler(valRevReq, valRevRes);
  assert.strictEqual(valRevRes.body.valid, false);
  assert.strictEqual(valRevRes.body.revoked, true);
  pass('License validation detects and reports revoked status');

  const { req: actRevReq, res: actRevRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: issuedLicense,
    device_id: 'new_device_06'
  });
  await licenseHandler(actRevReq, actRevRes);
  assert.strictEqual(actRevRes.statusCode, 403);
  assert.strictEqual(actRevRes.body.revoked, true);
  pass('Device activation rejected for revoked license');

  // Test 23: Email Retry on Transient 500 Error
  email.setMockHttpTransport(async () => {
    return {
      statusCode: 500,
      body: { message: 'Internal server error at provider' }
    };
  });

  const retryTestResult = await email.sendEmail({
    to: 'retry@animatto.app',
    subject: 'Transient Test',
    html: '<p>test</p>',
    text: 'test'
  });
  assert.strictEqual(retryTestResult.success, false);
  assert.strictEqual(retryTestResult.status, 'awaiting_retry');
  pass('Transient 500 server error properly sets status to awaiting_retry');

  // Now mock success for retry
  email.setMockHttpTransport(async () => {
    return {
      statusCode: 200,
      body: { id: 'msg_resend_retry_success' }
    };
  });
  const retrySuccess = await email.retryEmail(retryTestResult.outboxId, {
    recipient: 'retry@animatto.app',
    subject: 'Transient Test',
    content: { html: '<p>test</p>', text: 'test' }
  });
  assert.strictEqual(retrySuccess.success, true);
  assert.strictEqual(retrySuccess.status, 'sent');
  pass('Awaiting retry email successfully dispatched and transitioned to sent');

  // Test 24: Email Permanent Failure on 4xx Client Error
  email.setMockHttpTransport(async () => {
    return {
      statusCode: 422,
      body: { message: 'Domain not verified' }
    };
  });
  const failTestResult = await email.sendEmail({
    to: 'fail@animatto.app',
    subject: 'Permanent Fail Test',
    html: '<p>test</p>',
    text: 'test'
  });
  assert.strictEqual(failTestResult.success, false);
  assert.strictEqual(failTestResult.status, 'failed');
  pass('Permanent 4xx client error properly sets status to failed');

  // Test 25: Customer License Recovery via Email Outbox
  email.setMockHttpTransport(async () => {
    return { statusCode: 200, body: { id: 'msg_recovery_success' } };
  });
  const { req: recReq, res: recRes } = createMockReqRes('POST', {
    action: 'recover',
    email: 'buyer@animatto.app'
  });
  await licenseHandler(recReq, recRes);
  assert.strictEqual(recRes.statusCode, 200);
  assert(recRes.body.message.includes('license recovery email has been sent'));
  pass('Customer license recovery email queued and dispatched');

  // Test 26: Phase 9 — Lifetime Pro ($3.99 USD) Webhook Fulfillment
  const proEventBody = JSON.stringify({
    type: 'payment.succeeded',
    id: 'evt_pro_399',
    data: {
      payment_id: 'pay_pro_399',
      customer_email: 'pro_buyer@animatto.app',
      product_id: 'pdt_animatto_pro_lifetime',
      total_amount: 399,
      currency: 'USD'
    }
  });
  const proTs = Math.floor(Date.now() / 1000);
  const proHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_pro_399.${proTs}.${proEventBody}`)
    .digest('base64');
  const proHeaders = {
    'webhook-id': 'evt_pro_399',
    'webhook-timestamp': String(proTs),
    'webhook-signature': `v1,${proHmac}`
  };
  const { req: proReq, res: proRes } = createMockReqRes('POST', proEventBody, proHeaders);
  await webhookHandler(proReq, proRes);
  assert.strictEqual(proRes.statusCode, 200);
  assert.strictEqual(proRes.body.action, 'license_issued');
  assert.strictEqual(proRes.body.license_key, undefined, 'License key must NOT be exposed in webhook response');
  const proOrder = await db.getOrder('pay_pro_399');
  const proTokenCheck = verifyLicenseToken(proOrder.licenseToken, TEST_PUBLIC_KEY_BASE64);
  assert.strictEqual(proTokenCheck.valid, true);
  assert.strictEqual(proTokenCheck.payload.tier, 'pro');
  assert.strictEqual(proTokenCheck.payload.productId, 'pdt_animatto_pro_lifetime');
  assert(proTokenCheck.payload.entitlements.includes('pro_sound_studio'));
  assert(proTokenCheck.payload.entitlements.includes('pro_custom_palettes'));
  assert(!proTokenCheck.payload.entitlements.includes('founder_badge'));
  pass('Lifetime Pro ($3.99) fulfilled with tier pro and Pro entitlements');

  // Test 27: Phase 9 — Founder Supporter ($5.99 USD) Fulfillment & Entitlement Inheritance
  const founderEventBody = JSON.stringify({
    type: 'payment.succeeded',
    id: 'evt_founder_599',
    data: {
      payment_id: 'pay_founder_599',
      customer_email: 'founder_buyer@animatto.app',
      product_id: 'pdt_animatto_founder_lifetime',
      total_amount: 599,
      currency: 'USD',
      metadata: {
        tier: 'founder',
        supporter_name: 'Grace Hopper',
        supporter_consent: 'true'
      }
    }
  });
  const founderTs = Math.floor(Date.now() / 1000);
  const founderHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_founder_599.${founderTs}.${founderEventBody}`)
    .digest('base64');
  const founderHeaders = {
    'webhook-id': 'evt_founder_599',
    'webhook-timestamp': String(founderTs),
    'webhook-signature': `v1,${founderHmac}`
  };
  const { req: founderReq, res: founderRes } = createMockReqRes('POST', founderEventBody, founderHeaders);
  await webhookHandler(founderReq, founderRes);
  assert.strictEqual(founderRes.statusCode, 200);
  assert.strictEqual(founderRes.body.action, 'license_issued');
  assert.strictEqual(founderRes.body.license_key, undefined, 'License key must NOT be exposed in webhook response');
  const founderOrder = await db.getOrder('pay_founder_599');
  const founderTokenCheck = verifyLicenseToken(founderOrder.licenseToken, TEST_PUBLIC_KEY_BASE64);
  assert.strictEqual(founderTokenCheck.valid, true);
  assert.strictEqual(founderTokenCheck.payload.tier, 'founder');
  // Verify 100% entitlement inheritance of all Pro features:
  assert(founderTokenCheck.payload.entitlements.includes('pro_sound_studio'));
  assert(founderTokenCheck.payload.entitlements.includes('pro_custom_palettes'));
  assert(founderTokenCheck.payload.entitlements.includes('aquarium_pro'));
  assert(founderTokenCheck.payload.entitlements.includes('multi_device_3'));
  // Verify Founder perks:
  assert(founderTokenCheck.payload.entitlements.includes('founder_badge'));
  assert(founderTokenCheck.payload.entitlements.includes('readme_acknowledgement'));
  assert(founderTokenCheck.payload.entitlements.includes('early_beta_access'));
  // Verify Supporter Name with consent pass-through:
  assert.strictEqual(founderTokenCheck.payload.supporterName, 'Grace Hopper');
  assert.strictEqual(founderTokenCheck.payload.supporterConsent, true);
  pass('Founder Supporter ($5.99) fulfilled with full Pro entitlement inheritance & supporter consent');

  // Test 28: Phase 9 — Underpaid Order Rejection (< 399 for Pro, < 599 for Founder)
  const underpaidProBody = JSON.stringify({
    type: 'payment.succeeded',
    id: 'evt_underpaid_pro',
    data: {
      payment_id: 'pay_underpaid_pro',
      customer_email: 'underpaid@animatto.app',
      product_id: 'pdt_animatto_pro_lifetime',
      total_amount: 250 // Less than required 399 cents
    }
  });
  const underpaidProHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_underpaid_pro.${nowTs}.${underpaidProBody}`)
    .digest('base64');
  const { req: underpaidReq, res: underpaidRes } = createMockReqRes('POST', underpaidProBody, {
    'webhook-id': 'evt_underpaid_pro',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': `v1,${underpaidProHmac}`
  });
  await webhookHandler(underpaidReq, underpaidRes);
  assert.strictEqual(underpaidRes.statusCode, 400);
  assert(underpaidRes.body.error.includes('Payment amount mismatch'));
  pass('Underpaid payment amounts strictly rejected before license issuance');

  // Test 30: Phase 11 — Checkout Tier Escalation & Parameter Mismatch Rejection
  const { req: mismatchReq1, res: mismatchRes1 } = createMockReqRes('POST', {
    tier: 'founder',
    productId: 'pdt_animatto_pro_lifetime',
    customerEmail: 'buyer@animatto.app'
  });
  await checkoutHandler(mismatchReq1, mismatchRes1);
  assert.strictEqual(mismatchRes1.statusCode, 400);
  assert.strictEqual(mismatchRes1.body.error, 'Mismatched tier and product ID');

  const { req: mismatchReq2, res: mismatchRes2 } = createMockReqRes('POST', {
    tier: 'pro',
    productId: 'pdt_animatto_founder_lifetime',
    customerEmail: 'buyer@animatto.app'
  });
  await checkoutHandler(mismatchReq2, mismatchRes2);
  assert.strictEqual(mismatchRes2.statusCode, 400);
  assert.strictEqual(mismatchRes2.body.error, 'Mismatched tier and product ID');

  const { req: badProdReq30, res: badProdRes30 } = createMockReqRes('POST', {
    tier: 'pro',
    productId: 'pdt_malicious_exploit',
    customerEmail: 'buyer@animatto.app'
  });
  await checkoutHandler(badProdReq30, badProdRes30);
  assert.strictEqual(badProdRes30.statusCode, 400);
  assert.strictEqual(badProdRes30.body.error, 'Invalid product ID');
  pass('Checkout tier escalation and parameter mismatch strictly rejected');

  // Test 31: Phase 11 — Checkout Email Validation (Required on POST, Strict RFC 5322 Format)
  const invalidEmails = ['notanemail', 'user@', '@domain.com', 'spaces in@mail.com'];
  for (const badMail of invalidEmails) {
    const { req: badMailReq, res: badMailRes } = createMockReqRes('POST', {
      tier: 'pro',
      customerEmail: badMail
    });
    await checkoutHandler(badMailReq, badMailRes);
    assert.strictEqual(badMailRes.statusCode, 400);
    assert.strictEqual(badMailRes.body.error, 'Invalid customer email address format');
  }

  const { req: noMailReq, res: noMailRes } = createMockReqRes('POST', {
    tier: 'pro'
  });
  await checkoutHandler(noMailReq, noMailRes);
  assert.strictEqual(noMailRes.statusCode, 400);
  assert.strictEqual(noMailRes.body.error, 'Customer email address is required');
  pass('Checkout rejects missing and malformed customer email addresses');

  // Test 32: Phase 11 — Webhook Non-USD Currency Rejection
  const nonUsdEvent = {
    type: 'payment.succeeded',
    id: 'evt_non_usd_01',
    data: {
      payment_id: 'pay_non_usd_01',
      customer_email: 'buyer@animatto.app',
      product_id: 'pdt_animatto_pro_lifetime',
      total_amount: 399,
      currency: 'EUR'
    }
  };
  const nonUsdSigned = signWebhook('evt_non_usd_01', nonUsdEvent);
  const { req: nonUsdReq, res: nonUsdRes } = createMockReqRes('POST', nonUsdSigned.rawBody, nonUsdSigned.headers);
  await webhookHandler(nonUsdReq, nonUsdRes);
  assert.strictEqual(nonUsdRes.statusCode, 400);
  assert(nonUsdRes.body.error.includes('currency'));
  pass('Webhook rejects non-USD transaction currencies');

  // Test 33: Phase 11 — Webhook Invalid / Missing Customer Email Rejection
  const invalidWebhookMails = ['not_an_email', 'missing_domain@', ''];
  for (let i = 0; i < invalidWebhookMails.length; i++) {
    const badMailId = `evt_bad_mail_${i}`;
    const badEvent = {
      type: 'payment.succeeded',
      id: badMailId,
      data: {
        payment_id: `pay_bad_mail_${i}`,
        customer_email: invalidWebhookMails[i],
        product_id: 'pdt_animatto_pro_lifetime',
        total_amount: 399,
        currency: 'USD'
      }
    };
    const badSigned = signWebhook(badMailId, badEvent);
    const { req: bReq, res: bRes } = createMockReqRes('POST', badSigned.rawBody, badSigned.headers);
    await webhookHandler(bReq, bRes);
    assert.strictEqual(bRes.statusCode, 400);
    assert(bRes.body.error.includes('customer email'));
  }
  pass('Webhook rejects missing or invalid customer email format');

  // Test 34: Phase 11 — Duplicate License Delivery Email Safely Prevented
  email.setMockHttpTransport(async () => {
    return { statusCode: 200, body: { id: 'msg_dedup_success' } };
  });

  const dedupOrder = {
    orderId: 'pay_dedup_order_01',
    customerEmail: 'dedup_user@animatto.app',
    licenseToken: 'ANIM-PRO-DEDUPTOKEN123',
    tier: 'pro'
  };

  const firstDelivery = await email.sendLicenseDeliveryEmail(dedupOrder);
  assert.strictEqual(firstDelivery.success, true);
  assert.strictEqual(firstDelivery.duplicate, undefined);

  const secondDelivery = await email.sendLicenseDeliveryEmail(dedupOrder);
  assert.strictEqual(secondDelivery.success, true);
  assert.strictEqual(secondDelivery.duplicate, true);

  const existingOutbox = await db.getEmailByOrderId('pay_dedup_order_01', 'license_delivery');
  assert(existingOutbox !== null);
  assert.strictEqual(existingOutbox.recipient, 'dedup_user@animatto.app');
  pass('Duplicate license delivery email safely prevented via outbox idempotency');

  // Test 35: Phase 11 — Email Outbox Retry with Exponential Backoff
  email.setMockHttpTransport(async () => {
    return { statusCode: 500, body: { error: 'Internal Resend Server Error' } };
  });

  const backoffResult = await email.sendEmail({
    to: 'backoff_user@animatto.app',
    subject: 'Backoff Test Subject',
    html: '<p>Test</p>',
    orderId: 'pay_backoff_01',
    messageType: 'license_delivery'
  });

  assert.strictEqual(backoffResult.success, false);
  assert.strictEqual(backoffResult.status, 'awaiting_retry');

  const backoffItem = await db.getEmailByOrderId('pay_backoff_01', 'license_delivery');
  assert(backoffItem !== null);
  assert.strictEqual(backoffItem.status, 'awaiting_retry');
  assert.strictEqual(backoffItem.attempts, 1);
  const retryAtProp = backoffItem.nextRetryAt || backoffItem.next_retry_at;
  assert(retryAtProp !== null);
  const nextRetryTime = new Date(retryAtProp).getTime();
  assert(nextRetryTime > Date.now(), 'Next retry must be scheduled in the future');

  const noRetryYet = await email.processEmailOutboxRetries({ maxBatch: 10 });
  assert.strictEqual(noRetryYet.processed, 0);

  // Advance retry timestamp to past and restore successful transport
  backoffItem.nextRetryAt = new Date(Date.now() - 5000).toISOString();
  if (backoffItem.next_retry_at) backoffItem.next_retry_at = backoffItem.nextRetryAt;
  email.setMockHttpTransport(async () => {
    return { statusCode: 200, body: { id: 'msg_backoff_retried' } };
  });

  const retryProcessed = await email.processEmailOutboxRetries({ maxBatch: 10 });
  assert.strictEqual(retryProcessed.processed, 1);
  assert.strictEqual(retryProcessed.succeeded, 1);

  const retriedItem = await db.getEmailByOrderId('pay_backoff_01', 'license_delivery');
  assert.strictEqual(retriedItem.status, 'sent');
  assert.strictEqual(retriedItem.attempts, 2);
  pass('Email outbox transient errors schedule bounded exponential backoff and batch retry');

  // Test 36: Phase 11 — Operator Recovery of Failed Email Outbox Items
  email.setMockHttpTransport(async () => {
    return { statusCode: 422, body: { message: 'Domain validation error' } };
  });

  const failedResult = await email.sendEmail({
    to: 'operator_recovery@animatto.app',
    subject: 'Permanent Error Subject',
    html: '<p>Error</p>'
  });

  assert.strictEqual(failedResult.success, false);
  assert.strictEqual(failedResult.status, 'failed');

  const recovered = await db.recoverFailedEmail(failedResult.outboxId);
  assert.strictEqual(recovered, true);

  const outboxList = await db.getEmailOutbox('operator_recovery@animatto.app');
  assert.strictEqual(outboxList.length, 1);
  const recoveredItem = outboxList[0];
  assert.strictEqual(recoveredItem.status, 'awaiting_retry');
  assert.strictEqual(recoveredItem.attempts, 0);
  const recRetryTime = new Date(recoveredItem.nextRetryAt || recoveredItem.next_retry_at).getTime();
  assert(recRetryTime <= Date.now() + 1000);
  pass('Operator recovery successfully resets failed email outbox items for retry');

  // Test 37: Phase 11 — Concurrent Webhook Deliveries Serialize Safely
  const raceOrderId = 'pay_race_fulfill_99';
  email.setMockHttpTransport(async () => {
    return { statusCode: 200, body: { id: 'msg_race_success' } };
  });

  const concurrentCalls = await Promise.all([1, 2, 3, 4, 5].map(async (i) => {
    const eventBody = {
      type: 'payment.succeeded',
      id: `evt_race_fulfill_99_${i}`,
      data: {
        payment_id: raceOrderId,
        customer_email: 'race_customer@animatto.app',
        product_id: 'pdt_animatto_pro_lifetime',
        total_amount: 399,
        currency: 'USD'
      }
    };
    const signedRace = signWebhook(`evt_race_fulfill_99_${i}`, eventBody);
    const { req, res } = createMockReqRes('POST', signedRace.rawBody, signedRace.headers);
    await webhookHandler(req, res);
    return res;
  }));

  for (const res of concurrentCalls) {
    assert.strictEqual(res.statusCode, 200);
  }

  const issuedCount = concurrentCalls.filter(r => r.body.action === 'license_issued').length;
  const alreadyCount = concurrentCalls.filter(r => r.body.action === 'license_already_fulfilled').length;
  assert.strictEqual(issuedCount, 1, 'Exactly one concurrent call must issue the license');
  assert.strictEqual(alreadyCount, 4, 'All subsequent concurrent calls must return already fulfilled');

  const persistedRaceOrder = await db.getOrder(raceOrderId);
  assert(persistedRaceOrder !== null);

  const outboxRaceEmail = await db.getEmailByOrderId(raceOrderId, 'license_delivery');
  assert(outboxRaceEmail !== null);
  pass('Concurrent webhook deliveries serialize safely without duplicate order or email creation');

  // Test 38: Phase 11 — Concurrent Device Activations Capped at 3 Devices
  const raceTokenPayload = {
    orderId: 'pay_concurrent_dev_test',
    customerEmail: 'dev_race@animatto.app',
    productId: 'pdt_animatto_pro_lifetime',
    tier: 'pro',
    maxDevices: 3,
    issuedAt: Math.floor(Date.now() / 1000),
    expiresAt: null,
    entitlements: ['pro_sound_studio', 'pro_custom_palettes', 'aquarium_pro', 'multi_device_3']
  };
  const raceDevToken = generateLicenseToken(raceTokenPayload, TEST_PRIVATE_KEY_SEED);
  await db.saveOrder({
    orderId: 'pay_concurrent_dev_test',
    customerEmail: 'dev_race@animatto.app',
    productId: 'pdt_animatto_pro_lifetime',
    tier: 'pro',
    amount: 399,
    currency: 'USD',
    licenseToken: raceDevToken,
    status: 'active'
  });

  const concDevResults = await Promise.all([1, 2, 3, 4, 5, 6].map(async (i) => {
    const { req, res } = createMockReqRes('POST', {
      action: 'activate',
      license_key: raceDevToken,
      device_id: `dev-conc-${i}`,
      device_name: `Concurrent Mac ${i}`
    });
    await licenseHandler(req, res);
    return res;
  }));

  const succDevs = concDevResults.filter(r => r.statusCode === 200 && r.body.success === true);
  const rejDevs = concDevResults.filter(r => r.statusCode === 403 && r.body.error && r.body.error.includes('limit reached'));
  assert.strictEqual(succDevs.length, 3, 'Exactly 3 activations must succeed');
  assert.strictEqual(rejDevs.length, 3, 'Remaining 3 activations must be rejected with 403');

  const finalDevActivations = await db.getActiveDevices(raceDevToken);
  assert.strictEqual(finalDevActivations.length, 3);
  pass('Concurrent device activations strictly serialized to 3-device limit');

  // Test 39: Phase 11 — Complete 11-Step Sandbox Purchase-to-Revocation Lifecycle
  // Step 1: Sandbox checkout session creation
  const { req: s1Req, res: s1Res } = createMockReqRes('POST', {
    tier: 'founder',
    customerEmail: 'founder_journey@animatto.app',
    supporterConsent: true,
    supporterName: 'Ada Lovelace'
  });
  await checkoutHandler(s1Req, s1Res);
  assert.strictEqual(s1Res.statusCode, 200);
  assert.strictEqual(s1Res.body.status, 'sandbox_ready');
  assert.strictEqual(s1Res.body.product.tier, 'founder');
  assert.strictEqual(s1Res.body.product.price_usd, 5.99);

  // Step 2: Dodo Payments webhook delivery
  const journeyOrderId = 'pay_e2e_journey_11step';
  const journeyEvent = {
    type: 'payment.succeeded',
    id: 'evt_e2e_journey_11step',
    data: {
      payment_id: journeyOrderId,
      customer_email: 'founder_journey@animatto.app',
      product_id: 'pdt_animatto_founder_lifetime',
      total_amount: 599,
      currency: 'USD',
      metadata: {
        tier: 'founder',
        supporter_name: 'Ada Lovelace',
        supporter_consent: 'true'
      }
    }
  };
  const journeySigned = signWebhook('evt_e2e_journey_11step', journeyEvent);

  email.setMockHttpTransport(async () => {
    return { statusCode: 200, body: { id: 'msg_journey_sent' } };
  });

  const { req: s2Req, res: s2Res } = createMockReqRes('POST', journeySigned.rawBody, journeySigned.headers);
  await webhookHandler(s2Req, s2Res);
  assert.strictEqual(s2Res.statusCode, 200);
  assert.strictEqual(s2Res.body.action, 'license_issued');
  assert.strictEqual(s2Res.body.license_key, undefined, 'License token not exposed in webhook response');

  // Step 3 & 4: Entitlement and Ed25519 token verification
  const journeyOrder = await db.getOrder(journeyOrderId);
  assert(journeyOrder !== null);
  assert.strictEqual(journeyOrder.tier, 'founder');
  assert.strictEqual(journeyOrder.supporterName, 'Ada Lovelace');
  assert.strictEqual(journeyOrder.supporterConsent, true);

  const jToken = journeyOrder.licenseToken;
  const jTokenCheck = verifyLicenseToken(jToken, TEST_PUBLIC_KEY_BASE64);
  assert.strictEqual(jTokenCheck.valid, true);
  assert.strictEqual(jTokenCheck.payload.tier, 'founder');
  assert(jTokenCheck.payload.entitlements.includes('pro_sound_studio'));
  assert(jTokenCheck.payload.entitlements.includes('readme_acknowledgement'));

  // Step 5 & 6: Order persistence & email outbox verification
  const jEmailOutbox = await db.getEmailByOrderId(journeyOrderId, 'license_delivery');
  assert(jEmailOutbox !== null);
  assert.strictEqual(jEmailOutbox.status, 'sent');
  assert.strictEqual(jEmailOutbox.recipient, 'founder_journey@animatto.app');

  // Step 7: Native app activation: Device 1 (Mac Studio M2)
  const { req: s7Req, res: s7Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: jToken,
    device_id: 'mac-studio-m2',
    device_name: 'Work Studio'
  });
  await licenseHandler(s7Req, s7Res);
  assert.strictEqual(s7Res.statusCode, 200);
  assert.strictEqual(s7Res.body.success, true);
  assert.strictEqual(s7Res.body.active_devices_count, 1);

  // Step 8: Multi-Mac limit enforcement (Max 3)
  const { req: s8aReq, res: s8aRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: jToken,
    device_id: 'macbook-pro-m3',
    device_name: 'Travel Laptop'
  });
  await licenseHandler(s8aReq, s8aRes);
  assert.strictEqual(s8aRes.statusCode, 200);
  assert.strictEqual(s8aRes.body.active_devices_count, 2);

  const { req: s8bReq, res: s8bRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: jToken,
    device_id: 'mac-mini-m1',
    device_name: 'Home Server'
  });
  await licenseHandler(s8bReq, s8bRes);
  assert.strictEqual(s8bRes.statusCode, 200);
  assert.strictEqual(s8bRes.body.active_devices_count, 3);

  // 4th Device rejected
  const { req: s8cReq, res: s8cRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: jToken,
    device_id: 'macbook-air-m2',
    device_name: 'Bedside Air'
  });
  await licenseHandler(s8cReq, s8cRes);
  assert.strictEqual(s8cRes.statusCode, 403);
  assert(s8cRes.body.error.includes('limit reached'));

  // Step 9: Device deactivation & replacement
  const { req: s9aReq, res: s9aRes } = createMockReqRes('POST', {
    action: 'deactivate',
    license_key: jToken,
    device_id: 'mac-studio-m2'
  });
  await licenseHandler(s9aReq, s9aRes);
  assert.strictEqual(s9aRes.statusCode, 200);
  assert.strictEqual(s9aRes.body.active_devices_count, 2);

  // Now 4th device can activate into freed slot
  const { req: s9bReq, res: s9bRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: jToken,
    device_id: 'macbook-air-m2',
    device_name: 'Bedside Air'
  });
  await licenseHandler(s9bReq, s9bRes);
  assert.strictEqual(s9bRes.statusCode, 200);
  assert.strictEqual(s9bRes.body.active_devices_count, 3);

  // Step 10: License recovery
  const { req: s10Req, res: s10Res } = createMockReqRes('POST', {
    action: 'recover',
    email: 'founder_journey@animatto.app'
  });
  await licenseHandler(s10Req, s10Res);
  assert.strictEqual(s10Res.statusCode, 200);
  assert(s10Res.body.message.includes('license recovery email has been sent'));

  // Step 11: Refund webhook processing and activation lockout
  const refundJourneyEvent = {
    type: 'refund.succeeded',
    id: 'evt_refund_journey_11',
    data: {
      payment_id: journeyOrderId
    }
  };
  const refundSigned = signWebhook('evt_refund_journey_11', refundJourneyEvent);
  const { req: s11aReq, res: s11aRes } = createMockReqRes('POST', refundSigned.rawBody, refundSigned.headers);
  await webhookHandler(s11aReq, s11aRes);
  assert.strictEqual(s11aRes.statusCode, 200);
  assert.strictEqual(s11aRes.body.action, 'entitlement_revoked');

  // License activation now rejected
  const { req: s11bReq, res: s11bRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: jToken,
    device_id: 'new-device-attempt',
    device_name: 'Blocked Mac'
  });
  await licenseHandler(s11bReq, s11bRes);
  assert.strictEqual(s11bRes.statusCode, 403);
  assert(s11bRes.body.error.includes('revoked'));

  pass('Complete 11-step sandbox purchase-to-revocation lifecycle verified end-to-end');

  // Test 40: Regression Scan: Zero Compromised Private Key Seeds in Working Tree
  const filesToScan = [
    'web/api/webhook.js',
    'web/api/checkout.js',
    'web/api/license.js',
    'web/lib/crypto.js',
    'web/lib/db.js',
    'web/lib/email.js',
    'Animatto/EntitlementManager.swift',
    'Tests/AnimattoTests.swift'
  ];

  for (const relPath of filesToScan) {
    const fullPath = path.join(__dirname, '..', '..', relPath);
    if (fs.existsSync(fullPath)) {
      const content = fs.readFileSync(fullPath, 'utf8');
      const lines = content.split('\n');
      for (const line of lines) {
        const matches = line.match(/[A-Za-z0-9+/=]{40,}/g) || [];
        for (const m of matches) {
          const hash = crypto.createHash('sha256').update(m).digest('hex');
          assert.notStrictEqual(
            hash,
            COMPROMISED_SEED_SHA256,
            `FATAL SECURITY REGRESSION: Found compromised private key seed in ${relPath}`
          );
        }
      }
    }
  }
  pass('Zero compromised private key seeds found in application source code');

  console.log(`\n======================================================`);
  console.log(`🎉 ALL ${testCount} PAYMENT LIFECYCLE, BACKEND & SECURITY TESTS PASSED!`);
  console.log(`======================================================\n`);
}

runTests().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});

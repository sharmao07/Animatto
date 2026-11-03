/**
 * Backend & Cryptography Automated Test Suite
 * 
 * Verifies:
 * - Ed25519 token creation, cross-platform structure, and signature validation
 * - Tampering resistance and expiration handling
 * - Standard Webhooks HMAC-SHA256 signature verification & replay protection
 * - Webhook event lifecycle & idempotency
 * - Device activation limit enforcement (max 3 devices)
 */

const assert = require('assert');
const crypto = require('crypto');
const {
  OFFICIAL_PUBLIC_KEY_BASE64,
  generateLicenseToken,
  verifyLicenseToken,
  verifyWebhookSignature
} = require('../lib/crypto');

const webhookHandler = require('../api/webhook');
const licenseHandler = require('../api/license');

const TEST_PRIVATE_KEY = 'IbwwDQm6w1f6OW/sM4dUDRX5L5U7U2yxCKBzX/EsASw=';
const TEST_WEBHOOK_SECRET = 'whsec_5Jv7tK1yP3zQ8mN4bW9xR2dL6cF0aE';

// Mock Express/Vercel Req/Res Helpers
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
  console.log('=== RUNNING ANIMATTO BACKEND & CRYPTOGRAPHY TESTS ===\n');

  // Test 1: Generate and Verify Valid License Token
  const payload = {
    orderId: 'ord_test_001',
    customerEmail: 'alex@example.com',
    productId: 'animatto_pro_lifetime',
    tier: 'pro',
    maxDevices: 3,
    issuedAt: Math.floor(Date.now() / 1000),
    expiresAt: null,
    entitlements: ['pro_sound_studio', 'pro_custom_palettes', 'aquarium_pro']
  };

  const token = generateLicenseToken(payload, TEST_PRIVATE_KEY);
  assert(token.startsWith('ANIM-PRO-'), 'Token must start with ANIM-PRO-');
  pass('Generated valid Ed25519 token format');

  const verification = verifyLicenseToken(token, OFFICIAL_PUBLIC_KEY_BASE64);
  assert(verification.valid === true, 'Valid token must verify true');
  assert.strictEqual(verification.payload.orderId, 'ord_test_001');
  assert.strictEqual(verification.payload.maxDevices, 3);
  pass('Cryptographic verification succeeded against official public key');

  // Test 2: Reject Tampered Payload
  const parts = token.replace('ANIM-PRO-', '').split('.');
  const tamperedPayloadStr = Buffer.from(parts[0], 'base64url').toString('utf8').replace('"maxDevices":3', '"maxDevices":999');
  const tamperedB64 = Buffer.from(tamperedPayloadStr).toString('base64url');
  const tamperedToken = `ANIM-PRO-${tamperedB64}.${parts[1]}`;

  const tamperedResult = verifyLicenseToken(tamperedToken, OFFICIAL_PUBLIC_KEY_BASE64);
  assert.strictEqual(tamperedResult.valid, false, 'Tampered token must be rejected');
  assert(tamperedResult.error.includes('signature mismatch'), 'Error must note signature mismatch');
  pass('Tampered payload successfully rejected by Ed25519 verification');

  // Test 3: Reject Expired Token
  const expiredPayload = {
    ...payload,
    orderId: 'ord_expired_002',
    expiresAt: Math.floor(Date.now() / 1000) - 3600 // Expired 1 hour ago
  };
  const expiredToken = generateLicenseToken(expiredPayload, TEST_PRIVATE_KEY);
  const expiredResult = verifyLicenseToken(expiredToken, OFFICIAL_PUBLIC_KEY_BASE64);
  assert.strictEqual(expiredResult.valid, false);
  assert.strictEqual(expiredResult.error, 'License expired');
  pass('Expired token properly detected and rejected');

  // Test 4: Webhook Signature Verification
  const webhookBody = JSON.stringify({
    type: 'payment.succeeded',
    id: 'evt_001',
    data: { payment_id: 'pay_999', customer_email: 'customer@test.com' }
  });
  const nowTs = Math.floor(Date.now() / 1000);
  const secretBytes = Buffer.from(TEST_WEBHOOK_SECRET.replace('whsec_', ''), 'base64');
  const validHmac = crypto.createHmac('sha256', secretBytes)
    .update(`evt_001.${nowTs}.${webhookBody}`)
    .digest('base64');

  const validHeaders = {
    'webhook-id': 'evt_001',
    'webhook-timestamp': String(nowTs),
    'webhook-signature': `v1,${validHmac}`
  };

  const webhookCheck = verifyWebhookSignature(webhookBody, validHeaders, TEST_WEBHOOK_SECRET);
  assert.strictEqual(webhookCheck.valid, true);
  pass('Valid Standard Webhook HMAC-SHA256 signature verified');

  // Test 5: Webhook Replay Attack Protection (Stale Timestamp)
  const staleHeaders = {
    ...validHeaders,
    'webhook-timestamp': String(nowTs - 600) // 10 minutes old
  };
  const staleCheck = verifyWebhookSignature(webhookBody, staleHeaders, TEST_WEBHOOK_SECRET);
  assert.strictEqual(staleCheck.valid, false);
  assert(staleCheck.reason.includes('replay tolerance'));
  pass('Stale webhook rejected by replay protection');

  // Test 6: Process Payment Webhook & Issue License
  process.env.DODO_PAYMENTS_WEBHOOK_SECRET = TEST_WEBHOOK_SECRET;
  process.env.LICENSE_SIGNING_PRIVATE_KEY = TEST_PRIVATE_KEY;

  const { req: hookReq, res: hookRes } = createMockReqRes('POST', webhookBody, validHeaders);
  await webhookHandler(hookReq, hookRes);

  assert.strictEqual(hookRes.statusCode, 200);
  assert.strictEqual(hookRes.body.action, 'license_issued');
  assert(hookRes.body.license_key.startsWith('ANIM-PRO-'));
  pass('Webhook payment.succeeded handled and signed license issued');

  // Test 7: Webhook Idempotency (Duplicate Delivery)
  const { req: dupReq, res: dupRes } = createMockReqRes('POST', webhookBody, validHeaders);
  await webhookHandler(dupReq, dupRes);
  assert.strictEqual(dupRes.statusCode, 200);
  assert.strictEqual(dupRes.body.idempotent_duplicate, true);
  pass('Duplicate webhook delivery detected and handled idempotently');

  // Test 8: Device Activation & Enforce Device Limit (Max 3)
  const testLicense = hookRes.body.license_key;

  // Device 1
  const { req: d1Req, res: d1Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: testLicense,
    device_id: 'macbook_pro_m2_01',
    device_name: "MacBook Pro"
  });
  await licenseHandler(d1Req, d1Res);
  assert.strictEqual(d1Res.statusCode, 200);
  assert.strictEqual(d1Res.body.active_devices_count, 1);
  pass('Device 1 activated successfully (1/3)');

  // Device 2
  const { req: d2Req, res: d2Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: testLicense,
    device_id: 'imac_m3_02',
    device_name: "iMac 24-inch"
  });
  await licenseHandler(d2Req, d2Res);
  assert.strictEqual(d2Res.statusCode, 200);
  assert.strictEqual(d2Res.body.active_devices_count, 2);
  pass('Device 2 activated successfully (2/3)');

  // Device 3
  const { req: d3Req, res: d3Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: testLicense,
    device_id: 'mac_mini_m2_03',
    device_name: "Mac mini Studio"
  });
  await licenseHandler(d3Req, d3Res);
  assert.strictEqual(d3Res.statusCode, 200);
  assert.strictEqual(d3Res.body.active_devices_count, 3);
  pass('Device 3 activated successfully (3/3)');

  // Device 4 (Must be rejected with 403 Device Limit Reached)
  const { req: d4Req, res: d4Res } = createMockReqRes('POST', {
    action: 'activate',
    license_key: testLicense,
    device_id: 'macbook_air_m1_04',
    device_name: "MacBook Air"
  });
  await licenseHandler(d4Req, d4Res);
  assert.strictEqual(d4Res.statusCode, 403);
  assert(d4Res.body.error.includes('Activation limit reached'));
  pass('Device 4 rejected: 3-device activation limit strictly enforced');

  // Test 9: Deactivate Device
  const { req: deactReq, res: deactRes } = createMockReqRes('POST', {
    action: 'deactivate',
    license_key: testLicense,
    device_id: 'macbook_pro_m2_01'
  });
  await licenseHandler(deactReq, deactRes);
  assert.strictEqual(deactRes.statusCode, 200);
  assert.strictEqual(deactRes.body.deactivated, true);
  assert.strictEqual(deactRes.body.active_devices_count, 2);
  pass('Device 1 deactivated; available slots opened (2/3)');

  // Device 4 can now activate!
  const { req: d4RetryReq, res: d4RetryRes } = createMockReqRes('POST', {
    action: 'activate',
    license_key: testLicense,
    device_id: 'macbook_air_m1_04',
    device_name: "MacBook Air"
  });
  await licenseHandler(d4RetryReq, d4RetryRes);
  assert.strictEqual(d4RetryRes.statusCode, 200);
  assert.strictEqual(d4RetryRes.body.active_devices_count, 3);
  pass('Device 4 now succeeds after slot freed');

  console.log(`\n========================================`);
  console.log(`🎉 ALL ${testCount} BACKEND & CRYPTO TESTS PASSED!`);
  console.log(`========================================\n`);
}

runTests().catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});

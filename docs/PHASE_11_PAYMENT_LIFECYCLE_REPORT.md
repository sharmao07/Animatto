# Animatto Phase 11 — Payment Lifecycle & License Fulfillment Hardening Report

## Executive Summary

Phase 11 establishes high reliability, cryptographic security, and automated resiliency across the complete Dodo Payments sandbox checkout-to-license fulfillment lifecycle. Building on the cryptographic guarantees established in Phase 5 and the multi-tier entitlement architecture finalized in Phases 9 and 10, Phase 11 eliminates attack surfaces, prevents duplicate license issuance under concurrent loads, secures transactional email delivery with exponential backoff and operator recovery, and verifies the end-to-end sandbox purchase lifecycle across 48 automated test suites, 2,062 Swift assertions, and native macOS application builds.

---

## 1. Checkout Security & Parameter Validation

### Product & Tier Mappings
- **Lifetime Pro ($3.99 USD / 399¢):** Product ID `pdt_animatto_pro_lifetime` (or `DODO_PAYMENTS_PRO_PRODUCT_ID`).
- **Founder Supporter ($5.99 USD / 599¢):** Product ID `pdt_animatto_founder_lifetime` (or `DODO_PAYMENTS_FOUNDER_PRODUCT_ID`).
- **Legacy Compatibility:** Seamless mapping of `pdt_animatto_premium_lifetime` to Lifetime Pro ($3.99).

### Tier Escalation Prevention
- Strict validation rejects mismatched requests (e.g., requesting `tier: "founder"` with `productId: "pdt_animatto_pro_lifetime"`, or requesting `tier: "pro"` with `productId: "pdt_animatto_founder_lifetime"`). Such requests fail immediately with HTTP 400 (`"Mismatched tier and product ID"`).
- Requests containing unrecognized product IDs fail with HTTP 400 (`"Invalid product ID"`).

### Customer Email Verification
- All checkout requests enforce strict RFC 5322 email regex verification (`EMAIL_REGEX`).
- `POST` checkout requests require a valid, non-empty customer email; missing or malformed email addresses fail closed with HTTP 400 (`"Invalid customer email address format"` / `"Customer email address is required"`).

### Edge Defense & Abuse Prevention
- **Return URL Allowlist:** Sanitizes redirect URLs to official domains (`animatto.app`, `*.animatto.app`, `*.vercel.app`, and `localhost`/`127.0.0.1` for local development); all untrusted URLs default safely to `https://animatto.app/success`.
- **Sliding Window Rate Limiter:** Enforces a 20 request/minute throttle per client IP address with memory cleanup sweeps when the map exceeds 1,000 active entries to eliminate memory leakage in serverless runtime containers.
- **Payload Size Limits:** Rejects requests exceeding 16 KB with HTTP 413.

---

## 2. Webhook Security & Fulfillment Idempotency

### HMAC-SHA256 & Replay Protection
- Standard Webhooks signature verification enforces SHA-256 HMAC authentication over `webhook-id.webhook-timestamp.body`.
- Replay tolerance strictly rejects timestamps older than 300 seconds (5 minutes) or timestamps set in the future.
- Live mode enforces fail-closed operations if `DODO_PAYMENTS_WEBHOOK_SECRET` or `LICENSE_SIGNING_PRIVATE_KEY` are not configured.

### Payload Verification Prior to License Issuance
- Strict email format validation rejects missing or malformed customer emails with HTTP 400 before state changes or cryptographic key signing.
- Strict currency validation requires `USD` and rejects unsupported foreign currencies with HTTP 400 (`"Unsupported currency"`).
- Server-side amount validation ensures payments meet or exceed the mandatory threshold (399¢ for Pro, 599¢ for Founder); underpaid transactions fail with HTTP 400 (`"Payment amount mismatch"`).

### Removal of Token Exposure
- **Critical Security Hardening:** Webhook HTTP responses for both initial issuance (`action: "license_issued"`) and idempotent replays (`action: "license_already_fulfilled"`) omit the raw `license_key` field (`undefined`), preventing token leakage in external HTTP logs, proxy traces, or third-party monitoring services.
- The signed license token is delivered exclusively through the secure transactional email outbox and durable database storage.

### Advisory Locks & Concurrent Delivery Serialization
- PostgreSQL fulfillment utilizes transaction-level advisory locks via `SELECT pg_advisory_xact_lock(hashtext('ord_' || orderId))` in `saveOrder`.
- Simultaneous webhook deliveries for the same order are serialized at the database engine level: exactly one transaction fulfills and issues the license, while concurrent deliveries safely detect the active record and return `action: "license_already_fulfilled"` without issuing duplicate tokens or dispatching duplicate emails.

---

## 3. Transactional Email Reliability & Outbox Architecture

### PostgreSQL Outbox Schema
The durable `email_outbox` table tracks transactional delivery state across serverless invocations:
- `id`: Serial primary key
- `order_id`: Foreign order reference
- `message_type`: Purpose category (`license_delivery`, `recovery`)
- `recipient`: Normalized customer email address
- `subject` & `content`: Message subject and rendered HTML/text payloads
- `status`: Lifecycle state (`queued`, `sent`, `awaiting_retry`, `failed`)
- `attempts`: Monotonically incrementing attempt count
- `next_retry_at`: Scheduled timestamp for exponential backoff retries
- `resend_id`: External provider message ID upon successful dispatch
- `last_error`: Diagnostic error message on delivery failures

### Deduplication Guarantee
- Before queueing or sending, `sendLicenseDeliveryEmail` verifies existing entries via `db.getEmailByOrderId(orderId, 'license_delivery')`.
- If an email has already been dispatched (`status: "sent"`) or is currently queued (`status: "queued"`), the operation returns `{ success: true, duplicate: true }` without inserting a second row into `email_outbox`.

### Bounded Exponential Backoff
- On transient HTTP errors (status codes 429 or 5xx) from Resend, the message transitions to `awaiting_retry`.
- Backoff intervals scale exponentially: $\min(3600, 2^{\text{attempt}} \times 10)\text{ seconds}$.
- The outbox worker (`processEmailOutboxRetries`) batches pending messages where `next_retry_at <= NOW()` and attempts delivery up to `MAX_DISPATCH_RETRIES` (3 attempts).

### Operator Recovery
- Permanent failures (HTTP 4xx client errors or exhausted retry quotas) transition to `failed`.
- The database export `recoverFailedEmail(outboxId)` allows support operators or automated dead-letter-queue scripts to safely reset an outbox item to `awaiting_retry` with `attempts = 0` and `next_retry_at = NOW()`.

---

## 4. End-to-End 11-Step Sandbox Lifecycle Journey

The full purchase-to-revocation lifecycle was verified with automated tests:

1. **Sandbox Checkout Session:** Initiated via `POST /api/checkout` with tier, email, and supporter consent; returned verified `sandbox_ready` checkout configuration.
2. **Webhook Receipt:** Simulated Dodo Payments `payment.succeeded` event with HMAC-SHA256 signature and replay timestamp.
3. **Price & Tier Validation:** Verified $5.99 (599¢) pricing and customer email validity.
4. **Ed25519 Token Issuance:** Server signed cryptographic license token containing complete Founder perks (`founder_badge`, `readme_acknowledgement`, `early_beta_access`) and Pro feature inheritance (`pro_sound_studio`, `pro_custom_palettes`, `aquarium_pro`, `multi_device_3`).
5. **Durable Persistence:** Order persisted in database store with active status and supporter consent metadata.
6. **Delivery Outbox:** Transactional email queued with `order_id` and dispatched via Resend mock transport.
7. **Native App Activation (Device 1):** Mac Studio M2 registered successfully (`active_devices_count: 1`).
8. **Multi-Mac Limit Enforcement (Devices 2, 3, 4):** MacBook Pro M3 and Mac mini M1 registered successfully (`active_devices_count: 2, 3`); MacBook Air M2 rejected with HTTP 403 (`"Device limit reached"`).
9. **Device Deactivation & Slot Replacement:** Device 1 deactivated (`active_devices_count: 2`); Device 4 activated into the newly freed slot (`active_devices_count: 3`).
10. **Account Recovery:** License recovery request dispatched recovery email without enumerating unregistered accounts.
11. **Refund & Revocation Lockout:** Dodo Payments `refund.succeeded` event processed; entitlement status updated to `refunded`; subsequent activation attempts rejected with HTTP 403 (`"License has been revoked due to refund or chargeback."`).

---

## 5. Verification Results

| Test Category | Suite / Command | Result | Details |
|---|---|---|---|
| **Security & Backend Suite** | `node web/test/test_backend.js` | **48 / 48 PASSED** | All Phase 5, Phase 9, Phase 10 & Phase 11 tests passed with 0 failures |
| **Web Static Validation** | `npm --prefix web test` | **52 / 52 PASSED** | Content security policy, canonical links, metadata, and asset integrity |
| **Native Swift Test Suite** | `swiftc ... Tests/AnimattoTests.swift` | **2,062 / 2,062 PASSED** | 100% assertions passed across all application phases |
| **Xcode Debug Build** | `xcodebuild -scheme Animatto` | **BUILD SUCCEEDED** | Native binary and bundle validated with 0 errors |
| **Private Key Regression Scan** | SHA-256 fingerprint matching | **0 LEAKS FOUND** | Working tree completely free of private key fixtures |

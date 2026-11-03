# Animatto Production Database & Security Configuration Guide

This document describes the production security architecture, database deployment requirements, and secret management protocols for Animatto macOS companion backend services.

---

## 1. Cryptographic Key Management (Ed25519)

Animatto uses asymmetric Ed25519 public-key cryptography to enable **100% offline license verification** on macOS without DRM phone-home overhead.

### Keypair Roles & Separation
- **Production Public Verification Key:** Embedded directly in the client application:
  - Swift App: `Animatto/EntitlementManager.swift` (`LicenseCryptoUtility.officialPublicKeyBase64`)
  - Web Backend: `web/lib/crypto.js` (`OFFICIAL_PUBLIC_KEY_BASE64`)
  - Value: `THicWCQTcrv96L6uwREk9qLrOiQcz5aGnVgbG7QXMGE=`
- **Production Private Signing Key:** Kept **strictly** in server-side environment variables:
  - Server Variable: `LICENSE_SIGNING_PRIVATE_KEY`
  - Format: Raw 32-byte Ed25519 private seed encoded as Base64.
  - **Zero Source Fallbacks:** The serverless webhook endpoint (`web/api/webhook.js`) fails closed with HTTP 500 if this secret is unconfigured in live mode.
- **Testing Isolation:** Automated test suites (`web/test/test_backend.js`) dynamically generate ephemeral Ed25519 keypairs at runtime in memory. Test-signed tokens are strictly rejected by the production public key.

---

## 2. Persistent Database Architecture

Animatto uses PostgreSQL for serverless data persistence on Vercel:

### Supported Providers
- **Vercel Postgres** (powered by Neon)
- **Neon Serverless Postgres**
- **Supabase Database**
- **AWS RDS / Railway Postgres**

### Connection Strings
Configure either of the following environment variables in your Vercel project:
- `DATABASE_URL=postgres://user:password@host:5432/animatto?sslmode=require`
- `POSTGRES_URL=postgres://...`

### Database Schema & Tables
Tables and indexes are automatically created via idempotent migrations in `web/lib/db.js` (`initDatabase()`):

| Table | Purpose | Concurrency & Integrity Controls |
|---|---|---|
| `webhook_events` | Webhook idempotency & retry tracking | Unique `event_id` with multi-phase states: `processing`, `completed`, `failed`. Rejections and errors are NOT marked completed, permitting provider retries. |
| `orders` | Durable purchase fulfillment & licenses | Unique `order_id` constraint. Concurrent deliveries return existing active license without re-issuing conflicting tokens. |
| `device_activations` | 3-device activation limits | PostgreSQL `pg_advisory_xact_lock(hashtext(token_hash))` ensures atomic limit checks across concurrent serverless instances. |
| `email_outbox` | Transactional email audit & state machine | Explicit states: `queued`, `sent`, `failed`, `awaiting_retry`. Stores Resend message IDs and delivery attempt counts. |

### Fail-Closed Enforcement
In production mode (`NODE_ENV=production` or `DODO_PAYMENTS_MODE=live`):
- If `DATABASE_URL` is missing or the database connection fails, operations **fail closed immediately** with HTTP 500.
- The system **never silently falls back to local JSON or in-memory stores in production**.

---

## 3. Transactional Email Delivery (Resend)

Order confirmations and license recovery emails are dispatched via the native HTTPS Resend REST API client (`web/lib/email.js`).

### Configuration
```bash
RESEND_API_KEY=re_123456789...
EMAIL_FROM="Animatto Licensing <support@animatto.app>"
```

### State Machine
1. **`queued`:** Persisted into `email_outbox` prior to HTTP dispatch.
2. **`sent`:** Resend returned HTTP 200/201 with message ID.
3. **`awaiting_retry`:** Transient network failure or 5xx provider error. Automatically eligible for subsequent retry attempts (up to 3).
4. **`failed`:** Unrecoverable 4xx client rejection (e.g., malformed email or unverified domain) or exceeded maximum retry attempts.

---

## 4. Webhook Processing Order of Operations

1. **Size check:** Request body capped at 64 KB.
2. **HMAC Signature Check:** Verified against `DODO_PAYMENTS_WEBHOOK_SECRET` with 5-minute replay tolerance window. Invalid signatures return HTTP 401 without modifying database state.
3. **Payload Pre-Validation:** Rejects test events when running in live mode; verifies product ID and payment amount.
4. **Idempotency Check:** Records event as `processing` in PostgreSQL. If already completed, returns HTTP 200 with cached result.
5. **Atomic Execution:** Fulfills order, saves to `orders` table, queues and dispatches email, then updates event status to `completed`.
6. **Error Handling:** On unhandled exceptions, event status is marked `failed` so the provider's retry schedule can deliver the event again.

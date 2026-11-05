# Animatto — Official Dodo Payments Integration Guide

This document specifies the architecture, setup, security controls, and testing workflows for the official **Dodo Payments** (Merchant of Record) integration in Animatto.

---

## 1. Official Dodo Payments Plugin Installation

The official Dodo Payments Antigravity plugin provides agent skills and MCP tools covering the complete Dodo Payments API, SDK specifications, and webhook catalog.

### Installation Steps

From outside the repository:

```bash
# 1. Clone official plugin repository
git clone https://github.com/dodopayments/dodo-agent-plugin.git

# 2. Install plugin into Antigravity
agy plugin install ./dodo-agent-plugin/providers/antigravity

# 3. Verify installed components
agy plugin list
```

Installed components:
- **18 Skills:** `checkout-integration`, `webhook-integration`, `billing-sdk`, `testing-and-go-live`, `license-keys`, `product-catalog-management`, `dodo-best-practices`, etc.
- **2 MCP Servers:** `dodo-knowledge` (`https://knowledge.dodopayments.com/mcp`), `dodopayments-api` (`https://mcp.dodopayments.com/mcp`).
- **Installed Location:** `/Users/ojussharma/.gemini/config/plugins/dodopayments`

---

## 2. Product Architecture & Pricing Model

Animatto uses a clean, two-tier one-time perpetual pricing model without recurring subscriptions:

| Product Tier | Unit Price | Billing Type | Max Personal Macs | Entitlements & Benefits |
|---|---|---|---|---|
| **Animatto Lifetime Pro** | **$3.99 USD** (399¢) | One-time | 3 | Pro Sound Studio, Custom Palettes & Themes, Aquarium Pro Customization, Multi-Mac (up to 3 Macs) |
| **Animatto Founder Supporter** | **$5.99 USD** (599¢) | One-time | 3 | **100% of Pro features** + Founder Supporter Badge, Early Beta Access, Optional README Recognition |

> [!IMPORTANT]
> **Strict Entitlement Inheritance:** Founder Supporter ($5.99) inherits 100% of Lifetime Pro benefits plus Founder exclusive perks.
> **Zero Tier Escalation via Metadata:** Founder status is bound solely to verified Dodo product IDs on the server. Client-supplied metadata or tampering can never escalate a Lifetime Pro purchase to Founder Supporter.

---

## 3. Product-ID Mapping & Environment Variables

All product IDs and credentials are kept strictly configurable through environment variables with safe defaults.

### Environment Variable Reference

| Variable | Required | Default / Example | Purpose |
|---|---|---|---|
| `DODO_PAYMENTS_ENVIRONMENT` | Yes | `test_mode` | Mode selector: `'test_mode'` (safe default) or `'live_mode'` |
| `DODO_PAYMENTS_MODE` | No | `test` | Backward-compatible alias for environment (`test` / `live`) |
| `DODO_PAYMENTS_API_KEY` | Yes (API calls) | `dodo_test_...` | Bearer token for server-side Dodo SDK calls |
| `DODO_PAYMENTS_WEBHOOK_KEY` | Yes (Webhooks) | `whsec_...` | Standard Webhooks signing key for HMAC-SHA256 verification |
| `DODO_PAYMENTS_WEBHOOK_SECRET` | No | `whsec_...` | Backward-compatible alias for `DODO_PAYMENTS_WEBHOOK_KEY` |
| `DODO_PAYMENTS_PRO_PRODUCT_ID` | Optional | `pdt_animatto_pro_lifetime` | Product ID for Lifetime Pro ($3.99 USD) |
| `DODO_PAYMENTS_FOUNDER_PRODUCT_ID` | Optional | `pdt_animatto_founder_lifetime` | Product ID for Founder Supporter ($5.99 USD) |
| `ENABLE_PRODUCTION_PAYMENTS` | Yes (Live only) | `false` | Production safety gate: must be `true` to enable live payments |
| `LICENSE_SIGNING_PRIVATE_KEY` | Yes | 32-byte Base64 Seed | Server-side Ed25519 seed used to cryptographically sign license tokens |
| `LICENSE_VERIFICATION_PUBLIC_KEY` | Optional | `THicWCQT...` | Ed25519 verification public key (embedded in macOS native app) |
| `DATABASE_URL` / `POSTGRES_URL` | Yes (Production) | `postgresql://...` | PostgreSQL connection string for ACID order & webhook idempotency |
| `RESEND_API_KEY` | Yes (Emails) | `re_...` | Resend API key for license delivery and recovery transactional emails |
| `EMAIL_FROM` | Optional | `Animatto Licensing <support@animatto.app>` | Verified sender address for transactional emails |

---

## 4. Server-Side Checkout Sessions

All checkout sessions are created server-side using the official `dodopayments` SDK via `client.checkoutSessions.create`:

```javascript
const session = await client.checkoutSessions.create({
  product_cart: [
    { product_id: effectiveProductId, quantity: 1 }
  ],
  customer: customerEmail ? { email: customerEmail } : undefined,
  return_url: returnUrl,
  metadata: {
    app: 'Animatto',
    platform: 'macOS',
    tier: effectiveTier,
    supporter_name: supporterName || '',
    supporter_consent: supporterConsent ? 'true' : 'false'
  }
});
```

### Security Gates & Safeguards

1. **Provider-Hosted Checkout Only:** Animatto never handles, collects, or stores raw payment card details. All financial transactions take place on Dodo Payments hosted checkout.
2. **Product Allowlist:** The server strictly checks requested product IDs against the allowlist (`pdt_animatto_pro_lifetime`, `pdt_animatto_founder_lifetime`, or configured environment variables).
3. **Mismatched Tier Rejection:** If a client requests `tier: 'founder'` with a Pro product ID or vice-versa, the request is rejected immediately with HTTP 400.
4. **Email Format Validation:** Customer emails are validated against RFC 5322 regex and length constraints before checkout session creation.
5. **Return URL Allowlist:** Untrusted redirect targets are sanitized to `https://animatto.app/success` to eliminate open redirect vectors.
6. **No Client Entitlement on Redirect:** The browser redirect is treated strictly as an informational UI landing page. Licenses are NEVER issued on redirect.

---

## 5. Webhook Fulfillment & Idempotency

Webhooks are delivered to `/api/webhook`.

### Processing Lifecycle

```
[Dodo Payments Event]
         │
         ▼
[1. Payload Size Check (< 64KB)]
         │
         ▼
[2. Standard Webhooks HMAC-SHA256 Signature Verification] ──(Invalid)──► HTTP 401
         │
         ▼
[3. Fail-Closed Secret & Key Check] ──(Missing in Live)──► HTTP 500
         │
         ▼
[4. Live Mode Rejection of Test Events] ──(Test Event in Live)──► HTTP 400
         │
         ▼
[5. Event Parameter Pre-validation]
    - Product ID in allowlist
    - Transaction currency == 'USD'
    - Amount >= $3.99 (Pro) or >= $5.99 (Founder)
    - Valid customer email format
         │
         ▼
[6. Atomic Database Idempotency Check]
    - If event already completed: Return HTTP 200 (idempotent_duplicate)
    - If event currently processing: Return HTTP 202
    - If order already fulfilled: Return HTTP 200 without reissuing
         │
         ▼
[7. Verified Tier Derivation]
    - Tier determined solely by verified product_id
    - Untrusted client metadata cannot escalate tier
         │
         ▼
[8. Cryptographic License Issuance]
    - Ed25519 signature over canonical JSON
    - Perpetual lifetime access (expiresAt: null)
    - 3-device personal activation limit
         │
         ▼
[9. Transactional Email Outbox Queue]
    - Delivered via Resend HTTPS API with retry backoff
         │
         ▼
[10. Mark Event Completed & Return HTTP 200]
```

### Security & Privacy Controls

- **Token Secrecy:** The license token is NEVER returned in the webhook HTTP response body or logged to server stdout/stderr.
- **Fail-Safe Retries:** If an unexpected internal database error occurs during order processing, the event is marked as `failed` (not `completed`), allowing Dodo Payments to retry the webhook safely.
- **Revocation Handling:** `refund.succeeded` and `dispute.opened` events immediately revoke entitlement in the persistent database and lock out native app activations.

---

## 6. Dodo Dashboard Configuration Checklist

Before conducting sandbox or production transactions, configure the Dodo Payments Dashboard:

### 1. Products Setup (Test Mode)
- **Product 1 (Lifetime Pro):**
  - Name: `Animatto Lifetime Pro`
  - Price: `$3.99 USD`
  - Payment Type: One-time payment
  - Product ID: Copy generated `pdt_...` ID to `DODO_PAYMENTS_PRO_PRODUCT_ID`
- **Product 2 (Founder Supporter):**
  - Name: `Animatto Founder Supporter`
  - Price: `$5.99 USD`
  - Payment Type: One-time payment
  - Product ID: Copy generated `pdt_...` ID to `DODO_PAYMENTS_FOUNDER_PRODUCT_ID`

### 2. Webhook Endpoint Setup (Test Mode)
- Navigate to **Developer → Webhooks → Create Webhook**.
- **Endpoint URL:** `https://your-domain.com/api/webhook`
- **Subscribed Events:**
  - `payment.succeeded`
  - `payment.failed`
  - `refund.succeeded`
  - `dispute.opened`
- Copy the **Signing Secret** (`whsec_...`) to `DODO_PAYMENTS_WEBHOOK_KEY`.

---

## 7. Automated Test Suite Verification

Animatto includes 58 backend security, licensing, checkout, and webhook tests in `web/test/test_backend.js`.

### Running Backend Tests

```bash
node web/test/test_backend.js
```

### Running Native macOS App Tests

```bash
swiftc -DDEBUG -sdk $(xcrun --show-sdk-path) $(ls Animatto/*.swift | grep -v AnimattoApp.swift) Tests/AnimattoTests.swift -o /tmp/animatto_tests && /tmp/animatto_tests
```

### Running Website Static Quality & SEO Checks

```bash
node web/test/validate_web.js
```

All 58 backend tests and 2,130 native app unit assertions pass with 100% success.

---

## 8. Remaining Production Prerequisites

Before switching `DODO_PAYMENTS_ENVIRONMENT` to `live_mode` and setting `ENABLE_PRODUCTION_PAYMENTS=true`:

1. **Merchant Verification:** Complete KYC/KYB identity and business verification in the Dodo Payments live dashboard.
2. **Live Products:** Create live `Animatto Lifetime Pro` ($3.99) and `Animatto Founder Supporter` ($5.99) products in the Dodo live dashboard.
3. **Live Webhook Endpoint:** Create a production HTTPS webhook endpoint in the Dodo live dashboard and configure `DODO_PAYMENTS_WEBHOOK_KEY` in production environment variables (e.g. Vercel).
4. **Live Database:** Provision production PostgreSQL (Vercel Postgres, Neon, AWS RDS, Supabase) and configure `DATABASE_URL`.
5. **Private Key Generation:** Generate a cryptographically secure 32-byte Ed25519 seed and set `LICENSE_SIGNING_PRIVATE_KEY` in production secrets.
6. **Domain Verification:** Verify `animatto.app` domain in Resend for transactional email dispatch.

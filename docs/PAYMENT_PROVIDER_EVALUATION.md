# Animatto — Payment Provider Evaluation & Seller Compliance Report

**Document Version:** 1.0.0  
**Target Release:** Animatto v1.2.0 (Phase 4)  
**Primary Provider Candidate:** Dodo Payments (Merchant of Record)  
**Alternative Compared:** Gumroad  
**Date:** November 4, 2026  

---

## 1. Executive Summary

This evaluation establishes the payment and licensing infrastructure for Animatto's optional one-time Premium license ($9.99 USD). Animatto adopts **Dodo Payments** as its primary Merchant of Record (MoR) provider candidate due to native Indian Rupee (INR) bank payouts, competitive transaction fees (4% + 15¢ in India vs. ~13% on Gumroad), and native software licensing and entitlement features.

### Legal Account-Holder Checkpoint
> [!IMPORTANT]
> **Minor Account-Holder Requirement:** The primary project maintainer is currently under 18 years old. Under the Indian Contract Act (1872) and global KYC/AML compliance regulations, individuals under 18 cannot legally enter binding financial merchant contracts or undergo personal financial KYC.
> 
> **Lawful Action Required:** A parent or legal guardian must act as the registered account holder (as an Individual/Sole Proprietor with their own PAN, Aadhaar, and bank account), or establish a registered business entity (LLP or Private Limited company) where an adult legal guardian serves as director and authorized signatory.
> 
> **Stop Condition Adherence:** No imaginary or falsified production credentials will be used. All code and backend systems are built with provider-independent interfaces, sandbox/test mode verification, and zero client secrets.

---

## 2. Provider Detailed Comparison: Dodo Payments vs. Gumroad

| Evaluation Criteria | Dodo Payments (Recommended) | Gumroad (Alternative) | Analysis & Recommendation |
|---|---|---|---|
| **Seller Country Support** | Officially supports India (IN) for sellers and payouts | Supports India, but requires third-party payout rails | **Dodo is superior**: First-class onboarding for Indian developers. |
| **Payout Method & Currency** | Direct bank transfer (NEFT/RTGS/IMPS) in native INR | Payouts via PayPal or Stripe Connect | **Dodo is superior**: Direct local bank deposits avoid PayPal's high FX margins (3.5%–4%) and Stripe Connect's invite-only restrictions in India. |
| **Transaction Fees** | **India:** 4% + 15¢ (cards & UPI)<br>**US:** 4% + 40¢<br>**International:** +1.5% | **Flat 10%** + payment processing fee (~2.9% + 30¢), totaling **~12.9% + 30¢** | **Dodo is ~60% cheaper**: On a $9.99 purchase, Dodo takes ~$0.80–$0.95 vs. Gumroad's ~$1.59. |
| **Merchant of Record (MoR) Scope** | Global MoR: calculates, collects, and remits sales tax, EU/UK VAT, and Indian GST. Provides compliant tax invoices. | Global MoR: handles global sales tax and VAT. | **Equal**: Both act as full legal resellers, removing tax registration burdens from the developer. |
| **Software Licensing Capabilities** | Built-in software license key generation, device activation tracking, validation, and automated refund revocation. | Basic license key generator. Device tracking requires custom backend. | **Dodo is superior**: Integrated entitlement and device-instance lifecycle. |
| **Webhook Protocol** | Standard Webhooks specification with HMAC-SHA256 signatures (`webhook-id`, `webhook-signature`, `webhook-timestamp`). | Custom ping/webhook HTTP POST. | **Dodo is superior**: Industry-standard cryptographic webhook security. |
| **Sandbox / Test Mode** | Full sandbox (`https://test.dodopayments.com`) with test cards and simulated webhook delivery. | Basic test purchase feature. | **Dodo is superior**: Predictable, isolated sandbox environment. |

---

## 3. Financial Analysis & Pricing Strategy

### Product Definition: Animatto Premium (One-Time Purchase)
- **Retail Price:** **$9.99 USD** (approx. ₹830 INR).
- **Billing Model:** One-time perpetual license. No recurring subscriptions.
- **Device Limit:** Up to **3 personal Macs** per license key.

### Fee Breakdown & Net Payout Estimates (at $9.99 USD)

1. **Domestic US Customers (4% + $0.40):**
   - Gross: $9.99
   - Dodo Fee: $0.40 + $0.40 = $0.80
   - **Net Revenue: $9.19 (92.0%)**

2. **International Customers (5.5% + $0.40):**
   - Gross: $9.99
   - Dodo Fee: $0.55 + $0.40 = $0.95
   - **Net Revenue: $9.04 (90.5%)**

3. **Domestic Indian Customers via UPI/Cards (4% + $0.15 = ~₹45.7):**
   - Gross: ₹830.00
   - Dodo Fee: ~₹45.70
   - **Net Revenue: ~₹784.30 (94.5%)**

### Payout Terms
- **Minimum Payout / Free Threshold:** Payouts of $1,000+ carry **$0 payout fee**.
- **Under $1,000 Payout Fee:** Flat $5.00 per payout.
- **Recommendation:** Maintain an automatic monthly payout threshold of $1,000 or bi-monthly withdrawal once initial volume stabilizes.

---

## 4. Legal Compliance & Action Plan for Production

To activate production sales lawfully, the following steps must be completed by an adult representative:

1. **Adult Account-Holder Identification:** Maintainer's parent or legal guardian agrees in writing to act as the legal merchant of record account holder.
2. **KYC Verification:**
   - Identity verification of parent/guardian (Indian PAN Card and Aadhaar Card).
   - Residential address verification.
   - Bank account linking (Indian savings or current account matching the guardian's name).
3. **Business Profile Review:** Submit Animatto's website (`https://animatto.app` or vercel domain) showing transparent pricing, terms of service, and refund policy.
4. **API Key Generation:** Generate production `live_` API key and configure production webhook endpoint in Dodo Payments dashboard.
5. **Private Key Storage:** Generate server-side Ed25519 private key in production serverless environment variables (`LICENSE_SIGNING_PRIVATE_KEY`).

---

## 5. Summary of Architecture Principles

1. **Client Isolation:** The macOS client never holds payment API keys, webhook secrets, or private signing keys.
2. **Offline Verification:** The macOS client verifies licenses locally using an embedded Ed25519 public key.
3. **Zero Telemetry:** Neither the client nor the backend tracks user behavior or transmits companion data.
4. **Data Preservation:** Deactivating a license or running in unlicensed mode preserves 100% of user data, companions, and configurations.

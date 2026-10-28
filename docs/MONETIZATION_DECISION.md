# Animatto — Monetization, Premium Tier, and Licensing Assessment

## Executive Summary & Recommendation

**Strategic Recommendation:** **DEFER COMMERCIAL MONETIZATION. KEEP ANIMATTO 100% FREE AND OPEN-SOURCE.**

Animatto is released under the **Apache 2.0 License**. Its core appeal rests on being a delightfully private, native macOS companion application that runs completely offline with zero telemetry and zero recurring cloud costs for local physics, animation, memory, and dialogue.

Introducing paywalls, software activation locks, or DRM on local companion features would:
1. Contradict the Apache 2.0 open-source ethos.
2. Compromise offline reliability and user privacy.
3. Introduce disproportionate operational burdens (refunds, VAT/tax filing, key recovery, chargeback disputes) for a desktop pet utility.
4. Encourage hostile user circumvention without providing meaningful value.

Therefore, **all existing and core desktop companion features are permanently classified as FREE**. A defensive entitlement architecture is established to formalize these boundaries, and a provider assessment is conducted should hosted cloud services (e.g., hosted multi-device sync or cloud LLM quotas) be introduced in the distant future.

---

## 1. Value Analysis: Free vs. Optional Future Premium

| Capability Category | Classification | Rationale |
| :--- | :--- | :--- |
| **Desktop Physics, Wandering & Falling** | **100% FREE** | Core product foundation; must never be gated or disabled. |
| **Unlimited Characters & User Sprites** | **100% FREE** | User-owned artwork; gating user files is unethical. |
| **10-Trait Personality Matrix & Presets** | **100% FREE** | Core behavioral simulation; purely local computation. |
| **Speech Bubbles & Contextual Dialogue** | **100% FREE** | Pre-bundled curated dialogue library; zero recurring cost. |
| **Character Memory & Continuity** | **100% FREE** | Local JSON storage in Application Support; private to user. |
| **Multi-Companion Social Interactions** | **100% FREE** | Local physics interaction between active companions. |
| **Focus Sessions & Pomodoro Companion** | **100% FREE** | Local productivity utility; zero external dependencies. |
| **Workshop Studio & Background Eraser** | **100% FREE** | Native on-device Apple Vision segmentation; runs offline. |
| **Software Updates & GitHub Releases** | **100% FREE** | Open-source distribution via GitHub. |
| *Hosted Multi-Device Cloud Sync* | *Potential Future Premium* | Only justifiable if dedicated database servers are maintained. |
| *Hosted Managed LLM Token Quotas* | *Potential Future Premium* | Only justifiable if paying upstream AI inference costs per token. |
| *Curated Commercial Artist Marketplace* | *Potential Future Premium* | Commission-based revenue sharing for professional artist packs. |

---

## 2. Operational & Security Implications of Licensing

1. **Security Risks of Client-Side Gating:** Client-side license verification in open-source binaries is trivially bypassable (e.g. patching assembly or replacing a boolean). True enforcement requires a server-side authority that provides server-rendered value, which does not apply to a local AppKit desktop companion.
2. **Offline Resilience:** Users frequently run Animatto on laptops without active internet connections (e.g., in transit, on planes). If licensing requires periodic online validation or phone-home pings, offline users could suffer lockouts or degraded behavior.
3. **Data Preservation:** Licensing state failures or subscription lapses must **never** delete local character files, erase memories, or alter user preferences.

---

## 3. Merchant-of-Record (MoR) & Licensing Provider Comparison

Should monetization ever become necessary for hosted cloud infrastructure, the following providers were audited:

| Provider | Model | Fees | Merchant of Record (Global Tax) | License Key API | Offline / Hardware Lock | Suitability |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lemon Squeezy** | MoR | 5% + $0.50 per transaction | Handles global VAT, sales tax, EU invoicing, chargebacks. | Full REST API (`/v1/licenses/activate`, `/v1/licenses/validate`). | Supports device activation limits and instance IDs. | **Best for commercial digital licenses.** |
| **Polar.sh** | MoR / Open Source | 4% + $0.40 per transaction | Built specifically for open-source developer funding and MoR benefit. | Flexible benefit grants, GitHub OAuth, Discord integration. | Geared towards subscription benefits and SaaS access. | **Best for developer-first open source funding.** |
| **Gumroad** | MoR | 10% flat fee + payment processing | Handles global tax; older UI and high fee structure. | Basic license verification API (`/v2/licenses/verify`). | Basic activation count tracking. | High fees (10%) make it uncompetitive. |
| **GitHub Sponsors** | Direct Sponsorship | 0% for user sponsors (Stripe fees apply) | Not an MoR; requires maintainer to handle tax liabilities. | GitHub GraphQL / REST API to check sponsorship status. | Online GitHub query required; no standalone key. | **Ideal for optional community donations.** |

---

## 4. Architectural Boundaries

To ensure complete modularity, the entitlement system is isolated in [`Animatto/EntitlementManager.swift`](file:///Users/ojussharma/Desktop/KinetiPet/Animatto/EntitlementManager.swift):
- All core desktop capabilities return `isGranted = true` regardless of license status.
- `LicenseKey` entries are stored in macOS Keychain (`kSecClassGenericPassword`), never in plaintext `UserDefaults`.
- Full license keys are strictly redacted in logs (`XXXX-****-****-YYYY`).
- Network failures trigger a resilient 14-day `.gracePeriod` that guarantees full access and zero data loss.

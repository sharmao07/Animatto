# Animatto — Product Readiness & Free-versus-Pro Strategy

**Document Version:** 1.1.0  
**Status:** Audit & Baseline Established  
**Architecture Source of Truth:** Native macOS (AppKit, SwiftUI, Apple Vision)  
**Related Documents:** [`docs/MONETIZATION_DECISION.md`](MONETIZATION_DECISION.md), [`docs/TEST_PLAN.md`](TEST_PLAN.md)

---

## Executive Summary

Animatto is a native macOS desktop companion application released under the **Apache 2.0 open-source license**. Its primary value proposition rests on high-quality desktop physics, window-edge interactions, personality-driven dialogue, character memory, and ambient weather particle effects—executed 100% offline with zero telemetry and zero required cloud subscriptions.

This document establishes the product boundaries for a future commercial **Free vs. Pro** model. It explicitly defines what remains permanently free, evaluates candidate premium features based on actual code verification, proposes a simple initial pricing experiment, and protects the core open-source experience from hostile gating.

---

## 1. Feature Inventory & Current Implementation Status

| Capability / Feature | Component / File | Audit Status | Current Tier Classification |
| :--- | :--- | :--- | :--- |
| **Desktop Physics, Wandering & Gravity** | `PetEngine.swift` | **Implemented & Verified** | **100% FREE** |
| **Window Surface & Screen Edge Collision** | `PetEngine.swift` | **Implemented & Verified** | **100% FREE** |
| **Menu Bar Upside-Down Walking Mode** | `PetEngine.swift`, `MenuBarDashboard.swift` | **Implemented & Verified** | **100% FREE** |
| **Companion Dragging & Toss Physics** | `PetEngine.swift` | **Implemented & Verified** | **100% FREE** |
| **10-Trait Personality Matrix & Presets** | `PersonalityModel.swift`, `BehaviorEngine.swift` | **Implemented & Verified** | **100% FREE** |
| **Contextual Speech Bubbles & Dialogue** | `DialogueSystem.swift` | **Implemented & Verified** | **100% FREE** |
| **Local Character Memory & Continuity** | `CharacterMemoryStore.swift` | **Implemented & Verified** | **100% FREE** |
| **Multi-Companion Social Interactions** | `SocialInteractionManager.swift` | **Implemented & Verified** | **100% FREE** |
| **Pomodoro & Focus Productivity Timer** | `ProductivityTimerManager.swift` | **Implemented & Verified** | **100% FREE** |
| **Starter Companions (8 Sprites) & User Import** | `PetStorage.swift`, `DefaultCompanions/` | **Implemented & Verified** | **100% FREE** |
| **Workshop: Local Offline AI Magic Eraser** | `WorkshopService.swift` (Apple Vision) | **Implemented & Verified** | **100% FREE** |
| **Menu Bar Dashboard Popover Panel** | `MenuBarDashboard.swift` | **Implemented & Verified** | **100% FREE** |
| **Privacy Shield (Instant Pause & Mute)** | `PetEngine.swift`, `ScreenAwarenessSystem.swift` | **Implemented & Verified** | **100% FREE** |
| **Ambient Worlds: 6 Weather Environments** | `AmbientEngine.swift` | **Implemented & Verified** | **100% FREE** |
| **Ambient Worlds: Particle Quality Modes & Presets**| `AmbientModels.swift`, `AmbientEngine.swift` | **Implemented & Verified** | **100% FREE** |
| **Ambient Worlds: 11-Language Localization** | `AmbientLocalization.swift` | **Implemented & Verified** | **100% FREE** |
| **Ambient Minigame (Catch Droplets)** | `AmbientMinigameManager.swift` | **Implemented & Verified** | **100% FREE** |
| **Open-Meteo Automatic Live Weather Sync** | `WeatherSyncService.swift` | **Implemented & Verified** | **100% FREE** |
| **Custom Atmosphere Preset Creation & Export** | `AtmospherePackService.swift` | **Implemented & Verified** | **Candidate for Pro Pack** |
| **Screen Awareness (ScreenCaptureKit & Vision)** | `ScreenAwarenessSystem.swift` | **Implemented (Opt-in)** | **Candidate for Pro / BYOK** |
| **Remote AI Generation (Pollinations API)** | `WorkshopService.swift` | **Implemented (Free tier endpoint)** | **Candidate for Pro** |
| **Shimeji Community Directory Search** | `WorkshopService.swift` | **Implemented (External API)** | **100% FREE** |
| **Hosted Multi-Device Cloud Sync** | None (Proposed) | **Not Implemented; Future Only** | **Future Pro Subscription** |
| **Curated Studio-Grade Artist DLC Packs** | None (Proposed) | **Not Implemented; Future Only** | **Future Pro / Marketplace** |
| **Managed LLM Conversational Quota** | None (Proposed) | **Not Implemented; Future Only** | **Future Pro Subscription** |

---

## 2. Free Edition (Permanent Scope)

The **Free Edition** represents the complete, uncompromising desktop companion experience. A user downloading Animatto for free must have a rich, delightful, and non-crippled utility:

1. **Full Behavioral Core:** Complete access to all 10 personality archetypes (Curious, Sleepy, Playful, Shy, Mischievous, Calm, Energetic, Sarcastic, Supportive, Balanced) with autonomous movement, mood calculations, and contextual dialogue.
2. **Unlimited Local Artwork:** Users can import an unlimited number of local `.png`, `.gif`, and `.webp` animations from their own machine without artificial caps.
3. **Core Physics & Window Interactions:** Autonomous roaming across all spaces, jumping on active window titlebars, falling with gravity, and upside-down walking underneath the macOS menu bar.
4. **Local Privacy & Offline AI Tools:** Character memory saved locally on disk, full Pomodoro timer manager, Privacy Shield toggle, and offline Apple Vision background segmentation.
5. **Basic Ambient Worlds:** Core weather environments (Rain, Snow, Fog, Sunlight, Wind, Autumn Leaves) running locally with Low Power, Balanced, and High Quality simulation modes.
6. **Open Updates & Zero Ads:** Direct GitHub DMG downloads, zero adware, zero tracking, and zero forced registration.

---

## 3. Proposed Pro Edition (Feature Evaluation & Readiness)

The **Pro Edition** must be composed exclusively of convenience enhancements, aesthetic expansion, and service-backed integrations rather than defensive gating of local offline utilities.

| Proposed Pro Feature | Architecture Evaluation | Verification Status | Ready for Immediate Sale? |
| :--- | :--- | :--- | :--- |
| **1. Mac App Store Convenience Build** | Open-source DMG remains free on GitHub; notarized Mac App Store build with iCloud sync sold for a one-time price. | Architecture supports sandbox; requires Apple Developer account submission. | **No** (Pending Developer ID & App Store review) |
| **2. Multi-Companion Saved Layout Presets** | Saving and restoring multi-companion desktop groups (e.g. "Work Mode: Cat + Slime", "Chill Mode: Bird + Fox"). | Core multi-companion engine exists (`activePets`); serialization of grouped layouts is partially implemented. | **No** (Requires UI preset grouping tests) |
| **3. Curated Themed Atmosphere & Soundscape Packs** | Bespoke audio soundscapes (binaural rain, crackling fire) and hand-drawn seasonal particle art packs (`.animattopack`). | Pack import/export engine verified (`AtmospherePackService`); audio soundscape synthesis not yet bundled. | **No** (Requires curated artwork & audio assets) |
| **4. Cloud LLM Conversational Brain (Managed API Quota)** | Real-time conversational companionship with cloud LLMs (Gemini / Claude) beyond offline rule-based speech bubbles. | Provider interface implemented (`ScreenUnderstandingProvider`); cloud proxy backend and token accounting not built. | **No** (Requires hosted backend proxy) |
| **5. Advanced Workshop Batch Vectorizer & Exporter** | Multi-frame sprite sheet slicing, automated palette swapping, and signed creator pack publishing. | Basic Vision single-frame and GIF remover verified; batch vectorization is future proposal only. | **No** (Future proposal only) |

> [!IMPORTANT]
> **Defensive Rule:** No feature will be marketed or sold as part of an immediately purchasable "Pro" tier until its implementation is 100% complete, verified by automated tests, and tested on production macOS hardware.

---

## 4. Simple Initial Pricing Experiment

### Hypothesis
*A significant subset of macOS users values friction-free distribution (Mac App Store 1-click install, auto-updates, iCloud sync) and high-production aesthetic packs enough to pay a modest one-time fee ($4.99 – $9.99).*

### Experiment Design
1. **Primary Model:** **Paid Front Door on Mac App Store ($4.99 One-Time) + Free Direct GitHub DMG.**
   - **GitHub / Website:** Remains 100% free and open-source (Apache 2.0).
   - **Mac App Store:** Priced at **$4.99** (Tier 5) as a one-time convenience purchase.
2. **Alternative Test (Direct DMG):** **Supporter Edition / Digital Tip Jar via Lemon Squeezy or Polar.sh ($5.00 – $15.00).**
   - Grants an optional cosmetic perk (e.g., golden companion crown toggle, Supporter badge in About window).
   - No feature paywall; measures voluntary willingness-to-pay (WTP) among existing enthusiastic users.

### Value & Risk Analysis
- **Expected Customer Value:** Instant convenience, seamless updates, supporting indie open-source development, and zero subscription fatigue.
- **Possible Drawbacks:** Some users may mistake the Mac App Store pricing for a proprietary lock-in if the open-source direct build is not clearly communicated.
- **Success Metrics to Measure:**
  - Conversion rate from website visitors to DMG downloads vs. Mac App Store purchases.
  - Tip jar donation volume per 1,000 active installations.
  - User sentiment and bug reports regarding licensing friction.

---

## 5. Upgrade Boundaries & Ethical Guarantees

To ensure Animatto retains its reputation as a safe, delightful, and private macOS desktop companion:

1. **No Hostage Data:** Upgrading or downgrading must never delete character files, erase memories, or alter user configuration.
2. **Offline Resilience:** Animatto must remain 100% functional without an active network connection. Offline users must never encounter lockout screens, modal nag dialogs, or degraded physics loops.
3. **Transparent Privacy:** Screen awareness, audio monitoring, and update checks must remain strictly opt-in with explicit disclosures.
4. **Clean Uninstallation:** Uninstalling the app must never require proprietary uninstaller software. All user data is isolated in `~/Library/Application Support/AnimattoPets` and standard `UserDefaults`.
5. **No Artificial Resource Throttling:** The free edition will never artificially limit CPU frame rates, degrade physics responsiveness, or inject watermarks onto companion sprites.

---

## 6. Explicit Non-Goals for Current Cycle

The following items are **explicitly out of scope** for this product-readiness milestone:
- **No In-App Purchases (StoreKit) Implementation:** StoreKit 2 and payment APIs must not be linked or activated in this cycle.
- **No License Activation Keys or DRM:** No client-side gating or license validation servers.
- **No Subscription Management Infrastructure:** No recurring billing logic or account creation walls.
- **No Web Storefront or Payment Gateway Integration:** No Stripe, PayPal, or Lemon Squeezy checkouts embedded in the native app.

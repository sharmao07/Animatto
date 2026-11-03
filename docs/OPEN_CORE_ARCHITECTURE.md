# Animatto — Open-Core Architecture & Licensing Framework

**Document Version:** 1.0.0  
**Target Release:** Animatto v1.2.0+  
**Primary License:** Apache License, Version 2.0 (Unchanged)  
**Classification:** Core Architectural Specification

---

## 1. Executive Vision: The Open-Core Foundation

Animatto is built as a premier, high-craft native macOS companion application that adheres strictly to **open-core software design principles**. The root repository is licensed under the permissive **Apache License, Version 2.0**, ensuring that every developer, user, and contributor enjoys complete access to the core engine, runtime physics, rendering pipelines, local intelligence models, and desktop widgets.

The open-core model establishes a clean architectural separation between:
1. **The Free Open-Source Core:** Contains 100% of the standalone desktop companion experience, offline physics, animation decoding, procedural sound synthesis, vision tools, and Aquarium Mode.
2. **Optional Modular Extensions (Animatto Pro):** Standalone commercial or cloud-backed additions (e.g., hosted GPU compute, encrypted multi-device cloud synchronizers, commercial artist packs) that plug into the core via decoupled interfaces without modifying or restricting core source code.

```
+--------------------------------------------------------------------------+
|                     ANIMATTO APPLICATION LAYER                          |
+--------------------------------------------------------------------------+
|  +-------------------------------------+  +---------------------------+  |
|  |       FREE APACHE-2.0 CORE          |  |  OPTIONAL PRO EXTENSIONS  |  |
|  |                                     |  |                           |  |
|  | * Desktop Companion Engine          |  | * Multi-Device Cloud Sync |  |
|  | * Sprite Sequence & APNG Decoders   |  | * Hosted GPU Diffusion   |  |
|  | * Desktop Aquarium Glass Widget     |  | * Pro Artist Bundles      |  |
|  | * Ambient Worlds Particle Systems   |  | * Commercial Support      |  |
|  | * Focus Timer & Behavior Sync       |  |                           |  |
|  | * Procedural Audio Synthesizer      |  |                           |  |
|  | * Privacy-Gated Screen Awareness   |  |                           |  |
|  | * 100% Offline Local Continuity     |  |                           |  |
|  +-------------------------------------+  +---------------------------+  |
|                     |                                   |                |
|                     +-----------------+-----------------+                |
|                                       v                                  |
|                         +---------------------------+                    |
|                         |  EntitlementManager.swift |                    |
|                         |  (Zero Telemetry / Local) |                    |
|                         +---------------------------+                    |
+--------------------------------------------------------------------------+
```

---

## 2. Inviolable Core Principles

To protect users and community trust, the Animatto project operates under four inviolable rules:

### Principle 1: No Feature Regressions or Paywalling
Features delivered in the free open-source core will **never** be gated, degraded, crippled, or transferred into a paid tier. Once a capability is free under Apache-2.0, it remains free in perpetuity.

### Principle 2: Complete Offline Autonomy
The core application requires zero network connections to execute. Companions roam, interact, jump, fall, speak, remember, and swim without sending a single byte over the Internet. An air-gapped Mac running Animatto has the exact same core feature set as an online Mac.

### Principle 3: Zero Telemetry & Privacy Preservation
Animatto contains no third-party tracking SDKs, no behavioral analytics, no advertising beacons, and no unique hardware identifier harvesting. All user character files, memories, and screen context interactions reside locally in `~/Library/Application Support/AnimattoPets` and macOS Keychain.

### Principle 4: Graceful Degradation & Zero Data Loss
Should an optional Pro license expire or fail validation, the user's local companions, imported sprites, custom tags, memories, and desktop placements remain completely untouched and active. Licensing states never purge user data.

---

## 3. Decoupled Entitlement Architecture

All licensing queries flow through a decoupled singleton service: [`Animatto/EntitlementManager.swift`](file:///Users/ojussharma/Desktop/KinetiPet/Animatto/EntitlementManager.swift).

### 3.1 Architectural Segregation
```swift
public enum AppEntitlement: String, CaseIterable, Identifiable, Codable {
    // 100% Free Core Capabilities (Unconditionally granted across all states)
    case coreDesktopPhysics       = "core_desktop_physics"
    case unlimitedCharacters      = "unlimited_characters"
    case personalityMatrix        = "personality_matrix"
    case contextualDialogue       = "contextual_dialogue"
    case characterMemory          = "character_memory"
    case socialEncounters         = "social_encounters"
    case productivitySessions     = "productivity_sessions"
    case workshopStudio           = "workshop_studio"
    
    // Potential Future Cloud/Service Capabilities (Require Active Pro)
    case cloudSyncBackup          = "cloud_sync_backup"
    case hostedLLMStreaming       = "hosted_llm_streaming"
    case creatorMarketplace       = "creator_marketplace"
    
    public var isFreeTier: Bool {
        switch self {
        case .coreDesktopPhysics,
             .unlimitedCharacters,
             .personalityMatrix,
             .contextualDialogue,
             .characterMemory,
             .socialEncounters,
             .productivitySessions,
             .workshopStudio:
            return true
        case .cloudSyncBackup,
             .hostedLLMStreaming,
             .creatorMarketplace:
            return false
        }
    }
}
```

### 3.2 Unconditional Grant Logic
The evaluation method guarantees that free-tier capabilities completely bypass license status checks:
```swift
public func isEntitled(to entitlement: AppEntitlement) -> Bool {
    // Free capabilities are unconditionally granted across all states
    if entitlement.isFreeTier {
        return true
    }
    return status.isValid(asOf: nowProvider())
}
```

---

## 4. Cryptographic License Verification Design

For optional commercial extensions, Animatto uses cryptographic offline key verification rather than invasive phone-home checks.

### 4.1 Key Format & Signature Envelope
Commercial license keys are formatted as human-readable Base32 / alphanumeric tokens:
```
ANIMATTO-PRO-[PAYLOAD]-[SIGNATURE]
```
Where:
- `PAYLOAD`: Base64URL-encoded JSON structure containing:
  - `licId`: Unique license UUID.
  - `tier`: License tier (`pro_annual`, `pro_lifetime`, `team_commercial`).
  - `issuedAt`: Unix timestamp of issuance.
  - `expiresAt`: Optional Unix timestamp of expiration (`nil` for lifetime).
  - `maxSeats`: Permitted concurrent installations (default 3 or 5).
- `SIGNATURE`: Ed25519 digital signature generated by the vendor's private signing key, verified client-side against a pre-bundled public key.

### 4.2 Offline Validation Lifecycle
1. **Air-Gapped Verification:** The client decodes the payload, verifies the Ed25519 cryptographic signature using the embedded public key, and evaluates expiration timestamps against the monotonic system clock.
2. **Keychain Security:** Validated license keys are stored in the user's macOS Keychain under `com.dev.Animatto.licensing` (`kSecClassGenericPassword`), protected by macOS hardware encryption.
3. **Redaction Protocol:** Any logs or UI views displaying license keys must invoke `LicenseRedactor.redact()` to display only the first and last four characters:
   `ANIM-****-****-9XYZ`.

### 4.3 State Machine Transition Matrix
| Current State | Trigger Event | Next State | User Impact |
| :--- | :--- | :--- | :--- |
| `unlicensed` | User inputs valid signed key | `valid` | Pro extensions unlock immediately; core features remain free. |
| `valid` | Expiration date reached | `expired` | Pro extensions revert to free fallbacks; zero data loss. |
| `valid` | Network failure during optional sync | `gracePeriod` | 14-day grace period keeps Pro extensions active. |
| `valid` / `gracePeriod` | User clicks Deactivate | `unlicensed` | Key removed from Keychain; all local data preserved. |
| `valid` | Revocation certificate encountered | `revoked` | Friendly dialog explaining refund/chargeback status. |

---

## 5. Development & Verification Framework

To facilitate rigorous unit testing and continuous integration without requiring live payment sandbox credentials:
1. **Mock Storage Interface:** [`MockLicenseStorage`](file:///Users/ojussharma/Desktop/KinetiPet/Animatto/EntitlementManager.swift) allows headless deterministic testing without touching macOS Keychain.
2. **Dedicated Test Keys:**
   - `ANIM-PRO-TEST-ACTIVE`: Triggers `.valid` lifetime Pro status.
   - `ANIM-PRO-TEST-EXPIRED`: Triggers `.expired` status.
   - `ANIM-PRO-TEST-REVOKED`: Triggers `.revoked` status.
3. **Interactive Debug Tester:** In `#if DEBUG` builds, [`FreeVsPremiumSheet`](file:///Users/ojussharma/Desktop/KinetiPet/Animatto/FreeVsPremiumSheet.swift) exposes instant mock status switcher buttons for manual QA.

---

## 6. Guidelines for Contributors

1. **New Core Features:** Any feature that operates purely on-device using local CPU/GPU compute, local files, or macOS APIs **must** be contributed directly to the free open-source core under Apache-2.0.
2. **PR Checks:** Pull requests that introduce network gates, user tracking, or arbitrary feature restrictions on local capabilities will be rejected.
3. **No Commercial Gating in Core Repos:** No commercial checkout SDKs (Stripe, LemonSqueezy, Gumroad) may be compiled into the core open-source binary.

# Animatto — Free vs. Premium Boundaries & Feature Specifications

**Policy:** [`MONETIZATION_DECISION.md`](MONETIZATION_DECISION.md) is the current decision. Features already in this Apache-2.0 tree are not for sale. Cloud sync, a hosted LLM, and a marketplace are unimplemented ideas, not products you can buy.

**Document Version:** 1.0.0  
**Target Release:** Animatto v1.2.0+  
**Classification:** Product Specification & Tier Definition

---

## 1. Overview of the Tier Model

Animatto maintains an unwavering commitment to open-source software. All core companion capabilities are **100% free forever** under the Apache License, Version 2.0. Optional premium capabilities (Animatto Pro) exist solely to fund recurring external server infrastructure (cloud compute, multi-device database hosting) and professional artist collaborations without compromising the free desktop experience.

---

## 2. The Eight Free Core Pillars (100% Apache-2.0)

Every user downloading Animatto has permanent, unrestricted access to these eight pillars:

```
+---------------------------------------------------------------------------------------------------+
|                                 THE EIGHT FREE CORE PILLARS                                      |
+-----------------------------+-----------------------------+---------------------------------------+
| 1. Companion Physics        | 2. Asset & Shimeji Import   | 3. Desktop Aquarium Widget            |
| * Roaming, falling, jumping | * Unlimited characters      | * 4 original species (120 frames)     |
| * Multi-display traversal   | * Custom XML manifests      | * 3D buoyancy & schooling physics     |
| * Menu bar upside-down walk | * APNG, GIF, spritesheets   | * Borderless glass widget frame       |
+-----------------------------+-----------------------------+---------------------------------------+
| 4. Ambient Worlds Engine    | 5. Focus & Productivity     | 6. Procedural Audio Engine            |
| * Rain, Snow, Fireflies     | * Pomodoro & sprint timers  | * Footstep synthesis & cat purring    |
| * Dynamic weather sync      | * Companion state sync      | * Aquarium aerator & water caustics   |
| * 60fps particle simulation | * Distraction shields       | * Native macOS audio ducking          |
+-----------------------------+-----------------------------+---------------------------------------+
| 7. Privacy Screen Awareness | 8. Offline Self-Containment                                         |
| * On-device Apple Vision    | * Zero telemetry & tracking                                         |
| * 10-trait personality tree | * No mandatory cloud account                                        |
| * Speech bubbles & dialogue | * 100% operational on air-gapped systems                              |
+-----------------------------+---------------------------------------------------------------------+
```

### Pillar 1: Companion Locomotion & Physics Simulation
- **Capabilities:** Autonomous desktop wandering, climbing window frames, realistic falling acceleration with terminal velocity clamping, edge dropping, floor collision detection, drag-and-drop interruption, and upside-down menu bar locomotion.
- **Performance:** Monotonic tick loop executing at up to 60 ticks/second with irregular delta time clamping, consuming less than 1.5% CPU during active roaming and 0.0% during sleep states.
- **Licensing Rationale:** Foundational companion mechanics; must never be restricted.

### Pillar 2: Multi-Companion Roster & Shimeji Import Engine
- **Capabilities:** Unlimited simultaneous desktop companions, zero artificial slot caps, support for custom sprite sheets, animated GIFs, multi-frame APNGs, and custom XML companion manifests.
- **Storage:** Local user library stored safely in `~/Library/Application Support/AnimattoPets` with directory isolation and path-traversal sanitization.
- **Licensing Rationale:** User-generated and community-imported artwork belongs entirely to the user. Artificial limits on local artwork are unacceptable.

### Pillar 3: Desktop Aquarium Widget & Starter Aquatic Species
- **Capabilities:** A dedicated desktop aquarium widget floating seamlessly on the macOS desktop (or pinned floating). Includes four original pixel-art species (Finny the Golden Sunfin, Pip the Spotted Pygmy Puffer, Glow the Neon Ghost Tetra, Barnaby the Mossy Hermit Crab) spanning 120 transparent animation frames across 6 behavioral states.
- **Physics:** 3D aquatic buoyancy, drag, turn banking, soft boundary repulsion, benthic negative buoyancy, schooling/flocking algorithms, sinking food pellet dissolution, and refractive glass-tap shockwaves.
- **Licensing Rationale:** Desktop ambience is a core feature of Animatto, fully self-contained using local CoreGraphics and CoreAnimation rendering.

### Pillar 4: Ambient Worlds Particle Engine
- **Capabilities:** High-performance procedural desktop atmospheres: Rain, Snow, Fireflies, Starfall, and Autumn Leaves. Dynamic live weather synchronization using open Open-Meteo APIs (zero API keys required) with temperature and condition mapping.
- **Rendering:** Metal-accelerated and CoreGraphics canvases with low-power mode automatic scaling (20Hz / 30Hz / 60Hz).
- **Licensing Rationale:** Lightweight on-device environmental enrichment; zero recurring operational costs.

### Pillar 5: Productivity Focus Timer & Behavior Synchronizer
- **Capabilities:** Full Pomodoro timer (25/5), short sprints (15m), and deep focus intervals (50m). Roaming companions dynamically react to focus phases—studying quietly during focus sessions and playing enthusiastically during breaks.
- **Integrations:** Native macOS notifications, menu bar countdown timer, and distraction shield mode.
- **Licensing Rationale:** Core utility value supporting user focus and mindfulness without cloud dependency.

### Pillar 6: Procedural Audio Engine
- **Capabilities:** Real-time procedural audio synthesis for companion footsteps (soft paws, pitter-patter, heavy steps), feline purring acoustics, aquatic aerator air bubbles, water ripples, and quiet UI micro-interactions.
- **Safety:** Automatic multi-companion rate-limiting, spatial audio ducking, master mute, and zero audio allocation during system sleep.
- **Licensing Rationale:** Audio is synthesized mathematically on-device using AVFoundation and bundled public domain/permissive audio assets.

### Pillar 7: Privacy-Gated Screen Awareness & Local Personality
- **Capabilities:** On-device Apple Vision context awareness that observes active permitted application categories (code editor, browser, media player) without logging keystrokes or private content. Companions generate contextual speech bubbles and internal thoughts shaped by a 10-trait personality matrix and local continuity memory.
- **Security:** Strict opt-in consent gate, local memory pruning, and zero outbound transmission.
- **Licensing Rationale:** Privacy is a fundamental human right. AI personality features executed locally on Apple Silicon must remain private and free.

### Pillar 8: Offline Self-Containment & Zero Telemetry
- **Capabilities:** Animatto functions with 100% fidelity on an air-gapped machine. No account creation is required, no phone-home telemetry pings are sent, and no license key checks occur for core features.
- **Licensing Rationale:** Core open-source software must be resilient, reliable, and completely respectful of user autonomy.

---

## 3. Candidate Premium Additions (Animatto Pro)

The following capabilities represent candidate premium additions designed to fund external infrastructure and commissioned artists:

| Capability | Target User Value | Operational Cost Rationale | Technical Boundary | Recommended Licensing Model |
| :--- | :--- | :--- | :--- | :--- |
| **Pro Artist Companion Packs** | Handcrafted 4K sprite animations, exclusive commissioned companion species, unique sound effects, and bespoke behaviors. | **High upfront artist commissioning fees.** Direct revenue-share with freelance digital pixel artists and animators. | Packaged as signed `.animattopack` bundles verified by Ed25519 signature in `EntitlementManager`. | One-time purchase / Pro bundle inclusion. |
| **Multi-Device Encrypted Cloud Sync** | Seamless companion roaming across multiple Macs (e.g., MacBook and iMac), syncing character memories, personality growth, and focus statistics. | **Recurring database & bandwidth costs.** Requires managed, end-to-end encrypted cloud storage clusters (e.g., CloudKit / AWS DynamoDB). | Separate sync adapter client; local JSON storage remains 100% free on every machine. | Pro Annual / Lifetime license. |
| **Hosted High-Speed AI Diffusion** | High-speed cloud generation of custom companions using large diffusion models (SDXL, Flux-Pro) without local GPU strain. | **Direct GPU compute costs per generation ($0.02 - $0.05 / image).** API fees charged by model hosting infrastructure. | Plug-in provider in `AIImageGeneratorProvider.swift`; local free Pollinations provider remains unconditionally free. | Pro token allowance or quota. |
| **Exclusive Ambient Biomes** | Advanced aquarium biomes (Deep Abyss, Bioluminescent Trench, Kelp Forest) and animated dynamic backgrounds. | **3D artist modeling & audio soundscape licensing.** Direct commissioning costs for environmental artists. | Registered dynamically in `AtmospherePackService`. Standard 5 themes remain 100% free. | Pro Bundle inclusion. |
| **Commercial Team License & Priority Support** | Permitted commercial distribution across company fleets, customized corporate mascot packs, and SLA priority support. | **Direct developer time and support overhead.** Enterprise security reviews and centralized deployment guides. | Signed multi-seat license key with organizational metadata and volume MDM configuration profile. | Commercial Organization Seat License. |

---

## 4. Architectural Guarantee: The Free Core Firewall

To ensure that the introduction of Animatto Pro never erodes the free open-source core:

1. **Compilation Guard:** The core open-source binary distributed on GitHub compiles directly with all 8 core pillars active out of the box, without requiring any license files, environment variables, or private API keys.
2. **Feature Isolation:** Premium extensions must always be architected as optional modular add-ons that communicate through published interfaces (`EntitlementManager`, `AtmospherePackService`, `AIImageGeneratorProvider`).
3. **Grace Period Guarantee:** If an active Pro license encounters a network interruption or validation issue during cloud sync, the system defaults to a resilient 14-day grace period where all features remain completely accessible.
4. **Permanent Offline Fallback:** If a license expires, the application gracefully steps down to the Free Core tier with zero data deletion, zero companion eviction, and zero nagging intrusive popups.

# Animatto — Stage 2: Cat Animation Architecture Specification

**Status:** Completed Architecture Design (Stage 2)  
**Target Implementation:** Stage 3  
**Visual Reference Master:** `Animatto/DefaultCompanions/animatto_cat.png` (1024×1024 RGBA sRGB master artwork)  
**Target Platform:** macOS 14.6+ (Sonoma) and macOS 15+ (Sequoia) on Apple Silicon & Intel

---

## 1. Executive Summary & Existing System Audit

Animatto currently supports companion rendering via [MediaRenderers.swift](file:///Users/ojussharma/Desktop/KinetiPet/Animatto/MediaRenderers.swift) and [PetEngine.swift](file:///Users/ojussharma/Desktop/KinetiPet/Animatto/PetEngine.swift). In the current baseline:
1. **Asset Loading:** A companion is initialized with a single static image (`.png`, `.jpg`, `.webp`) or animated video/GIF (`.gif`, `.mp4`, `.mov`).
2. **Current State Machine:** `PetInstance.PetState` exposes three coarse states: `.walking`, `.idle`, and `.sleeping`.
3. **Motion Simulation:** Walking is visually approximated by horizontal translation, a directional scale flip (`scaleEffect(x: walkDirectionRight ? 1 : -1)`), and a vertical sinusoidal bob (`walkBobOffset = CGFloat(abs(sin(walkTime)) * bobHeight)`).
4. **Caching:** `CompanionImageCache` provides an `NSCache<NSURL, NSImage>` capped at 64 entries and 128 MB total cost limit, storing single static images or multi-frame NSImages.

While lightweight, this system does not express quadruped feline kinetics: paw articulation, spine flexibility, crouch preparation, leap trajectories, aerial descent postures, landing recoil, curled loaf sleeping, or grooming.

This specification establishes the complete architecture for Animatto's official built-in animated cat companion across **9 discrete behavioral states**, complete with memory-conscious shared frame caching, physics coupling, and an asset delivery pipeline.

---

## 2. Animation States & State Machine Design

The Cat Animation System defines **9 core states** structured into continuous loops and transitional one-shot actions:

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> Walk: Behavior Engine Tick / Move
    Idle --> Sit: High Laziness / Low Energy
    Idle --> Sleep: CharacterAction.sleeping
    Idle --> Grooming: Autonomous Flair / Calm Mood
    Idle --> Jump: Obstacle / Playful Leap / User Throw

    Walk --> Idle: Stop Movement
    Walk --> Run: High Energy / Exploring Mode
    Walk --> Jump: Window Ledge Ascent
    Walk --> Fall: Walked off Window Ledge

    Run --> Walk: Deceleration
    Run --> Idle: Abrupt Stop
    Run --> Jump: Running Leap
    Run --> Fall: Dropped Platform

    Jump --> Fall: Trajectory Apex (Vy <= 0)
    
    Fall --> Land: Collision with Floor / Window Top
    
    Land --> Idle: Recoil Complete (Stationary)
    Land --> Walk: Recoil Complete (Moving)

    Sit --> Idle: Distraction / Alert
    Sit --> Grooming: Grooming while seated
    Sit --> Sleep: Curl up into loaf

    Sleep --> Idle: Wakeup Event / Music Track Change

    Grooming --> Idle: Cycle Complete
    Grooming --> Sit: Cycle Complete (Seated)
```

### Detailed State Specifications

| State | Type | Frame Count | Target FPS | Frame Duration | Loop Policy | Audio Coupling |
|---|---|:---:|:---:|:---:|---|---|
| **`idle`** | Cyclic Loop | 6 frames | 10 fps | 100 ms | Infinite loop until state change | Subtle breathing / silence |
| **`walk`** | Cyclic Loop | 8 frames | 12 fps | 83 ms | Aligns with `walkSpeed` | Footstep triggers on frames 2 & 6 |
| **`run`** | Cyclic Loop | 6 frames | 18 fps | 55 ms | Aligns with high `walkSpeed` | Rapid footstep triggers on frames 1 & 4 |
| **`jump`** | Transitional | 4 frames | 15 fps | 66 ms | Play once; holds frame 3 at peak | Soft leap push-off whoosh |
| **`fall`** | Cyclic Loop | 4 frames | 12 fps | 83 ms | Loops while `isFalling == true` | Wind flutter / fall dialogue |
| **`land`** | Transitional | 3 frames | 15 fps | 66 ms | Play once; auto-recovers to idle/walk | Companion landing voice (`.curious`) |
| **`sit`** | Hold + Sub-loop | 4 frames | 8 fps | 125 ms | Plays entry, then loops subtle tail wag | Contentment purr / chime |
| **`sleep`** | Cyclic Loop | 4 frames | 6 fps | 166 ms | Continuous until wake trigger | Synchronized with `AudioEngine` sleep purr |
| **`grooming`** | One-shot Loop | 6 frames | 10 fps | 100 ms | Plays 1–3 full repetitions, then returns | Soft grooming rustle |

#### State Descriptions & Key Poses
1. **`idle` (Neutral Awareness):**
   - Quadruped standing posture consistent with `animatto_cat.png`.
   - Subtle vertical torso expansion on inhalation; ears prick up slightly; tail tip curves gently side to side.
2. **`walk` (Lateral Four-Beat Trot):**
   - Natural quadruped walk cycle: Left-Hind $\rightarrow$ Left-Fore $\rightarrow$ Right-Hind $\rightarrow$ Right-Fore.
   - Paws plant firmly on ground plane ($Y=0$ anchor). Head counter-balances step cadence.
3. **`run` (Rotary Gallop / Bound):**
   - Spine compresses and extends dynamically.
   - Extended suspension phase where all four paws leave ground plane.
4. **`jump` (Upward Spring):**
   - Frame 0: Crouch compression and hind leg load.
   - Frame 1: Explosive extension upward.
   - Frame 2: Ascending arc, paws tucked forward.
   - Frame 3: Apex posture (front paws reaching for ledge).
5. **`fall` (Aerial Freefall):**
   - Paws spread outward for drag / righting reflex (cat righting reflex).
   - Tail trailing upward; ears pressed slightly back.
6. **`land` (Impact Dissipation):**
   - Frame 0: Paws contact floor; shoulders compress.
   - Frame 1: Full deep compression absorbing kinetic energy.
   - Frame 2: Spring-back recovery to neutral standing height.
7. **`sit` (Alert Rest):**
   - Hind legs folded beside body; forelegs vertical and straight.
   - Tail wrapped smoothly around front paws; head rotates to look toward user cursor.
8. **`sleep` (Curled Loaf):**
   - Body curled in a soft sphere or bread loaf; paws tucked completely underneath.
   - Eyes closed in happy crescents; slow, deep breathing cycle with Zzz ambient particles.
9. **`grooming` (Facial Wash & Paw Lick):**
   - Forepaw raised to mouth, licked twice, and rubbed over ear and whiskers.
   - Eyes close comfortably during the sweep; tail remains relaxed.

---

## 3. Asset Specifications, Directory Structure & Licensing

### Directory Organization

All sprite assets for the official animated cat will reside in `Animatto/DefaultCompanions/Cat/`:

```text
Animatto/DefaultCompanions/Cat/
├── manifest.json                  # Canonical animation metadata and timing
├── LICENSE.txt                    # Original permissive license (MIT / CC0)
├── ATTRIBUTION.md                 # Authorship and copyright statement
├── idle/
│   ├── idle_00.png
│   ├── idle_01.png
│   └── ... (idle_05.png)
├── walk/
│   ├── walk_00.png
│   └── ... (walk_07.png)
├── run/
│   ├── run_00.png
│   └── ... (run_05.png)
├── jump/
│   ├── jump_00.png
│   └── ... (jump_03.png)
├── fall/
│   ├── fall_00.png
│   └── ... (fall_03.png)
├── land/
│   ├── land_00.png
│   └── ... (land_02.png)
├── sit/
│   ├── sit_00.png
│   └── ... (sit_03.png)
├── sleep/
│   ├── sleep_00.png
│   └── ... (sleep_03.png)
└── grooming/
    ├── grooming_00.png
    └── ... (grooming_05.png)
```

### Technical Asset Standards

1. **Resolution & Canvas:**
   - **Source Resolution:** 256×256 px square canvas per frame.
   - **Render Target:** Downscaled at runtime to companion display size (default: 80×80 pt to 128×128 pt on Retina @2x/@3x displays).
   - **Ground Baseline:** Bottom edge of paws grounded at $Y = 32$ px above canvas bottom across all grounded frames (`idle`, `walk`, `run`, `sit`, `sleep`, `grooming`).
2. **Color & Alpha:**
   - **Format:** 32-bit PNG (PNG-24 with 8-bit straight alpha channel).
   - **Color Profile:** sRGB IEC61966-2.1 matching `animatto_cat.png`.
   - **Edge Treatment:** Clean anti-aliased borders; no premultiplied dark halo artifacts on transparent backgrounds.
3. **Directionality:**
   - **Canonical Facing:** All source sprites are rendered facing **Right** (+X axis).
   - **Left-Facing Inversion:** Performed at render time by applying horizontal scale transform (`scaleEffect(x: -1, y: 1)` in SwiftUI / `CATransform3DMakeScale(-1, 1, 1)` in Core Animation). No duplicate inverted files are stored.
4. **Manifest Schema (`manifest.json`):**
   ```json
   {
     "characterId": "animatto_official_cat",
     "version": "1.0.0",
     "name": "Animatto Cat",
     "masterArtwork": "animatto_cat.png",
     "canvasSize": { "width": 256, "height": 256 },
     "groundBaselineY": 32,
     "states": {
       "idle": {
         "folder": "idle",
         "frameCount": 6,
         "frameDurationMs": 100,
         "loop": true
       },
       "walk": {
         "folder": "walk",
         "frameCount": 8,
         "frameDurationMs": 83,
         "loop": true,
         "footstepFrames": [2, 6]
       },
       "run": {
         "folder": "run",
         "frameCount": 6,
         "frameDurationMs": 55,
         "loop": true,
         "footstepFrames": [1, 4]
       },
       "jump": {
         "folder": "jump",
         "frameCount": 4,
         "frameDurationMs": 66,
         "loop": false
       },
       "fall": {
         "folder": "fall",
         "frameCount": 4,
         "frameDurationMs": 83,
         "loop": true
       },
       "land": {
         "folder": "land",
         "frameCount": 3,
         "frameDurationMs": 66,
         "loop": false,
         "nextState": "idle"
       },
       "sit": {
         "folder": "sit",
         "frameCount": 4,
         "frameDurationMs": 125,
         "loop": true
       },
       "sleep": {
         "folder": "sleep",
         "frameCount": 4,
         "frameDurationMs": 166,
         "loop": true
       },
       "grooming": {
         "folder": "grooming",
         "frameCount": 6,
         "frameDurationMs": 100,
         "loop": false,
         "nextState": "idle"
       }
     }
   }
   ```
5. **Licensing & IP Hygiene:**
   - 100% original artwork directly derivative of `animatto_cat.png`.
   - Free of third-party IP, trademarked visual motifs, or unlicensed spritesheets.
   - Distributed under the project's MIT License with CC0 dedication for artistic assets.

---

## 4. Shared Decoded-Frame Cache Architecture

### The Problem with Naive Animation Loading
When running multiple instances (e.g., 5 companions on screen), a naive frame loader either:
1. Reloads and decodes PNG data on every tick $\rightarrow$ excessive CPU usage (15%+ CPU spikes) and battery drain.
2. Allocates separate `NSImage` arrays per companion $\rightarrow$ 5 instances $\times$ 45 frames $\times$ 1 MB decoded bitmaps = 225 MB redundant RAM consumption.

### The Unified Decoded Frame Cache (`AnimationAssetCache`)

```text
┌────────────────────────────────────────────────────────┐
│               AnimationAssetCache.shared               │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Manifest Cache: [CharacterID : AnimationManifest]│  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Decoded Texture Buffer:                         │  │
│  │  Key: "animatto_official_cat/walk/02"             │  │
│  │  Value: CGImage (256x256 RGBA @ 262 KB)          │  │
│  │  Total Cache Footprint: 45 frames ≈ 11.8 MB      │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
          ▲                       ▲                    ▲
          │                       │                    │
┌──────────────────┐    ┌──────────────────┐  ┌──────────────────┐
│ PetInstance #1   │    │ PetInstance #2   │  │ PetInstance #3   │
│ (Frame Index: 2) │    │ (Frame Index: 5) │  │ (Frame Index: 2) │
└──────────────────┘    └──────────────────┘  └──────────────────┘
```

### Key Technical Mechanisms

1. **Singleton Frame Pool:**
   - Implemented as a thread-safe actor or locked class: `AnimationAssetCache`.
   - Stores pre-decoded `CGImage` instances keyed by `AnimationCacheKey(characterId, state, frameIndex)`.
2. **Pre-Decoded Surface Bitmaps:**
   - Decodes compressed PNG data upfront on a background queue (`DispatchQueue.global(qos: .userInitiated)`) using `CGImageSourceCreateWithURL` and `CGImageSourceCreateImageAtIndex` with `kCGImageSourceShouldCacheImmediately: true`.
   - Eliminates JIT decompression stalls during display presentation.
3. **Zero-Copy Multi-Instance Sharing:**
   - All active instances of the cat companion reference identical memory buffers in the shared cache.
   - Total memory cost for 1, 5, or 20 active cats remains identical: **~11.8 MB** (45 frames $\times$ 256 $\times$ 256 $\times$ 4 bytes).
4. **Memory Pressure Eviction:**
   - Subscribes to `NSApplication.didReceiveMemoryWarningNotification`.
   - Inactive animation states (e.g. `grooming` when no companion is grooming) are dropped from cache first; active states (`idle`, `walk`) are pinned.

---

## 5. Integration with Physics, Behavior & Audio Systems

### 5.1 Physics Simulator Integration (`CompanionPhysicsSimulator`)

The existing physics tick in `PetInstance` runs at ~33 Hz (0.03s timer). Animation playback advances on frame delta time, mapping directly to physics parameters:

```swift
// Target Stage 3 mapping in PetInstance.physicsTick()
if isFalling {
    if yVelocity > 1.0 {
        animationState = .jump // Apex/Ascent phase
    } else {
        animationState = .fall // Terminal descent
    }
} else if wasFallingLastTick && !isFalling {
    animationState = .land // Impact absorption (one-shot)
} else if isMovingHorizontally {
    animationState = (currentSpeed > 3.0) ? .run : .walk
} else if isCurledSleeping {
    animationState = .sleep
} else if isSeated {
    animationState = .sit
} else {
    animationState = .idle
}
```

### 5.2 Window Platform & Ledge Awareness (`WindowPlatformTracker`)
- **Walking on Ledge:** Uses `.walk` cycle while $X$ coordinates remain within `platform.minX ... platform.maxX`.
- **Stepping Off Ledge:** When stepping beyond window borders:
  1. `currentPlatform` is dropped to `nil`.
  2. `isFalling` triggers immediately $\rightarrow$ animation transitions smoothly from `.walk` $\rightarrow$ `.fall`.
  3. On contact with lower window or screen floor $\rightarrow$ animation transitions `.fall` $\rightarrow$ `.land` $\rightarrow$ `.idle` or `.walk`.

### 5.3 Behavior Engine Integration (`BehaviorEngine`)
- **`CharacterAction.walking`:** Transitions to `.walk` (or `.run` if personality `energy > 0.8`).
- **`CharacterAction.exploring`:** Triggers high-speed sprint (`.run`) with directional changes.
- **`CharacterAction.idle`:** Weighted selection between:
  - `.idle` (70% probability)
  - `.sit` (20% probability, increased by `laziness`)
  - `.grooming` (10% probability, increased by calm ambience)
- **`CharacterAction.sleeping`:** Smooth sequence: standing $\rightarrow$ `.sit` (transition) $\rightarrow$ `.sleep` (loaf loop).

### 5.4 Audio & Footstep Synchronization (`AudioEngine`)
- **Current Approach:** Footsteps play via periodic timer check (`walkTime / Double.pi`).
- **Target Animation-Driven Approach:** The animation player inspects the active frame index. When entering a frame marked in `manifest.json` under `footstepFrames` (e.g. frames 2 and 6), `AudioEngine.shared.playFootstep()` is triggered directly.
- **Sleep Purrs:** Synchronized directly with the chest expansion phase of the `.sleep` frame cycle.

---

## 6. Stage 3 Implementation Plan & Asset Checklist

### Stage 3 Implementation Milestones

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Stage 3 Roadmap Phases                          │
├───────────────────────┬────────────────────────────────────────────────┤
│ Phase 3.1: Asset      │ Produce and commit 45 original PNG frames in   │
│ Production            │ Animatto/DefaultCompanions/Cat/<state>/        │
├───────────────────────┼────────────────────────────────────────────────┤
│ Phase 3.2: Cache &    │ Implement AnimationAssetCache and              │
│ Player Architecture   │ SpriteSequencePlayer component in Swift        │
├───────────────────────┼────────────────────────────────────────────────┤
│ Phase 3.3: PetEngine  │ Expand PetState and couple frame playback to   │
│ Integration           │ physics tick, WindowPlatformTracker & gravity  │
├───────────────────────┼────────────────────────────────────────────────┤
│ Phase 3.4: Audio &    │ Couple footsteps and sleep purrs to specific   │
│ Behavior Sync         │ animation keyframes and personality actions    │
├───────────────────────┼────────────────────────────────────────────────┤
│ Phase 3.5: Benchmark  │ Measure tick rate, CPU, and memory across      │
│ & Verification        │ 1–10 animated companions; update docs          │
└───────────────────────┴────────────────────────────────────────────────┘
```

### Stage 3 Asset Checklist

- [ ] **`idle` State (6 frames):**
  - [ ] `idle_00.png` through `idle_05.png`
  - [ ] Seamless loop verification
  - [ ] Ground plane alignment ($Y = 32$ px)
- [ ] **`walk` State (8 frames):**
  - [ ] `walk_00.png` through `walk_07.png`
  - [ ] Paw contact alignment on frames 2 & 6
  - [ ] Seamless trot cycle loop
- [ ] **`run` State (6 frames):**
  - [ ] `run_00.png` through `run_05.png`
  - [ ] Extended spine stretch & compression
  - [ ] Paw contact alignment on frames 1 & 4
- [ ] **`jump` State (4 frames):**
  - [ ] `jump_00.png` (crouch prep)
  - [ ] `jump_01.png` (spring extension)
  - [ ] `jump_02.png` (ascending arc)
  - [ ] `jump_03.png` (apex reach)
- [ ] **`fall` State (4 frames):**
  - [ ] `fall_00.png` through `fall_03.png`
  - [ ] Righting reflex spread-paw posture
  - [ ] Looping aerodynamic flutter
- [ ] **`land` State (3 frames):**
  - [ ] `land_00.png` (initial paw contact)
  - [ ] `land_01.png` (full crouch compression)
  - [ ] `land_02.png` (recoil recovery)
- [ ] **`sit` State (4 frames):**
  - [ ] `sit_00.png` through `sit_03.png`
  - [ ] Upright seated posture, tail wrap
- [ ] **`sleep` State (4 frames):**
  - [ ] `sleep_00.png` through `sleep_03.png`
  - [ ] Curled loaf, rhythmic chest rise and fall
- [ ] **`grooming` State (6 frames):**
  - [ ] `grooming_00.png` through `grooming_05.png`
  - [ ] Paw lick and ear wash sequence
- [ ] **Metadata & Licensing:**
  - [ ] `manifest.json` configured with frame timings and metadata
  - [ ] `LICENSE.txt` & `ATTRIBUTION.md` committed with CC0 / MIT terms

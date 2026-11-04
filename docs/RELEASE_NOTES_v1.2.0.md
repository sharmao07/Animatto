# Animatto v1.2.0 (Public Beta) Release Notes

**Release Date:** November 4, 2026  
**Build:** 1.2.0 (Build 3)  
**Distribution File:** `Animatto-v1.2.0.dmg` (12.0 MB / 12,628,992 bytes)  
**SHA-256 Checksum:** `0c5df80d8ea7f5bc89b1d0227c578f056f2ae70222ab3fcf5bdc0f489ad17809`  
**Compatibility:** macOS 14.6 (Sonoma) and macOS 15.0+ (Sequoia) — Universal Binary (Apple Silicon M1/M2/M3/M4 & Intel x86_64)

---

## What's New in Animatto v1.2.0

### 🐠 In-Place Aquarium Mode Transformation
- **Widget Transformation:** Turning on Aquarium Mode transforms your existing desktop companion widgets directly into living, glass aquariums. No separate or floating tank window is created.
- **Multiple Independent Tanks:** Concurrently running companion widgets transform into independent aquariums with distinct aquatic ecosystems, plants, bubble streams, and swimming fish.
- **Interactive Marine Life:**
  - **Tap Glass:** Clicking inside any aquarium widget sends real-time water shockwaves, rippling the surface and scattering nearby fish.
  - **Single-Click Feeding:** Drop sinking food pellets that attract hungry fish and dissolve naturally.
  - **Species Included:** Finny (Golden Sunfin), Pip (Spotted Pygmy Puffer), Glow (Neon Ghost Tetra), and Barnaby (Pacific Hermit Crab).
- **Restoration:** Turning off Aquarium Mode cleanly restores your original desktop companions with their exact animations, physics, and desktop positions.
- **Battery Optimization:** Central companion physics timer pauses while transformed, eliminating redundant 30 Hz thread wakeups and conserving battery power.

### 🎨 Native macOS Interface & Liquid Glass Vibrancy
- Redesigned with Apple's 8pt spatial layout grid and native SF Pro typography.
- Neutral `NSVisualEffectView` under-window vibrancy avoids muddy window background bleed.
- 6 accent color palettes (Sunset Coral, Ocean Cyan, Emerald Leaf, Royal Amethyst, Honey Amber, Electric Sakura) with dynamic Dark and Light Mode adaptation.
- Full state synchronization across Main App Studio, Menu Bar popover, and Desktop Widgets.

### 🌧️ Ambient Worlds & Live Weather Sync
- 6 procedural particle environments: Rain, Snow, Sakura Blossom, Fireflies, Starlight, and Autumn Leaves.
- Dynamic weather sync with Open-Meteo API covering global locations and 11 localized languages.
- Interactive ambient minigame with collectible floating orbs, real-time combos, and persistent high scores.

### 🪄 Creator Studio & Magic Eraser
- Import any GIF, PNG, or Shimeji sprite pack from your computer.
- Automatic sprite slicing and sequence frame detection.
- Magic Eraser powered by on-device Apple Vision subject segmentation (`VNGenerateForegroundInstanceMaskRequest`) for instant 1-click background removal without cloud uploads.
- Free AI sprite generation powered by Pollinations.ai Flux.

### ⏱️ Productivity & Pomodoro Timer
- Customizable Focus (25m), Short Break (5m), and Long Break (15m) sessions.
- Interactive companion focus behavior: companions rest or study quietly during focus sessions to minimize desktop distractions.
- System notifications with sound chimes and sleep/wake continuity.

### 🔒 Privacy-First Architecture & Cryptographic Licensing
- **100% Offline-First:** Zero background tracking, telemetry, or analytics. Your desktop remains private.
- **Ed25519 Cryptographic Signatures:** High-assurance digital signature verification with rotated official public keys.
- **Hardware-Bound Device Limits:** Offline activation limits (up to 5 devices per license) with privacy-preserving SHA-256 hardware identifier hashes.

---

## Installation & First-Launch Guide

1. **Download:** Download `Animatto-v1.2.0.dmg` from the GitHub Releases page.
2. **Mount & Copy:** Open the DMG and drag the `Animatto` icon into the `Applications` folder shortcut.
3. **First-Launch Gatekeeper Authorization:**
   Because this beta candidate is distributed outside the Mac App Store:
   - In Finder, open your **Applications** folder.
   - **Right-click (Control-click)** on `Animatto.app` and choose **Open**.
   - Click **Open** on the confirmation dialog.
   *(You only need to do this once on first launch; subsequent launches open normally from Spotlight or Launchpad).*

---

## Known Limitations

- **Gatekeeper First-Launch:** Requires right-click -> Open on first launch until the maintainer's paid Apple Developer ID notarization ticket is stapled.
- **Sandbox Mode:** Payment processing is configured in sandbox evaluation mode during beta.
- **Discord Rich Presence:** Companion Discord activity requires a running local Discord desktop client.

---

## Feedback & Bug Reports

We welcome community feedback and bug reports:
- **Issue Tracker:** [https://github.com/sharmao07/Animatto/issues](https://github.com/sharmao07/Animatto/issues)
- **Discussions:** [https://github.com/sharmao07/Animatto/discussions](https://github.com/sharmao07/Animatto/discussions)
- **Security Inquiries:** [https://github.com/sharmao07/Animatto/security/advisories/new](https://github.com/sharmao07/Animatto/security/advisories/new)

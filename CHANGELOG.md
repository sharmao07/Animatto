# Changelog

All notable changes to **Animatto** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-28

### Added
- **Project Rebrand:** Rebranded application from KinetiPet to **Animatto** across all Swift modules, build targets, UI views, and distribution assets.
- **Physics Simulation Engine:**
  - Autonomous roaming across macOS desktop spaces using transparent `.screenSaver` level `NSPanel` windows.
  - Surface collision detection allowing companions to stand and walk on top of active application windows.
  - Natural walking hops with dynamic velocity scaling, gravity acceleration, and edge bouncing.
  - Interactive dragging and flinging with cursor release momentum.
  - Menu Bar Walking mode with inverted gravity along the macOS menu bar.
- **Creative AI Workshop:**
  - **Magic Eraser (Offline Local AI):** Background removal for both still images and multi-frame animated GIFs using Apple's on-device `VNGenerateForegroundInstanceMaskRequest`.
  - **AI Sprite Generator:** Cloud-based text-to-sprite anime generation using `flux-anime`.
  - **Shimeji DB Search:** Online community character library browser and downloader.
- **Menu Bar Dashboard:**
  - Sleek `MenuBarExtra` popover dashboard with live toggles for physics pausing, audio muting, upside-down menu bar mode, and companion swapping.
- **System Integrations:**
  - Native Discord Rich Presence via local Unix Domain Socket (`discord-ipc-0`) without external third-party SDK dependencies.
  - Music playback status observer reacting to Spotify and Apple Music playback via AppleScript.
- **Safe Data & Preference Migration:**
  - Automatic, idempotent migration from legacy folders (`AnimotionPets`, `KinetiPet`) into `~/Library/Application Support/AnimattoPets`.
  - Idempotent migration of user preferences from `com.dev.KinetiPet` to `com.dev.Animatto`.
- **Open-Source Community Health:**
  - Added [Code of Conduct](CODE_OF_CONDUCT.md), [Security Policy](SECURITY.md), [Contributing Guidelines](CONTRIBUTING.md), and GitHub issue/PR templates.

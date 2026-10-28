<div align="center">

# 🐾 Animatto

**Anime-inspired interactive desktop companions for your Mac.**  
*Autonomous roaming, surface physics, window collision, on-device AI Magic Eraser, and menu bar walking.*

[![Build Status](https://github.com/sharmao07/Animatto/actions/workflows/macos-build.yml/badge.svg)](https://github.com/sharmao07/Animatto/actions/workflows/macos-build.yml)
[![Release](https://img.shields.io/github/v/release/sharmao07/Animatto?style=flat&color=3B82F6&label=Release)](https://github.com/sharmao07/Animatto/releases)
[![macOS](https://img.shields.io/badge/Platform-macOS%2014.6%2B-black.svg?style=flat&logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-FA7343.svg?style=flat&logo=swift)](https://swift.org/)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-8A2BE2.svg?style=flat)](https://github.com/sharmao07/Animatto)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/sharmao07/Animatto?style=flat&color=yellow)](https://github.com/sharmao07/Animatto/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/sharmao07/Animatto?style=flat&color=brightgreen)](https://github.com/sharmao07/Animatto/issues)

<p align="center">
  <a href="#-installation"><b>Download DMG</b></a> •
  <a href="#-key-features"><b>Key Features</b></a> •
  <a href="#-creative-ai-workshop"><b>AI Workshop</b></a> •
  <a href="#-building-from-source"><b>Build from Source</b></a> •
  <a href="#-privacy--security"><b>Privacy</b></a> •
  <a href="#-contributing"><b>Contributing</b></a>
</p>

---

</div>

## 🌟 Overview

**Animatto** reimagines desktop shimejis and virtual companions natively for macOS. Built with **Swift, SwiftUI, AppKit, and Apple Vision**, companions roam freely across your screens, obey gravity, leap atop application window borders, react to your music, and even flip gravity to walk upside-down along the macOS menu bar.

Unlike legacy web-view or electron companions, Animatto uses lightweight native `NSPanel` transparent overlays at `.screenSaver` levels, ensuring high frame rates, zero window shadows, minimal CPU overhead, and completely offline machine learning.

A recorded demonstration video is available at [`demo/Animatto-Demo.mp4`](demo/Animatto-Demo.mp4).

---

## ✨ Key Features

### 🐾 1. Realistic Desktop Physics & Interactions
* **Autonomous Roaming:** Companions navigate screens independently across all spaces and virtual desktops.
* **Surface & Window Collision:** Scans active macOS application windows so companions can stand, jump, and walk along the title bars of your open windows.
* **Natural Movement & Gravity:** Dynamic walking hops scaled with velocity, realistic gravity acceleration, falling physics, and edge bounce mechanics.
* **Direct Interaction:** Click, drag, and fling companions anywhere on your screen. Drop them to watch them fall back to the nearest window or floor.
* **Menu Bar Walking Mode:** Invert gravity to let companions walk upside-down directly underneath your macOS Menu Bar.

### 🎨 2. Creative AI Workshop
* **Magic Eraser (100% On-Device Local AI):** Leverages Apple's native Vision framework (`VNGenerateForegroundInstanceMaskRequest`) to segment subjects and strip backgrounds from still images and **frame-by-frame animated GIFs** entirely offline.
* **AI Sprite Generator (Cloud):** Generate custom chibi anime sprites on demand from text prompts via `flux-anime`.
* **Community Shimeji DB Browser:** Search and download thousands of community-crafted anime and video-game companions directly inside the app.

### ⚡ 3. Menu Bar Dashboard
* Compact, responsive `MenuBarExtra` popover panel for instant control:
  * Pause or resume physics simulation instantly.
  * Mute audio effects.
  * Toggle Menu Bar walking mode.
  * Switch companions without keeping the main library window open.

### 🎵 4. System Integrations
* **Discord Rich Presence (RPC):** Connects directly to Discord's local Unix Domain Socket (`discord-ipc-0`) via Apple's native `Network.framework`—zero external dependencies or binary bloat.
* **Music Playback Sync:** Observes active Spotify and Apple Music playback status via AppleScript, allowing companions to react to your tunes.
* **Companion Timers & Naps:** Set custom 5, 15, 30, or 60-minute alarms and focus timers.

---

## 💻 System Requirements

| Requirement | Specification |
| :--- | :--- |
| **Operating System** | macOS 14.6 (Sonoma) or newer (macOS 15 Sequoia supported) |
| **Architecture** | Apple Silicon (M1/M2/M3/M4) & Intel 64-bit |
| **Required Permissions** | **Accessibility** (optional, for window-edge collision detection) |

---

## 🚀 Installation

### Option 1: Direct Download (Recommended)

1. Download the latest release disk image:  
   👉 **[Download Animatto-v1.0.dmg](https://github.com/sharmao07/Animatto/releases/latest)**
2. Double-click `Animatto-v1.0.dmg` to open it.
3. Drag **Animatto.app** into your **Applications** folder.
4. **First Launch (macOS Gatekeeper):**
   * Because Animatto is built independently, macOS Gatekeeper may show an unnotarized developer prompt on first launch.
   * Right-click (or Control-click) `Animatto.app` in `/Applications` and click **Open**.
   * Click **Open** in the confirmation dialog.

### Option 2: Building from Source

```bash
# 1. Clone the repository
git clone https://github.com/sharmao07/Animatto.git
cd Animatto

# 2. Open in Xcode
open Animatto.xcodeproj

# 3. Build via command line
xcodebuild -project Animatto.xcodeproj -scheme Animatto -configuration Release build
```

The compiled application bundle will be located at:  
`./build/Build/Products/Release/Animatto.app`

---

## 📂 Project Structure

```
Animatto/
├── Animatto.xcodeproj/       # Xcode project and build configurations
├── Animatto/
│   ├── AnimattoApp.swift      # Application entry point & MenuBarExtra scene
│   ├── PetEngine.swift        # Physics simulation, window manager & behavior loop
│   ├── MainAppView.swift      # Library grid, preview inspector & settings view
│   ├── AIToolsView.swift      # Magic Eraser (Apple Vision), AI Gen & Shimeji DB
│   ├── MenuBarDashboard.swift # Menu bar popover mini-dashboard
│   ├── PetStorage.swift       # Persistent storage (~/Library/Application Support/AnimattoPets)
│   ├── MediaRenderers.swift   # AppKit wrappers for animated GIFs & video loops
│   ├── SystemIntegrations.swift # Discord IPC Unix socket client & music monitor
│   └── Assets.xcassets/       # AppIcon, accent colors, and UI assets
├── .github/
│   ├── ISSUE_TEMPLATE/        # Bug report and feature request templates
│   ├── workflows/             # GitHub Actions CI workflows
│   └── PULL_REQUEST_TEMPLATE.md # Pull request submission checklist
├── demo/
│   └── Animatto-Demo.mp4      # Demonstration video
├── Animatto-v1.0.dmg          # Pre-packaged macOS installer
├── CHANGELOG.md               # Version history and changelog
├── CHECKLIST.md               # Master development roadmap
├── CODE_OF_CONDUCT.md         # Contributor Covenant Code of Conduct
├── CONTRIBUTING.md            # Guidelines for open-source contributors
├── LICENSE                    # Apache-2.0 License
├── README.md                  # Project documentation
└── SECURITY.md                # Security and vulnerability reporting policy
```

---

## 🔒 Privacy & Security

Animatto is engineered with strict privacy principles:

* **100% On-Device Vision Processing:** Background removal using Apple's Vision framework (`VNGenerateForegroundInstanceMaskRequest`) runs entirely on your Mac's Neural Engine / GPU. No images or animated GIF frames leave your machine.
* **Isolated Local IPC:** Discord RPC communicates through a local Unix socket (`discord-ipc-0`) without binding public ports or communicating with third-party tracking endpoints.
* **No Telemetry or Tracking:** Zero analytics, zero ad trackers, zero unsolicited network calls.

See [SECURITY.md](SECURITY.md) for full security disclosures and vulnerability reporting instructions.

---

## 🤝 Contributing

Contributions are warmly welcomed! Please see our [Contributing Guide](CONTRIBUTING.md) to get started.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m "feat: add amazing feature"`)
4. Push to your branch (`git push origin feature/amazing-feature`)
5. Open a [Pull Request](https://github.com/sharmao07/Animatto/pulls)

Please make sure to read and follow the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## 📈 Activity & Community

[![Star History Chart](https://api.star-history.com/svg?repos=sharmao07/Animatto&type=Date)](https://star-history.com/#sharmao07/Animatto&Date)

---

## 📄 License

This project is open-source software licensed under the **Apache License, Version 2.0**. See the [LICENSE](LICENSE) file for details.

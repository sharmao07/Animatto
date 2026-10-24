# KinetiPet 🐾

> **Anime-inspired interactive desktop companions for your Mac.** Built natively with Swift, SwiftUI, AppKit, and Apple Vision.

[![macOS](https://img.shields.io/badge/platform-macOS%2014.6%2B-black.svg?style=flat&logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat&logo=swift)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🌟 Overview

**KinetiPet** brings interactive virtual companions (inspired by desktop shimejis and virtual pets) to macOS. Characters roam your desktop freely, react to gravity, hop between application windows, and can even walk upside-down along the macOS menu bar.

It features a built-in **Workshop** with on-device Apple Vision AI for background removal, text-to-sprite AI generation, an external community Shimeji database browser, Discord Rich Presence, and music reactivity.

A recorded demonstration video is available at [`demo/KinetiPet-Demo.mp4`](demo/KinetiPet-Demo.mp4).

---

## ✨ Key Features

### 🐾 1. Realistic Desktop Physics & Interactions
- **Autonomous Roaming:** Companions navigate screens independently across all spaces using transparent `NSPanel` overlays (`.screenSaver` level).
- **Surface Collision:** Detects open window edges and screen floors, allowing pets to walk on top of active windows.
- **Natural Bobbing & Physics:** Dynamic walking hops scaled with movement velocity, gravity acceleration, edge bouncing, and falling physics.
- **Direct Interaction:** Drag and fling pets anywhere on the screen, toggle naps, or set built-in timers.
- **Menu Bar Walking Mode:** Companion flips gravity and walks upside-down along the top macOS Menu Bar.

### 🎨 2. Creative AI Workshop
- **Magic Eraser (Offline Local AI):** Uses Apple's native Vision framework (`VNGenerateForegroundInstanceMaskRequest`) to segment subjects and remove backgrounds from still images and **frame-by-frame animated GIFs** entirely on-device without internet access.
- **AI Sprite Generator (Cloud):** Generates chibi anime sprites from text descriptions via the Pollinations `flux-anime` model.
- **Shimeji DB Search:** Queries an online database to preview and download community-created desktop companions.

### ⚙️ 3. Settings & Integrations
- **Behavior Controls:** Real-time sliders for gravity strength, walking speed, and random event frequency.
- **Appearance Customization:** Dynamic theme accent color selection.
- **Discord Rich Presence (RPC):** Connects directly to Discord's local Unix Domain Socket (`discord-ipc-0`) via Apple's `Network.framework` without external dependencies.
- **Music Reactivity:** Actively listens to Spotify and Apple Music playback status via AppleScript to react to your music.

### ⚡ 4. Menu Bar Dashboard
- Persistent menu bar icon with a popover panel for quick access: pause physics, mute audio, toggle menu bar walking, or switch companions.

---

## 🛠 Tech Stack

- **UI & Lifecycle:** Swift, SwiftUI, AppKit (`NSPanel`, `NSHostingView`, `NSImageView`)
- **Computer Vision:** Apple Vision (`VNGenerateForegroundInstanceMaskRequest`), CoreImage (`CIContext`), ImageIO
- **Video & Media:** AVFoundation, AVKit (`AVPlayerLayer`)
- **Networking & IPC:** Apple `Network.framework` (`NWConnection` Unix Domain Socket), `URLSession`

---

## 🚀 Getting Started

### Prerequisites
- macOS 14.6 (Sonoma) or later
- Xcode 15.0 or later

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/KinetiPet.git
   cd KinetiPet
   ```

2. Open the project in Xcode:
   ```bash
   open KinetiPet.xcodeproj
   ```

3. Press **Cmd + R** to build and run, or build via command line:
   ```bash
   xcodebuild -project KinetiPet.xcodeproj -scheme KinetiPet -configuration Release build
   ```

---

## 📂 Project Structure

```
KinetiPet/
├── KinetiPet.xcodeproj/       # Xcode project configuration
├── KinetiPet/
│   ├── KinetiPetApp.swift     # Application entry point & MenuBarExtra scene
│   ├── PetEngine.swift        # Physics simulation, window manager & behavior loop
│   ├── MainAppView.swift      # Main navigation, Character Library & Settings view
│   ├── AIToolsView.swift      # Magic Eraser (Apple Vision), AI Gen & Shimeji DB
│   ├── MenuBarDashboard.swift # Menu bar popover controls
│   ├── PetStorage.swift       # File persistence (~/Library/Application Support)
│   ├── MediaRenderers.swift   # AppKit wrappers for animated GIFs & video loops
│   ├── SystemIntegrations.swift # Discord IPC Unix socket client & music monitor
│   └── Assets.xcassets/       # Icons and color assets
├── demo/
│   └── KinetiPet-Demo.mp4     # Demonstration video
├── LICENSE                    # Apache 2.0 License
└── README.md                  # Project documentation
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

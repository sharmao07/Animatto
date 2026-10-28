# Contributing to Animatto 🐾

Thank you for your interest in contributing to **Animatto**! We welcome community contributions, bug reports, feature suggestions, and companion artwork.

Please take a moment to review this document before submitting contributions.

---

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please treat all contributors with kindness, empathy, and respect.

---

## Ways to Contribute

1. **Report Bugs:** Open an issue with a detailed reproduction scenario, macOS version, and logs.
2. **Suggest Features:** Share ideas for new companion behaviors, physics interactions, or Workshop tools.
3. **Contribute Code:** Improve physics simulation, fix issues, optimize memory usage, or add integrations.
4. **Sprite & Character Contributions:** Share custom transparent PNG/GIF animations and presets.
5. **Documentation:** Improve installation steps, API notes, or user guides.

---

## Development Setup

### Prerequisites
- **Operating System:** macOS 14.6 (Sonoma) or newer.
- **Xcode:** Xcode 15.0+ or Xcode 16.0+ with macOS SDK.
- **Hardware:** Apple Silicon (M1/M2/M3/M4) or Intel Mac.
- **Command Line Tools:** `xcode-select --install`

### Getting the Code
1. Fork the repository on GitHub: [`https://github.com/sharmao07/Animatto`](https://github.com/sharmao07/Animatto)
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/Animatto.git
   cd Animatto
   ```
3. Open the project in Xcode:
   ```bash
   open Animatto.xcodeproj
   ```
4. Build and run:
   - In Xcode: Select the **Animatto** scheme and press **Cmd + R**.
   - From Terminal:
     ```bash
     xcodebuild -project Animatto.xcodeproj -scheme Animatto -configuration Debug build
     ```

---

## Architectural Overview

* **`AnimattoApp.swift`**: Application entry point and MenuBarExtra scene configuration.
* **`PetEngine.swift`**: Physics simulation engine, window-edge collision detection, gravity, bounce loop, and transparent `NSPanel` overlay controller.
* **`MainAppView.swift`**: Primary navigation, Character Library, Settings, and theme controls.
* **`AIToolsView.swift`**: Creative Workshop containing on-device Apple Vision segmentation (Magic Eraser), Cloud AI sprite generation, and community Shimeji DB integration.
* **`MenuBarDashboard.swift`**: Quick-access Menu Bar popover dashboard with physics toggles, audio mute, and window summoning.
* **`PetStorage.swift`**: Persistent storage manager (`~/Library/Application Support/AnimattoPets`) with automatic backwards-compatibility migrations.
* **`MediaRenderers.swift`**: AppKit wrappers for animated GIFs, transparent PNGs, and looped media.
* **`SystemIntegrations.swift`**: Local Unix Domain Socket Discord RPC (`discord-ipc-0`) and AppleScript music playback observer.

---

## Coding Guidelines

- **Swift Style:** Follow standard [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- **SwiftUI & AppKit Isolation:** Keep UI declarative in SwiftUI and confine window-level manipulation (`NSPanel`, `NSWindow`, screen frames) to AppKit managers.
- **Threading:** Never run long-running tasks, file I/O, or computer vision inference on the main thread or physics animation loop.
- **Preserve Comments:** Keep existing comments intact and add clear documentation for public functions.
- **Privacy First:** Ensure all vision tools default to on-device offline processing without transmitting private user data.

---

## Submitting Pull Requests

1. Create a descriptive feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Commit your changes with clear, concise commit messages:
   ```bash
   git commit -m "feat(physics): add realistic wall sliding friction"
   ```
3. Test your changes thoroughly on macOS to ensure no regressions.
4. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
5. Open a Pull Request against `main` using the provided [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md).

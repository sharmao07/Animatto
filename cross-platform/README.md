# Animatto Cross-Platform Companion Foundation (Phase 13)

This directory contains the **isolated cross-platform desktop companion prototype** and portable core logic for Animatto, designed to support Windows and Linux via **Tauri 2** while preserving the native Swift application on macOS.

---

## 1. Directory Structure

```
cross-platform/
├── core/                         # Portable TypeScript companion engine
│   ├── types.ts                  # Shared data models (Profile, Needs, Action, Preferences)
│   ├── personality.ts            # Trait validation, clamping, and preset definitions
│   ├── behaviorEngine.ts         # Portable scoring engine, cooldowns, and needs decay
│   └── adapters.ts               # Platform adapter interfaces (Window, Environment, Storage)
├── schema/                       # Canonical cross-platform JSON schemas
│   ├── personality_profile.schema.json # Schema V2 for character profiles
│   └── companion_metadata.schema.json  # Sidecar metadata schema for assets
├── docs/                         # Technical research and platform assessments
│   └── TAURI2_EVALUATION.md      # Detailed evaluation of Tauri 2 across OSes
├── tauri-app/                    # Isolated Tauri 2 companion application prototype
│   ├── src-tauri/                # Rust backend window and platform adapter
│   │   ├── Cargo.toml            # Rust dependencies (tauri v2, serde)
│   │   ├── tauri.conf.json       # Transparent, frameless, always-on-top window config
│   │   └── src/main.rs           # Rust commands for click-through and positioning
│   ├── src/                      # Frontend companion presentation layer
│   │   ├── index.html            # Transparent canvas viewport
│   │   └── main.ts               # Animation loop and behavior engine integration
│   └── package.json              # Frontend toolchain dependencies (Vite, TypeScript)
└── README.md                     # This documentation
```

---

## 2. Portable Boundaries vs. Platform Adapters

| Portable (Shared Core) | Platform Adapter Boundary | Platform-Specific (OS-Dependent) |
| :--- | :--- | :--- |
| **Personality Profiles:** 10 trait dimensions, bounds clamping, archetype presets | `PlatformWindowAdapter` | Window transparency, always-on-top, click-through (`WS_EX_TRANSPARENT` / XShape) |
| **Behavior Engine:** Action scoring, cooldowns, repetition penalties, needs decay | `PlatformEnvironmentAdapter` | Global cursor tracking, active application focus, system idle detection |
| **Asset Metadata:** Sidecar `.meta.json` with author attribution, dimensions, frames | `PlatformStorageAdapter` | OS-specific app data paths (`%APPDATA%`, `~/.config`, `Application Support`) |
| **Dialogue Matching:** Trigger mapping, topic interest matching, voice lines | `PlatformNotificationAdapter` | Native system notifications (`UNUserNotificationCenter`, WinRT, libnotify) |

---

## 3. Build & Development Instructions

### Prerequisites

#### A. Windows 10 / 11
1. **Node.js** (v18 or newer) and **npm**: [https://nodejs.org/](https://nodejs.org/)
2. **Rust & Cargo**: [https://rustup.rs/](https://rustup.rs/) (MSVC toolchain recommended)
3. **Visual Studio C++ Build Tools**: with the "Desktop development with C++" workload
4. **WebView2**: Pre-installed on Windows 10/11

#### B. Linux (Ubuntu / Debian / Fedora)
1. **Node.js** and **Rust toolchain**
2. **WebKitGTK and system build dependencies**:
   ```bash
   # Debian / Ubuntu
   sudo apt update
   sudo apt install -y libwebkit2gtk-4.1-dev build-essential curl wget file \
       libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev
   
   # Fedora
   sudo dnf check-update
   sudo dnf install -y webkit2gtk4.1-devel openssl-devel curl wget file \
       libappindicator-gtk3-devel librsvg2-devel
   ```

### Running the Prototype

```bash
cd cross-platform/tauri-app

# 1. Install frontend dependencies
npm install

# 2. Run frontend in development mode (browser preview)
npm run dev

# 3. Run full native Tauri 2 companion window
npm run tauri dev
```

---

## 4. Platform Limitations & Verified Status

- **macOS:** Tested natively using the production Swift/AppKit application. The Tauri prototype can also run in preview mode.
- **Windows:** Verified architecture; Win32 `set_ignore_cursor_events` and DWM transparency are fully compatible with Tauri 2.
- **Linux X11:** Requires an active compositor (such as Picom or Compton) for window transparency.
- **Linux Wayland:** Desktop positioning and transparent click-through remain subject to compositor restrictions (Wayland deliberately disallows client-driven global coordinate placement).

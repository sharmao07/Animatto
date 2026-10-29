# Animatto Beta Testing Guide

Welcome to the Animatto private beta testing program! This guide covers everything you need to safely install, evaluate, and provide feedback on the native macOS desktop companion application.

---

## 1. Beta Program Purpose & Scope

Animatto is a native macOS application designed to bring interactive, autonomous desktop companions and ambient weather worlds to macOS.

The primary goals of this testing cycle are:
- Verifying physics calculations, window collisions, and screen boundaries on macOS Sonoma (14.6+) and Sequoia (15.0+).
- Testing multi-monitor companion movement across disparate display resolutions and scaling factors.
- Evaluating memory footprint and CPU efficiency during continuous particle simulations.
- Testing offline functionality and verifying zero data leakage.

> [!WARNING]
> This is pre-release software. While Animatto does not modify user system files, unintended behavior, temporary visual glitches, or unexpected CPU usage may occur.

---

## 2. System Requirements

- **Operating System:** macOS 14.6 (Sonoma) or macOS 15.0+ (Sequoia).
- **Architecture:** Universal Binary supporting both Apple Silicon (M1/M2/M3/M4) and Intel x86_64.
- **Display:** Single or multiple displays supported.
- **Permissions (Optional):**
  - **Screen Recording:** *Optional.* Required only if testing Screen Awareness contextual dialogue.
  - **Apple Events (Automation):** *Optional.* Required only if testing music-synced dancing with Apple Music or Spotify.
  - **Internet Connection:** *Optional.* The app operates 100% offline. Network access is only used for Open-Meteo weather synchronization and GitHub release update checks.

---

## 3. Installation Instructions

Because this candidate is an ad-hoc signed internal beta build (not yet notarized by Apple Developer ID):

1. **Mount the Disk Image:**
   - Double-click `Animatto-v1.1.0.dmg`.
   - A Finder window will open displaying the Animatto application and Applications folder link.
2. **Install the Application:**
   - Drag `Animatto.app` into the `Applications` folder shortcut.
3. **First-Launch Gatekeeper Authorization:**
   - Standard double-clicking may trigger a macOS prompt stating: *"Animatto cannot be opened because the developer cannot be verified."*
   - To authorize the ad-hoc build:
     1. Open your `Applications` folder in Finder.
     2. **Right-click (Control-click)** on `Animatto.app` and select **Open**.
     3. Click **Open** on the confirmation dialog.
   - On subsequent launches, you can open Animatto normally from Spotlight, Launchpad, or the Applications folder.

---

## 4. How to Use Animatto

### 4.1 Spawning & Managing Companions
- Upon initial launch, the main Animatto Studio window will appear.
- Select a companion from the roster or gallery and click **Spawn Companion**.
- The companion will appear on your desktop, walking along window titlebars and screen boundaries.
- **Dragging:** Click and hold any companion to pick them up and drag them around your screens. Releasing drops them with realistic gravity.
- **Menu Bar Control:** Click the Animatto icon in your macOS menu bar to quickly spawn, dismiss, pause, or mute companions without opening the full studio.

### 4.2 Ambience & Particle Simulations
- Open Animatto -> **Ambience** tab.
- Choose from 6 environment presets (Rain, Snow, Fog, Sunlight, Wind, Falling Leaves).
- Test the particle simulation intensity slider and monitor system responsiveness.

### 4.3 Quitting the Application
- Use standard macOS shortcuts: press `Cmd + Q` while the main window is focused.
- Alternatively, click the Menu Bar icon and select **Quit Animatto**.

---

## 5. Diagnostic Capture & Reporting Bugs

If you encounter an unexpected crash, visual glitch, or abnormal behavior:

1. **Crash Reports:**
   - macOS automatically records crash logs. Open `/Applications/Utilities/Console.app`.
   - In the sidebar, navigate to **Crash Reports** and search for `Animatto`.
2. **Sanitizing Sensitive Information:**
   - Do **NOT** post screenshots containing private personal documents or browser tabs.
   - Do **NOT** share any cloud API keys or personal credentials.
3. **Submitting Feedback:**
   - Open a ticket at: `https://github.com/sharmao07/Animatto/issues`
   - Use the template provided in `docs/BETA_TEST_CHECKLIST.md`.

---

## 6. Known Limitations in Current Build

- **DMG Visual Alignment:** The background layout in the mounted DMG installer is currently misaligned and clipped on the right edge. Installation by dragging works correctly despite the visual bug.
- **Weather Localization:** On macOS systems formatted with comma decimal separators (e.g. German, French), weather synchronization may return a parse error (Issue #44).
- **Atmosphere Pack Relaunch:** Custom imported atmosphere presets may not persist across application restarts (Issue #45).
- **Video Companion Playback:** Video-based companions currently lock to their initial animation loop (Issue #47).

---

## 7. Clean Uninstallation Instructions

To completely remove Animatto and restore your Mac to its prior state:

1. **Quit the Application:**
   - Ensure Animatto is completely terminated (`Cmd + Q` or check Activity Monitor).
2. **Delete the Application Bundle:**
   ```bash
   rm -rf /Applications/Animatto.app
   ```
3. **Remove Application Support & Cache:**
   ```bash
   rm -rf ~/Library/Application\ Support/Animatto
   rm -rf ~/Library/Caches/com.dev.Animatto
   ```
4. **Purge Preferences & Saved State:**
   ```bash
   defaults delete com.dev.Animatto 2>/dev/null || true
   rm -rf ~/Library/Saved\ Application\ State/com.dev.Animatto.savedState
   ```
5. **Clear Stored Keychain Credentials (if used):**
   - Open `/Applications/Utilities/Keychain Access.app`.
   - Search for `com.dev.Animatto` and delete any stored items.

# Animatto v1.2.0 Beta Testing Guide

Welcome to the Animatto public beta testing program! This guide covers everything you need to safely install, evaluate, and provide feedback on the native macOS desktop companion and ambient world application.

---

## 1. Beta Program Purpose & Scope

Animatto is a native macOS companion application engineered with Swift and SwiftUI for macOS Sonoma (14.6+) and macOS Sequoia (15.0+).

The primary goals of this v1.2.0 testing cycle are:
- Verifying the in-place **Aquarium Mode** desktop widget transformation across multiple independent widgets.
- Verifying autonomous companion physics, gravity, and window platform traversal across single and multi-display setups.
- Evaluating memory footprint and CPU efficiency during continuous ambient particle simulations and extended idle states.
- Verifying offline-first operation, local memory persistence, and privacy protection (zero network telemetry).

> [!NOTE]
> Animatto is an offline-first native application. It does **not** collect telemetry, track usage, or transmit desktop content to cloud servers.

---

## 2. System Requirements

- **Operating System:** macOS 14.6 (Sonoma) or macOS 15.0+ (Sequoia).
- **Architecture:** Universal Binary with native Apple Silicon (M1/M2/M3/M4) and Intel (x86_64) binaries.
- **Display:** Single or multiple displays supported.
- **Permissions (Optional):**
  - **Screen Recording:** *Optional.* Required only if testing Screen Awareness contextual dialogue.
  - **Apple Events (Automation):** *Optional.* Required only if testing music-synced dancing with Apple Music or Spotify.
  - **Internet Connection:** *Optional.* The app operates 100% offline. Network access is only used for Open-Meteo weather synchronization and GitHub release update checks.

---

## 3. Installation Instructions

Because this beta candidate is distributed directly via GitHub prior to final Developer ID certificate notarization:

1. **Mount the Disk Image:**
   - Double-click `Animatto-v1.2.0.dmg`.
   - A Finder window will open displaying the Animatto application and Applications folder link on custom artwork.
2. **Install the Application:**
   - Drag `Animatto.app` into the `Applications` folder shortcut.
3. **First-Launch Gatekeeper Authorization:**
   - Standard double-clicking may trigger a macOS prompt stating: *"Animatto cannot be opened because the developer cannot be verified."*
   - To authorize the build:
     1. Open your `Applications` folder in Finder.
     2. **Right-click (Control-click)** on `Animatto.app` and select **Open**.
     3. Click **Open** on the confirmation dialog.
     4. (Alternatively, open **System Settings > Privacy & Security** and click **Open Anyway** under the Security section).
   - On subsequent launches, you can open Animatto normally from Spotlight, Launchpad, or the Applications folder.

---

## 4. How to Use Animatto v1.2.0

### 4.1 Desktop Companions
- Upon initial launch, the main Animatto Studio window will appear.
- Select a companion from the roster or gallery and click **Spawn Companion**.
- The companion will appear on your desktop, walking along window titlebars and screen boundaries.
- **Dragging:** Click and hold any companion to pick them up and drag them around your screens. Releasing drops them with realistic gravity.
- **Menu Bar Control:** Click the Animatto paw icon in your macOS menu bar to quickly spawn, dismiss, pause, or mute companions without opening the full studio.

### 4.2 Aquarium Mode (In-Place Widget Transformation)
- Click **Turn On Aquarium Mode** from the Menu Bar popover or Aquarium tab.
- All active desktop companion widgets transform directly in-place into interactive aquariums.
- **Interactions:**
  - **Tap Glass:** Click anywhere inside the aquarium widget to send water shockwaves and scatter nearby fish.
  - **Feed:** Click the "Feed" button or tap near the top of the tank to drop sinking food pellets.
- **Restoration:** Click **Turn Off Aquarium Mode** to restore your original desktop companions to their exact positions and behaviors.

### 4.3 Ambient Worlds & Weather
- Open the **Ambient Worlds** tab to select from 6 atmospheric particle environments (Rain, Snow, Sakura, Fireflies, Starlight, Autumn).
- Toggle live weather synchronization to sync desktop atmosphere with local conditions via Open-Meteo.

### 4.4 Quitting the Application
- Press `Cmd + Q` while the main window is focused, or click the Menu Bar icon and select **Quit Animatto**.

---

## 5. Privacy-Conscious Feedback & Bug Reporting

Animatto provides an automated, privacy-conscious diagnostic export tool directly in Settings:

1. **Copying Privacy-Sanitized Diagnostics:**
   - In Animatto, open **Settings (`⌘,`) > Software Updates & Diagnostics**.
   - Click the **"Copy Diagnostics"** button.
   - This copies a diagnostic breadcrumb summary directly to your clipboard.
   - **Privacy Guarantee:** The in-memory logger automatically redacts your macOS username (`/Users/<username>` -> `~`), email addresses, and secret tokens before copying. No data is ever sent to any remote server automatically.
2. **Crash Reports:**
   - macOS automatically records native Cocoa crash logs. Open `/Applications/Utilities/Console.app`.
   - In the sidebar, navigate to **Crash Reports** and search for `Animatto`.
3. **Submitting Feedback:**
   - Open a ticket at: [https://github.com/sharmao07/Animatto/issues/new/choose](https://github.com/sharmao07/Animatto/issues/new/choose)
   - Choose the **Beta Feedback & Diagnostics** template.
   - Paste the sanitized diagnostic report directly into section 6 of the issue.
   - Or join the discussion at: [https://github.com/sharmao07/Animatto/discussions](https://github.com/sharmao07/Animatto/discussions)

---

## 6. Known Limitations in Current Beta Build

- **Gatekeeper First-Launch Prompt:** Until the maintainer's paid Apple Developer ID certificate and notarization ticket are stapled, macOS requires right-clicking and selecting **Open** on first launch.
- **Sandbox Licensing Mode:** Payment processing is configured in sandbox evaluation mode; live credit card processing is intentionally disabled during beta.
- **Discord Rich Presence:** Companion Discord activity requires a running local Discord desktop client application with IPC socket access.

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

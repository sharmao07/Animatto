# Animatto v1.2.0 Beta Test Checklist & Validation Matrix

Please use this structured checklist to validate Animatto v1.2.0 (Build 3) across real-world macOS hardware and software setups. Submit reports, bug filings, and diagnostics to GitHub: `https://github.com/sharmao07/Animatto/issues`.

---

## 1. Beta Tester Environment Information

| Field | Configuration / Value | Notes |
| :--- | :--- | :--- |
| **Tester Handle / Name** | | GitHub username or contributor tag |
| **macOS Version** | macOS 14.6+ Sonoma / macOS 15+ Sequoia | System Settings > General > About |
| **Mac Hardware & Chip** | Apple Silicon (M1/M2/M3/M4) or Intel Core (x86_64) | Universal binary verification |
| **Display Configuration** | Single built-in / Multi-monitor (Resolution & scale) | Note Spaces and menu bar arrangements |
| **Test Build** | v1.2.0 (Build 3) | Universal Binary (`Animatto-v1.2.0.dmg`) |

---

## 2. Nine-Subsystem Operational Matrix

Mark each scenario with `[x]` for Pass, `[ ]` for Not Tested, or `[!]` for Defect / Bug.

### Area 1: Desktop Companions & Physics
- [ ] **Spawning:** Companions spawn with clean transparency, correct sprite scaling, and grounded physics.
- [ ] **Autonomous Movement:** Companions switch naturally between idle, walking, sitting, and sleeping.
- [ ] **Gravity & Collision:** When dragged and released mid-air, companions fall with terminal velocity cap and bounce dampening.
- [ ] **Window Obstacle Traversal:** Companions walk on top of visible application window top borders.
- [ ] **Upside-Down Menu Bar Physics:** Inverting gravity anchors companions to the top macOS menu bar smoothly.

### Area 2: Multi-Widget & Social Dynamics
- [ ] **Multi-Companion Independence:** Spawning multiple companions allows each to move autonomously without locking up.
- [ ] **Social Encounters:** Two companions crossing paths recognize each other and trigger contextual social dialogue.
- [ ] **Quiet Mode Precedence:** Toggling Quiet Mode in Settings mutes social dialogue while preserving companions' individual visual states.
- [ ] **Roster Dismissal:** Closing individual companion widgets dismisses them cleanly without affecting others.

### Area 3: In-Place Aquarium Mode Transformation
- [ ] **Widget Transformation:** Enabling Aquarium Mode transforms existing desktop companion widgets into aquatic habitats in place (no floating aquarium window).
- [ ] **Aquatic Behavior:** Companions transition to smooth 3D hydrodynamic buoyancy, banking, and wall repulsion.
- [ ] **Interactive Feeding & Tapping:** Clicking/tapping inside the transformed widget drops dissolvable food pellets and triggers swimming darts.
- [ ] **Restoration:** Disabling Aquarium Mode smoothly restores companions back to their walking desktop forms.
- [ ] **Battery Efficiency:** The 30 Hz desktop physics timer pauses completely while in Aquarium Mode.

### Area 4: Ambient Worlds & Audio Engine
- [ ] **Weather Particulates:** Rain, Snow, Sakura petals, and Fireflies render smoothly with low CPU load.
- [ ] **Dynamic Audio Ambience:** Procedural audio layers (rain, wind, stream) play smoothly and duck appropriately.
- [ ] **Master Mute & Volume:** Toggling audio mute in Settings or Menu Bar instantly halts ambient and SFX audio.
- [ ] **Low Power Mode:** Enabling macOS Low Power Mode scales particle emission to preserve battery.

### Area 5: Creator Studio & Magic Eraser
- [ ] **Custom Sprite Import:** Importing GIF, PNG sequence, or WebP sprite sheets creates valid companions.
- [ ] **Magic Eraser:** Alpha keying and background subtraction accurately isolates sprites with clean edges.
- [ ] **Manifest Generation:** Custom companions export valid `manifest.json` schemas with states and animations.

### Area 6: Productivity & Pomodoro Tools
- [ ] **Focus Timer Lifecycle:** Starting a Pomodoro timer displays countdown and places companion in focus mode.
- [ ] **Break Phase Transition:** Completing focus cycles triggers audio chimes and companion celebration dialogue.
- [ ] **Timer Suspension:** Sleep/wake cycles suspend and resume timer monotonic intervals without drift or crash.

### Area 7: Menu Bar & System Integrations
- [ ] **Status Extra Popover:** Clicking the menu bar extra reveals quick roster controls, mute, and Aquarium toggle.
- [ ] **Discord Rich Presence:** Companion status accurately appears in Discord when enabled in Settings.
- [ ] **Music Sync:** Companion bobs to active Apple Music / Spotify playback cadence when enabled.

### Area 8: Permissions & Privacy Shield
- [ ] **Screen Recording Fallback:** App functions 100% offline and without error if Screen Recording is denied.
- [ ] **Privacy Shield Exclusions:** Passwords, 1Password, Bitwarden, KeePassXC, and Keychain windows are strictly excluded.
- [ ] **Zero Telemetry:** No network requests are dispatched without explicit user action.

### Area 9: Persistence, Restart, Sleep & Wake
- [ ] **Preference Persistence:** Custom scales, audio levels, and companion rosters persist across app quit (`⌘Q`) and restart.
- [ ] **System Sleep/Wake:** Putting Mac to sleep and waking does not corrupt window frames or spike CPU.
- [ ] **Software Update Check:** Manual check for updates against GitHub Releases verifies SemVer tags cleanly.

---

## 3. Diagnostic Reporting
If an unexpected behavior occurs:
1. Open **Settings (`⌘,`) > Software Updates & Diagnostics**.
2. Click **"Copy Diagnostics"**.
3. Paste the sanitized report directly into your issue on GitHub.

# Animatto Beta Test Checklist & Bug Submission Template

Please use this checklist to record test coverage across your hardware and software configuration. Submit completed reports or filing tickets on GitHub: `https://github.com/sharmao07/Animatto/issues`.

---

## 1. Tester Environment Information

| Field | Value | Notes / Description |
| :--- | :--- | :--- |
| **Tester Name / Handle** | | |
| **macOS Version** | (e.g. macOS 14.6.1, 15.1) | Check in Apple menu -> About This Mac |
| **Mac Model & Architecture** | (e.g. MacBook Pro M3 Max, Mac mini Intel i7) | Apple Silicon (arm64) vs Intel (x86_64) |
| **Display Configuration** | (e.g. 1 built-in Retina, 2 external 4K displays) | Note scaling factors (e.g. 200%, 150%) |
| **Test Candidate Version** | v1.1.0 (Build 2) | SHA-256: `2ade474e741ffd...` |

---

## 2. Verification Checklist

Mark each scenario with `[x]` for Pass, `[ ]` for Not Tested, or `[!]` for Fail/Bug.

### A. Installation & Launch Lifecycle
- [ ] **DMG Mounting:** Disk image mounts cleanly on double-click.
- [ ] **Drag Installation:** `Animatto.app` installs into `/Applications` without permission errors.
- [ ] **First Launch:** Right-click -> Open successfully bypasses ad-hoc Gatekeeper warning.
- [ ] **Default Window:** Main Studio window opens automatically upon first launch.
- [ ] **Menu Bar Icon:** Status bar extra appears in the macOS top menu bar.
- [ ] **Clean Termination:** `Cmd + Q` or Menu Bar -> Quit terminates all companion instances.
- [ ] **Relaunch:** Re-opening the app restores prior roster and preferences.

### B. Companion Physics & Movement
- [ ] **Spawning:** Clicking "Spawn" creates a desktop companion with correct transparency.
- [ ] **Dragging & Drop:** Companion can be picked up, dragged, and falls with gravity on release.
- [ ] **Ledge & Edge Detection:** Companion walks along screen bottom and bounces off screen edges.
- [ ] **Window Titlebar Walking:** Companion walks on top of standard native application windows.
- [ ] **Multi-Monitor Traversal:** Companion walks seamlessly across adjacent display boundaries.
- [ ] **Display Reconfiguration:** Connecting/disconnecting a monitor keeps companions on active screens.

### C. UI, Controls & Performance
- [ ] **Floating Window Level:** Companions remain visible above normal application windows.
- [ ] **Menu Bar Launcher:** Companions can be spawned and dismissed from menu bar extra.
- [ ] **Speech Bubbles:** Speech bubbles position correctly and do not clip off-screen.
- [ ] **Ambience Presets:** Weather particle effects render smoothly without excessive lag.
- [ ] **CPU Footprint:** Idle CPU usage remains under 5% with 2 companions active.
- [ ] **Memory Usage:** Memory footprint remains stable (< 200MB) without memory leaks.

### D. Privacy, Permissions & Offline Operation
- [ ] **Permission Denial:** App functions completely when Screen Recording permission is denied.
- [ ] **Offline Mode:** App functions completely with Wi-Fi / Ethernet disconnected.
- [ ] **Clean Data Removal:** Following uninstall instructions purges all preferences and files.

---

## 3. Bug Report Submission Template

When reporting an issue, please format your GitHub Issue as follows:

```markdown
### Summary
A clear and concise description of what the bug is.

### Environment
- macOS Version: [e.g. 15.0.1]
- Mac Model / Architecture: [e.g. M2 MacBook Air / arm64]
- Candidate Version: v1.1.0 (Build 2)
- Multi-Monitor Setup: [Single / Dual display]

### Steps to Reproduce
1. Launch Animatto.
2. Go to '...'
3. Click '....'
4. Observe error.

### Expected Behavior
A concise description of what you expected to happen.

### Actual Behavior
What actually happened (include screenshots or Console logs if available).

### Severity & Impact
- [ ] P0 (Crash / Data Loss)
- [ ] P1 (Core Function Broken)
- [ ] P2 (Major Feature Defect)
- [ ] P3 (Minor Glitch / Polish)
```

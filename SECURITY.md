# Animatto — Security Policy & Privacy Charter

The Animatto team takes application security, user privacy, and data stewardship seriously. Animatto is designed on a **privacy-first, local-first** architecture. This charter details exactly how data is handled, what is stored locally, what external communication occurs, and how you retain complete control over your desktop environment.

---

## 1. Supported Versions

Security patches and reliability updates are released for the current active version series:

| Version | Supported          | Status |
| :------ | :----------------- | :----- |
| 1.1.x   | :white_check_mark: | Current active release line |
| 1.0.x   | :white_check_mark: | Supported previous release line |
| < 1.0.0 | :x:                | Unsupported early prototypes |

---

## 2. Plain-Language Privacy Charter

### A. What Animatto Collects vs. Does NOT Collect

* **Animatto DOES NOT Collect Personal Data:** Animatto contains zero third-party analytics SDKs, advertising frameworks, user tracking pixels, or background telemetry.
* **Animatto DOES NOT Log Keystrokes or Input:** Desktop companion windows (`NSPanel`) operate at floating window levels (`.screenSaver` / `.floating`) and do not hook system keyboard events or intercept keystrokes entered into other applications.
* **Animatto DOES NOT Silently Upload Screenshots:** No screen captures or desktop visual content are ever transmitted to any remote server without explicit, affirmative user consent and user-provided API credentials.

### B. What Is Stored Locally on Your Mac

All application state is kept entirely on your local machine:
1. **Character Sprites & Artwork:** Stored in `~/Library/Application Support/AnimattoPets/` (or standard OS app data directories).
2. **Personality Profiles:** Stored as local JSON files containing only simulation traits, topic preferences, and behavioral boundaries.
3. **Character Memories:** Stored in `~/Library/Application Support/AnimattoPets/character_memories.json`. Memories are strictly bounded (capped at 20 transient and 50 durable records per companion) and record only abstract companion-to-companion interactions (e.g. "Greeted Luna 3 times"). Private memories are never embedded into exported profiles.
4. **Application Settings:** Stored in standard sandboxed `UserDefaults` (`com.dev.Animatto`).
5. **Credentials & License Material:** If configured by the user, API keys or license keys are stored securely in the **macOS Keychain** (`kSecClassGenericPassword`), never in plaintext files.

---

## 3. External Network Communication

Animatto is designed to operate completely offline. The following features represent the **only** external network requests:

| Feature | External Endpoint | Protocol | Trigger | User Control |
| :--- | :--- | :--- | :--- | :--- |
| **Software Updates** | `api.github.com/repos/sharmao07/Animatto/releases` | HTTPS | Launch (optional) or manual "Check for Updates" button | Can be disabled in Settings; respects 15s timeout & 7-day dismissal cooldown. |
| **Cloud Vision Analysis** *(Optional)* | User-configured cloud endpoint (e.g. OpenAI/Anthropic/custom) | HTTPS | Only when "Screen Awareness" + "Cloud Processing" are explicitly enabled | Requires separate checkbox consent and user-entered API key. |
| **Live Weather Sync** *(Optional)* | `api.open-meteo.com` | HTTPS | When "Live Weather Sync" is toggled in Ambience Settings | User-entered coordinates only; zero API key/token required; 15-minute rate limit & offline cache; one-click "Clear Location Data" button. |
| **Discord Rich Presence** | Local Unix Domain Socket (`discord-ipc-0`) | Local IPC | Companion active | Purely local inter-process communication; no external network packets emitted by Animatto. |
| **Music Sync** | Local AppleScript / Scripting Bridge | Local IPC | Music playing in Spotify / Apple Music | Purely local query to local desktop music players. |

---

## 4. Visual Screen Awareness & Privacy Safeguards

Animatto features an optional **Screen Awareness** engine powered by macOS `ScreenCaptureKit`:
1. **Explicit Opt-In Required:** The feature is disabled by default. Enabling it triggers the official macOS Screen Recording permission prompt.
2. **In-Memory Downscaling Only:** Captured frames are downscaled in volatile memory to low-resolution thumbnails (max 512px) strictly for activity classification. **Raw screenshots are never written to disk.**
3. **Application Exclusion List:** Animatto automatically skips visual observation when sensitive applications are frontmost, including:
   - Password Managers (1Password, Bitwarden, KeePass, Apple Keychain Access)
   - Secure Browsing / Terminal sessions
   - Custom applications designated by the user in Settings.
4. **Local Processing Preferred:** By default, visual classification targets a local on-device endpoint (e.g., local Ollama/LM Studio instance). Remote cloud processing requires affirmative checkbox consent.

---

## 5. AI & Untrusted Input Boundaries

All external inputs, model outputs, and window titles are treated as untrusted:
* **No Code Execution:** Model-generated dialogue text is strictly rendered as passive text within SwiftUI speech bubbles. It is never parsed as code, shell commands, or system automation scripts.
* **Dialogue Sanitizer:** All speech bubble messages pass through `DialogueSanitizer` before rendering, which strips terminal ANSI escape sequences (`\x1B[...]`), unprintable control characters, and null bytes, and clamps length to 280 characters to prevent visual UI overflow.
* **Prompt Injection Defense:** System prompts enforce strict conversational boundaries, instructing companions to remain in character and ignore any visual desktop text attempting to alter assistant instructions.

---

## 6. Media & Asset Import Validation

Imported companion sprites, GIFs, and community asset packs are verified defensively:
1. **Magic Byte Signature Verification:** Files are inspected for valid binary magic numbers (`\x89PNG\r\n\x1a\n` for PNG, `GIF87a`/`GIF89a` for GIF, `\xFF\xD8\xFF` for JPEG, `RIFF...WEBP` for WebP). File extensions alone are never trusted.
2. **Path Traversal Prevention:** Import paths are stripped of directory traversal sequences (`../`, `..\`), root slashes, colons, and null bytes.
3. **Resource Quotas:** Imported asset files are subject to a strict 50MB file size ceiling before decoding to protect against memory exhaustion.
4. **Atmosphere Pack Security:** Community `.animattopack` files are capped at 10MB, strictly schema-validated, and verified to contain zero executable scripts, shell commands, tokens, or system paths.

---

## 7. Emergency Controls & Privacy Shield

Users can instantly stop all companion activity and background monitoring:
* **Privacy Shield ("Freeze All & Stop Monitoring"):** Accessible via the menu bar dashboard and settings. Clicking this immediately:
  - Freezes all companion movement and physics loops.
  - Mutes all speech bubbles and audio effects.
  - Stops `EnvironmentMonitor` application tracking and cursor observation.
  - Stops all `ScreenAwarenessService` capture tasks.
  - Cancels all active multi-character social encounters.
* **Bulk Memory Deletion:** Users can inspect stored character memories and wipe all records across all companions with a single click in Settings.

---

## 8. Reporting a Vulnerability

If you discover a security vulnerability or privacy flaw in Animatto, please report it responsibly:

1. **Confidential Reporting:** Please do **not** open a public issue for security disclosures.
2. **GitHub Security Advisory:** Submit a confidential advisory report via the **Security** tab → [Report a vulnerability](https://github.com/sharmao07/Animatto/security/advisories/new).
3. **Response Commitment:**
   - **Acknowledgment:** Within 48 hours of report submission.
   - **Triage & Reproduction:** Within 5 business days.
   - **Fix & Patch Release:** Released as an expedited update with coordinated disclosure.

---

## 9. Known Architectural Limitations

1. **Heuristic Screen Content:** While application exclusion lists prevent capture when password managers are active, Animatto cannot guarantee heuristic detection of sensitive text displayed inside generic browser tabs or text editors without user-defined application exclusion.
2. **Linux Wayland Sandboxing:** On Linux Wayland compositors, desktop window positioning and transparency are constrained by compositor security policies that restrict client-driven window placement.

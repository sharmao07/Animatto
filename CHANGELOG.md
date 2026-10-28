# Changelog

All notable changes to **Animatto** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - 2026-10-28

### Added
- **In-App Updater & Release Quality (Phase 12):**
  - Centralized `UpdateService` and `UpdateConfiguration` implementing a transparent notification-and-inspection update discovery model for Animatto.
  - Strict SemVer 2.0 parser and comparator (`SemanticVersion`) supporting `v`/`V` prefixes, multi-part numeric versions (`[1, 0, 0]`), prerelease precedence (`1.0.0-rc.1 < 1.0.0`), and build metadata isolation.
  - Official GitHub Releases API discovery (`https://api.github.com/repos/sharmao07/Animatto/releases`) with 15s timeouts, 403 rate-limit detection, 404 handling, and offline fallback.
  - Secure release asset validation (`ReleaseAssetInfo`) verifying HTTPS protocols and official GitHub release domains (`github.com`, `objects.githubusercontent.com`), filtering for distribution `.dmg` assets.
  - Safe update strategy: zero silent background binary downloads, zero automatic executable replacement, zero elevated scripts, and complete respect for macOS Gatekeeper and user consent.
  - Intelligent dismissal management: dismissing an update suppresses background alerts for 7 days or until a newer version arrives; manual checks bypass suppression.
  - User-facing update controls in `SettingsView` and `MenuBarDashboard`: version readout, live state feedback, release highlights, verified asset download size, and 1-click external navigation to GitHub releases.
  - Repeatable release packaging workflow (`scripts/build-and-package.sh`): builds release archive, strips extended attributes, applies and strictly verifies code signatures, creates UDZO-compressed DMG with Applications symlink, documents Apple Notarization, and generates SHA-256 checksums.
  - Native pixel-perfect macOS app icon set (`AppIcon.appiconset`) generating clean assets across all 10 standard resolutions (16x16 to 1024x1024) and updating `Contents.json`.
  - Updated CI pipeline (`.github/workflows/macos-build.yml`) ensuring full compilation of Phases 8-12 and validating the release packaging workflow.
  - Added 69 new unit assertions (615 total passing) verifying version parsing, precedence, JSON decoding, asset validation, update check state transitions, rate limits, timeouts, and dismissal cooldowns.
- **Workshop & Creator Studio (Phase 11):**
  - Upgraded the Workshop into a comprehensive 4-tab Creator Studio: Magic Eraser, AI Generator, Shimeji DB, and Personality Preset Gallery.
  - Centralized `WorkshopConfiguration` establishing centrally configurable external endpoints (`aiEndpointTemplate`, `shimejiSearchEndpoint`), request timeouts (25s), maximum download size limits (50MB), and offline mode gates (`isOnlineDisabled`).
  - Enhanced Vision background removal engine (`VisionBackgroundRemover`) with memory-safe frame processing using `autoreleasepool`, cancellation support, and preservation of GIF properties (`kCGImagePropertyGIFDelayTime`, `kCGImagePropertyGIFUnclampedDelayTime`, `kCGImagePropertyGIFLoopCount`, `kCGImagePropertyGIFHasGlobalColorMap`).
  - Robust import and signature verification (`WorkshopImportValidator`): validates file magic bytes (`\x89PNG\r\n\x1a\n`, `GIF87a`/`GIF89a`, `\xFF\xD8\xFF`, `RIFF...WEBP`, `ftyp`) rather than relying solely on file extensions.
  - Strict security and path traversal prevention stripping directory traversal patterns (`../`, `..\`), root slashes, colons, null bytes, and illegal shell characters, with snake_case normalization.
  - Community attribution and metadata sidecars (`CommunityAssetAttribution`): automatically persists `<companion>.meta.json` sidecars capturing author, uploader, source URL, license, and import date.
  - Decoupling of personality profiles and artwork (`PersonalityDecoupler`): updating companion artwork (`updateArtwork`) rebinds the character ID without altering existing traits, topic preferences, or memories; applying personality presets (`applyPreset`) updates the personality matrix without modifying sprite or animation assets.
  - Dedicated Personality Preset Gallery: interactive visual browser for all 10 archetypes (Curious, Sleepy, Playful, Shy, Mischievous, Calm, Energetic, Sarcastic, Supportive, Balanced) with trait breakdowns, sample voice lines, and 1-click application to any library companion.
  - Transparent canvas preview with checkerboard background pattern and explicit privacy/network status badges on every tool (`[Offline Local AI]`, `[Offline Local]`, `[Remote Cloud API]`, `[Remote Community API]`).
- **Productivity Companion & Focus Sessions (Phase 10):**
  - Centralized `ProductivityTimerManager` engine supporting quick countdown timers (5m, 15m, 30m, 60m), classic Pomodoro (25m focus / 5m break), Long Focus (50m focus / 10m break), and custom user-defined focus and break intervals.
  - Wall-clock deadline calculations (`targetDeadline`) preventing countdown drift across Mac sleep, wake, app backgrounding, and system stalls.
  - Unique generation ID tracking (`generationId`) ensuring cancelled or restarted timers cannot receive stale notification callbacks or trigger duplicate completion alerts.
  - System sleep/wake observer (`NSWorkspace.didWakeNotification`) that gracefully recomputes remaining session intervals and triggers completion if the deadline elapsed during sleep.
  - Session state persistence in `UserDefaults` (`com.dev.Animatto.productivity_session`) allowing countdown restoration or graceful completion across app termination and relaunch.
  - Native macOS user notifications via `UNUserNotificationCenter` with sound chimes and deterministic injectable test handlers for headless environments.
  - Full companion behavioral integration: configurable companion focus behavior (`FocusCompanionBehavior`) enabling companions to sleep quietly, sit idle, or maintain normal movement during active focus sessions.
  - Automatic companion wake-up on break start, celebratory hopping celebration on session completion, and focus-appropriate contextual dialogue triggers (`.focusStarted`, `.breakStarted`, `.timerFinished`).
  - Distraction suppression: spontaneous idle chatter and spontaneous multi-character social encounters are automatically suspended during active focus sessions, while direct user interactions (clicks, drags) remain responsive.
  - Productivity controls integrated across the app: sleek menu bar dashboard section with quick-start buttons, progress bar, and lifecycle controls (pause, resume, skip, stop, restart); pet desktop context menu with live countdown and timer actions; and comprehensive settings configuration section.
- **Character Memory & Continuity (Phase 8):**
  - Schema-versioned local memory store (`CharacterMemoryStore`) persisting structured memory records in `~/Library/Application Support/AnimattoPets/character_memories.json` via atomic file operations.
  - Distinct categorization of memories: transient short-term interactions, durable social memories, user-confirmed preferences, and derived interaction patterns.
  - Automatic memory consolidation for repeated companion encounters (incrementing interaction counts rather than accumulating unbounded duplicate entries).
  - Configurable retention bounds (capped at 20 transient and 50 durable memories per companion) and automatic time-based pruning of expired transient records.
  - Memory management controls in UI: global and per-character memory enable toggles, companion memory inspector, individual record deletion, and bulk memory clearing with confirmation alerts.
  - Privacy safeguards: zero cloud sync, zero LLM dependencies, no raw screen or keystroke capture, and strict isolation preventing private memories from leaking into exported personality profiles.
- **Multi-Character Social Behavior (Phase 9):**
  - Centralized `SocialInteractionManager` coordinating spontaneous social encounters between active desktop companions.
  - Decoupled `SocialParticipant` protocol enabling headless state machine testing without GUI or AppKit window dependencies.
  - Physical feasibility checks: spatial distance filtering (60pt to 380pt range), vertical surface level verification (within 25pt on desktop floor or window ledge), upside-down menu mode matching, and rejection when companions are dragged or falling.
  - Personality-driven intent selection: highly sociable characters favor greetings and chats, energetic/playful companions perform playful hops, shy characters observe from a safe distance, and independent companions roam solo.
  - Sleeping companion policies: lazy/independent sleeping companions decline waking for casual encounters.
  - Multi-phase encounter lifecycle: initiating, approaching, interacting, and concluding with smooth physical disengagement (turning away and resuming normal movement).
  - Coordinated speech bubble exchanges with natural delays between greeting and reply.
  - Global and per-character social toggles, 40-second symmetric pair encounter cooldowns, and instant cancellation upon user interruption (drag, click, or dismissal).
- **Contextual Dialogue & Speech Bubble Engine (“The Mouth”):**
  - Integrated adaptive floating speech bubble panel (`SpeechBubblePanel`) with click-to-dismiss support that catches taps on the speech bubble while cleanly passing through background clicks outside the bubble.
  - Adaptive pointer positioning that dynamically detects top screen margins and flips pointer orientation (`.up`) to place speech bubbles below pets when clearance above is constrained.
  - New event-driven dialogue triggers: falling, landing/touchdown, obstacle/ledge encounters, dynamic music track playback, and user returned from inactivity.
  - Curated dialogue library pools across 8 distinct personality tones (Neutral, Curious, Sleepy, Shy, Playful, Cheerful, Sarcastic, Supportive) for physics collisions, ledges, music, and return greetings.
  - Per-character dialogue muting toggle (`dialogueMuted`) in `CharacterBehaviorPreferences` and the Workshop/Library settings view.
  - Stale context suppression discarding event triggers older than 5.0 seconds to prevent conversational bursts upon wake or resume.
  - Full synchronization with Phase 6 personality matrix traits and topic preferences.
- **Personality Matrix (10 Dimensions):**
  - Expanded personality model with 10 normalized traits: Energetic, Lazy, Curious, Playful, Sarcastic, Supportive, Shy, Sociable, Mischievous, and Independent.
  - Added new personality archetype presets: Playful, Calm, Sarcastic, and Supportive, alongside existing presets.
- **Interests, Likes & Dislikes System:**
  - Configurable topic preferences across Coding, Gaming, Music, Art, Anime, Study, and Relaxation.
  - Differentiates between Liking, Interested, Disliking, and Neutral preferences.
  - Automatically correlates with detected application context, visual activities, and music playback.
- **Behavioral Boundaries & Preferences:**
  - Per-character preferences for cursor following (with master enable toggle and follow strength), sleep frequency, exploration tendency, and speech bubble comment frequency.
  - Precedence rules enforcing strict respect for user preferences over personality traits.
- **Behavior Preview & Test Simulator:**
  - Lightweight, deterministic simulation preview in SwiftUI displaying action tendency percentages, cursor responses, topic reactions, and voice sample dialogue without side effects on active desktop companions.
- **Community Profile Sharing & Version Migration:**
  - Versioned schema migration (Schema V1 -> V2) with safe backward compatibility and bounds clamping.
  - Local JSON export and sanitized import with validation rejecting embedded private data.

## [1.0.0] - 2026-10-28

### Added
- **Workshop & Creator Studio (Phase 11):**
  - Upgraded the Workshop into a comprehensive 4-tab Creator Studio: Magic Eraser, AI Generator, Shimeji DB, and Personality Preset Gallery.
  - Centralized `WorkshopConfiguration` establishing centrally configurable external endpoints (`aiEndpointTemplate`, `shimejiSearchEndpoint`), request timeouts (25s), maximum download size limits (50MB), and offline mode gates (`isOnlineDisabled`).
  - Enhanced Vision background removal engine (`VisionBackgroundRemover`) with memory-safe frame processing using `autoreleasepool`, cancellation support, and preservation of GIF properties (`kCGImagePropertyGIFDelayTime`, `kCGImagePropertyGIFUnclampedDelayTime`, `kCGImagePropertyGIFLoopCount`, `kCGImagePropertyGIFHasGlobalColorMap`).
  - Robust import and signature verification (`WorkshopImportValidator`): validates file magic bytes (`\x89PNG\r\n\x1a\n`, `GIF87a`/`GIF89a`, `\xFF\xD8\xFF`, `RIFF...WEBP`, `ftyp`) rather than relying solely on file extensions.
  - Strict security and path traversal prevention stripping directory traversal patterns (`../`, `..\`), root slashes, colons, null bytes, and illegal shell characters, with snake_case normalization.
  - Community attribution and metadata sidecars (`CommunityAssetAttribution`): automatically persists `<companion>.meta.json` sidecars capturing author, uploader, source URL, license, and import date.
  - Decoupling of personality profiles and artwork (`PersonalityDecoupler`): updating companion artwork (`updateArtwork`) rebinds the character ID without altering existing traits, topic preferences, or memories; applying personality presets (`applyPreset`) updates the personality matrix without modifying sprite or animation assets.
  - Dedicated Personality Preset Gallery: interactive visual browser for all 10 archetypes (Curious, Sleepy, Playful, Shy, Mischievous, Calm, Energetic, Sarcastic, Supportive, Balanced) with trait breakdowns, sample voice lines, and 1-click application to any library companion.
  - Transparent canvas preview with checkerboard background pattern and explicit privacy/network status badges on every tool (`[Offline Local AI]`, `[Offline Local]`, `[Remote Cloud API]`, `[Remote Community API]`).
- **Productivity Companion & Focus Sessions (Phase 10):**
  - Centralized `ProductivityTimerManager` engine supporting quick countdown timers (5m, 15m, 30m, 60m), classic Pomodoro (25m focus / 5m break), Long Focus (50m focus / 10m break), and custom user-defined focus and break intervals.
  - Wall-clock deadline calculations (`targetDeadline`) preventing countdown drift across Mac sleep, wake, app backgrounding, and system stalls.
  - Unique generation ID tracking (`generationId`) ensuring cancelled or restarted timers cannot receive stale notification callbacks or trigger duplicate completion alerts.
  - System sleep/wake observer (`NSWorkspace.didWakeNotification`) that gracefully recomputes remaining session intervals and triggers completion if the deadline elapsed during sleep.
  - Session state persistence in `UserDefaults` (`com.dev.Animatto.productivity_session`) allowing countdown restoration or graceful completion across app termination and relaunch.
  - Native macOS user notifications via `UNUserNotificationCenter` with sound chimes and deterministic injectable test handlers for headless environments.
  - Full companion behavioral integration: configurable companion focus behavior (`FocusCompanionBehavior`) enabling companions to sleep quietly, sit idle, or maintain normal movement during active focus sessions.
  - Automatic companion wake-up on break start, celebratory hopping celebration on session completion, and focus-appropriate contextual dialogue triggers (`.focusStarted`, `.breakStarted`, `.timerFinished`).
  - Distraction suppression: spontaneous idle chatter and spontaneous multi-character social encounters are automatically suspended during active focus sessions, while direct user interactions (clicks, drags) remain responsive.
  - Productivity controls integrated across the app: sleek menu bar dashboard section with quick-start buttons, progress bar, and lifecycle controls (pause, resume, skip, stop, restart); pet desktop context menu with live countdown and timer actions; and comprehensive settings configuration section.
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

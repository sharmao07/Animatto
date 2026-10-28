# Animatto — Master Development Checklist

**Purpose:** Evolve Animatto from a physics-driven macOS desktop pet into a customizable, privacy-conscious companion for Shimejis, anime characters, pixel-art sprites, GIFs, and other supported characters. Its characters should have distinct personalities, habits, preferences, memories, and contextual reactions.

Check items only after implementation and verification. macOS-specific features must be tested on a Mac before being marked complete.

## Phase 0 — Branding, project hygiene, and baseline
- [x] Rename KinetiPet to Animatto across applicable source, configuration, UI, documentation, and release assets.
- [x] Update project/target/scheme/product/display names where appropriate.
- [x] Decide whether the bundle identifier should remain stable; document consequences before changing it.
- [x] Preserve existing imported characters and settings during storage/preferences migration.
- [x] Keep legacy storage paths where needed for migration.
- [x] Update README, setup instructions, badges, release notes, and project structure.
- [x] Make the README license statement match the actual LICENSE file without changing license terms accidentally.
- [x] Review external GitHub/Vercel URLs before changing them; do not break deployed services.
- [x] Search old product-name variants in text files and inspect screenshots/videos/icons for old branding.
- [x] Remove duplicate/obsolete project files without deleting real features.
- [x] Establish a clean Git state and safe branch/commit point.
- [x] Record current app version, supported macOS version, build settings, and known issues.

## Phase 1 — Stabilize the existing macOS app
- [x] Build in Xcode on macOS and record the actual result.
- [x] Fix random-event-frequency scale mismatch.
- [x] Verify gravity, walking speed, event frequency, spawn size, and accent color persist correctly.
- [x] Verify PNG/GIF import, library listing, previews, and pet launching.
- [x] Make supported-media types consistent across importing, storage, previews, and spawning.
- [x] Decide whether JPEG/JPG are supported and make them work end-to-end if so.
- [x] Decide whether MP4/MOV are supported and connect/test the video renderer if so; otherwise remove misleading options.
- [x] Verify GIF animation does not reset during UI updates.
- [x] Verify sprites do not clip or squash at different sizes/aspect ratios.
- [x] Test dragging, window closing, repeated spawning, and memory/resource cleanup.
- [x] Verify gravity, edge turnaround, floor/window collisions, and menu-bar walking.
- [x] Test multiple displays, Spaces, fullscreen apps, and resolution changes where supported.
- [x] Align deployment target and documentation with APIs actually used.
- [x] Connect Discord Rich Presence, music monitoring, and Launch at Login to real implementations or disable/remove their controls until ready.
- [x] Implement or remove placeholder controls such as Clear Cache and Mute Audio.
- [x] Verify timers, alerts, and menu-bar controls work end-to-end.
- [x] Test missing apps, permissions, socket failures, and integration disconnections.
- [x] Add unit tests for settings conversion, storage, and testable logic; document checks requiring macOS.

## Phase 2 — Personality and behavior engine
### Personality profiles
- [x] Create a versioned `PersonalityProfile` model for each character.
- [x] Add normalized traits (0.0–1.0), e.g. curiosity, energy, laziness, playfulness, sociability, mischief, shyness, supportiveness, and attention-seeking.
- [x] Create safe default profiles for characters without custom settings.
- [x] Store personality separately from art assets.
- [x] Add edit, reset, duplicate, export, and import controls.
- [x] Add presets such as Curious, Sleepy, Playful, Shy, Mischievous, Calm, and Energetic.
- [x] Version profiles and support safe migration.
### Internal needs and mood
- [x] Add energy, boredom, curiosity, social interest, and mood.
- [x] Define how actions change needs (activity uses energy, rest restores it, etc.).
- [x] Bound state values and prevent runaway behavior loops.
- [x] Define what resets on launch and what persists.
### Action selection
- [x] Build a `BehaviorEngine` that selects goals/actions separately from physics.
- [x] Evaluate walking, exploring, approaching, observing, playing, sitting, idling, sleeping, reacting, and speaking.
- [x] Score actions from traits, needs, events, context, and cooldowns instead of relying only on random rolls.
- [x] Add action history, cooldowns, behavior durations, and interruption rules.
- [x] Check physical feasibility before selecting an action.
- [x] Keep the existing physics engine responsible for executing movement.
- [x] Ensure basic behavior works offline without AI/network access.
- [x] Add privacy-safe diagnostics explaining why actions were chosen.
- [x] Test that different profiles produce noticeably different behavior.

## Phase 3 — Lightweight environmental awareness (“The Eyes”)
- [x] Create an `EnvironmentMonitor` that converts supported system/user events into a unified event model.
- [x] Detect app activation changes where supported by macOS APIs.
- [x] Investigate focused-window titles/events and handle unavailable data gracefully.
- [x] Observe character clicks, dragging, dropping, collisions, falls, ledge encounters, spawning, and dismissal.
- [x] Observe cursor proximity without excessive polling.
- [x] Track idle duration using a privacy-conscious, configurable approach.
- [x] Observe music changes only when music reactivity is enabled and available.
- [x] Debounce events and rate-limit noisy sources.
- [x] Use minimized event labels such as `AppActivated`, `UserReturned`, and `CharacterDragged`.
- [x] Make app/environment awareness optional and explain what is observed.
- [x] Let personalities react differently to the same event.
- [x] Add configurable event categories and avoid interruptions during focus-critical activities.

## Phase 4 — Visual screen awareness (“The Eyes”, visual mode)
- [x] Research/prototype ScreenCaptureKit on supported macOS versions.
- [x] Request screen-recording permission through the official macOS flow.
- [x] Explain what is captured, when analysis runs, and whether content leaves the Mac.
- [x] Make visual analysis opt-in, visibly active, and easy to pause/disable.
- [x] Add application exclusions and avoid protected/sensitive content where feasible.
- [x] Capture only when needed; use minimal resolution/content and do not retain screenshots by default.
- [x] Define the first supported observations and avoid overstating visual understanding.
- [x] Evaluate local computer vision before adding a multimodal model.
- [x] Add confidence thresholds and safe fallbacks.
- [x] Prevent duplicate comments without retaining the underlying screenshot.
- [x] Clearly handle unsupported surfaces and protected content.

## Phase 5 — LLM engine (“The Brain”)
- [x] Define a provider interface so models can be swapped without coupling the behavior engine to one vendor.
- [x] Provide rule-based/offline fallback when AI is unavailable.
- [x] Keep inference off the physics timer and UI thread; add timeouts and cancellation.
- [x] Send only the minimum sanitized context needed.
### Cloud option
- [x] Evaluate providers for cost, latency, image capability, privacy terms, reliability, and availability.
- [x] Require explicit consent before sending screen-derived content to a cloud provider.
- [x] If users provide their own API keys, store them securely; never ship a shared secret in the app.
- [x] Add visible cloud-request indicators, rate limits, and graceful quota/network failures.
### Local option
- [x] Evaluate suitable quantized language/vision-language models for Apple Silicon and supported hardware.
- [x] Benchmark RAM, latency, startup time, battery, and thermal behavior.
- [x] Make local model installation, storage, updates, and removal understandable.
- [x] Keep the app usable if the model is unavailable.
### Output safeguards
- [x] Validate model outputs against an approved set of actions and bounded parameters.
- [x] Sanitize generated speech-bubble text.
- [x] Treat screen text/window titles as untrusted data, not instructions.
- [x] Never allow generated text to run shell commands, click controls, or take system actions.

## Phase 6 — Personality matrix and preferences
- [x] Add trait controls for Energetic, Lazy, Curious, Playful, Sarcastic, Supportive, Shy, Sociable, Mischievous, and Independent.
- [x] Add user-defined likes/dislikes/interests such as coding, gaming, music, art, anime, or study time.
- [x] Map app categories to reactions only when app awareness is enabled.
- [x] Add per-character controls for cursor following, attention-seeking, sleep frequency, exploration, and comment frequency.
- [x] Ensure preferences consistently influence action scoring and dialogue.
- [x] Explain traits and provide a behavior preview/test mode.
- [x] Support profile export/import and community sharing without private memory by default.

## Phase 7 — Speech bubbles and dialogue (“The Mouth”)
### UI
- [x] Build a lightweight floating bubble positioned relative to each character.
- [x] Keep it readable across themes/display scales and within screen bounds.
- [x] Avoid stealing focus or blocking mouse interaction.
- [x] Support short text, auto-dismissal, accessible contrast, and manual dismissal.
- [x] Test movement between displays/Spaces and prevent clipping.
### Dialogue
- [x] Add character-specific dialogue for waking, sleeping, falling, exploring, clicks, drags, social encounters, and other events.
- [x] Prefer contextual rules before requesting AI-generated dialogue.
- [x] Keep AI comments short, relevant, and personality-consistent.
- [x] Add global and per-character cooldowns, duplicate-line suppression, and frequency controls.
- [x] Add Quiet Mode, mute-dialogue controls, and settings for AI dialogue.
- [x] Avoid interruptions during fullscreen games, presentations, and focus sessions by default.
### Triggers
- [x] Support optional reactions to app changes, long inactivity, pet interactions, user return, and social encounters.
- [x] Use conservative defaults so the companion remains pleasant rather than distracting.

## Phase 8 — Character memory and continuity
- [x] Define which memories are useful and allowed.
- [x] Store locally in a reliable format such as SQLite or versioned structured files.
- [x] Separate stable personality, short-term event history, and learned/user-approved preferences.
- [x] Retain useful settings without storing unnecessary personal activity.
- [x] Limit transient history and delete it automatically when appropriate.
- [x] Provide per-character view/edit where appropriate, reset, disable, and delete controls.
- [x] Migrate memory safely across updates.
- [x] Do not store screenshots/raw screen content by default.
- [x] Keep personality export separate from private memory.
- [x] Explain local storage and any AI-provider data sharing.

## Phase 9 — Multi-character social behavior
- [x] Build a `SocialInteractionManager` for nearby-character events.
- [x] Detect feasible encounters based on position and supported surfaces.
- [x] Add greetings, approaching/facing, play, and disengagement.
- [x] Use personality traits such as sociability, shyness, energy, and mischief.
- [x] Prevent endless loops with cooldowns and interruption rules.
- [x] Make basic interactions work offline without an LLM.
- [x] Add optional speech-bubble exchanges.
- [ ] Consider familiarity/relationship values only after basic interaction works.
- [x] Ensure characters can always be paused, dismissed, or separated easily.

## Phase 10 — Productivity companion
- [ ] Verify the existing 5/15/30/60-minute timers and alerts.
- [ ] Define timer notification, animation, sound, and speech behavior.
- [ ] Add Pomodoro presets and custom focus/break durations.
- [ ] Let pets sleep/be quiet during focus and wake/play during breaks.
- [ ] Add pause, resume, skip, and stop controls.
- [ ] Handle app restarts and sleep/wake without stale alerts.
- [ ] Keep productivity optional and non-obstructive.

## Phase 11 — Workshop and creator experience
- [ ] Verify Vision background removal for still images and supported GIF frames.
- [ ] Verify AI image generation and label cloud processing clearly.
- [ ] Verify Shimeji search, preview, and downloads against the deployed service.
- [ ] Handle outages, malformed responses, blocked downloads, and unsupported media.
- [ ] Keep external URLs centrally configurable where appropriate.
- [ ] Improve import validation and errors.
- [ ] Preserve transparency, animation, and image dimensions.
- [ ] Include attribution/source metadata for community assets where possible.
- [ ] Associate personality profiles with characters separately from sprites.
- [ ] Add a preset/profile gallery and document local vs. online operations.

## Phase 12 — In-app updater and release quality
- [ ] Define version and release-tag conventions.
- [ ] Query GitHub Releases with timeouts and error handling.
- [ ] Compare installed and remote versions correctly.
- [ ] Avoid repeated prompts after dismissal.
- [ ] Show release notes and official download links.
- [ ] Use HTTPS and verify download sources.
- [ ] Do not silently replace the app with an unverified binary.
- [ ] Decide between opening the release page, downloading a DMG, or using a dedicated updater.
- [ ] Test offline mode, rate limits, prereleases, and version parsing.
- [ ] Establish repeatable build/archive/sign/package/release steps.
- [ ] Complete app icon and release assets.
- [ ] Test distributed builds on supported macOS versions and a clean account.
- [ ] Document signing, notarization, and first-launch prompts accurately.

## Phase 13 — Windows and Linux
- [ ] Specify portable behavior/physics requirements separately from Apple APIs.
- [ ] Prototype a Tauri 2 transparent/frameless companion window.
- [ ] Validate always-on-top, input handling, multi-monitor, and OS limitations.
- [ ] Design a Rust backend for safe native windowing and a TypeScript behavior/animation frontend.
- [ ] Separate portable personality logic from platform adapters.
- [ ] Port physics, action selection, needs, cooldowns, and profiles.
- [ ] Define cross-platform asset/animation support.
- [ ] Test Linux desktop-environment differences and Windows fullscreen/multimonitor behavior.
- [ ] Document platform-specific limitations.
- [ ] Wait until macOS behavior interfaces are stable before a full rewrite.

## Phase 14 — Optional premium tier and licensing
- [ ] Decide whether premium is needed and define free/premium boundaries.
- [ ] Keep core movement, basic personality profiles, and user-owned characters usable without payment where possible.
- [ ] Define entitlements before implementing purchases.
- [ ] Evaluate current providers/terms for Lemon Squeezy, Gumroad, or alternatives.
- [ ] Implement license entry, validation, activation limits, deactivation, and recovery.
- [ ] Validate licenses server-side; do not trust a client-side boolean as authorization.
- [ ] Never ship provider secrets in the app.
- [ ] Handle offline use and licensing outages fairly.
- [ ] Explain expiry behavior and preserve user data.
- [ ] Test invalid/revoked keys, duplicate activations, outages, and clock changes.
- [ ] Keep monetization separate from stabilization and core personality work.

## Phase 15 — Privacy, security, and reliability
- [ ] Publish a plain-language explanation of environmental awareness and screen analysis.
- [ ] Make screen capture, AI analysis, cloud requests, memory, and dialogue controls separately configurable where possible.
- [ ] Request permissions only for enabled features.
- [ ] Minimize captured/transmitted data and avoid retaining raw screenshots.
- [ ] Validate downloaded files, network responses, file sizes, and types.
- [ ] Keep API credentials out of source, logs, and build artifacts.
- [ ] Constrain AI-generated text and actions to approved capabilities.
- [ ] Prevent AI output from executing commands or system actions.
- [ ] Review sandboxing and permissions and document deliberate exceptions.
- [ ] Test repeated launches, dismissals, sleep/wake, network loss, and termination.
- [ ] Provide a quick way to pause all pets and disable monitoring.
- [ ] Keep core movement/animation working when AI is off or unavailable.

## Phase 16 — Testing, documentation, and community
- [ ] Create test plans for physics, personality, event handling, dialogue cooldowns, and memory.
- [ ] Unit-test action scoring, cooldowns, event debouncing, migrations, and profile serialization.
- [ ] Compare multiple profiles under the same sequence of events.
- [ ] Verify no screen data is captured/transmitted while awareness is disabled.
- [ ] Test cloud/local AI failure and fallback behavior.
- [ ] Test display scales, multiple monitors, Spaces, and fullscreen apps.
- [ ] Record a real demo with only verified features.
- [ ] Update architecture, installation, privacy, screenshots, and known issues in documentation.
- [ ] Separate implemented features from planned/experimental features.
- [x] Publish sample profiles and community contribution instructions.
- [x] Create a privacy-safe bug-report template and maintain a changelog.

## Phase 17 — Ambient Worlds and Weather-Reactive Companions

### A. Ambient environment engine

- [ ] Create an independent, efficient ambient rendering system.
- [ ] Add toggleable rain, snow, fog, sunlight, wind, and falling-leaf effects.
- [ ] Support adjustable intensity, particle density, speed, and visual quality where appropriate.
- [ ] Support foreground/background depth variation through particle size, opacity, movement speed, and blur.
- [ ] Provide smooth transitions between environment types.
- [ ] Support multiple displays and handle resolution changes, Spaces, and fullscreen limitations.
- [ ] Preserve desktop click-through behavior and existing pet interaction, dragging, physics, and menu-bar walking.
- [ ] Provide immediate hide, pause, and disable controls.
- [ ] Keep the ambient renderer independent of the high-frequency pet physics loop.
- [ ] Make manually selected environments work entirely offline.

### B. Weather-reactive companions

- [ ] Add supported ambient-condition events to the existing environmental event system.
- [ ] Integrate weather reactions into the existing `BehaviorEngine` and personality system.
- [ ] Let personality traits influence responses to rain, snow, sunlight, fog, wind, and leaves.
- [ ] Allow characters to investigate or interact with selected environmental effects when physically feasible.
- [ ] Add optional, contextual weather-related dialogue through the existing speech-bubble system.
- [ ] Respect personality preferences, action cooldowns, Quiet Mode, dialogue mute settings, and focus protections.
- [ ] Ensure characters continue behaving normally when ambient effects are disabled.
- [ ] Integrate with existing multi-character social behavior without duplicating Phase 9 systems.
- [ ] Prevent noisy environment events from causing repetitive actions or excessive dialogue.

### C. Optional desktop collectible minigame

- [ ] Add an optional collectible system with original assets, such as leaves, snow crystals, stars, or small ambient creatures.
- [ ] Support configurable spawn intervals, rarity, and safe spawn limits.
- [ ] Provide a working collection interaction and scoring system.
- [ ] Optionally support collection boxes, rarity-based scoring, and collection progress.
- [ ] Allow participating companions to interact with collectibles through the existing behavior and physics systems.
- [ ] Add session start/stop, reset, and disable controls.
- [ ] Ensure the minigame remains completely optional and does not interrupt ordinary desktop use.
- [ ] Preserve appropriate collection progress without allowing unbounded data growth.
- [ ] Consider cosmetic unlocks and collectible achievements without introducing monetization or paid currencies.

### D. Live weather synchronization and inverse mode

- [ ] Research suitable weather-data providers, current terms, request limits, pricing, and attribution requirements before selecting a provider.
- [ ] Define a replaceable weather-provider interface.
- [ ] Allow users to enter or select a location manually.
- [ ] Keep manual weather selection available without network access.
- [ ] Map supported real-world weather conditions to the available ambient environments.
- [ ] Add an optional inverse mode that maps external conditions to a contrasting ambience.
- [ ] Make inverse mappings predictable, documented, and configurable where appropriate.
- [ ] Add refresh limits, timeouts, error handling, caching, and offline fallback.
- [ ] Display whether the current ambience is manually selected or weather-synchronized.
- [ ] Explain location data usage and provide controls to disable synchronization and clear saved location information.
- [ ] Avoid unnecessary location permissions and continuous location tracking.

### E. Atmosphere presets and custom moods

- [ ] Create reusable, versioned atmosphere presets.
- [ ] Provide built-in presets such as Rainy Evening, First Snow, Autumn Window, Golden Morning, Quiet Night, and Misty Forest.
- [ ] Let users adjust environment settings and save their own presets.
- [ ] Support preset loading, validation, reset, deletion, and safe migration.
- [ ] Allow presets to configure environment type, intensity, visual quality, wind, and permitted companion reactions where appropriate.
- [ ] Add optional time-based ambience scheduling, disabled by default.
- [ ] Allow manual overrides of automatically selected presets.
- [ ] Keep presets independent of private character memory and artwork.

### F. Performance and accessibility

- [ ] Add Low Power, Balanced, and High Quality modes.
- [ ] Adjust particle density, rendering complexity, and update frequency according to the selected quality.
- [ ] Bound particle counts and memory usage.
- [ ] Pause or reduce unnecessary rendering when effects are hidden or inactive.
- [ ] Avoid blocking the UI and physics loop.
- [ ] Test for resource leaks during repeated environment changes and app termination.
- [ ] Add reduced-motion support and respect supported macOS accessibility preferences.
- [ ] Avoid flashing, strobe-like effects, excessive brightness, and obstruction of application content.
- [ ] Provide keyboard-accessible settings, clear labels, readable contrast, and accessible game feedback.
- [ ] Preserve click-through interaction with underlying applications.

### G. Localization

- [ ] Extend the existing localization architecture for the new features.
- [ ] Localize environment names, preset names, settings, descriptions, minigame instructions, scores, errors, and accessibility labels.
- [ ] Target 11 languages: English, Hindi, Japanese, Korean, Simplified Chinese, Traditional Chinese, Spanish, French, German, Italian, and Brazilian Portuguese.
- [ ] Use proper localization resources and native date/number formatting.
- [ ] Handle text expansion and missing translations gracefully.
- [ ] Never mark a language complete when its strings have merely been copied from English.

### H. Community atmosphere packs

- [ ] Define a versioned, file-based atmosphere-pack format.
- [ ] Support importing and exporting compatible presets and optional artwork.
- [ ] Preserve source and licensing attribution when available.
- [ ] Validate schema versions, identifiers, media types, file sizes, and configuration ranges.
- [ ] Reject malformed or unsupported packs safely.
- [ ] Treat imported content as untrusted data and prohibit executable code or scripts.
- [ ] Provide safe removal of imported packs and their associated assets.
- [ ] Keep private character memory, credentials, personal location data, and activity history out of shared packs.
- [ ] Reuse the existing Workshop and profile-sharing architecture where practical.
- [ ] Keep accounts, hosted marketplaces, and cloud synchronization outside the initial scope.

### I. Testing, documentation, and integration

- [ ] Test environment selection, rendering controls, particle limits, transitions, and cleanup.
- [ ] Test weather-event integration with personalities, behavior selection, and dialogue cooldowns.
- [ ] Test minigame spawning, collection, scoring, session lifecycle, and persistence.
- [ ] Test live-weather mapping, inverse mode, offline fallback, refresh limits, and location clearing.
- [ ] Test preset serialization, migration, and malformed atmosphere-pack imports.
- [ ] Test reduced-motion behavior, quality modes, and disabled ambient effects.
- [ ] Regression-test dragging, physics, multiple characters, social interactions, speech bubbles, and existing preferences.
- [ ] Verify multiple displays, fullscreen behavior, and click-through handling on macOS.
- [ ] Update architecture, privacy, installation, and user documentation to reflect only verified functionality.
- [ ] Keep manual weather selection usable without network access.
- [ ] Document features that require further macOS testing or remain incomplete.

## Recommended order
1. Branding and baseline cleanup.
2. Stabilize and test the existing macOS app.
3. Implement personality profiles and local weighted behavior selection.
4. Add lightweight event-based environmental awareness.
5. Add speech bubbles and rule-based, character-specific dialogue with cooldowns.
6. Add local memory and personality export/import.
7. Add optional ScreenCaptureKit visual awareness with consent and exclusions.
8. Add a model-provider interface and benchmark local/cloud options.
9. Add multi-character social interactions.
10. Add ambient worlds and weather-reactive companions.
11. Improve productivity, Workshop reliability, updater, and releases.
12. Prototype Windows/Linux after portable behavior interfaces stabilize.
13. Evaluate licensing after the core experience is reliable.

## Design principles
- Characters have recognizable differences, not merely different random probabilities.
- Core movement and personality work offline without an LLM.
- AI enriches decisions and dialogue but does not run every physics tick.
- Screen awareness is opt-in, visible, limited, and privacy-conscious.
- Cooldowns prevent constant or repeated dialogue.
- Users can pause, dismiss, mute, reset memory, and disable monitoring anytime.
- Personality data is portable, versioned, and separate from artwork.
- Implement and verify one phase at a time; do not claim untested functionality.

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
- [ ] Fix random-event-frequency scale mismatch.
- [ ] Verify gravity, walking speed, event frequency, spawn size, and accent color persist correctly.
- [ ] Verify PNG/GIF import, library listing, previews, and pet launching.
- [ ] Make supported-media types consistent across importing, storage, previews, and spawning.
- [ ] Decide whether JPEG/JPG are supported and make them work end-to-end if so.
- [ ] Decide whether MP4/MOV are supported and connect/test the video renderer if so; otherwise remove misleading options.
- [ ] Verify GIF animation does not reset during UI updates.
- [ ] Verify sprites do not clip or squash at different sizes/aspect ratios.
- [ ] Test dragging, window closing, repeated spawning, and memory/resource cleanup.
- [ ] Verify gravity, edge turnaround, floor/window collisions, and menu-bar walking.
- [ ] Test multiple displays, Spaces, fullscreen apps, and resolution changes where supported.
- [ ] Align deployment target and documentation with APIs actually used.
- [ ] Connect Discord Rich Presence, music monitoring, and Launch at Login to real implementations or disable/remove their controls until ready.
- [ ] Implement or remove placeholder controls such as Clear Cache and Mute Audio.
- [ ] Verify timers, alerts, and menu-bar controls work end-to-end.
- [ ] Test missing apps, permissions, socket failures, and integration disconnections.
- [ ] Add unit tests for settings conversion, storage, and testable logic; document checks requiring macOS.

## Phase 2 — Personality and behavior engine
### Personality profiles
- [ ] Create a versioned `PersonalityProfile` model for each character.
- [ ] Add normalized traits (0.0–1.0), e.g. curiosity, energy, laziness, playfulness, sociability, mischief, shyness, supportiveness, and attention-seeking.
- [ ] Create safe default profiles for characters without custom settings.
- [ ] Store personality separately from art assets.
- [ ] Add edit, reset, duplicate, export, and import controls.
- [ ] Add presets such as Curious, Sleepy, Playful, Shy, Mischievous, Calm, and Energetic.
- [ ] Version profiles and support safe migration.
### Internal needs and mood
- [ ] Add energy, boredom, curiosity, social interest, and mood.
- [ ] Define how actions change needs (activity uses energy, rest restores it, etc.).
- [ ] Bound state values and prevent runaway behavior loops.
- [ ] Define what resets on launch and what persists.
### Action selection
- [ ] Build a `BehaviorEngine` that selects goals/actions separately from physics.
- [ ] Evaluate walking, exploring, approaching, observing, playing, sitting, idling, sleeping, reacting, and speaking.
- [ ] Score actions from traits, needs, events, context, and cooldowns instead of relying only on random rolls.
- [ ] Add action history, cooldowns, behavior durations, and interruption rules.
- [ ] Check physical feasibility before selecting an action.
- [ ] Keep the existing physics engine responsible for executing movement.
- [ ] Ensure basic behavior works offline without AI/network access.
- [ ] Add privacy-safe diagnostics explaining why actions were chosen.
- [ ] Test that different profiles produce noticeably different behavior.

## Phase 3 — Lightweight environmental awareness (“The Eyes”)
- [ ] Create an `EnvironmentMonitor` that converts supported system/user events into a unified event model.
- [ ] Detect app activation changes where supported by macOS APIs.
- [ ] Investigate focused-window titles/events and handle unavailable data gracefully.
- [ ] Observe character clicks, dragging, dropping, collisions, falls, ledge encounters, spawning, and dismissal.
- [ ] Observe cursor proximity without excessive polling.
- [ ] Track idle duration using a privacy-conscious, configurable approach.
- [ ] Observe music changes only when music reactivity is enabled and available.
- [ ] Debounce events and rate-limit noisy sources.
- [ ] Use minimized event labels such as `AppActivated`, `UserReturned`, and `CharacterDragged`.
- [ ] Make app/environment awareness optional and explain what is observed.
- [ ] Let personalities react differently to the same event.
- [ ] Add configurable event categories and avoid interruptions during focus-critical activities.

## Phase 4 — Visual screen awareness (“The Eyes”, visual mode)
- [ ] Research/prototype ScreenCaptureKit on supported macOS versions.
- [ ] Request screen-recording permission through the official macOS flow.
- [ ] Explain what is captured, when analysis runs, and whether content leaves the Mac.
- [ ] Make visual analysis opt-in, visibly active, and easy to pause/disable.
- [ ] Add application exclusions and avoid protected/sensitive content where feasible.
- [ ] Capture only when needed; use minimal resolution/content and do not retain screenshots by default.
- [ ] Define the first supported observations and avoid overstating visual understanding.
- [ ] Evaluate local computer vision before adding a multimodal model.
- [ ] Add confidence thresholds and safe fallbacks.
- [ ] Prevent duplicate comments without retaining the underlying screenshot.
- [ ] Clearly handle unsupported surfaces and protected content.

## Phase 5 — LLM engine (“The Brain”)
- [ ] Define a provider interface so models can be swapped without coupling the behavior engine to one vendor.
- [ ] Provide rule-based/offline fallback when AI is unavailable.
- [ ] Keep inference off the physics timer and UI thread; add timeouts and cancellation.
- [ ] Send only the minimum sanitized context needed.
### Cloud option
- [ ] Evaluate providers for cost, latency, image capability, privacy terms, reliability, and availability.
- [ ] Require explicit consent before sending screen-derived content to a cloud provider.
- [ ] If users provide their own API keys, store them securely; never ship a shared secret in the app.
- [ ] Add visible cloud-request indicators, rate limits, and graceful quota/network failures.
### Local option
- [ ] Evaluate suitable quantized language/vision-language models for Apple Silicon and supported hardware.
- [ ] Benchmark RAM, latency, startup time, battery, and thermal behavior.
- [ ] Make local model installation, storage, updates, and removal understandable.
- [ ] Keep the app usable if the model is unavailable.
### Output safeguards
- [ ] Validate model outputs against an approved set of actions and bounded parameters.
- [ ] Sanitize generated speech-bubble text.
- [ ] Treat screen text/window titles as untrusted data, not instructions.
- [ ] Never allow generated text to run shell commands, click controls, or take system actions.

## Phase 6 — Personality matrix and preferences
- [ ] Add trait controls for Energetic, Lazy, Curious, Playful, Sarcastic, Supportive, Shy, Sociable, Mischievous, and Independent.
- [ ] Add user-defined likes/dislikes/interests such as coding, gaming, music, art, anime, or study time.
- [ ] Map app categories to reactions only when app awareness is enabled.
- [ ] Add per-character controls for cursor following, attention-seeking, sleep frequency, exploration, and comment frequency.
- [ ] Ensure preferences consistently influence action scoring and dialogue.
- [ ] Explain traits and provide a behavior preview/test mode.
- [ ] Support profile export/import and community sharing without private memory by default.

## Phase 7 — Speech bubbles and dialogue (“The Mouth”)
### UI
- [ ] Build a lightweight floating bubble positioned relative to each character.
- [ ] Keep it readable across themes/display scales and within screen bounds.
- [ ] Avoid stealing focus or blocking mouse interaction.
- [ ] Support short text, auto-dismissal, accessible contrast, and manual dismissal.
- [ ] Test movement between displays/Spaces and prevent clipping.
### Dialogue
- [ ] Add character-specific dialogue for waking, sleeping, falling, exploring, clicks, drags, social encounters, and other events.
- [ ] Prefer contextual rules before requesting AI-generated dialogue.
- [ ] Keep AI comments short, relevant, and personality-consistent.
- [ ] Add global and per-character cooldowns, duplicate-line suppression, and frequency controls.
- [ ] Add Quiet Mode, mute-dialogue controls, and settings for AI dialogue.
- [ ] Avoid interruptions during fullscreen games, presentations, and focus sessions by default.
### Triggers
- [ ] Support optional reactions to app changes, long inactivity, pet interactions, user return, and social encounters.
- [ ] Use conservative defaults so the companion remains pleasant rather than distracting.

## Phase 8 — Character memory and continuity
- [ ] Define which memories are useful and allowed.
- [ ] Store locally in a reliable format such as SQLite or versioned structured files.
- [ ] Separate stable personality, short-term event history, and learned/user-approved preferences.
- [ ] Retain useful settings without storing unnecessary personal activity.
- [ ] Limit transient history and delete it automatically when appropriate.
- [ ] Provide per-character view/edit where appropriate, reset, disable, and delete controls.
- [ ] Migrate memory safely across updates.
- [ ] Do not store screenshots/raw screen content by default.
- [ ] Keep personality export separate from private memory.
- [ ] Explain local storage and any AI-provider data sharing.

## Phase 9 — Multi-character social behavior
- [ ] Build a `SocialInteractionManager` for nearby-character events.
- [ ] Detect feasible encounters based on position and supported surfaces.
- [ ] Add greetings, approaching/facing, play, and disengagement.
- [ ] Use personality traits such as sociability, shyness, energy, and mischief.
- [ ] Prevent endless loops with cooldowns and interruption rules.
- [ ] Make basic interactions work offline without an LLM.
- [ ] Add optional speech-bubble exchanges.
- [ ] Consider familiarity/relationship values only after basic interaction works.
- [ ] Ensure characters can always be paused, dismissed, or separated easily.

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
10. Improve productivity, Workshop reliability, updater, and releases.
11. Prototype Windows/Linux after portable behavior interfaces stabilize.
12. Evaluate licensing after the core experience is reliable.

## Design principles
- Characters have recognizable differences, not merely different random probabilities.
- Core movement and personality work offline without an LLM.
- AI enriches decisions and dialogue but does not run every physics tick.
- Screen awareness is opt-in, visible, limited, and privacy-conscious.
- Cooldowns prevent constant or repeated dialogue.
- Users can pause, dismiss, mute, reset memory, and disable monitoring anytime.
- Personality data is portable, versioned, and separate from artwork.
- Implement and verify one phase at a time; do not claim untested functionality.

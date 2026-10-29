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

Animatto's native macOS architecture is cleanly decoupled across distinct subsystems:

* **`AnimattoApp.swift`**: Application entry point and MenuBarExtra scene configuration.
* **`PetEngine.swift`**: Physics simulation engine, window-edge collision detection, gravity, bounce loop, and transparent `NSPanel` overlay controller.
* **`MainAppView.swift`**: Primary navigation, Character Library, Settings, and theme controls.
* **`AIToolsView.swift`**: Creative Workshop containing on-device Apple Vision segmentation (Magic Eraser), Cloud AI sprite generation, and community Shimeji DB integration.
* **`MenuBarDashboard.swift`**: Quick-access Menu Bar popover dashboard with physics toggles, audio mute, and window summoning.
* **`PersonalityModel.swift`**: Personality profiles, 10 archetype presets, topic preferences, and dynamic internal needs.
* **`BehaviorEngine.swift`**: Autonomous weighted action selection, action scoring, cooldowns, and repetition penalties.
* **`PersonalityStorage.swift`**: JSON profile persistence, Schema V2 migration, and forbidden-key sanitization.
* **`EnvironmentSystem.swift`**: Frontmost app monitoring, cursor proximity tracking with 50pt hysteresis, and inactivity events.
* **`DialogueSystem.swift`**: Speech bubble rendering, `DialogueSanitizer` (ANSI & control code stripping), and anti-spam cooldowns.
* **`ScreenAwarenessSystem.swift`**: ScreenCaptureKit desktop observation with explicit user consent gates and in-memory downscaling.
* **`CharacterMemoryStore.swift`**: Local transient and durable memory storage with TTL pruning and deduplication.
* **`SocialInteractionManager.swift`**: Multi-companion encounters, spatial feasibility, coordinated dialogue, and pair cooldowns.
* **`ProductivityTimerManager.swift`**: Focus and Pomodoro timers with wall-clock deadline recovery across sleep/wake cycles.
* **`WorkshopService.swift`**: Magic-byte signature verification, sidecar attribution preservation (`.meta.json`), and path traversal prevention.
* **`UpdateService.swift`**: SemVer 2.0 parser and GitHub Releases updater with domain restriction and Gatekeeper safety.
* **`EntitlementManager.swift`**: Open-source free tier guarantees, Keychain storage (`kSecClassGenericPassword`), and key redactor.
* **`AmbientEngine.swift`**: Atmospheric particle simulation, floating click-through overlay panel, and preset management.
* **`AmbientLocalization.swift`**: Genuine 11-language localized translations and fallback resolvers.
* **`AmbientMinigameManager.swift`**: Atmospheric collectible spawner, rarity multipliers, scoring, and persistence.
* **`WeatherSyncService.swift`**: Open-Meteo weather synchronization (zero API key), 15-minute rate-limiting, and inverse weather mode.
* **`AtmospherePackService.swift`**: File-based `.animattopack` export and import validation with strict 10MB bounds.
* **`SystemIntegrations.swift`**: Local Unix Domain Socket Discord RPC (`discord-ipc-0`) and AppleScript music playback observer.
* **`cross-platform/`**: Portable TypeScript behavior engine and isolated Tauri 2 companion prototype.

---

## Testing Your Changes

Before submitting a Pull Request, run all unit tests and static analysis checks:

```bash
# 1. Run headless fast unit test suite (884 passing assertions)
swiftc -DDEBUG -sdk $(xcrun --show-sdk-path) $(ls Animatto/*.swift | grep -v AnimattoApp.swift) Tests/AnimattoTests.swift -o /tmp/animatto_tests && /tmp/animatto_tests

# 2. Build and analyze Xcode project
xcodebuild -project Animatto.xcodeproj -scheme Animatto -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO clean build analyze
```

For complete details on test scenarios and deterministic fixtures, consult [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md).

---

## Community Asset Attribution & Sidecars

When contributing companion sprites, GIFs, or personality presets:
1. Ensure you possess the rights or appropriate open-source / creative commons license for any media.
2. Provide companion attribution metadata via the sidecar format (`<companion_name>.meta.json`):
   ```json
   {
     "name": "CompanionName",
     "uploader": "ContributorHandle",
     "sourceURL": "https://example.com/source",
     "license": "CC-BY-4.0"
   }
   ```
3. Never include executable scripts, shell commands, private credentials, or personal activity history in shared profiles.

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

---

## AI Contributor Attribution Policy

Animatto values transparency in software engineering. When generative AI coding tools materially contribute to the design, implementation, debugging, or testing of a feature or bug fix, we acknowledge them via Git commit trailers (`Co-authored-by:`), similar to how open-source projects credit pair programmers.

### Recognized AI Tool Formats

Only use verified or canonical trailer formats:

| AI Assistant / Tool | Recommended Git Trailer Format | Notes / GitHub Recognition |
|---|---|---|
| **OpenAI Codex** | `Co-authored-by: Codex <codex@openai.com>` | Resolves to official OpenAI account [`@codex`](https://github.com/codex) with avatar. |
| **OpenAI ChatGPT** | `Co-authored-by: ChatGPT <199175422+chatgpt-codex-connector[bot]@users.noreply.github.com>` | Resolves to official OpenAI GitHub App [`@chatgpt-codex-connector[bot]`](https://github.com/apps/chatgpt-codex-connector). |
| **Google Gemini** | `Co-authored-by: Google Gemini <200291788+gemini-code-assist@users.noreply.github.com>` | Resolves to official Google account [`@gemini-code-assist`](https://github.com/gemini-code-assist) with avatar. |
| **Google Antigravity** | `Co-authored-by: Google Antigravity <antigravity.git@gmail.com>` | Resolves to [`@antigravity-git`](https://github.com/antigravity-git) (Google Antigravity profile). Alternatively: `<google-antigravity@users.noreply.github.com>`. |

### Rules & Guidelines

1. **Human Authorship:** The human developer remains the primary commit author (`Author:` field). The AI tool is credited exclusively as a co-author via `Co-authored-by:`.
2. **Material Contribution Only:** Add trailers only when the tool materially wrote, refactored, or debugged code. Do not credit tools for trivial formatting or purely human-authored commits.
3. **Selective Credit:** Attribute only the specific tool(s) used for that change. Never batch-credit all four tools indiscriminately.
4. **Git Trailer Formatting:**
   - Place `Co-authored-by:` trailers at the very bottom of the commit message.
   - Separate the commit summary and body from the trailers with at least one blank line.
   - Do not leave blank lines between multiple trailer entries.
5. **PR Merge Survival (Squash and Merge):**
   - Animatto merges PRs into `main` using **Squash and Merge**.
   - When merging via GitHub UI or the GitHub CLI (`gh pr merge --squash`), ensure any `Co-authored-by:` lines are preserved in the final squash commit message body. GitHub will record the co-authors on the resulting `main` commit.
6. **No History Rewriting:** Never rewrite published Git history, force-push branches, or create empty/artificial commits solely to manipulate contributor graphs.

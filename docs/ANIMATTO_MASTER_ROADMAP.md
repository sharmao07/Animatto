# Animatto — Master Roadmap

**Status:** Planning document. No product code was changed to produce it.  
**Audit date:** 6 November 2026  
**Repository:** https://github.com/sharmao07/Animatto  
**Audited commit:** `fe5643b` (`main`, matches `origin/main`)  
**Working tree at audit:** clean, apart from this file

This roadmap is based on the git history, source, workflows, and a direct check of GitHub issues, releases, Actions, and Dependabot. Historical phase reports are treated as claims. Where this document repeats a number, it says whether that number was re-run here.

---

## 1. Executive summary

Animatto is a real native macOS companion, not a sketch. The Swift/AppKit engine, aquarium transformation, ambient particles, focus timers, Creator Studio, menu bar, and website previews are implemented in `main`. A local Debug build with Xcode 27.2 succeeded in this session, and the resulting app process stayed running. The website and the Tauri browser preview also ran.

It is not a publicly released product. The newest GitHub release is a pre-release nightly from 30 October 2026 (`nightly-20261031-0ba39a8`), which is older than Aquarium Mode, Phase 13, window-policy, and payments work. There is no Developer ID signature and no notarization. The bundle identifier is still `com.dev.Animatto`, and `DEVELOPMENT_TEAM` is unset. Hardened Runtime is enabled in the Xcode project, which is necessary and not sufficient.

`macOS Build & Analyze` on `main` is red. Run `42216300204` (6 November 2026) failed at **Build macOS Application** with exit code 65 on Xcode 16.2. Static analysis, unit tests, and packaging never started. The same tree compiled locally on Xcode 27.2. The supported compiler is therefore not the compiler CI uses.

The Swift suite was re-run locally: **2,126 assertions passed, 1 failed**. The failure is `dist/Animatto-v1.2.0.dmg must exist`. That file is not in the repository. README still says 1,621 and 884 passing assertions. Phase reports cite 2,105 and 2,130. None of those counts match this run.

Licensing is the other product decision that has to stop moving. `docs/MONETIZATION_DECISION.md` says to keep the app free and defer commerce. `docs/PRICING_AND_ENTITLEMENTS.md` and the app sell a story of Lifetime Pro at $3.99 and Founder Supporter at $5.99, and `EntitlementManager` gates sound, palettes, and aquarium options that already live in Apache-2.0 source. Checkout code defaults to Dodo test mode and the static pages do not link to `/api/checkout`. Live payments are not enabled. They should stay that way until the policy below is explicit.

**Recommended immediate work:** Phase 15, make `main` build in CI on one declared Xcode, and stop the unit suite from requiring a DMG that packaging has not produced yet.

---

## 2. Completed work verified from git

| Commit | What the history shows | What was re-checked |
|---|---|---|
| `6345972` | Phase 13 stability, display lifecycle, diagnostics | Commit is on `main`. The report's assertion count was not reproduced. |
| `bef273b` | Aquarium desktop window level and theme surfaces | `docs/WINDOWS_AND_UI_POLISH_REPORT.md` matches the commit message. Behavior was not re-tested on a second display or over a full-screen app. |
| `ba08ac0` | Dodo hosted checkout, webhook verification, test-mode default | `web/lib/dodo.js` defaults unknown environments to `test_mode`. `web/api/checkout.js` refuses `live_mode` unless `ENABLE_PRODUCTION_PAYMENTS=true`. Pages are tested to avoid linking `/api/checkout`. The backend suite was **not** re-run in this audit. |
| `a635924` | Vite bumped to `^6.4.5` | `cross-platform/tauri-app/package-lock.json` locks Vite **6.4.5**. |
| `fe5643b` | Docs claim 0 open Dependabot alerts | GitHub Dependabot API returned **0 open alerts** during this audit. |
| `7935e4a` and later release commits | Packaging script, release workflow, v1.2.0 notes | Script and workflow exist. They have not produced the release that GitHub currently lists. |

Also present and substantial, from reading the tree rather than the reports:

- Native modules under `Animatto/` for physics, behavior, memory, social interaction, aquarium, ambient worlds, weather, productivity, workshop, entitlements, updates, and menu bar.
- Website generator `web/tools/build-pages.js` and 13 static pages. Local page validation passed in the setup session that preceded this audit.
- Cross-platform TypeScript core. Its 14 assertions passed in that same session. The Tauri app is a Vite prototype. Rust is not installed on the audit machine, so `npm run tauri dev` was not run.
- Two workflows: `.github/workflows/macos-build.yml` and `.github/workflows/release.yml`. The release workflow knows how to import a Developer ID certificate and call `notarytool`, and it skips notarization when the certificate secret is absent.
- GitHub issues: `gh issue list` returned no open issues. Closed issues exist. Zero open issues means nobody has filed beta feedback. It does not mean the product has no defects.

---

## 3. Incomplete work and known limitations

### Verified in this audit

- CI on `main` does not compile with Xcode 16.2. The failed log ends in `Command SwiftCompile failed with a nonzero exit code`. The diagnostic line itself was not in the captured tail, so the exact Swift error is still unknown.
- Local unit tests fail on a missing release DMG, so a green compile would still leave CI red once the test step runs. `macos-build.yml` runs tests before `scripts/build-and-package.sh`.
- No `dist/` artifact is checked in. Phase 13's report names `dist/Animatto-v1.2.0.dmg` and a SHA-256. That file is absent here.
- The only GitHub release is `Animatto Nightly — 2026-10-31`, marked pre-release, at commit `0ba39a8`. That commit is not `main`.
- Bundle id `com.dev.Animatto`. Automatic signing. No development team.
- Ad-hoc `codesign` of the local Debug app failed with `resource fork, Finder information, or similar detritus not allowed`. The unsigned Debug binary still launched on this Mac. That is not a Gatekeeper-clean install for other people.
- README assertion counts are stale (1,621 in the build instructions, 884 in the tree diagram).
- `changes_codex/` duplicates `MainAppView.swift`, `AquariumManager.swift`, `PetEngine.swift`, `DesignSystem.swift`, `Tests/AnimattoTests.swift`, and a window-policy report. The live sources are under `Animatto/` and `Tests/`.
- Four pricing documents disagree. See section 4.
- Pro gates in `EntitlementManager.isEntitled` cover code that is already in this Apache-2.0 tree: `AudioEngine.swift`, `AudioConsoleView.swift`, `SettingsView.swift`, `DesignSystem.swift`, `AquariumDashboardView.swift`.

### Not re-tested here, so still assumptions

- Multi-display topology, Spaces, and full-screen isolation. The window-policy code and tests exist. No second display or full-screen app was exercised.
- Intel (`x86_64`) builds. Phase 13 claims one. This audit machine is arm64, and CI died before a build product existed.
- Release configuration (`xcodebuild -configuration Release`). Only Debug was built locally.
- Sleep/wake timer accuracy on hardware.
- Battery and CPU numbers in `docs/PERFORMANCE_REPORT.md`. That report describes a method and a machine. It was not repeated.
- Backend "58/58" from the `ba08ac0` message. Not re-run.
- Whether ScreenCaptureKit, Apple Events, and local network use are described by the correct usage strings for notarization. Entitlements include network client and Apple Events. A full notarization dry run has not happened.
- Weather coordinate precision. Issue 16 is closed; the current payload was not inspected line by line.

### Product limits that are fine to keep

- Tauri is a prototype. Transparent click-through windows are the hard part, and they are not done. It should not block the Mac release.
- Cloud sync, hosted LLM conversation, and a creator marketplace are named entitlements with no product behind them.
- The website's local Python server does not honor Vercel's clean URLs. Production `vercel.json` does. That is a local-preview quirk, not a launch blocker.

---

## 4. Decisions

### 4.1 What "Pro" can legally be

Apache-2.0 already gives anyone the right to use, modify, and distribute the source that has been published. Client-side `if isEntitled` checks in that source are not a proprietary boundary. They are bypassable, and removing the historical commits would not undo the grant.

Do this:

- Leave every line already published under Apache-2.0 under Apache-2.0.
- Do not move current physics, aquarium, ambient worlds, timers, Magic Eraser, themes, or sound code into a private repository.
- Do not describe a "perpetual commercial grant" for code the repository already licenses under Apache-2.0. `docs/PRICING_AND_ENTITLEMENTS.md` uses that phrase. It conflicts with `LICENSE`.
- Keep core behavior ungated. `isEntitled` already returns true for the free-tier cases. Preserve that.
- If a paid offer ever exists, it has to be something new that was never committed under Apache-2.0, or a service rather than a lock on local code: hosted checkout convenience, support, a future Mac App Store build of the same free app, or artwork and services created later under a separate license. `docs/MONETIZATION_DECISION.md` and `docs/OPEN_CORE_ARCHITECTURE.md` already point this way. Make them the policy and edit the pricing docs to match. Do not expand gates in the meantime.
- Leave Dodo in test mode. Do not set `ENABLE_PRODUCTION_PAYMENTS`. The website must keep saying that purchase is not live.

### 4.2 Hosting

The marketing site is static and can stay on the current Vercel project, or move to GitHub Pages, without changing the product. The payment functions, Postgres, and email are a different system. They are unused in production today. Do not migrate them, and do not buy a commercial host, until a later decision actually turns payments on. Vercel Hobby limits matter only at that later date.

### 4.3 Cross-platform

Do not schedule a Windows or Linux release. Keep `cross-platform/` compiling so the shared behavior tests stay honest. A native port waits until the Mac app is notarized and has real users.

### 4.4 Beta before or after notarization

People outside this Mac cannot reliably install an ad-hoc build. Internal debugging can use the Debug app. A public beta requires a Developer ID-signed, notarized DMG. Hardware testing by the maintainer can start before that, on the machine that already builds. Inviting strangers should wait until Phase 17 produces an installable pre-release.

---

## 5. Release blockers

1. `main` does not build on the Xcode 16.2 CI runner.
2. The unit suite fails without a DMG, and CI runs that suite before packaging.
3. No notarized, version-matched public artifact. The published nightly is not `main`.
4. No Apple Developer ID identity is configured. Workflow secrets are optional and currently absent, so release builds skip notarization.
5. Placeholder bundle id and no team.
6. Contradictory public claims about price, license, and test counts. Shipping those claims would misrepresent the product.
7. No real multi-display, Spaces, or full-screen session has been recorded against current `main`.

---

## 6. Prioritized phases

Phases 15–21 are the path to a public macOS release. Phase 22 is maintenance. Later ideas are listed once, not as fake phases.

### Phase 15 — Make `main` buildable and testable

- **Objective:** One Xcode version, a green `macOS Build & Analyze` run, and a unit suite that does not depend on a file the suite itself does not build.
- **Priority:** Critical. **Complexity:** Medium.
- **Depends on:** Nothing.
- **Tasks:**
  - Pull the Swift diagnostic from run `42216300204` (or a rerun with a retained log) and fix the Xcode 16.2 compile, or deliberately move CI to the Xcode version that actually builds and document that version in `README` and the workflow.
  - Stop pinning "Xcode 16" in prose if the project only builds on a newer toolchain.
  - Change `testReleaseDMGIntegrityAndChecksums` so the fast suite skips or separates artifact checks. Run the DMG checksum only after `scripts/build-and-package.sh`.
  - Confirm the workflow then executes analyze, unit tests, `web/test/test_backend.js`, and `npm --prefix web test`.
  - Choose a final bundle identifier and set it in the project. Leave signing identity for Phase 17.
- **Files:** `.github/workflows/macos-build.yml`, `Tests/AnimattoTests.swift`, `Animatto.xcodeproj/project.pbxproj`, `README.md`.
- **Verification:** A new Actions run on `main` is green through the build step on a clean runner. Local `swiftc` tests pass without `dist/`.
- **Done when:** The latest `macOS Build & Analyze` conclusion is success, and the README names the same Xcode the workflow uses.

### Phase 16 — One licensing story, no new gates

- **Objective:** Public docs, the website, and `EntitlementManager` describe the same product: the Apache-2.0 app is free; payments stay in test mode; existing local features are not held hostage.
- **Priority:** Critical. **Complexity:** Small.
- **Depends on:** The decision in section 4.1, which this audit recommends adopting.
- **Tasks:**
  - Make `docs/MONETIZATION_DECISION.md` the policy. Update `docs/PRICING_AND_ENTITLEMENTS.md`, `docs/PRODUCT_READINESS.md`, `docs/FREE_PREMIUM_BOUNDARIES.md`, the README pricing section, and `web/tools/build-pages.js` so they do not offer a commercial grant over Apache-2.0 code or imply that checkout is live.
  - Leave `ENABLE_PRODUCTION_PAYMENTS` false. Keep the website test that rejects `/api/checkout` links.
  - Do not add features behind `proSoundStudio`, `proCustomPalettes`, or `aquariumPro`. Existing gates may remain as dormant UI, or be opened so the free build matches the license. Prefer opening them if the gated behavior is already the better product. Do not delete the entitlement code in a hurry; decide in one commit with tests updated.
  - State that cloud sync, hosted LLM, and a marketplace are unimplemented ideas, not SKUs.
- **Files:** the docs above, `web/tools/build-pages.js`, `Animatto/EntitlementManager.swift`, and the call sites listed in section 3 only if gates are opened.
- **Verification:** `node web/test/validate_web.js` and `node web/test/test_backend.js`. Read the pricing page and confirm the purchase control stays disabled.
- **Done when:** A new reader cannot find two prices or two licenses for the same feature.

### Phase 17 — Developer ID, notarization, and a real pre-release

- **Objective:** A Gatekeeper-clean DMG built from current `main`, attached to a GitHub pre-release whose version matches the binary.
- **Priority:** Critical. **Complexity:** Medium. Blocked on an Apple Developer account, which no code change can invent.
- **Depends on:** Phase 15. Phase 16 should land first so the pre-release notes do not advertise a live purchase.
- **Tasks:**
  - Enroll the Apple Developer Program if it is not already active. Create a Developer ID Application certificate.
  - Store certificate, notary key, and team id as the secrets `.github/workflows/release.yml` already reads. Do not commit them.
  - Fix the resource-fork failure before signing: `xattr` hygiene in `scripts/build-and-package.sh` so `codesign --options runtime` succeeds on a clean export.
  - Confirm entitlements match actual behavior: outgoing network, Apple Events for Music and Spotify, and Screen Recording only when Screen Awareness is used. Add usage strings a reviewer and a user can understand.
  - Run `./scripts/build-and-package.sh` with the real identity. Require `spctl` to accept the DMG. Staple the ticket.
  - Tag a pre-release, not a stable release. Point `docs/RELEASE_NOTES_v1.2.0.md` at that tag or replace it with notes for the tag that actually ships. Retire the October nightly as the download the website offers, or label it historical.
  - Keep `UpdateService` restricted to official GitHub release assets, and make it look at the new tag.
- **Files:** `scripts/build-and-package.sh`, `.github/workflows/release.yml`, `Animatto/Animatto.entitlements`, Info.plist usage strings, `Animatto/UpdateService.swift`, `docs/RELEASE_NOTES_v1.2.0.md`, download copy in `web/tools/build-pages.js`.
- **Verification:** On a Mac that has never built the app, download the DMG, open it through Gatekeeper, and launch. `codesign -dvvv` shows Developer ID and a team id. `spctl -a -t install` passes.
- **Done when:** The GitHub release asset's checksum matches `dist/SHA256SUMS.txt`, and the website offers that asset.

### Phase 18 — Hardware beta, and no new features

- **Objective:** Learn whether the aquarium, window policy, ambient overlay, and timers behave on real desktops. Fix only what that session breaks.
- **Priority:** Critical. **Complexity:** Large, because it is calendar time and hardware, not code volume.
- **Depends on:** A build the tester did not compile themselves, ideally the Phase 17 DMG. The maintainer may start a private pass on the Debug app in parallel with Phase 17.
- **Tasks:**
  - Execute `docs/BETA_TEST_CHECKLIST.md` and record results. Minimum matrix: one Apple Silicon display, two displays with different scales, one full-screen app, Mission Control / Spaces, sleep and wake during a focus timer, menu-bar walking, drag and throw, aquarium transform and restore in place, ambient rain with reduced motion on, Privacy Shield.
  - If Intel remains a supported claim, run the same pass on Intel or drop Intel from the README.
  - File defects as GitHub issues. Fix release blockers before any feature work.
  - Re-measure CPU and memory with the method in `docs/PERFORMANCE_REPORT.md` only if a beta session shows heat, fan, or battery pain. Do not treat the November 3 table as current.
- **Files:** whatever the sessions implicate, most likely `Animatto/PetEngine.swift`, `AquariumManager.swift`, `AmbientEngine.swift`, `WindowPlatformTracker.swift`, `ProductivityTimerManager.swift`.
- **Verification:** A written log for each matrix row: pass, fail, or not available. Failing rows become issues with builds attached.
- **Done when:** No open issue from that matrix is a crash, a stuck overlay, a window left above full-screen apps, or a timer that jumps after sleep.

### Phase 19 — Repository that tells the truth

- **Objective:** A newcomer can build, test, and understand the app from `README.md` without reading thirty phase reports.
- **Priority:** High. **Complexity:** Small. Can run beside Phases 15–17. Do not let it delay the CI fix.
- **Depends on:** Phase 15's real test count and Xcode version.
- **Tasks:**
  - Replace the README counts, the aquarium description, and the install path with what `main` does.
  - Add a short "historical reports" note at the top of `docs/` or in `README`: phase reports are point-in-time and are not the current test dashboard.
  - Delete or clearly archive `changes_codex/` after a diff confirms it is not newer than `Animatto/`. Do that in a dedicated commit once this planning restriction is lifted. Until then, do not treat those copies as source.
  - Keep `CONTRIBUTING.md` build commands identical to the workflow.
- **Files:** `README.md`, `CONTRIBUTING.md`, `docs/*` headers, `changes_codex/`.
- **Verification:** A cold clone following only the README produces a Debug app and a passing unit suite.
- **Done when:** README counts match the latest local or CI run, and `changes_codex/` is gone or marked as an archive.

### Phase 20 — Accessibility and quiet use

- **Objective:** The app remains pleasant for people who need reduced motion, readable text, and a way to silence it.
- **Priority:** High. **Complexity:** Medium.
- **Depends on:** Phase 18, so fixes follow observed pain.
- **Tasks:**
  - Check VoiceOver on the main library, settings, and menu-bar dashboard. Fix unlabeled controls that block basic use.
  - Confirm reduced-motion skips nonessential ambient and aquarium motion.
  - Confirm Privacy Shield and Quiet Mode stop speech, audio, and screen capture, and that the state survives relaunch.
  - Do not add a new interaction model.
- **Files:** `Animatto/MenuBarDashboard.swift`, `SettingsView.swift`, `AmbientEngine.swift`, `DialogueSystem.swift`, `ScreenAwarenessSystem.swift`.
- **Verification:** VoiceOver can open settings and pause companions. Reduced motion and Privacy Shield behave as labeled.
- **Done when:** Those three paths are checked on the notarized build and any failures are closed.

### Phase 21 — Release candidate

- **Objective:** Call the notarized build stable only after the gates above are true.
- **Priority:** Critical for the announcement, not before. **Complexity:** Medium.
- **Depends on:** Phases 15–20.
- **Tasks:**
  - Tag from a green `main`. Build the release workflow without `skip_notarization`.
  - Release notes list what is free, what is not for sale, and the macOS versions actually tested.
  - `UpdateService` sees the stable tag and rejects non-GitHub URLs, as it should already.
  - Keep a way to ship a follow-up build the same week.
- **Files:** release workflow, release notes, website download page.
- **Verification:** The checklist in section 9 is entirely checked.
- **Done when:** A person who is not the author installs the DMG from the website and gets the version named in the release notes.

### Phase 22 — Post-launch maintenance

- **Objective:** Stay releasable.
- **Priority:** High after launch. **Complexity:** Ongoing, small slices.
- **Depends on:** Phase 21.
- **Tasks:** Watch crash reports and issues. Patch notarized updates. Re-run Dependabot reviews when they open. Do not start a Windows port or a payment launch in the same breath as a crash fix.
- **Done when:** This is a habit, not a milestone. The exit criterion is a documented update process that has shipped at least one fix after 21.

### Explicitly not phases

| Idea | Why it waits |
|---|---|
| Windows/Linux Tauri product | Platform windowing is unsolved. The Mac app is the product. |
| Live Dodo payments | Policy is "not for sale," and merchant, database, and email production are separate projects. |
| Moving the static site off Vercel | No user benefit while the site is a demo. |
| Cloud sync, hosted LLM, marketplace | Not implemented. Selling them would be a new product. |
| More companions, more biomes, more themes | The differentiator is already built. Reliability is the scarce resource. |

---

## 7. What to do next

Start **Phase 15**. Everything public depends on a `main` branch that CI can compile and test. While that fix is in progress, write down the Phase 16 policy in a single docs pass so the next pre-release does not advertise a $3.99 product the license does not support.

Do not open a Windows port, do not flip `ENABLE_PRODUCTION_PAYMENTS`, and do not add features.

---

## 8. Product direction

Animatto is different from a looping GIF pet because the companion uses real windows, can become an aquarium in that same widget, and can quiet down during focus. Privacy is part of the pitch only if the core keeps working offline and the optional network calls stay optional: weather, cloud image generation, and update checks.

The feature set is already wide enough. More systems will make hardware testing slower and the docs less believable. The valuable work is the boring path: a build strangers can install, a license story that matches Apache-2.0, and a beta that tries full-screen apps and a second monitor.

Sustainable money, later, is support, a convenience store listing, or new services and art that were never part of this tree. It is not a retrofit paywall. Community growth follows a readable README and a DMG that opens. It does not follow another phase report.

---

## 9. Release-readiness checklist

Check these on the tag that is about to be called stable. Historical reports do not count.

- [ ] `macOS Build & Analyze` is green on the tag's commit.
- [ ] The workflow's Xcode version and the README's Xcode version are the same.
- [ ] Fast unit tests pass without a pre-existing `dist/` directory.
- [ ] DMG checksum test passes against the DMG just produced.
- [ ] `web` validation and `web/test/test_backend.js` pass in CI.
- [ ] `npm audit` and Dependabot show no open alerts the maintainer has accepted as ship-blocking.
- [ ] Bundle id is final. Developer ID signature and notarization ticket are stapled.
- [ ] `spctl` accepts the DMG on a Mac that did not build it.
- [ ] Version, release notes, website download, and `UpdateService` all name that build.
- [ ] README test counts match the run that just passed.
- [ ] Pricing pages say the app is free and that checkout is not live.
- [ ] No Apache-2.0 source was moved to a private repo to create a paid tier.
- [ ] Beta matrix in Phase 18 has a written result for single display, multi-display, full-screen, and sleep/wake.
- [ ] Reduced motion, Privacy Shield, and a VoiceOver pass of the main controls were tried on the notarized build.
- [ ] The October 2026 nightly is not presented as the current download.
- [ ] `changes_codex/` is not the tree a contributor might edit by mistake.

---

## Appendix — How to read older documents

| Document | Use it as |
|---|---|
| `docs/MONETIZATION_DECISION.md`, `docs/OPEN_CORE_ARCHITECTURE.md` | The policy this roadmap adopts |
| `docs/PRICING_AND_ENTITLEMENTS.md`, parts of `docs/PRODUCT_READINESS.md`, `docs/FREE_PREMIUM_BOUNDARIES.md` | Proposals that contradict that policy until Phase 16 edits them |
| `docs/DODO_PAYMENTS_INTEGRATION.md` | Accurate description of test-mode code, not permission to charge cards |
| `docs/DEPENDABOT_REMEDIATION_REPORT.md` | Consistent with Vite 6.4.5 and 0 open alerts on 6 November 2026 |
| `docs/WINDOWS_AND_UI_POLISH_REPORT.md` | Accurate description of `bef273b`; hardware proof still open |
| `docs/PHASE_13_STABILITY_REPORT.md` and other phase reports | Point-in-time notes. Their pass counts are not current |
| `docs/PERFORMANCE_REPORT.md` | One machine on 3 November 2026. Repeat only if beta shows a cost problem |
| `README.md` | Stale counts and the first file Phase 19 must repair |

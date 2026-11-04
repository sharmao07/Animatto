# Animatto Phase 12 — Public Beta Launch & Community Growth Report

## Executive Summary

Phase 12 prepares Animatto for a controlled, privacy-first public beta release (v1.2.0) and establishes its initial community launch materials. This phase implements the agreed Glueys-inspired website enhancements, audits beta release artifacts and checksums, creates comprehensive community launch copy, validates the Founder Supporter recognition workflow, and solidifies the feedback triage pipeline.

All code and website changes have been verified against the full automated test suite (52 web checks, 48 backend/security tests, 2,062 native Swift assertions, and an Xcode Debug build).

---

## 1. Release Preparation & Artifact Audit

### Beta Build Verification
- **Application Version:** `1.2.0` (Marketing Version)
- **Universal Binary Architecture:** Apple Silicon (`arm64`) and Intel (`x86_64`)
- **Minimum macOS Target:** macOS 14.6 Sonoma (macOS 15.x Sequoia fully supported)
- **Release DMG Path:** `dist/Animatto-v1.2.0.dmg`
- **File Size:** ~12.6 MB
- **SHA-256 Checksum:**
  ```text
  0c5df80d8ea7f5bc89b1d0227c578f056f2ae70222ab3fcf5bdc0f489ad17809
  ```
- **Checksum Manifest:** `dist/SHA256SUMS.txt` verified matching.

### Code Signing & Apple Notarization Status
- **Current Signing State:** The beta release candidate is currently **ad-hoc signed** (`codesign -s -`) for open community testing.
- **Notarization Status:** Independent Apple Notarization has **not** yet been executed, as the maintainer's paid Apple Developer ID credentials have not been configured in the local build environment.
- **Workflow Readiness:** The release automation script (`scripts/build-and-package.sh`) is fully implemented with Developer ID codesigning (`--identity`) and `xcrun notarytool` profile submission support (`--notary-profile`), ready for immediate execution once credentials are provided.
- **Gatekeeper Communication:** Installation documentation (`docs/BETA_TESTING_GUIDE.md` and website `/download`) explicitly instructs users how to authorize the ad-hoc build via Finder right-click -> **Open**, or via the Terminal quarantine removal command:
  ```bash
  xattr -cr /Applications/Animatto.app
  ```

---

## 2. Website Improvements (Glueys-Inspired)

The promotional website (`web/`) was updated to implement the agreed Glueys-inspired enhancements while strictly preserving Animatto's warm cream/coral visual identity (`#FAF8F5`, `#E05A47`), original pixel artwork, and 13-page structure:

1. **Character-Focused Homepage Hero:**
   - Highlights the original companions with clear typography and badges: `macOS 14.6+`, `100% Offline & Private`, `Zero Background Telemetry`, and `Apache-2.0 Open Source`.
   - Prominent call-to-actions: **Download Beta for Mac**, **See it in Action**, and **GitHub**.
   - Preserved the interactive desktop canvas illustration (`data-demo="hero"`).
2. **Meet the Companions Section:**
   - Tactile companion cards displaying original pixel art frames:
     - **Mochi:** Surface Roamer (window titlebar walking, resting during focus, menu bar walking).
     - **Finny:** Golden Sunfin (lively surface swimmer, curious, cursor-following).
     - **Pip:** Pygmy Puffer (chubby, cautious, avoids sudden glass taps).
     - **Glow:** Ghost Tetra (luminescent schooling companion).
     - **Barnaby:** Hermit Crab (patient benthic gravel explorer).
3. **Interactive "See Animatto in Action" Section (`#action`):**
   - High-contrast interactive showcase directing visitors to browser demonstrations of all four signature pillars:
     - **Desktop Aquarium:** In-place widget transformation with 4 species and glass taps.
     - **Ambient Worlds:** Click-through weather particle overlays with 11 localized atmospheres.
     - **Focus & Pomodoro Timers:** 25/5 and 50/10 productivity cycles.
     - **Creator Studio:** On-device Apple Vision Magic Eraser and sprite generation.
4. **"Your Desktop Through the Day" Timeline:**
   - A sequential 4-step workflow timeline illustrating how Animatto fits into a user's workday:
     - **09:00 AM:** Morning Kickoff (companion stretches along menu bar).
     - **11:30 AM:** Deep Work Sprint (Pomodoro active; companion rests; gentle rain).
     - **02:00 PM:** Afternoon Break (aquarium feeding and relaxation).
     - **06:00 PM:** Golden Hour (sunset atmosphere and evening rest).
5. **Improved Spacing & Responsive Grid:**
   - Elevated cards (`var(--sur)`), subtle borders (`var(--line)`), and refined padding.
   - Responsive multi-column layouts adapting smoothly to tablet (2-column) and mobile (single-column) screens.

---

## 3. Community Launch Materials

Complete, production-ready community launch copy has been prepared and stored in [`docs/COMMUNITY_LAUNCH_KIT.md`](COMMUNITY_LAUNCH_KIT.md):

- **GitHub Release v1.2.0-beta.1 Notes:** Markdown release description with highlights, universal binary download links, checksums, and Gatekeeper guidance.
- **Reddit Introduction Post Draft:** Formatted for `r/macapps` and `r/mac` emphasizing native Swift/AppKit performance, zero telemetry, nostalgic desktop companions, and open-source availability.
- **Product Hunt Listing Draft:** Complete with product name, tagline, description, topic tags, and the Maker's opening comment.
- **Screenshots & Video Demo Plan:** Specifications for 5 Retina screenshots and a 60-second video demo storyboard showcasing window walking, Aquarium Mode in-place transformation, ambient rain, and focus rest.
- **Beta Tester Onboarding Instructions:** Step-by-step guide for download, verification, installation, and exploration.
- **Launch Constraint Notice:** Per strict instructions, **zero community announcements will be published automatically**; all drafts are held for maintainer approval.

---

## 4. Founder Programme & Licensing Policy

- **Tier Structure:**
  - **Lifetime Pro ($3.99 USD one-time):** Full access to upcoming Pro sound studios, custom palettes, custom aquarium geometry, and multi-Mac licensing (up to 3 personal Macs).
  - **Founder Supporter ($5.99 USD one-time):** All Pro features + optional repository README acknowledgement + early access to public beta releases.
- **Privacy & Supporter Recognition Policy:**
  - Supporter names are published in the `README.md` **strictly with explicit opt-in consent** provided during checkout or settings.
  - Supporters may request removal or name updates at any time via `support@animatto.app` without impacting their software license.
- **Live Payments Disabled:** Checkout remains strictly configured in sandbox mode (`DODO_PAYMENTS_MODE=test`) until maintainer verification and merchant onboarding are complete.

---

## 5. Feedback Triage & Bug Reporting Process

- **GitHub Issue Templates:** Verified existing templates in `.github/ISSUE_TEMPLATE/`:
  - `beta_feedback.md`: Structured form covering subsystem categorization, reproduction steps, expected vs. actual behavior, and sanitized diagnostic pastes.
  - `bug_report.md`: Standard defect reporting form.
  - `feature_request.md`: Suggestion submission form.
- **Privacy-Sanitized In-App Diagnostics:**
  - Users can copy diagnostics from **Settings > Software Updates & Diagnostics > "Copy Diagnostics"**.
  - The in-memory logger automatically strips usernames (`/Users/<user>` -> `~`), email addresses, and secret tokens.
- **Feedback Triage Matrix:**
  - **P0 (`beta-blocker`):** App crash, data loss, high CPU at idle (>20%). Target fix: 24h.
  - **P1 (`bug`):** Aquarium transformation defects, physics traversal clipping. Target fix: Next beta build.
  - **P2 (`enhancement`):** Cosmetic sprite alignment, particle tuning. Target fix: General release.
  - **P3 (`discussion`):** Feature requests, community suggestions.
- **Common Installation Troubleshooting Table:**
  - Gatekeeper quarantine removal (`xattr -cr /Applications/Animatto.app`).
  - Accessibility permission grant (required for window titlebar collision).
  - Screen Recording permission (optional, required only for local Screen Awareness).

---

## 6. Full Verification Results

| Suite | Command | Result | Notes |
|---|---|---|---|
| **Website Test Suite** | `npm --prefix web test` | **52 / 52 PASSED** | All 13 pages pass CSP, single `h1`, alt tags, internal links, JS syntax, and asset checks |
| **Backend & Security Tests** | `node web/test/test_backend.js` | **48 / 48 PASSED** | All Phase 5, Phase 9, Phase 10 & Phase 11 security, checkout, webhook, and lifecycle tests passed |
| **Native Swift Test Suite** | `swiftc ... Tests/AnimattoTests.swift` | **2,062 / 2,062 PASSED** | 100% assertions passed across all 20 phases |
| **Xcode Debug Build** | `xcodebuild -scheme Animatto` | **BUILD SUCCEEDED** | Native binary and bundle built cleanly |
| **Secret Scan** | SHA-256 fingerprint check | **0 LEAKS FOUND** | Working tree completely free of private key fixtures |

---

## 7. Remaining Blockers for General Availability (v1.2.0 GA)

1. **Apple Developer ID Certificate & Notarization:**
   - Obtain an active Apple Developer Program membership.
   - Generate a Developer ID Application certificate and export credentials.
   - Run `./scripts/build-and-package.sh --identity "Developer ID Application: ..." --notary-profile "..."`.
   - Staple the Apple notarization ticket to the application bundle and DMG.
2. **Production Payment Provider Activation:**
   - Complete Dodo Payments merchant verification.
   - Configure live product IDs and server environment variables (`DODO_PAYMENTS_API_KEY`, `DODO_PAYMENTS_WEBHOOK_SECRET`, `DODO_PAYMENTS_MODE=live`).
3. **Community Launch Execution:**
   - Review and publish the GitHub Release description for `v1.2.0-beta.1`.
   - Post the Reddit introduction and submit the Product Hunt listing upon maintainer approval.

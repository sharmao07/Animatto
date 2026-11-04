# Animatto Community Launch Kit — Public Beta (v1.2.0)

> [!IMPORTANT]
> **Community Distribution Notice:**
> These drafts are prepared for the project maintainer's review. **Do not publish posts, post to social channels, or submit listings automatically** without explicit human approval.

---

## 1. GitHub Release Description (`v1.2.0-beta.1`)

```markdown
# Animatto v1.2.0-beta.1 — Public Beta Release

Welcome to the first public beta of **Animatto** — a native macOS desktop companion and ambient world application built with Swift, SwiftUI, and AppKit.

### What's New in v1.2.0:
- **Desktop Companions:** Hand-crafted pixel companions (including Mochi the cat) with realistic physics, surface collision, window traversal, and menu bar walking.
- **In-Place Aquarium Mode:** Existing desktop widgets transform directly into living desktop aquariums featuring four original aquatic species (Finny, Pip, Glow, Barnaby), water shockwaves, and feeding physics.
- **Ambient Worlds:** Click-through weather particle overlays (Rain, Snow, Sakura, Cozy Café, Sunset, Ocean) localized across 11 languages with Open-Meteo live weather synchronization.
- **Creator Studio:** On-device Apple Vision Magic Eraser for background removal, AI sprite generator, and custom companion pack import/export.
- **Productivity & Focus:** Integrated Pomodoro timers (25/5, 50/10) with companion state coordination.
- **100% Offline & Private:** Zero background telemetry, no analytics SDKs, and strictly local memory persistence.

### Verification & Checksums
- **File:** `Animatto-v1.2.0.dmg` (Universal Binary: Apple Silicon & Intel x86_64)
- **SHA-256:** `0c5df80d8ea7f5bc89b1d0227c578f056f2ae70222ab3fcf5bdc0f489ad17809`
- **Minimum macOS:** macOS 14.6 Sonoma or macOS 15.x Sequoia

### Installation & Gatekeeper Note
This public beta build is ad-hoc signed while Developer ID notarization is in progress.
1. Download `Animatto-v1.2.0.dmg` and drag `Animatto.app` to your `Applications` folder.
2. If macOS prompts *"Animatto cannot be opened because the developer cannot be verified"*:
   - In Finder, **Right-click (Control-click)** `Animatto.app` and choose **Open**, then click **Open**.
   - Or run in Terminal: `xattr -cr /Applications/Animatto.app`
3. Check out the [Beta Testing Guide](https://github.com/sharmao07/Animatto/blob/main/docs/BETA_TESTING_GUIDE.md).

### Feedback & Diagnostics
Report issues using the [Beta Feedback Template](https://github.com/sharmao07/Animatto/issues/new/choose). You can copy privacy-redacted diagnostics directly from **Settings > Software Updates & Diagnostics > Copy Diagnostics**.
```

---

## 2. Reddit Introduction Post (r/macapps, r/mac)

**Suggested Title:**
`[Beta] Animatto — A native, privacy-first desktop companion & ambient aquarium for macOS (Open source, Swift/AppKit, no telemetry)`

**Post Body:**
```markdown
Hey r/macapps! 👋

For the past several months, I've been building **Animatto** — a native macOS companion app designed to bring a little calm and personality to your Mac desktop without being intrusive, resource-heavy, or creepy with telemetry.

### What is Animatto?
Remember virtual desktop pets from the 90s/2000s (like Neko or Shimeji)? Animatto takes that nostalgic concept and completely rebuilds it as a modern, high-performance native macOS app:

- **Physics & Window Traversal:** Characters walk along window edges, jump between open apps, nap when you're focusing, and can even walk upside-down along your menu bar.
- **In-Place Aquarium Mode:** At any time, you can transform your desktop widgets into an interactive aquarium tank with 4 original species (Finny the Golden Sunfin, Pip the Pygmy Puffer, Glow the Ghost Tetra, and Barnaby the Hermit Crab). You can tap the glass to create shockwaves or drop sinking food pellets.
- **Ambient Worlds:** An ultra-lightweight, click-through atmospheric overlay with gentle weather particles (Rainy Day, Sakura Garden, Winter Calm, Cozy Café, Sunset, Cosmic Dream). It can also sync with your local real-world weather via Open-Meteo.
- **Focus / Pomodoro Timers:** 25/5 and 50/10 focus intervals where companions quietly rest while you work and celebrate when you hit your breaks.
- **Creator Studio:** An on-device background remover powered by Apple's native Vision framework (zero cloud uploads) so you can turn your own art into companions.

### Privacy & Architecture
- **Native Swift, SwiftUI & AppKit:** Universal binary for macOS 14.6+ (Apple Silicon & Intel).
- **100% Offline:** Zero analytics SDKs, zero tracking pixels, zero background telemetry. All companion memory and settings stay in `~/Library/Application Support/Animatto/`.
- **Open Core (Apache-2.0):** The core application, cat, aquarium, ambient worlds, timers, and offline privacy are free forever under the Apache License 2.0.

### Public Beta & Feedback
We've just cut the `v1.2.0-beta.1` release and would love your honest feedback, bug reports, and performance impressions!

- **Website & Interactive Demos:** https://animatto-demo.vercel.app
- **GitHub Repository & Releases:** https://github.com/sharmao07/Animatto
- **DMG Download:** `Animatto-v1.2.0.dmg` (SHA-256: `0c5df80d8ea7f5bc89b1d0227c578f056f2ae70222ab3fcf5bdc0f489ad17809`)

*Note on Gatekeeper:* Because this is an open pre-notarization beta build, you may need to right-click `Animatto.app` and choose **Open** on first launch, or run `xattr -cr /Applications/Animatto.app`.

Looking forward to hearing what you think!
```

---

## 3. Product Hunt Listing Draft

### Basic Information
- **Product Name:** Animatto
- **Tagline:** A tiny, living world on your Mac desktop
- **Pricing:** Free & Open Source ($0 Core) • Optional Lifetime Pro ($3.99) & Founder Supporter ($5.99)
- **Primary Category:** Productivity, macOS Apps, Developer Tools, Open Source
- **Website URL:** https://animatto-demo.vercel.app
- **GitHub URL:** https://github.com/sharmao07/Animatto

### Description
Animatto is a native macOS companion app that brings hand-crafted pixel characters, interactive desktop aquariums, and calm ambient weather overlays directly to your desktop.

Companions roam across application windows, react to your focus state, balance along your menu bar, and rest during Pomodoro sprints. Tap the glass to feed aquarium fish or toggle gentle rain particles while you write code.

Engineered with Swift, AppKit, and Apple's Vision framework for macOS 14.6+, Animatto is 100% offline-first with zero tracking, low battery consumption, and an open-source core under Apache-2.0.

### Maker Comment (First Comment on Launch)
```text
Hey Product Hunt! 🐇

We spend 8–12 hours a day staring at flat glass displays and static windows. Most desktop software is purely functional; it does its job, but rarely brings delight or calm to the workspace.

We created Animatto to give your desktop a little life.

Key Highlights:
1. Native & Battery-Efficient: Built with Swift and AppKit. Uses smart display timer pausing so your MacBook battery isn't drained.
2. In-Place Aquarium Mode: Transforms your desktop widgets into an interactive aquatic simulation with 4 original species, feeding physics, and glass taps.
3. Ambient Weather: 8 built-in atmospheres (Rain, Sakura, Snow, Café) that render in a click-through layer so you can keep clicking apps underneath.
4. Total Privacy: Zero analytics, zero cloud tracking, and on-device Vision processing for custom companion creations.
5. Open Core: The core app is free forever under Apache-2.0.

We're in public beta today and would love to hear your thoughts, feedback, and favorite companion interactions!
```

---

## 4. Screenshots & Short Demo Recording Plan

### Visual Asset Specifications

| Asset | Format | Resolution | Description |
|---|---|---|---|
| **Hero Screenshot 1** | PNG (16-bit) | 2880 × 1800 (16:10 Retina) | macOS Sonoma desktop with Xcode, Mochi the cat walking on the titlebar, and menu bar icon active. |
| **Hero Screenshot 2** | PNG (16-bit) | 2880 × 1800 | Transformed Aquarium Mode widget with Sunfin and Pufferfish, submerged plants, and gentle water theme. |
| **Hero Screenshot 3** | PNG (16-bit) | 2880 × 1800 | Ambient Worlds Rainy Day overlay with light droplet refraction and companion sitting under an app window ledge. |
| **Hero Screenshot 4** | PNG (16-bit) | 2880 × 1800 | Creator Studio showing Apple Vision Magic Eraser removing a sprite background on-device. |
| **Hero Screenshot 5** | PNG (16-bit) | 2880 × 1800 | Pomodoro timer widget at 25:00 with companion sleeping in focus state. |

### Video Demo Plan (45–60 Seconds)
- **0:00 – 0:08:** Launch Animatto from Spotlight. Companion gracefully drops with gravity onto the active Finder window.
- **0:08 – 0:18:** User drags the companion and tosses them across screens; companion lands and walks across an active browser window.
- **0:18 – 0:30:** Toggle **Aquarium Mode** from the menu bar. Desktop widget transforms in-place; cursor taps the glass, causing fish to scatter and feed pellets to sink.
- **0:30 – 0:42:** Open Ambient Worlds and select **Rainy Day**. Drops drift down smoothly while user clicks through to code in an editor beneath.
- **0:42 – 0:52:** Engage Pomodoro timer. Companion curls up to sleep peacefully atop the editor.
- **0:52 – 1:00:** Title card: *Animatto — Native macOS Desktop Companions. Open Source on GitHub.*

---

## 5. Beta Tester Onboarding Instructions

### Welcome Message
Thank you for joining the Animatto v1.2.0 Public Beta! Your feedback helps us polish physics, battery efficiency, multi-display support, and accessibility before the v1.2.0 general release.

### Step-by-Step Onboarding
1. **Download:** Grab `Animatto-v1.2.0.dmg` from the GitHub Releases page or `dist/`.
2. **Verify Integrity:** Run in your Terminal:
   ```bash
   shasum -a 256 Animatto-v1.2.0.dmg
   # Expected output: 0c5df80d8ea7f5bc89b1d0227c578f056f2ae70222ab3fcf5bdc0f489ad17809
   ```
3. **Install:** Double-click the DMG and drag `Animatto.app` into `/Applications`.
4. **Authorize:**
   - On first launch, right-click `Animatto.app` in Finder and select **Open**.
   - If macOS blocks execution: `xattr -cr /Applications/Animatto.app`
5. **Explore Core Features:**
   - Spawn Mochi the Cat and observe window titlebar walking.
   - Click the menu bar icon and select **Turn On Aquarium Mode**.
   - Open **Ambient Worlds** and test different weather particles.
   - Start a 5-minute Focus Timer in **Productivity**.
6. **Provide Feedback:**
   - In Settings (`Cmd + ,`), click **"Copy Diagnostics"** for a sanitized system summary.
   - Open an issue on GitHub: [Submit Beta Feedback](https://github.com/sharmao07/Animatto/issues/new/choose).

---

## 6. Feedback Triage & Bug Reporting Process

### Priority Matrix
- **P0 / Blocker (`label: beta-blocker`):** App crash, kernel panics, data loss in local memory, infinite loop / CPU pegging (>20% CPU at idle). Resolved within 24 hours.
- **P1 / High (`label: bug`):** In-place aquarium transformation failure, physics traversal getting stuck off-screen, multi-display coordinate clipping. Resolved in the next beta build.
- **P2 / Normal (`label: enhancement`):** Cosmetic sprite clipping, particle density suggestions, new archetype voice lines.
- **P3 / Low (`label: discussion`):** Nice-to-have features, non-critical documentation improvements.

### Common Installation Issues & Solutions

| Issue | Root Cause | Verified Resolution |
|---|---|---|
| *"Animatto cannot be opened because the developer cannot be verified"* | Beta candidate is ad-hoc signed before Developer ID notarization | Right-click `Animatto.app` in Finder, click **Open**, then confirm. Or run `xattr -cr /Applications/Animatto.app`. |
| *"Companions do not detect window edges"* | Missing Accessibility permission in macOS | Open **System Settings > Privacy & Security > Accessibility** and ensure Animatto is toggled ON. |
| *"Screen Awareness dialogue doesn't react to current app"* | Missing Screen Recording permission | Open **System Settings > Privacy & Security > Screen Recording** and grant permission. (Note: Animatto analyzes screen bounds locally; nothing is uploaded). |
| *"Companion audio cannot be heard"* | Master audio muted or system output switched | Check the sound toggle in the menu bar popover, or open **Settings > Pro Sound Studio**. |

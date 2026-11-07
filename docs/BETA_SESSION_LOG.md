# Hardware and release session log

Recorded 7 November 2026 on the maintainer Mac. A row is filled only when that session actually ran.

| Check | Result |
|---|---|
| One built-in display, 1440×900 | Screen list was `{{0, 0}, {1440, 900}}`. Notification Centre widgets were at quartz `(8,483) 180×180`, `(188,483) 360×180`, `(8,663) 180×180`, `(188,663) 360×180`. A window placed at the converted Cocoa frame `(8,237) 180×180` listed back at quartz `(8,483)`, on the Clock widget. |
| Aquarium covers after the gravity fix (`ca15e5a`) | The earlier screenshot showed covers under the menu bar because gravity ran on widget covers. That path is skipped now. A fresh toggle after this branch was not watched on the desktop in this session. |
| Library companion while Aquarium Mode is on | Covered by unit tests on this branch. Not watched on the desktop in this session. |
| Second display | Not available. Only one screen was attached. |
| Full-screen app | Not run. |
| Mission Control / Spaces | Not run. |
| Sleep and wake during a focus timer | Not run. |
| Intel | Not run. This Mac is Apple silicon. Intel stays an unverified README claim. |
| VoiceOver on library, settings, and menu bar | Not run. |
| Reduced motion and Privacy Shield on a notarized build | Not run. There is no notarized build. |
| Developer ID and notarization | Blocked. No Apple Developer team, certificate, or notary secret is configured. The release workflow still skips notarization without those secrets. |
| Gatekeeper on a Mac that did not build the app | Not run. |
| Bundle id | Left as `com.dev.Animatto` so preferences, Keychain, and the updater stay on one id. |

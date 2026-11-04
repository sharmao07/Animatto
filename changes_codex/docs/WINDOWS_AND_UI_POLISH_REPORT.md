# Windows and UI Polish Report

## Scope

This change preserves Animatto's existing companion, Aquarium Mode, Ambient Worlds,
Creator Studio, Productivity, and menu-bar behavior while consolidating the two
window policies that were conflicting with Aquarium Mode. No pricing, licensing,
payment, backend, or website code was changed.

## Root causes

- Theme selection persisted its accent hex, but most semantic surface tokens still
  resolved directly to untinted AppKit window/control colors. The main AppKit
  window background was also reset independently of the SwiftUI theme.
- Aquarium widgets were initially configured for the desktop, but
  `PetInstance.updateWindowLevel` could later promote them to `.floating` when
  **Stay on Top** changed. That reset allowed the widget to stack with app and
  full-screen content. The old tests captured that unsafe behavior.

## Implementation

- `AnimattoThemeManager` is now the source for both SwiftUI and AppKit colors.
  Changing the persisted accent refreshes registered/native app window surfaces
  immediately. Semantic backgrounds, cards, controls, borders, dividers, hover,
  and pressed states receive restrained accent tinting while preserving macOS
  light/dark contrast.
- `WindowSurfaceCoordinator` registers normal app windows and reapplies the
  resolved theme to every live native window when the theme changes.
- `AnimattoWindowPolicy` centralizes desktop-aquarium and ordinary-companion
  level/Space behavior. Aquarium uses the desktop-icon band (above desktop
  widgets; below normal application windows), `.stationary`, and no
  `.canJoinAllSpaces` or `.fullScreenAuxiliary` behavior.
- Aquarium transformation, level updates, display-configuration changes, and
  direct settings changes all reapply the desktop policy. Its in-place
  transformation, exact frame/position, and cleanup behavior remain intact.
- The main window's non-glass surface now uses the shared theme surface rather
  than a hard-coded gray, keeping window chrome and SwiftUI content coherent.

## Regression coverage

Added tests cover:

- Registered native window surfaces changing with a custom accent and custom
  accent persistence in `UserDefaults`.
- Aquarium desktop level, stationary Space behavior, no full-screen auxiliary
  participation, and stacking above desktop widgets but below normal app content.
- Existing tests continue to cover in-place transformations, position retention,
  repeated show/hide cleanup, screen changes, and desktop-widget replacement.

## Validation

- Fast native test suite: **2,130 assertions passed, 0 failures**.
- Debug build: passed with `CODE_SIGNING_ALLOWED=NO`.
- Release build: passed with `CODE_SIGNING_ALLOWED=NO`; release app product was
  generated successfully.
- Existing Swift 6 actor-isolation warnings in `AnimationAssetCache.swift` were
  emitted in both configurations; they predate and are outside this change.
- Visual Space/full-screen verification still requires a real multi-display
  macOS developer desktop.

## Remaining manual checks

1. Put an app in full screen, then enable/disable Aquarium Mode and switch Spaces:
   the aquarium must stay on its desktop Space.
2. Attach/detach a display and change resolution while Aquarium Mode is active:
   positions should remain aligned with their replaced desktop widgets.
3. Switch every accent/theme in light and dark appearance and confirm live app,
   settings, sheets, and menu-bar surfaces update without relaunch.

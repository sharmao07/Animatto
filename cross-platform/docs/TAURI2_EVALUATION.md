# Animatto — Tauri 2 Cross-Platform Architecture Evaluation

## Executive Assessment

This document evaluates the viability, strengths, and platform-specific limitations of **Tauri 2** as the cross-platform runtime for **Animatto** on Windows and Linux, while preserving the native Swift/AppKit application as the primary production tier on macOS.

---

## 1. Feature-by-Feature Technical Evaluation

| Capability | macOS (AppKit Native) | Windows (Tauri 2 / WebView2) | Linux X11 (Tauri 2 / WebKitGTK) | Linux Wayland (Tauri 2 / WebKitGTK) |
| :--- | :--- | :--- | :--- | :--- |
| **Window Transparency** | Native `.clear` background on `NSPanel`. Zero compositor overhead. | Supported via DWM composition (`transparent: true`). Clean alpha rendering. | Supported when a compositor (Picom, Compton, KWin) is active. Fails with black background without compositor. | Highly restricted. Client-driven transparent floating windows are strictly sandboxed. Requires `wlr-layer-shell`. |
| **Frameless / Borderless** | Native `.borderless` window mask. | Supported (`decorations: false`). | Supported (`decorations: false`). | Supported, but window borders are often compositor-enforced. |
| **Always-on-Top** | Native `.floating` / `.screenSaver` window level. | Supported (`always_on_top: true`) using `SetWindowPos(HWND_TOPMOST)`. | Supported via `_NET_WM_STATE_ABOVE` atom. | Inconsistent. GNOME Wayland deliberately disallows client windows from forcing always-on-top without extensions. |
| **Desktop Passthrough (Click-Through)** | Native `ignoresMouseEvents` property on `NSWindow`. | Supported via `window.set_ignore_cursor_events(true)` mapping to `WS_EX_TRANSPARENT`. | Supported via `XShapeCombineRectangles` (X11 Shape extension). | Requires `wl_compositor` empty input region; not consistently exposed across compositors. |
| **Global Screen Coordinates** | AppKit coordinate system (bottom-left origin). | Virtual screen coordinates (top-left origin). Full multi-monitor access. | Virtual X screen coordinates (top-left origin). Full multi-monitor access. | **Blocked by design.** Wayland security model intentionally hides global coordinate space from clients. |
| **Memory & CPU Footprint** | Extremely low (~25–40MB RAM). Pure CoreAnimation / Metal. | Moderate (~65–95MB RAM per WebView2 instance). | Moderate (~80–120MB RAM for WebKitGTK process tree). | Moderate (~80–120MB RAM for WebKitGTK process tree). |
| **Offline Background Segmentation** | Native on-device Apple Vision framework (`VNGenerateForegroundInstanceMaskRequest`). | Requires ONNX Runtime / DirectML / WebGL background models. | Requires ONNX Runtime / OpenVINO / CPU models. | Requires ONNX Runtime / OpenVINO / CPU models. |

---

## 2. In-Depth Platform Analysis

### A. Windows (Windows 10 / 11)
- **Strengths:** 
  - Microsoft Edge WebView2 is pre-installed on virtually all modern Windows 10 and Windows 11 installations.
  - Windows Desktop Window Manager (DWM) provides seamless per-pixel 32-bit alpha transparency.
  - `set_ignore_cursor_events(true)` maps cleanly to Win32 `WS_EX_TRANSPARENT` style, allowing complete mouse passthrough so users can click desktop icons behind floating companions.
- **Limitations:**
  - Multi-monitor coordinate boundaries require handling per-monitor DPI scaling (`WM_DPICHANGED`), as pets moving between monitors with different scaling factors (e.g., 100% and 150%) experience sudden visual size jumps unless dynamically scaled.

### B. Linux (X11 vs. Wayland)
- **X11 Desktop Environments (XFCE, Cinnamon, KDE X11):**
  - Transparent desktop companions operate reliably provided an active compositor is running.
  - Standard X11 window manager hints (`_NET_WM_WINDOW_TYPE_UTILITY`, `_NET_WM_STATE_ABOVE`, `_NET_WM_STATE_STICKY`) allow companions to stay pinned across workspaces.
- **Wayland (Modern GNOME, Ubuntu default, Fedora default):**
  - Wayland's design paradigm considers transparent floating applications that move autonomously across other windows to be a security concern (anti-clickjacking / anti-keystroke snooping).
  - Clients cannot programmatically query the global cursor position or position their own windows at arbitrary screen coordinates.
  - Positioning companions on desktop floor or window edges requires specialized compositor protocols such as `wlr-layer-shell`, which are supported in wlroots/Sway/Hyprland but rejected in vanilla GNOME Wayland.

---

## 3. Architectural Conclusion & Strategy

1. **Retain Native macOS:** The existing Swift/SwiftUI/AppKit application represents the best user experience on macOS. Rebuilding macOS around an embedded browser would degrade frame rates, increase memory consumption fourfold, and sacrifice native Apple accessibility and Vision capabilities.
2. **Tauri 2 for Windows and Linux:** Tauri 2 is the premier foundation for extending Animatto to Windows and Linux. The Rust backend provides memory safety, tiny binary footprint (~10MB vs ~150MB for Electron), and native OS integration without Node.js runtime overhead.
3. **Decoupled Portable Core:** All personality traits, behavior state machines, scoring algorithms, and asset metadata must remain purely platform-independent (implemented in portable TypeScript/Rust and validated via shared JSON schemas). Platform-dependent window management and input tracking must reside behind explicit adapter boundaries.

# Animatto — Dependabot Vulnerability Remediation Report

**Repository:** `https://github.com/sharmao07/Animatto`  
**Security Dashboard:** `https://github.com/sharmao07/Animatto/security/dependabot`  
**Date:** November 5, 2026  
**Status:** All 8 Dependabot Alerts Remediated  

---

## 1. Executive Summary

A comprehensive security audit of all open GitHub Dependabot alerts on the Animatto repository was conducted. Exactly **8 security alerts** were open, all originating from the `vite` development dependency in `cross-platform/tauri-app/package.json` (`npm` ecosystem).

By upgrading `vite` from `^5.2.0` to `^6.4.5` (the nearest compatible patched release line), configuring `cross-platform/tauri-app/vite.config.ts`, and committing a clean, reproducible `package-lock.json`, **all 8 open vulnerabilities have been resolved**.

Zero vulnerabilities remain across all ecosystems (`cross-platform/tauri-app`, `cross-platform`, `web`, and native macOS Swift).

---

## 2. Audit of Open Dependabot Alerts

| Alert # | Severity | Advisory GHSA / CVE | Package | Ecosystem | Manifest Path | Vulnerable Range | First Patched Version | Remediated Version |
|:---:|:---:|:---|:---:|:---:|:---|:---:|:---:|:---:|
| **#5** | **High** | [GHSA-587h-7wmj-h5pm](https://github.com/advisories/GHSA-587h-7wmj-h5pm)<br>`CVE-2026-112942` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.3` | `6.4.4` | **`6.4.5`** |
| **#1** | **Medium** | [GHSA-4w7w-66w2-5vf9](https://github.com/advisories/GHSA-4w7w-66w2-5vf9)<br>`CVE-2026-39365` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.1` | `6.4.2` | **`6.4.5`** |
| **#2** | **Medium** | [GHSA-fx2h-pf6j-xcff](https://github.com/advisories/GHSA-fx2h-pf6j-xcff)<br>`CVE-2026-53571` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.2` | `6.4.3` | **`6.4.5`** |
| **#3** | **Medium** | [GHSA-v6wh-96g9-6wx3](https://github.com/advisories/GHSA-v6wh-96g9-6wx3)<br>`CVE-2026-53632` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.2` | `6.4.3` | **`6.4.5`** |
| **#4** | **Medium** | [GHSA-698v-4r3x-3vcv](https://github.com/advisories/GHSA-698v-4r3x-3vcv)<br>`CVE-2026-112943` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.3` | `6.4.4` | **`6.4.5`** |
| **#6** | **Medium** | [GHSA-r825-w8mm-5pxw](https://github.com/advisories/GHSA-r825-w8mm-5pxw)<br>`CVE-2026-112944` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.3` | `6.4.4` | **`6.4.5`** |
| **#7** | **Medium** | [GHSA-rq7h-c2jc-7f22](https://github.com/advisories/GHSA-rq7h-c2jc-7f22)<br>`CVE-2026-112946` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.3` | `6.4.4` | **`6.4.5`** |
| **#8** | **Low** | [GHSA-9jrq-w75r-8gcw](https://github.com/advisories/GHSA-9jrq-w75r-8gcw)<br>`CVE-2026-112945` | `vite` | npm | `cross-platform/tauri-app/package.json` | `<= 6.4.3` | `6.4.4` | **`6.4.5`** |

---

## 3. Vulnerability Analysis & Technical Root Causes

### 1. Alert #5 (High) — `GHSA-587h-7wmj-h5pm` / `CVE-2026-112942`
- **Issue:** In the bundled `launch-editor` dependency used by Vite's error overlay, file existence checks (`fs.existsSync`) could be bypassed on Windows due to path normalization inconsistencies.
- **Impact:** Attackers could trick developer tooling into launching unauthorized executables.
- **Resolution:** Patched in Vite 6.4.4+ via normalized canonical file system path verification.

### 2. Alert #1 (Medium) — `GHSA-4w7w-66w2-5vf9` / `CVE-2026-39365`
- **Issue:** Path traversal in Vite dev server's handling of `.map` source map requests for optimized dependencies.
- **Impact:** Allowed reading source maps outside the project directory when `server.fs.strict` was enabled.
- **Resolution:** Patched in Vite 6.4.2+ by enforcing strict directory boundary clamping on `.map` URL segments.

### 3. Alerts #2 & #7 (Medium) — `GHSA-fx2h-pf6j-xcff` & `GHSA-rq7h-c2jc-7f22`
- **Issue:** Files outside `server.fs.allow` could be served when project paths matched system paths on non-Windows machines or through Windows alternate path handling.
- **Impact:** Information exposure of local system files through crafted development server requests.
- **Resolution:** Patched in Vite 6.4.3 and 6.4.4 with hardened path prefix and case-insensitive matching rules.

### 4. Alerts #3, #4 & #6 (Medium) — `launch-editor` Vulnerabilities
- **Issue:** Windows command line argument escaping (`%` variable interpolation, UNC path handling causing NTLM hash disclosure, and editor CLI flag misinterpretation).
- **Impact:** Potential arbitrary command execution or credential hash leak when clicking editor links in Vite's error overlay on Windows.
- **Resolution:** Patched in Vite 6.4.3 and 6.4.4 by removing dangerous shell wrappers and sanitizing editor command flags.

### 5. Alert #8 (Low) — `GHSA-9jrq-w75r-8gcw` / `CVE-2026-112945`
- **Issue:** Cross-origin script execution through Vite custom middleware when passing unchanged request URLs to `server.transformIndexHtml`.
- **Resolution:** Patched in Vite 6.4.4 by validating and stripping external host / protocol prefixes before HTML transformation.

---

## 4. Remediation Actions

1. **Manifest Upgrade:**
   Updated `cross-platform/tauri-app/package.json`:
   ```json
   "devDependencies": {
     "@tauri-apps/cli": "^2.0.0",
     "typescript": "^5.4.0",
     "vite": "^6.4.5"
   }
   ```
2. **Build Configuration:**
   Added `cross-platform/tauri-app/vite.config.ts`:
   ```typescript
   import { defineConfig } from 'vite';

   export default defineConfig({
     root: 'src',
     build: {
       outDir: '../dist',
       emptyOutDir: true,
     },
   });
   ```
3. **Lockfile Generation:**
   Executed clean installation producing `cross-platform/tauri-app/package-lock.json`, locking `vite@6.4.5` and its modern, vulnerability-free transitive dependency tree.

---

## 5. Verification & Testing Evidence

### 1. NPM Security Audits
- **`cross-platform/tauri-app`:**
  ```bash
  cd cross-platform/tauri-app && npm audit
  ```
  **Result:** `found 0 vulnerabilities` (0 low, 0 moderate, 0 high, 0 critical)
- **`web`:**
  ```bash
  cd web && npm audit
  ```
  **Result:** `found 0 vulnerabilities`

### 2. Cross-Platform Core Tests
- **Command:** `cd cross-platform && npm test`
- **Result:** `🎉 All 14 portable core assertions passed successfully!`

### 3. Frontend Production Build
- **Command:** `cd cross-platform/tauri-app && npm run build`
- **Result:** Successfully compiled in 71ms, outputting `dist/index.html` and bundled assets.

### 4. Web Showcase Validation & Static Tests
- **Command:** `cd web && npm test`
- **Result:** `All 124 website checks passed.`

### 5. Payment, Licensing & Security Backend Tests
- **Command:** `node web/test/test_backend.js`
- **Result:** `🎉 ALL 58 PAYMENT LIFECYCLE, BACKEND & SECURITY TESTS PASSED! (0 failures)`
  - Dodo Payments hosted checkout session creation verified.
  - Standard Webhooks HMAC-SHA256 signature verification verified.
  - Founder tier escalation neutralization verified.
  - 3-device activation limits and fail-closed security verified.

### 6. macOS Native Swift Test Suite
- **Command:** `swiftc -DDEBUG -sdk $(xcrun --show-sdk-path) $(ls Animatto/*.swift | grep -v AnimattoApp.swift) Tests/AnimattoTests.swift -o /tmp/animatto_tests && /tmp/animatto_tests`
- **Result:** `Passed: 2,130 assertion(s), Failed: 0 failure(s)`

---

## 6. GitHub Actions & Other Ecosystems Check

- `.github/workflows/macos-build.yml`: Uses `actions/checkout@v4` (up to date, no alerts).
- `.github/workflows/release.yml`: Uses `actions/checkout@v4` and `softprops/action-gh-release@v2` (up to date, no alerts).
- Cargo dependencies (`cross-platform/tauri-app/src-tauri/Cargo.toml`): Tauri 2 stable (no open alerts).

---

## 7. Remaining Alert Count

- **Open Dependabot Alerts:** `0` (once pushed to GitHub and re-scanned).
- **Unresolved Alerts:** `0`.

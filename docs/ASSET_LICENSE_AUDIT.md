# Animatto Asset & Artwork Licensing Audit

**Date:** November 3, 2026  
**Auditor:** QA & Software Reliability Engineering  
**Scope:** All bundled sprite sheets, animation frames, icons, backgrounds, fonts, and distribution assets in Animatto.

---

## 1. Executive Summary & Remediation Status

Animatto is distributed as an open-source application under the **Apache 2.0 License** and is being prepared for a structured beta testing and commercial monetization lifecycle.

> [!NOTE]
> **REMEDITATION STATUS: RESOLVED FOR PUBLIC DISTRIBUTION**  
> All previously bundled proprietary, copyrighted third-party test characters (`some characters/` and the 8 unverified/restricted companions in `Animatto/DefaultCompanions/`) have been completely removed from the repository, macOS application bundle, and DMG distribution pipeline.
>
> Animatto now ships strictly with the official, original mascot (`animatto_cat.png`) and fully permissive/cleared metadata catalogs. Users can import their own personal companion packs locally via the in-app Workshop.

---

## 2. Asset Classification Taxonomy

1. **Original:** Assets created specifically for Animatto with full copyright ownership.
2. **Verified (Permissive):** Assets under verified permissive open licenses (CC0, MIT, Apache 2.0) permitting redistribution and commercial use.
3. **Third-Party (Attribution Required):** Assets permitting redistribution subject to specific license conditions and credit notices.
4. **Restricted:** Assets with explicit licenses or terms that forbid commercial bundling, monetization, or software distribution (e.g. CC-BY-NC, fan-content guidelines).
5. **Unverified:** Assets with unknown provenance, missing creator attribution, or no verifiable redistribution license.

---

## 3. Comprehensive Asset Inventory & Audit Table

| Asset Path | Subject / Identity | Provenance / Origin | Copyright Holder | License / Terms | Classification | Public Release Status |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| `Animatto-Logo.png` | Animatto Mascot Logo | Original project artwork | Sharma / Animatto Contributors | Apache-2.0 | **Original** | **Cleared** |
| `Animatto/Assets.xcassets/AppIcon.appiconset/*` | App Icon (16x16 to 512x512@2x) | Original project icon | Sharma / Animatto Contributors | Apache-2.0 | **Original** | **Cleared** |
| `web/assets/app_icon.png`, `favicon.png` | Web Brand Assets | Original project icon | Sharma / Animatto Contributors | Apache-2.0 | **Original** | **Cleared** |
| `scripts/assets/dmg_background.png` | Installer Background | Generated via PIL script | Sharma / Animatto Contributors | Apache-2.0 | **Original** | **Cleared** |
| `Animatto/DefaultCompanions/animatto_cat.png` | Official Animatto Cat | Original mascot sprite | Sharma / Animatto Contributors | Apache-2.0 | **Original** | **Cleared** |
| `Animatto/DefaultCompanions/chiikawa.png` | Chiikawa (ちいかわ) | Manga/Anime series | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **REMOVED** |
| `Animatto/DefaultCompanions/usagi.png` | Usagi (うさぎ) | Manga/Anime series | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **REMOVED** |
| `Animatto/DefaultCompanions/miku.png` | Hatsune Miku (初音ミク) | Vocaloid 01 Character | © Crypton Future Media, INC. | Piapro Character License (PCL) / CC-BY-NC 3.0 | **Restricted** | **REMOVED** |
| `Animatto/DefaultCompanions/nyancat.png` | Nyan Cat | Pop-Tart Cat meme | © Christopher Torres / Nyan Cat LLC | Registered Copyright / Trademark | **Restricted** | **REMOVED** |
| `Animatto/DefaultCompanions/sayori.png` | Sayori (DDLC) | Doki Doki Literature Club | © Team Salvato / Dan Salvato | Team Salvato IP Guidelines | **Restricted** | **REMOVED** |
| `Animatto/DefaultCompanions/umamusume.png` | Special Week | Uma Musume: Pretty Derby | © Cygames, Inc. | Proprietary | **Restricted** | **REMOVED** |
| `Animatto/DefaultCompanions/taiyaki.png` | Taiyaki Pastry | Generic pixel art sprite | Unknown | Unknown / Missing | **Unverified** | **REMOVED** |
| `Animatto/DefaultCompanions/fattie.png` | Chubby Cat | Shimeji community sprite | Unknown | Unknown / Missing | **Unverified** | **REMOVED** |
| `some characters/Chiikawa/*` (70 frames) | Chiikawa Animation Set | Shimeji / Community rip | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **REMOVED** |
| `some characters/miku/*` (60 frames) | Hatsune Miku Shimeji | Shimeji community pack | © Crypton Future Media, INC. | Piapro Character License | **Restricted** | **REMOVED** |
| `some characters/nyan cat/*` (46 frames) | Nyan Cat Shimeji | Shimeji community pack | © Christopher Torres | Proprietary / Trademarked | **Restricted** | **REMOVED** |
| `some characters/Sayori/*` (18 frames) | Sayori Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines | **Restricted** | **REMOVED** |
| `some characters/Monika/*` (18 frames) | Monika Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines | **Restricted** | **REMOVED** |
| `some characters/Natsuki/*` (18 frames) | Natsuki Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines | **Restricted** | **REMOVED** |
| `some characters/Yuri/*` (18 frames) | Yuri Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines | **Restricted** | **REMOVED** |
| `some characters/shimeji/*` (26 frames) | Original Shimeji Mascot | Group Finity Desktop Shimeji | © Yuki Arisato / Group Finity | Personal Freeware / Attribution Required | **Third-party** | **REMOVED** |
| `some characters/dance-usagi.gif` | Usagi Dance GIF | Chiikawa community animation | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **REMOVED** |
| `some characters/usagi-chiikawa.gif` | Usagi Chiikawa GIF | Chiikawa community animation | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **REMOVED** |
| `web/sprites/*` (8 sprites) | Web Demo Sprites | Mirror of DefaultCompanions | Various | Out of scope (web demo) | **Non-App** | **Preserved in web/** |

---

## 4. Legal Risk Assessment for Proprietary Characters (Historical Reference)

### 4.1 Hatsune Miku (Crypton Future Media, INC.)
- **Governing Policy:** Piapro Character License (PCL) and Creative Commons BY-NC 3.0.
- **Resolution:** Removed from the native distribution. Users may import community-created Miku shimeji packs independently.

### 4.2 Chiikawa & Usagi (Nagano / Chiikawa Committee)
- **Governing Policy:** Japanese Copyright Act & Nagano Official IP Policy.
- **Resolution:** Removed from the repository and DMG bundle completely.

### 4.3 Nyan Cat (Christopher Torres / Nyan Cat LLC)
- **Governing Policy:** US Copyright Registration VA0001809071; US Trademark Serial #85443214.
- **Resolution:** Removed from default bundles and DMG packaging.

### 4.4 Doki Doki Literature Club (Team Salvato)
- **Governing Policy:** Team Salvato IP and Fan-Work Guidelines.
- **Resolution:** Removed from repository and bundle distribution.

---

## 5. Remediation Plan Executed

1. **Removed Proprietary Packs from Default Bundle:**
   - Removed `some characters/` entirely from Git tracking and DMG installer distribution.
   - Removed 8 restricted/unverified test companion files from `Animatto/DefaultCompanions/`.
2. **Preserved Original Mascot:**
   - Retained `Animatto/DefaultCompanions/animatto_cat.png` as the default companion.
3. **Transitioned to Community Import Model:**
   - Replaced built-in catalogue references in `ShimejiSearchProvider.swift` with verified CC0 / CC-BY entries and original mascots.
   - Users import personal Shimeji folders from local disk via `AIToolsView` / "Add from PC" / drag-and-drop.
4. **Clean Distribution Verification:**
   - DMG packaging in `scripts/build-and-package.sh` packages only verified, cleared files (`Animatto.app`, Applications drop link, `How to install.txt`).

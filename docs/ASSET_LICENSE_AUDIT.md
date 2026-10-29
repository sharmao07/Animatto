# Animatto Asset & Artwork Licensing Audit

**Date:** October 29, 2026  
**Auditor:** QA & Software Reliability Engineering  
**Scope:** All bundled sprite sheets, animation frames, icons, backgrounds, fonts, and distribution assets in Animatto.

---

## 1. Executive Summary & Release Blocker Notice

Animatto is distributed as an open-source application under the **Apache 2.0 License** and is being prepared for a structured beta testing and commercial monetization lifecycle.

> [!CAUTION]
> **CRITICAL RELEASE BLOCKER:**  
> The current distribution candidate bundles multiple high-profile, proprietary, copyrighted character intellectual properties without verifiable commercial redistribution rights. Bundling these characters in a public release—particularly one intended for commercial monetization—poses severe copyright and trademark infringement liabilities.
>
> **The candidate package cannot be released publicly or commercially until these proprietary character assets are replaced with original or license-cleared alternatives.**

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
| `Animatto/DefaultCompanions/chiikawa.png` | Chiikawa (ちいかわ) | Manga/Anime series | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **BLOCKER** |
| `Animatto/DefaultCompanions/usagi.png` | Usagi (うさぎ) | Manga/Anime series | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **BLOCKER** |
| `Animatto/DefaultCompanions/miku.png` | Hatsune Miku (初音ミク) | Vocaloid 01 Character | © Crypton Future Media, INC. | Piapro Character License (PCL) / CC-BY-NC 3.0 (Non-commercial only) | **Restricted** | **BLOCKER** |
| `Animatto/DefaultCompanions/nyancat.png` | Nyan Cat | Pop-Tart Cat meme | © Christopher Torres / Nyan Cat LLC | Registered Copyright / Trademark; Commercial distribution forbidden | **Restricted** | **BLOCKER** |
| `Animatto/DefaultCompanions/sayori.png` | Sayori (DDLC) | Doki Doki Literature Club | © Team Salvato / Dan Salvato | Team Salvato IP Guidelines (Commercial bundling strictly prohibited) | **Restricted** | **BLOCKER** |
| `Animatto/DefaultCompanions/umamusume.png` | Special Week | Uma Musume: Pretty Derby | © Cygames, Inc. | Proprietary; Commercial bundling strictly prohibited | **Restricted** | **BLOCKER** |
| `Animatto/DefaultCompanions/taiyaki.png` | Taiyaki Pastry | Generic pixel art sprite | Unknown | Unknown / Missing | **Unverified** | **BLOCKER** |
| `Animatto/DefaultCompanions/fattie.png` | Chubby Cat | Shimeji community sprite | Unknown | Unknown / Missing | **Unverified** | **BLOCKER** |
| `some characters/Chiikawa/*` (70 frames) | Chiikawa Animation Set | Shimeji / Community rip | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **BLOCKER** |
| `some characters/miku/*` (60 frames) | Hatsune Miku Shimeji | Shimeji community pack | © Crypton Future Media, INC. | Piapro Character License (Non-commercial only) | **Restricted** | **BLOCKER** |
| `some characters/nyan cat/*` (46 frames) | Nyan Cat Shimeji | Shimeji community pack | © Christopher Torres | Proprietary / Trademarked | **Restricted** | **BLOCKER** |
| `some characters/Sayori/*` (18 frames) | Sayori Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines (Non-commercial only) | **Restricted** | **BLOCKER** |
| `some characters/Monika/*` (18 frames) | Monika Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines (Non-commercial only) | **Restricted** | **BLOCKER** |
| `some characters/Natsuki/*` (18 frames) | Natsuki Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines (Non-commercial only) | **Restricted** | **BLOCKER** |
| `some characters/Yuri/*` (18 frames) | Yuri Shimeji | DDLC community pack | © Team Salvato | Team Salvato IP Guidelines (Non-commercial only) | **Restricted** | **BLOCKER** |
| `some characters/shimeji/*` (26 frames) | Original Shimeji Mascot | Group Finity Desktop Shimeji | © Yuki Arisato / Group Finity | Personal Freeware / Attribution Required | **Third-party** | **Conditioned** |
| `some characters/dance-usagi.gif` | Usagi Dance GIF | Chiikawa community animation | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **BLOCKER** |
| `some characters/usagi-chiikawa.gif` | Usagi Chiikawa GIF | Chiikawa community animation | © Nagano / Chiikawa Committee | Proprietary; No redistribution license | **Restricted** | **BLOCKER** |
| `web/sprites/*` (8 sprites) | Web Demo Sprites | Mirror of DefaultCompanions | Various (see above) | Various (see above) | **Restricted / Unverified** | **BLOCKER** |

---

## 4. Legal Risk Assessment for Proprietary Characters

### 4.1 Hatsune Miku (Crypton Future Media, INC.)
- **Governing Policy:** Piapro Character License (PCL) and Creative Commons BY-NC 3.0.
- **Restrictions:** Crypton Future Media allows fan-created non-commercial derivatives with explicit credit notices. However, embedding Miku as a pre-bundled default companion in a commercial product, charging for the software, or bundling without direct written permission from Crypton Future Media violates the PCL.

### 4.2 Chiikawa & Usagi (Nagano / Chiikawa Committee)
- **Governing Policy:** Japanese Copyright Act & Nagano Official IP Policy.
- **Restrictions:** Nagano and corporate licensees (Doga Kobo, Kodansha) maintain strict commercial controls. No open-source or public distribution licenses have ever been issued for these characters. Distributing 70+ animated frames directly inside the DMG package constitutes unauthorized reproduction and distribution.

### 4.3 Nyan Cat (Christopher Torres / Nyan Cat LLC)
- **Governing Policy:** US Copyright Registration VA0001809071; US Trademark Serial #85443214.
- **Restrictions:** Christopher Torres has successfully litigated against unauthorized commercial uses and third-party software bundling (*Charlesworth v. Warner Bros.*). Bundling Nyan Cat frames in an installer without an executed licensing contract represents a high-risk liability.

### 4.4 Doki Doki Literature Club (Team Salvato)
- **Governing Policy:** Team Salvato IP and Fan-Work Guidelines.
- **Restrictions:** Team Salvato explicitly states that fan games and community mods may not distribute official game assets commercially, may not charge fees for any software containing DDLC characters, and may not redistribute assets in standalone applications.

---

## 5. Remediation Plan & Recommendations

To bring Animatto into compliance for public beta and commercial release:

1. **Remove Proprietary Packs from Default Bundle:**
   - Remove `some characters/` from the root DMG installer distribution.
   - Replace the 6 proprietary default companions in `Animatto/DefaultCompanions/` with original mascots.
2. **Transition to Community Import Model:**
   - Rely on Animatto's native import mechanism (`AIToolsView` / `WorkshopService` / "Add from PC") where users import their own personal Shimeji folders from their local disk.
   - The native application remains an impartial desktop player engine, insulating the developers from copyright liability.
3. **Commission Original Mascots:**
   - Create 4–6 original starter companions (e.g. Animatto Cat, Cloud Bunny, Pixel Shiba, Cyberbot).
   - Release the original mascots under Creative Commons CC0 or Apache-2.0.
4. **License Status for Internal Beta:**
   - For an **unlisted, closed internal beta** with trusted paired testers evaluating physics and multi-monitor engines, these assets may be evaluated as private test fixtures.
   - Under **no circumstances** should the current DMG be published to public package managers (Homebrew Cask, Mac App Store, or unrestricted GitHub Releases) in its current state.

# Security Policy

The Animatto team takes the security of our application, user data, and privacy seriously. This document outlines our security policies, supported versions, and how to responsibly report vulnerabilities.

---

## Supported Versions

Only the latest release receive security patches. We recommend all users keep Animatto updated to the latest available version.

| Version | Supported          |
| :------ | :----------------- |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

---

## Reporting a Vulnerability

If you discover a security vulnerability or privacy flaw in Animatto, please report it responsibly:

1. **Private Reporting:** Please do **not** open a public GitHub issue for security vulnerabilities.
2. **GitHub Security Advisory:** Submit a confidential report via the **Security** tab → [Report a vulnerability](https://github.com/sharmao07/KinetiPet/security/advisories/new).
3. **Alternative Contact:** If GitHub Security Advisories are unavailable, contact the project maintainer directly via GitHub profile contact information.

### What to Include in Your Report
To help us triage and resolve the issue quickly, please provide:
- A clear description of the vulnerability and potential impact.
- Step-by-step instructions or proof-of-concept (PoC) code to reproduce the issue.
- Operating system version (e.g., macOS 14.6 Sonoma, macOS 15 Sequoia) and hardware architecture (Apple Silicon vs. Intel).
- Any relevant logs or crash dumps.

### Response Timeline
- **Initial Response:** Within 48 hours acknowledging receipt of your report.
- **Triage & Assessment:** Within 5 business days confirming whether the issue is reproducible and its severity.
- **Remediation & Release:** A fix will be developed, tested, and released as a patch release as quickly as feasible.
- **Public Disclosure:** We coordinate public disclosure with you after a fix is published.

---

## Security & Privacy Architecture

Animatto is designed with privacy-first principles on macOS:

* **On-Device Machine Learning:** The **Magic Eraser** segmentation tool runs 100% offline using Apple's native Vision framework (`VNGenerateForegroundInstanceMaskRequest`). No user images, GIF frames, or processing data are transmitted over the network.
* **Isolated Local IPC:** Discord Rich Presence uses a local Unix Domain Socket (`discord-ipc-0`) without exposing any public network ports or remote endpoints.
* **Transparent Window Overlays:** Desktop companions exist as frameless, floating `NSPanel` surfaces with `.screenSaver` window levels. They do not intercept or record keystrokes or user input from other applications.
* **No Unsolicited Telemetry:** Animatto does not include third-party tracking, advertising SDKs, or background telemetry.

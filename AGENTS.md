# AI Agent Instructions for Animatto

This file provides context and operational guidelines for autonomous coding agents (including Google Antigravity, OpenAI Codex, OpenAI ChatGPT, and Google Gemini) working on the Animatto codebase.

---

## 1. Project Context

Animatto is a native macOS companion application built with Swift and SwiftUI, accompanied by a promotional web demonstration in `web/`.

- **Primary macOS App:** Targets macOS 14.6 (Sonoma) and macOS 15+ (Sequoia) on Apple Silicon and Intel Macs.
- **Architectural Guidelines:** Follow the decoupled modular architecture detailed in [`CONTRIBUTING.md`](CONTRIBUTING.md).
- **Quality Standards:** High-performance, offline-first, battery-efficient, preserving user privacy.

---

## 2. Validation & Build Commands

Before proposing code changes:

```bash
# Fast unit test suite
swiftc -DDEBUG -sdk $(xcrun --show-sdk-path) $(ls Animatto/*.swift | grep -v AnimattoApp.swift) Tests/AnimattoTests.swift -o /tmp/animatto_tests && /tmp/animatto_tests

# Xcode build verification
xcodebuild -project Animatto.xcodeproj -scheme Animatto -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

---

## 3. Commit Attribution Protocol

When an AI tool materially contributes to writing, debugging, refactoring, or testing code in this repository:

1. **Human Authorship:** The human maintainer/contributor remains the Git commit `Author`. Never overwrite the author identity.
2. **Commit Trailer:** Append the appropriate `Co-authored-by:` trailer to the end of the commit message, separated by a blank line:
   - **Google Antigravity:** `Co-authored-by: Google Antigravity <antigravity.git@gmail.com>`
   - **OpenAI Codex:** `Co-authored-by: Codex <codex@openai.com>`
   - **OpenAI ChatGPT:** `Co-authored-by: ChatGPT <199175422+chatgpt-codex-connector[bot]@users.noreply.github.com>`
   - **Google Gemini:** `Co-authored-by: Google Gemini <200291788+gemini-code-assist@users.noreply.github.com>`
3. **Selective Attribution:** Only credit the specific tool(s) that actively contributed to the specific commit.
4. **Squash Merges:** When crafting Pull Requests or squash-merge summaries, ensure the trailer is retained at the very end of the squash commit message so attribution is preserved in `main`.

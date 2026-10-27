---
rating: B2a
spec: "0.1"
updated: 2026-10-27
---

# AI Code Rating

**ACR B2a** (Maintainer: Experienced · AI Share: 26–50% · Oversight: Verified)

This project is rated with [AI Code Rating](https://aicoderating.com/spec/0.1/), spec version 0.1.

## How AI Was Used

The maintainer wrote most of monmon's code by hand, starting in 2022, before AI coding agents were used on it. Since 2026, an AI coding agent has written a growing share of the changes, such as the install script's checks, the Ansible playbook's fixes for current Raspberry Pi OS, and the timing of the first check after the Raspberry Pi boots. The vendored Waveshare LCD driver and the old test code in `_ARCHIVE` aren't counted, since they aren't monmon's own code. The maintainer decides what each change should do and reads and checks every line the AI writes before it's committed.

AI-written changes are also reviewed by a second AI, and the two go back and forth until it doesn't find any more issues. That review doesn't change the oversight level. Commits are marked with `Co-Authored-By: Claude Code` and, where Codex reviewed them, `Reviewed-By: Codex`.

---
name: commit
description: Pre-commit review + atomic check + stage + commit + push.
model: opus
---

# /commit — Commit Changes

Execute these steps IN ORDER. Gate 4 must pass.

## Steps

1. **NOTES CHECK**: Verify Obsidian project notes are synced with current decisions.
2. **QUALITY**: Review code changes for quality, security, and correctness.
3. **ATOMIC CHECK**: Is this a single logical change? If not, split into multiple commits.
4. **STAGE**: Stage specific files (`git add file1 file2`). Never `git add .` blindly.
5. **COMMIT**: Conventional commit message with Co-Authored-By.
6. **PUSH**: Immediate. Commit = commit + push. Non-negotiable.

## Rules

- Gate 4: Quality check passed, no secrets, atomic change.
- No secrets in staged files.
- Backup tag every 3-4 commits.

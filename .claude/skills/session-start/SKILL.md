---
name: session-start
description: Start a dev session. Environment detect, Obsidian sync, recap, Blueprint check, pre-existing errors, plan.
model: opus
---

# /session-start — Begin Dev Session

Execute these steps IN ORDER. No skipping.

## Steps

1. **ENVIRONMENT**: Detect OS, machine (local/VPS), paths, shell. Display result.
2. **RECAP**: Read last 3 session reports from `docs/Sessions/` in project repo. Display summary: work done, decisions, pending items, errors.
3. **EICHI**: Verify Eichi-Shinkofa KB is accessible (Obsidian MCP or file system).
4. **OBSIDIAN SYNC**: Read `02-Projets/[project]/` in Obsidian vault via MCP — load project notes.
5. **BLUEPRINT CHECK**: Verify `docs/Blueprint.md` exists and is current.
6. **CDC CHECK**: Verify `docs/CDC.md` exists. Flag any drift from implementation.
7. **PRE-EXISTING ERRORS**: Run test suite. If ANY test fails, flag as priority.
8. **VEILLE CHECK**: Verify stack versions via npm/pypi/web. Training data is ALWAYS months stale. One wrong version = cascading failures in code, tests, deploys.
9. **LEGO AUDIT**: If the project uses UI components, cross-reference project imports against `@shinkofa/ui` inventory in `rules/Quality.md` → "Shinkofa Lego Library" section. Flag any locally-defined components that should be imported from the library, and note any new library components available since last session.
10. **PLAN**: Present today's plan based on pending items + Jay's request. Wait for validation.

## Rules

- Pre-existing test failures MUST be addressed. Never ignore.
- If Blueprint or CDC is missing, suggest running `/concevoir` first.
- Obsidian project notes must be read before any work begins.
- Gate 0 must pass before ANY work begins.

See `mnk/05-Workflows.md` WF-01 for full details.

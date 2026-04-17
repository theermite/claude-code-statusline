---
name: session-start
description: Start a dev session. Environment detect, Obsidian sync, recap, Blueprint check, pre-existing errors, plan.
model: opus
---

# /session-start — Begin Dev Session

Execute these steps IN ORDER. No skipping (unless LITE_MODE applies — see Step 0).

## Steps

0. **PROJECT TYPE DETECTION**: Check for the presence of AT LEAST ONE of these files at the repo root: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`, `docker-compose.yml`, `pom.xml`, `build.gradle`. If **NONE** found → activate **LITE_MODE**. Display: `LITE_MODE: ON (non-code project)` or `LITE_MODE: OFF (code project detected: [filename])`. LITE_MODE skips steps 5, 6, 7, 8, 9 (marked below). All other steps run normally.

1. **ENVIRONMENT**: Detect OS, machine (local/VPS), paths, shell. Display result.
2. **OBSIDIAN SYNC (MANDATORY — BLOCKING)**: Read the **entire** `01-Projets/` folder in Obsidian vault via MCP. Load ALL files at once in parallel:
   - Meta: `_Index.md`, `_Marathon-Context.md`, `_Infrastructure.md`, `_Legacy-Index.md`
   - All project files: one `.md` per project (flat structure — no nested folders). At time of writing: `Koshin.md`, `Takumi.md`, `Kakusei.md`, `The-Ermite.md`, `Hikari-Deck.md`, `SLF-Esport.md`, `Discord.md`, `Eichi-Shinkofa.md`, `Hibiki.md`, `Michi-Shinkofa.md`, `Michi-Niwa.md`, `MNK-GoRin.md`, `Nagare.md`, `Shizen.md`, `Kisshin.md`, `Shinkofa-MCP.md`, `Telegram-Bots.md`, `Transition-Linux.md`, `Bibliotheque-Lego.md`, `Floorp.md`, `Contenu.md`, plus any new file added since.
   - **New flat structure** (post 2026-04-11): one file per project, no nested folders. The old `02-Projets/[project]/{Notes,Bugs,Decisions,Prochaines-Etapes}.md` structure is **LEGACY** — do not read it unless `01-Projets/` is missing something explicitly.
   - **If Obsidian MCP is unreachable: STOP. Do not proceed. Escalate to Jay.**
   This is the canonical project memory system — skipping it wastes context reconstruction every session and counts as `-20` on the session score.
3. **EICHI**: Verify Eichi-Shinkofa KB is accessible (Obsidian MCP or file system). Load relevant domains (not just tech).
4. **RECAP**: Read last 3 session reports from `docs/Sessions/` in project repo. Display summary: work done, decisions, pending items, errors.
5. **BLUEPRINT CHECK** *(SKIP in LITE_MODE)*: Verify `docs/Blueprint.md` exists and is current.
6. **CDC CHECK** *(SKIP in LITE_MODE)*: Verify `docs/CDC.md` exists. Flag any drift from implementation.
7. **PRE-EXISTING ERRORS** *(SKIP in LITE_MODE)*: Run test suite. If ANY test fails, flag as priority.
8. **VEILLE CHECK** *(SKIP in LITE_MODE)*: Verify stack versions via npm/pypi/web. Training data is ALWAYS months stale. One wrong version = cascading failures in code, tests, deploys.
9. **LEGO AUDIT** *(SKIP in LITE_MODE)*: If the project uses UI components, cross-reference project imports against `@shinkofa/ui` inventory in `rules/Quality.md` → "Shinkofa Lego Library" section. Flag any locally-defined components that should be imported from the library, and note any new library components available since last session.
10. **PLAN**: Present today's plan based on pending items + Jay's request. Wait for validation.

## Rules

- **Obsidian project notes reading is BLOCKING and non-negotiable** (step 2). A session that starts without it is a process violation. If MCP fails, escalate — never skip.
- Pre-existing test failures MUST be addressed (code projects only — N/A in LITE_MODE).
- If Blueprint or CDC is missing on a code project, suggest running `/concevoir` first.
- Gate 0 must pass before ANY work begins.
- If a hook, tool, or system rule blocks any of these steps: apply the Post-Block Recovery Protocol (`mnk/11-Post-Block-Recovery.md`). Never stay passive.

See `mnk/05-Workflows-Session.md` WF-01 for full details.

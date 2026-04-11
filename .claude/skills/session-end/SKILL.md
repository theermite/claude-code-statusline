---
name: session-end
description: End dev session. Full test suite, session report, Obsidian sync, docs update, scoring, save report.
model: opus
---

# /session-end — Close Dev Session

Execute these steps IN ORDER. Gate 8 must pass.

## Steps

1. **TESTS**: Run full test suite. Record pass/fail counts.
2. **REPORT**: Generate session report containing:
   - Work done (features completed, bugs fixed)
   - Tests: passed / failed / new tests written
   - Errors encountered + corrections applied
   - Decisions made
   - Pending items for next session
3. **OBSIDIAN SYNC**: Update Obsidian `01-Projets/[project].md` (flat structure — one file per project). Merge the session's decisions, bugs, and next steps into the relevant project file(s). Update cross-project connections if the session touched multiple projects. The old nested `02-Projets/[project]/{Notes,Bugs,Decisions,Prochaines-Etapes}.md` structure is LEGACY — do not create or update files there.
4. **DOCS UPDATE**: Ensure Blueprint, CDC, PET reflect current state. Update if changed.
5. **PENDING**: List remaining items explicitly.
6. **SCORING**: Calculate `Score = 100 - (violations x 10) - (warnings x 2)`.
7. **VISIBILITY CHECK**: Evaluate if this session produced something shareable. For each candidate, append a ready-to-publish entry to Obsidian `01-Projets/Contenu.md` under the "Idées / candidates" section (one bullet per idea with title + format + status). Options: mini-repo (reusable standalone solution), article (educational, common problem solved), PR/contribution (fix or improvement to an existing open-source project). If nothing qualifies, document "nothing shareable this session" in the report.
8. **SAVE**: Store report in `docs/Sessions/Session-YYYY-MM-DD-NNN.md`.

## Rules

- Gate 8: Obsidian synced, report written, docs updated, visibility check done.
- Session report serves as comparison point for next session.
- Next `/session-start` reads these reports.
- Never end a session with uncommitted work (atomic commit check).

See `mnk/05-Workflows.md` WF-10 for full details.

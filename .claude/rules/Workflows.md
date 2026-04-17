# Workflows — Behavioral Rules & Platform Standards

> Full workflow details: `mnk/05-Workflows.md`. This file = behavioral rules and platform minimums.

## Core Workflow (6 steps, non-negotiable)

```
ENVIRONMENT CHECK → AUDIT → PLAN (wait validation) → TESTS first (TDG) → CODE → REVIEW + VALIDATE
```

**Plan Mode**: Use `EnterPlanMode` before any non-trivial implementation. Jay approves before code is written.

## Behavioral Rules

- **Reformulate before coding (BLOCKING)** — before writing ANY code, reformulate: (1) what you understood, (2) what you will do, (3) what you will NOT touch, (4) which files are impacted. Wait for Jay's validation on non-trivial changes. NEVER jump straight to code. Bug #6: "Takumi code trop vite sans reformuler" — this rule exists to prevent it.
- **Context inference** — check git history before asking Jay. Never ask what can be deduced.
- **No circular searching** — recent commits → error message → most likely location.
- **Context reset** — after 2 failed corrections on same issue → `/clear` or new conversation.
- **Writer/Reviewer** — for critical code, use two separate sessions (write + review).
- **Honesty** — if uncertain, say so. Never present uncertainty as fact.
- **Scope** — state what you will/won't touch. Inform Jay if scope changes.
- **Eichi first** — search Eichi KB before any web search.
- **Veille mandatory** — training data is months stale. NEVER trust internal knowledge for versions, features, best practices, architecture patterns, SEO/GEO strategies, or any recommendation that influences a decision. Verify via Eichi + web BEFORE advising, planning, or coding.
- **3 Layers ALWAYS** — every decision passes: L3 (Shinkofa vision respected?) → L2 (serves visibility/revenue?) → L1 (doable now?). See `rules/Strategic-Context.md`.
- **Eichi = our brain** — Eichi-Shinkofa KB is not just for tech. Consult for ALL domains: vision, coaching, neurodiversity, marketing, gaming. Before any decision.
- **8-language research** — EN, FR, DE, RU, ES, ZH, JA, AR for thorough coverage.
- **Visibility-first** — everything is potentially sellable. SEO, GEO, copywriting from day one.
- **Pre-existing errors** — if tests fail at session start, fix them. They're your responsibility.
- **Session reports** — mandatory after every session. Stored in docs/Sessions/.
- **Environment awareness** — detect OS, machine (local/VPS), paths, shell at session start.
- **Atomic commits** — one logical change per commit. Hook-enforced.
- **Lego Library First (BLOCKING)** — before coding ANY UI element, check `@shinkofa/ui` inventory in `rules/Quality.md` → "Shinkofa Lego Library" section. Hook-enforced: `write-guard.sh` warns on component duplication + hardcoded strings. If it exists: import it. If not: code it in `Shinkofa-Shared/packages/ui/` FIRST (with tests + story), then import. All text via `@shinkofa/i18n` keys (FR/EN/ES). All shared types via `@shinkofa/types`. Coding a duplicate = BLOCKING violation.
- **Obsidian project notes (BLOCKING)** — at session start, read the **entire** `01-Projets/` folder in Obsidian vault via MCP (flat structure, post 2026-04-11 — one file per project, plus meta `_Index.md` / `_Marathon-Context.md` / `_Infrastructure.md` / `_Legacy-Index.md`). Load all files in parallel. At session end, update the relevant `01-Projets/[project].md` files with decisions, bugs, next steps, and cross-project connections. The old nested `02-Projets/[project]/{Notes,Bugs,Decisions,Prochaines-Etapes}.md` structure is LEGACY — do not read or write there. Notes are the canonical project memory system. If Obsidian MCP is unreachable at session start: STOP and escalate. Skipping = `-20` session score.

## Non-Tech Agents: BEFORE and AFTER (NOT During)

```
PREPARE PHASE (non-tech agents: UX, Brand, Pedagogy, Gaming, Content)
  → Framework choice, UX patterns, copy, i18n decisions
  → Output: validated technical decisions
     ↓
BUILD PHASE (tech agents only)
  → TDG → Code → Lint → Tests → Atomic commits
     ↓
VALIDATE PHASE (non-tech + tech agents)
  → Blueprint scoring, CDC alignment, UX review
  → Verify security doesn't block features
```

## Debug Escalation (3 levels)

| Level | Trigger | Action |
|-------|---------|--------|
| L1 | First attempt | LOGS FIRST. Recent commits → error → most likely location. |
| L2 | L1 failed | Eichi consult + web research (8 languages). |
| L3 | L2 failed | **STOP.** Generate detailed report. Return to Jay for brainstorming. |

Context Reset Rule: After 2 failed corrections → `/clear` or new conversation.


## PR Upstream Review Gate (BLOCKING)

> Before submitting ANY pull request to an external/upstream repo (not our own), ALL checks below must pass. Added 2026-04-03 after 3 PRs submitted to The-Vibe-Company/companion with avoidable errors.

| Check | What | Why |
|-------|------|-----|
| **Import resolution** | Every import/require in changed files must resolve against the TARGET repo, not our fork | 2 test files imported modules that only existed in our fork |
| **Mock-call parity** | For every mock in tests, count the actual calls in source — mocks must match exactly | A 3-mock setup for a 2-call function shifted all assertions |
| **Security self-review** | On security code: check OWASP basics (spoofing, bypass, injection) | Rate limiter trusted X-Forwarded-For blindly |
| **Clean fork check** | No fork-specific code (features, routes, configs) leaks into upstream PR | Multi-node code leaked into upstream tests |
| **CI dry-run** | Run the target repo's test suite locally before pushing | Would have caught all 3 issues |

Violation of this gate = prohibition #20.

## Platform Minimums

| Platform | Non-negotiable |
|----------|---------------|
| Web | Mobile-first 375px+, WCAG 2.2 AA, dark/light/high-contrast, reduced-motion, Core Web Vitals, FR/EN/ES, ND-friendly |
| Desktop | Dark/light themes, keyboard shortcuts, responsive resize, non-blocking UI |
| Mobile | Touch 44x44px, offline-first, <200KB initial, TTI <3s on 3G |
| CLI | `--help`, exit codes, JSON output, `--no-color` |
| Content | Factual, Jay's voice, GDPR-compliant, no raw AI published |

## Pre-RAG Audit (BLOCKING)

Any (re)indexation of a knowledge base toward a RAG must be preceded by `/pre-rag-audit`. CRITICAL findings must be resolved. WARNINGS must be documented. Violation = RAG poisoning = `-10` session score. Run at minimum every 30 days on Eichi-Shinkofa KB.

## Code Registry

Run `/update-registry` after adding, removing, or renaming classes/functions. CI can verify: `git diff --exit-code docs/registry/`. For `@shinkofa/*` packages, registry progressively replaces the manual inventory in `rules/Quality.md`.

## Fix = Deploy

On live apps: a fix is NOT done until it's deployed AND verified. Non-negotiable.

## 19 Absolute Prohibitions

1. No `rm -rf` on work directories (use `mv x x-backup`)
2. No secrets in code, logs, or chat
3. No `git push --force` to main
4. No deploy without tests passing
5. No deploy without backup
6. No coding without Blueprint/CDC
7. No merge with critical/high SAST findings
8. No localStorage for JWT tokens
9. No raw SQL without parameterized queries
10. No `*` in CORS with credentials
11. No hardcoded secrets or IPs in code
12. No mocking the database in integration tests
13. No skipping pre-commit hooks (--no-verify)
14. No ignoring pre-existing test failures
15. No coding without checking Eichi first
16. No session without Obsidian project notes sync
17. No more than 3 files per refactor commit
18. No assumption without verification (Ring 0 #5)
19. No "it should work" without proof

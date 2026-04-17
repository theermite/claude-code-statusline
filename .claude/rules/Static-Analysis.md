# Static Analysis Stack — Thresholds by Project Type

> Inspired by Exomondo's audit methodology on Hibiki. One linter is never enough.
> Templates: `templates/static-analysis/`. Canonical commands: `templates/static-analysis/README.md`.

## Python (PySide6, FastAPI, scripts, bots)

| Tool | Role | Pre-commit | CI |
|------|------|------------|-----|
| Ruff | Lint + format (fast) | Yes | Yes |
| Pylint | Deep analysis, cyclic imports, score /10 | No | Yes |
| Bandit | Security scanner (OWASP Python) | No | Yes |
| Vulture | Dead code detection | No | Yes |
| Radon | Cyclomatic complexity + maintainability index | No | Yes |
| mypy | Type checking (strict) | No | Yes |
| pip-audit | CVE dependency scan | No | Yes |

| Metric | Threshold | Blocking? |
|--------|-----------|-----------|
| Ruff errors | 0 | Yes |
| Pylint score | >= 8/10 | Warning < 8 |
| Bandit HIGH | 0 | Yes |
| Bandit MED | 0 | Warning |
| Vulture unused (>80% confidence) | 0 | Warning |
| Radon CC max per function | <= 15 (C) | Warning; > 30 = blocking |
| Radon CC average | <= 5 (A) | Warning |
| Radon MI | >= 60 (B) | Warning |
| mypy errors | 0 | Yes (typed code) |
| pip-audit HIGH/CRITICAL | 0 | Yes |

## TypeScript / JavaScript (Next.js, Vite, Electron, React)

| Tool | Role | Pre-commit | CI |
|------|------|------------|-----|
| Biome | Lint + format (fast) | Yes | Yes |
| tsc | Type checking | No | Yes |
| Madge | Circular imports detection | No | Yes |
| Knip | Dead code + unused deps | No | Yes |
| eslint-plugin-security | Security lint (OWASP JS) | No | Yes |
| npm audit | CVE dependency scan | No | Yes |

| Metric | Threshold | Blocking? |
|--------|-----------|-----------|
| Biome errors | 0 | Yes |
| tsc errors | 0 | Yes |
| Madge circular deps | 0 | Yes |
| Knip unused exports | 0 | Warning |
| Knip unused deps | 0 | Yes |
| npm audit HIGH/CRITICAL | 0 | Yes |
| Complexity max (Biome rule) | <= 15 | Warning; > 20 = blocking |

## Astro (sites, landing pages)

Inherits TypeScript stack above, plus:

| Tool | Role |
|------|------|
| astro check | Astro-specific type diagnostics |
| Lighthouse CI | Performance, a11y, SEO, best practices |
| pa11y-ci | Accessibility multi-page |

| Metric | Threshold | Blocking? |
|--------|-----------|-----------|
| astro check errors | 0 | Yes |
| Lighthouse Performance | >= 90 | Yes (pre-deploy) |
| Lighthouse Accessibility | >= 95 | Yes (pre-deploy) |
| Lighthouse SEO | >= 95 | Yes (pre-deploy) |
| pa11y errors | 0 | Yes (pre-deploy) |

## Bash (scripts, hooks)

| Tool | Role |
|------|------|
| ShellCheck | Static analysis for shell scripts |

| Metric | Threshold | Blocking? |
|--------|-----------|-----------|
| ShellCheck errors | 0 | Yes |

## Docker

| Tool | Role |
|------|------|
| Hadolint | Dockerfile linter |
| Trivy | Image + repo CVE + secrets scan |

| Metric | Threshold | Blocking? |
|--------|-----------|-----------|
| Hadolint errors | 0 | Yes |
| Trivy HIGH/CRITICAL | 0 | Yes (pre-deploy) |

## SQL (migrations)

| Tool | Role |
|------|------|
| SQLFluff | SQL linter (PostgreSQL dialect) |

## Transversal (all projects)

| Tool | Role |
|------|------|
| Gitleaks | Secret detection in git history |
| Semgrep | SAST multi-language (OWASP rules) |
| CycloneDX / Syft | SBOM generation (EU CRA 2026) |

| Metric | Threshold | Blocking? |
|--------|-----------|-----------|
| Gitleaks findings | 0 | Yes |
| Semgrep HIGH/CRITICAL | 0 | Yes |

## Pre-commit vs CI Split

**Pre-commit** (must be fast, <5s): Ruff, Biome, ShellCheck.
**CI** (thorough, can be slow): Pylint, Bandit, Vulture, Radon, mypy, Madge, Knip, Trivy, Semgrep, Gitleaks.

## Application Order

1. Test on **Hibiki** first (already partially instrumented by Exomondo)
2. Validate with Jay
3. Propagate via `/sync-repo` by project group
4. One group per session — never big-bang

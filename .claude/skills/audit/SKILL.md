---
name: audit
description: Project audit. Blueprint scoring (>=95%), veille, quality, security, performance, accessibility, visibility, docs, plan.
model: opus
---

# /audit — Audit a Project

Modes: `--audit` (diagnostic only), default (audit + plan), `--fix` (audit + auto-apply simple fixes), `--visibility` (magnetic visibility audit).

## Steps

1. **BLUEPRINT SCORE**: Check items / applicable items from matching Blueprints. Minimum 95%.
2. **3-LAYER ALIGNMENT**: Does this project serve L3 (Shinkofa vision — individuality, adaptation, invisible quality)? Is L2 (presentation/visibility) addressed? Is L1 (next action) clear? Consult Eichi MasterPlan for alignment.
3. **VEILLE**: State-of-art freshness (< 14 days). Verify dependency versions via npm/pypi/web. **CRITICAL**: Also verify that quality standards (WCAG, OWASP, CWV criteria), best practices, and architecture patterns referenced in this audit are current — training data is months stale.
4. **QUALITY**: All BLOCKING gates from `rules/Quality.md` verified. Verify current testing framework recommendations via web.
5. **SECURITY**: OWASP scan, dependencies, secrets, headers. CSP tested against features. Verify current OWASP Top 10 list via web (it changes).
6. **PERFORMANCE**: Core Web Vitals targets. Verify current Google thresholds via web (they evolve).
7. **ACCESSIBILITY**: axe-core, WCAG compliance. Verify current WCAG version and criteria via web.
8. **VISIBILITY**: SEO meta, structured data, GEO signals (if public-facing).
9. **DOCS CHECK**: Blueprint, CDC, PET match current reality.
10. **PLAN**: Generate structured execution plan for fixes with priorities.

## Visibility Audit Mode (`--visibility`)

When invoked with `--visibility`, run an extended visibility-specific audit:

| Check | What to verify |
|-------|---------------|
| **Big 5 Content** | Does the platform answer: pricing/costs, problems/downsides, comparisons, reviews, best-of? (They Ask You Answer method) |
| **SEO Foundation** | Meta tags, sitemap.xml, robots.txt, semantic HTML, internal linking, page speed |
| **GEO (AI Optimization)** | Structured data (Schema.org JSON-LD), E-E-A-T signals, citability formatting, entity clarity |
| **Email Capture** | Lead magnet present? Signup form on key pages? Automated nurture sequence? |
| **UX/Presentation** | Does the presentation sell the product? First impression, hero section, clear value proposition, CTA |
| **Projector Alignment** | Does the platform attract by invitation? No aggressive popups, no dark patterns, quality speaks for itself |
| **Content Freshness** | Last update date? Content < 3 months old? Active blog/articles? |
| **Cross-Platform** | Links to all active platforms? Solo.to linked? Social proof visible? |
| **Auto-Pipeline** | Is content auto-distributed to LinkedIn/Discord/Telegram/Dev.to/etc.? Video pipeline active? |
| **Mobile** | Mobile-first? Touch-friendly? Fast on 3G? |

Output: scored checklist + prioritized action plan for magnetic visibility improvements.

## Rules

- Gate 7: Every finding verified via external source.
- Score < 95% → correction plan required. No audit accepted below 95%.
- Consult Eichi BEFORE web research for patterns and known issues.
- Visibility audit: verify current SEO/GEO best practices via web before scoring.

See `mnk/05-Workflows.md` WF-09 for full details.

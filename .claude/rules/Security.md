# Security

> Principles: Defense in depth. Zero Trust. Least privilege. Secure by default.
> CRITICAL: Security must be verified NOT to block features. Every CSP, header, and policy must be tested against actual functionality.

## Authentication & Authorization

### JWT
- **httpOnly cookies ONLY** — never localStorage (hook-enforced)
- Algorithm: RS256 or ES256 (never HS256 in production)
- Access token: 15-30 min expiry
- Refresh token: rotated on each use, Redis blacklist for revocation
- Logout = blacklist both tokens immediately

### Passwords
- Argon2id (NIST 2023+ recommendation) or bcrypt ≥ 12 rounds
- Check against breached password lists (HaveIBeenPwned API)
- Minimum 12 characters, no arbitrary complexity rules

### RBAC
- Roles defined in database, not hardcoded
- `app_user` DB account: SELECT, INSERT, UPDATE only — no DELETE, no DROP
- RLS (Row Level Security) for multi-tenant data isolation

## Input Validation (4 layers)

1. **Schema validation** — Zod (frontend) / Pydantic (backend). Every endpoint.
2. **Business logic validation** — Domain rules (e.g., "can't book past date")
3. **Sanitization** — DOMPurify for user HTML. Parameterized queries only.
4. **Output encoding** — Context-aware escaping before rendering

Raw request body without validation = BLOCKING finding.

## Security Headers

| Header | Value |
|--------|-------|
| Strict-Transport-Security | `max-age=63072000; includeSubDomains; preload` |
| Content-Security-Policy | Nonce-based. **Test that it doesn't break features.** |
| X-Content-Type-Options | `nosniff` |
| X-Frame-Options | `DENY` (or `SAMEORIGIN` if iframe needed) |
| Referrer-Policy | `strict-origin-when-cross-origin` |
| Permissions-Policy | Restrict camera, microphone, geolocation |
| X-XSS-Protection | `0` (deprecated, CSP replaces it) |

## Rate Limiting

| Endpoint type | Limit |
|---------------|-------|
| Login / register | 5 attempts / 15 min |
| API (authenticated) | 100 requests / min |
| File uploads | 10 / hour |
| Password reset | 3 / hour |

## CORS
- Never `Access-Control-Allow-Origin: *` with credentials
- Whitelist specific origins only

## GDPR Compliance
- Right to erasure: `DELETE /api/users/me` must cascade-delete all user data
- Right to export: `GET /api/users/me/export` returns all user data as JSON
- Breach notification: within 72 hours
- Processing register: document what data is collected and why
- Cookie consent: explicit opt-in for non-essential cookies

## Dependencies
- `npm audit` / `pip-audit` on every CI run
- Zero critical/high CVEs at deploy time (BLOCKING)
- SBOM generation with CycloneDX on each release (EU CRA 2026)
- SAST: Semgrep + CodeQL on every PR to main

## LLM Security
- **Never execute LLM output as code** without human review
- Prompt injection testing on all LLM-facing inputs
- LLM responses are untrusted data — sanitize before rendering
- Rate limit LLM API calls separately from regular API

## Hook Security
- Any PR modifying `.claude/hooks/` requires production-level review
- Hook scripts run with minimal permissions
- No network calls from hooks without explicit documentation

## Vulnerability Response SLA

| Severity | Response time |
|----------|--------------|
| Critical | < 4 hours |
| High | < 1 day |
| Medium | < 1 week |
| Low | Next sprint |

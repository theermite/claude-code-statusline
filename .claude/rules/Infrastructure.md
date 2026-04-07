# Infrastructure

> This file is a TEMPLATE. Each project gets a customized version with its specific ports, domains, and Docker config.

## VPS OVH

8 cores, 22GB RAM, Ubuntu 25.04. **SSH**: `ssh vps` (ALWAYS alias, never IP). Key auth only.

## Port Registry

**Source of truth**: Centralized in `Shinkofa-Infra` repo.
Ranges: 3000-3099 (web), 5000-5099 (Node APIs), 5400-5499 (PostgreSQL), 6300-6399 (Redis), 8000-8099 (FastAPI)

Consult BEFORE any deploy, container creation, or nginx change.

## Docker Rules

- One Dockerfile per service
- Multi-stage builds for production images
- Non-root user in containers
- Health checks in compose files
- Named volumes for persistent data (NEVER anonymous volumes)
- `--no-cache` after any fix before redeploy
- Pin image versions (never use `:latest` in production)

## Environment Awareness

At session start, detect and confirm:
- OS: Windows / Linux / macOS
- Machine: local (Ermite-Game) / VPS / other
- Shell: bash / PowerShell / zsh
- Paths: use correct separators and conventions
- SSH: use `/c/Windows/System32/OpenSSH/ssh.exe` on Windows (not Git Bash ssh)

## Infrastructure Documentation (mandatory per project)

| Document | Location | Content |
|----------|----------|---------|
| Blueprint | `docs/Blueprint.md` | Architecture, tech choices, why |
| CDC | `docs/CDC.md` | Full requirements specification |
| PET | `docs/PET.md` | Technical execution plan |
| Port assignment | Shinkofa-Infra Port Registry | Which port this project uses |
| Docker config | `docker-compose.yml` | Container definitions |
| Nginx config | Shinkofa-Infra/nginx/ | Domain routing |

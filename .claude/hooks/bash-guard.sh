#!/bin/bash
# Unified Bash PreToolUse guard — all checks in one script
# Reduces Claude Code UI noise (1 hook entry instead of 9)
# Compatible: Git Bash on Windows (no grep -P)
#
# RECOVERY PRINCIPLE: Every BLOCKED/WARNING message MUST include
# a concrete recovery action so Takumi knows what to do next.

INPUT=$(cat)
CMD=$(echo "$INPUT" | sed -n 's/.*"command" *: *"\(.*\)".*/\1/p' | head -1)

# === RING 0 #1: SECRETS DETECTION ===
PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'
  'sk_live_[a-zA-Z0-9]+'
  'sk_test_[a-zA-Z0-9]+'
  'pk_live_[a-zA-Z0-9]+'
  'ghp_[a-zA-Z0-9]{36}'
  'gho_[a-zA-Z0-9]{36}'
  'github_pat_[a-zA-Z0-9]+'
  'Bearer [a-zA-Z0-9._-]+'
  'PRIVATE KEY'
)
for pattern in "${PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qiE "$pattern"; then
    echo "BLOCKED: Secret pattern detected ($pattern). RECOVERY: Replace the secret with an environment variable reference (e.g., \$VAR or process.env.VAR). Store the value in .env (gitignored). Retry without the secret." >&2
    exit 2
  fi
done
if echo "$INPUT" | grep -qiE 'password\s*[:=]\s*"[^$][^"]{3,}'; then
  echo "BLOCKED: Hardcoded password detected. RECOVERY: Move password to .env file, reference via environment variable, then retry." >&2
  exit 2
fi

# === RING 0 #2: DESTRUCTIVE GUARD ===
if echo "$INPUT" | grep -qE 'rm -rf|rm -fr|rmdir /s'; then
  if ! echo "$INPUT" | grep -qE '(node_modules|\.next|__pycache__|\.cache|\.pytest_cache|dist/\.)'; then
    echo "BLOCKED: rm -rf on non-cache directory. RECOVERY: Use 'mv <target> <target>-backup' instead. If deletion is truly needed, ask Jay for explicit confirmation first." >&2
    exit 2
  fi
fi
if echo "$INPUT" | grep -qiE 'DROP (TABLE|DATABASE|SCHEMA)|TRUNCATE |DELETE FROM .* WHERE 1|DELETE FROM [a-z]+ *;'; then
  echo "BLOCKED: Destructive SQL detected. RECOVERY: Run pg_dump backup first, then ask Jay for explicit confirmation. Never execute destructive SQL without a verified backup." >&2
  exit 2
fi

# === RING 1: REFACTOR FILE COUNT (warning) ===
if echo "$INPUT" | grep -q "git commit"; then
  MSG=$(echo "$INPUT" | grep -oE "(feat|fix|refactor|docs|chore|test|perf|ci|style)(\([a-zA-Z0-9_-]+\))?:.*" | head -1)
  if echo "$MSG" | grep -qi "refactor"; then
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
    if [ "$STAGED" -gt 5 ]; then
      echo "WARNING: Refactor commit touches $STAGED files (max: 5). ACTION: Split into smaller commits. Use 'git reset HEAD <files>' to unstage excess, commit first batch (max 3-5 related files), then stage and commit the rest." >&2
    fi
  fi
fi

# === RING 1: GIT ADD GUARD ===
# Block "git add ." and "git add -A" but allow "git add .claude/..." etc.
if echo "$INPUT" | grep -qE 'git add (\.|--all|-A)( |"|;|&&|\||\)|$)'; then
  echo "BLOCKED: Broad git add detected. RECOVERY: Use 'git add <specific files>' instead. List the files you intend to commit and add them by name. This prevents accidentally staging .env, credentials, or large binaries." >&2
  exit 2
fi

# === RING 1: DEPLOY CHECK (VPS targets only) ===
IS_DEPLOY=false
echo "$INPUT" | grep -qiE "scp .* vps|rsync .* vps" && IS_DEPLOY=true
echo "$INPUT" | grep -qiE "ssh .*(deploy|restart|systemctl)" && IS_DEPLOY=true
echo "$INPUT" | grep -qiE "docker compose.*up.*-d.*vps|docker-compose.*up.*-d.*vps" && IS_DEPLOY=true
if [ "$IS_DEPLOY" = true ]; then
  echo "WARNING: VPS deploy detected. ACTION: Before proceeding, verify: (1) all tests pass, (2) backup exists (pg_dump or git tag), (3) no uncommitted changes. If all checks pass, continue. If not, run the missing checks first." >&2
fi

# === RING 1: DB MIGRATION GUARD ===
if echo "$INPUT" | grep -qiE "alembic upgrade|prisma migrate|prisma db push"; then
  echo "WARNING: DB migration detected. ACTION: Run pg_dump backup BEFORE the migration. If already done in this session, continue. If not, run: pg_dump -Fc <dbname> > backup-\$(date +%Y%m%d-%H%M).dump, then retry." >&2
fi

# === RING 1: DEPENDENCY VERSION VEILLE ===
if echo "$INPUT" | grep -qiE "npm install [a-z@]|pnpm add [a-z@]|pip install [a-z]|yarn add [a-z@]"; then
  if echo "$INPUT" | grep -qE '@[0-9]+\.[0-9]+|==[0-9]+\.[0-9]+|>=[0-9]+\.[0-9]+'; then
    echo "WARNING: Specific version in install command. ACTION: Verify this version exists via npm/pypi/web (training data is months stale). If already verified, continue. If not, check first, then retry." >&2
  fi
fi

exit 0

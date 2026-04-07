#!/bin/bash
# Unified Bash PreToolUse guard — all checks in one script
# Reduces Claude Code UI noise (1 hook entry instead of 9)
# Compatible: Git Bash on Windows (no grep -P)

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
    echo "BLOCKED: Secret pattern detected ($pattern). Use environment variables."
    exit 2
  fi
done
if echo "$INPUT" | grep -qiE 'password\s*[:=]\s*"[^$][^"]{3,}'; then
  echo "BLOCKED: Hardcoded password detected. Use environment variables."
  exit 2
fi

# === RING 0 #2: DESTRUCTIVE GUARD ===
if echo "$INPUT" | grep -qE 'rm -rf|rm -fr|rmdir /s'; then
  if ! echo "$INPUT" | grep -qE '(node_modules|\.next|__pycache__|\.cache|\.pytest_cache|dist/\.)'; then
    echo "BLOCKED: rm -rf detected. Use 'mv x x-backup' instead."
    exit 2
  fi
fi
if echo "$INPUT" | grep -qiE 'DROP (TABLE|DATABASE|SCHEMA)|TRUNCATE |DELETE FROM .* WHERE 1|DELETE FROM [a-z]+ *;'; then
  echo "BLOCKED: Destructive SQL detected. Requires explicit confirmation."
  exit 2
fi

# === RING 1: REFACTOR FILE COUNT (warning) ===
if echo "$INPUT" | grep -q "git commit"; then
  MSG=$(echo "$INPUT" | grep -oE "(feat|fix|refactor|docs|chore|test|perf|ci|style)(\([a-zA-Z0-9_-]+\))?:.*" | head -1)
  if echo "$MSG" | grep -qi "refactor"; then
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
    if [ "$STAGED" -gt 5 ]; then
      echo "WARNING: Refactor commit touches $STAGED files (recommended max: 5). Consider splitting."
    fi
  fi
fi

# === RING 1: GIT ADD GUARD ===
# Block "git add ." and "git add -A" but allow "git add .claude/..." etc.
if echo "$INPUT" | grep -qE 'git add (\.|--all|-A)( |"|;|&&|\||\)|$)'; then
  echo "BLOCKED: Use 'git add <specific files>' instead of 'git add .' or 'git add -A'."
  exit 2
fi

# === RING 1: DEPLOY CHECK (VPS targets only) ===
IS_DEPLOY=false
echo "$INPUT" | grep -qiE "scp .* vps|rsync .* vps" && IS_DEPLOY=true
echo "$INPUT" | grep -qiE "ssh .*(deploy|restart|systemctl)" && IS_DEPLOY=true
echo "$INPUT" | grep -qiE "docker compose.*up.*-d.*vps|docker-compose.*up.*-d.*vps" && IS_DEPLOY=true
if [ "$IS_DEPLOY" = true ]; then
  echo "WARNING: VPS deploy detected. Verify backup + tests before proceeding."
fi

# === RING 1: DB MIGRATION GUARD ===
if echo "$INPUT" | grep -qiE "alembic upgrade|prisma migrate|prisma db push"; then
  echo "WARNING: DB migration detected. Was pg_dump run first?"
fi

# === RING 1: DEPENDENCY VERSION VEILLE ===
if echo "$INPUT" | grep -qiE "npm install [a-z@]|pnpm add [a-z@]|pip install [a-z]|yarn add [a-z@]"; then
  if echo "$INPUT" | grep -qE '@[0-9]+\.[0-9]+|==[0-9]+\.[0-9]+|>=[0-9]+\.[0-9]+'; then
    echo "VEILLE GUARD: Specific version detected. Verify it exists via npm/pypi/web — training data is months stale."
  fi
fi

exit 0

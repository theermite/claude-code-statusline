#!/bin/bash
# Unified Write|Edit PreToolUse guard — all checks in one script
# Reduces Claude Code UI noise (1 hook entry instead of 5)
# Compatible: Git Bash on Windows
#
# RECOVERY PRINCIPLE: Every BLOCKED/WARNING message MUST include
# a concrete recovery action so Takumi knows what to do next.

INPUT=$(cat)

# Extract file_path from JSON
FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path" *: *"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Convert Windows paths
FILE_PATH_UNIX=$(echo "$FILE_PATH" | awk '{gsub(/\\\\/, "/"); print}')
FILENAME=$(basename "$FILE_PATH")
EXTENSION="${FILENAME##*.}"
NAME="${FILENAME%.*}"
DIRNAME=$(dirname "$FILE_PATH_UNIX")

# === RING 0 #3: .ENV GUARD ===
case "$FILENAME" in
  .env|.env.local|.env.production|.env.prod)
    if [ ! -f "$DIRNAME/.env.example" ]; then
      echo "BLOCKED: .env.example must exist alongside $FILENAME. RECOVERY: Create $DIRNAME/.env.example with placeholder values (no real secrets), then retry this write." >&2
      exit 2
    fi
    ;;
esac

# === RING 1: LOCALSTORAGE JWT BLOCK ===
if echo "$INPUT" | grep -qiE "localStorage\.(set|get)Item.*(token|jwt|auth|session)"; then
  echo "BLOCKED: JWT tokens must use httpOnly cookies, not localStorage. RECOVERY: Replace localStorage with httpOnly cookie-based auth (set via backend Set-Cookie header). See rules/Security.md for the pattern. Retry after fixing." >&2
  exit 2
fi

# === RING 1: SECRETS IN FILES ===
if echo "$INPUT" | grep -qE 'sk_live_[a-zA-Z0-9]{10,}'; then
  echo "BLOCKED: Stripe live key detected in code. RECOVERY: Move the key to .env file, reference via process.env.STRIPE_SECRET_KEY, then retry." >&2
  exit 2
fi
if echo "$INPUT" | grep -qE 'ghp_[a-zA-Z0-9]{36}'; then
  echo "BLOCKED: GitHub token detected in code. RECOVERY: Move token to .env file, reference via environment variable, then retry." >&2
  exit 2
fi
if echo "$INPUT" | grep -qE 'PRIVATE KEY'; then
  echo "BLOCKED: Private key detected in code. RECOVERY: Store in .env (gitignored) or secrets manager, load at runtime, then retry." >&2
  exit 2
fi

# === RING 1: GITHUB ACTIONS SHA PINNING ===
if echo "$FILE_PATH" | grep -qE '\.github/workflows/.*\.yml$'; then
  if echo "$INPUT" | grep -qE 'uses:.*@(v[0-9]|main|master|latest)'; then
    echo "BLOCKED: GitHub Actions must be pinned to SHA, not tags. RECOVERY: Find the full commit SHA for the action version on GitHub, replace the tag with the SHA (e.g., actions/checkout@abc123...), then retry." >&2
    exit 2
  fi
fi

# === RING 0 #8: STACK VERSION GUARD ===
case "$FILENAME" in
  package.json|requirements.txt|pyproject.toml)
    CONTENT=$(echo "$INPUT" | sed -n 's/.*"new_string" *: *"\([^"]*\)".*/\1/p' | head -1)
    if [ -z "$CONTENT" ]; then
      CONTENT=$(echo "$INPUT" | sed -n 's/.*"content" *: *"\([^"]*\)".*/\1/p' | head -1)
    fi
    if echo "$CONTENT" | grep -qE '"[a-z@][^"]*"\s*:\s*"[\^~]?[0-9]+\.[0-9]+'; then
      echo "WARNING: Dependency versions in $FILENAME detected. ACTION: Verify versions via npm/pypi/web (training data is months stale). If already verified, continue." >&2
    fi
    ;;
  Dockerfile|Dockerfile.*)
    CONTENT=$(echo "$INPUT" | sed -n 's/.*"new_string" *: *"\([^"]*\)".*/\1/p' | head -1)
    if [ -z "$CONTENT" ]; then
      CONTENT=$(echo "$INPUT" | sed -n 's/.*"content" *: *"\([^"]*\)".*/\1/p' | head -1)
    fi
    if echo "$CONTENT" | grep -qE 'FROM .+:[0-9]+'; then
      echo "WARNING: Docker image version in $FILENAME detected. ACTION: Verify version via Docker Hub (training data is months stale). If already verified, continue." >&2
    fi
    ;;
esac

# === RING 1: LEGO LIBRARY GUARD (BLOCKING — Bug #2 fix 2026-04-09) ===
# Detect components that already exist in @shinkofa/ui
case "$EXTENSION" in
  tsx|jsx)
    # Skip library itself, tests, storybook, node_modules
    if ! echo "$FILE_PATH_UNIX" | grep -qE '(Shinkofa-Shared/|node_modules/|\.test\.|\.spec\.|\.stories\.|__tests__|\.claude/)'; then
      CONTENT=$(echo "$INPUT" | sed -n 's/.*"new_string" *: *"\(.*\)"/\1/p' | head -1)
      if [ -z "$CONTENT" ]; then
        CONTENT=$(echo "$INPUT" | sed -n 's/.*"content" *: *"\(.*\)"/\1/p' | head -1)
      fi
      # List of @shinkofa/ui component names (from Shinkofa-Shared/packages/ui/src/index.ts)
      LEGO_COMPONENTS="Button|Input|Textarea|Badge|Card|Skeleton|Modal|EmptyState|ThemeProvider|ThemeToggle|BackToTop|RevealOnScroll|LanguageSwitcher|CookieConsent|TagInput|DictationButton|CollapsibleCard|PromptDialog|SaveIndicator|ConfirmModal|SafeImage|BodyGraph|BodyGraphCenter|BodyGraphChannel|BodyGraphLegend|StructuredData|ArticleSchema|BreadcrumbSchema|FAQSchema|ReviewSchema|PortfolioItemSchema|PortfolioListSchema|ServiceSchema|ToastProvider|Toast|FilePicker|ImagePicker|ImageBrowserModal|NavShell|NavLink|NavGroup|SettingsSection|RevealToggle|PasswordChangeForm|AvatarUpload|AvatarCropModal"
      # Check for component definitions (export function X / export const X / function X)
      MATCH=$(echo "$CONTENT" | grep -oE "(export )?(function|const) ($LEGO_COMPONENTS)[^a-zA-Z]" | head -1)
      if [ -n "$MATCH" ]; then
        COMP_NAME=$(echo "$MATCH" | grep -oE "($LEGO_COMPONENTS)")
        echo "BLOCKED: '$COMP_NAME' already exists in @shinkofa/ui. Import from @shinkofa/ui instead of redefining. 48 days were wasted on Shizen because this guard was not blocking. NEVER duplicate a Lego component." >&2
        exit 2
      fi
    fi
    ;;
esac

# === RING 1: I18N GUARD (warning only) ===
# Detect hardcoded user-facing strings in JSX
case "$EXTENSION" in
  tsx|jsx)
    # Skip library, tests, storybook, node_modules, .claude
    if ! echo "$FILE_PATH_UNIX" | grep -qE '(Shinkofa-Shared/|node_modules/|\.test\.|\.spec\.|\.stories\.|__tests__|\.claude/)'; then
      I18N_CONTENT=$(echo "$INPUT" | sed -n 's/.*"new_string" *: *"\(.*\)"/\1/p' | head -1)
      if [ -z "$I18N_CONTENT" ]; then
        I18N_CONTENT=$(echo "$INPUT" | sed -n 's/.*"content" *: *"\(.*\)"/\1/p' | head -1)
      fi
      # Detect hardcoded strings in JSX attributes (title, placeholder, aria-label, alt)
      # Handle both raw quotes and JSON-escaped quotes (\")
      if echo "$I18N_CONTENT" | grep -qE '(title|placeholder|aria-label|alt)=\\?"[A-Z\xC0-\xFF][a-zA-Z\xC0-\xFF ]{3,}\\?"'; then
        echo "WARNING: Hardcoded user-facing string in JSX attribute. ACTION: Replace with @shinkofa/i18n key via labels prop pattern. Add key to FR/EN/ES locale files, use t('namespace:key'). Continue after fixing." >&2
      fi
      # Detect hardcoded text content in JSX tags (>Word word<)
      if echo "$I18N_CONTENT" | grep -qE '>[A-Z\xC0-\xFF][a-zA-Z\xC0-\xFF ]{3,}<'; then
        echo "WARNING: Hardcoded user-facing text in JSX. ACTION: Replace with {t('namespace:key')} from @shinkofa/i18n. Add key to FR/EN/ES locale files. Continue after fixing." >&2
      fi
    fi
    ;;
esac

# === RING 1: NAMING CONVENTIONS (warning only) ===
case "$FILENAME" in
  README.md|LICENSE|CHANGELOG.md|CLAUDE.md|SKILL.md|MEMORY.md|Makefile|Dockerfile|Dockerfile.*|.gitignore|.gitkeep|.env*|package.json|tsconfig.json|biome.json|vitest.config.*|playwright.config.*|next.config.*|tailwind.config.*|postcss.config.*|*.lock|index.ts|index.js|index.tsx)
    ;;
  *)
    if ! echo "$FILE_PATH" | grep -qE '(\.claude/|\.github/|node_modules/|\.next/|__pycache__|\.obsidian/|\.vscode/)'; then
      case "$EXTENSION" in
        py)
          if ! echo "$NAME" | grep -qE '^[a-z][a-z0-9_]*$'; then
            echo "WARNING: Python files should use snake_case: $FILENAME. ACTION: Rename to snake_case and update imports, then retry." >&2
          fi
          ;;
        sh)
          if ! echo "$NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
            echo "WARNING: Bash scripts should use kebab-case: $FILENAME. ACTION: Rename to kebab-case and update references, then retry." >&2
          fi
          ;;
        ts|js)
          if ! echo "$NAME" | grep -qE '^[a-z][a-zA-Z0-9]*$'; then
            echo "WARNING: TS/JS utility files should use camelCase: $FILENAME. ACTION: Rename to camelCase and update imports, then retry." >&2
          fi
          ;;
        tsx|jsx)
          if ! echo "$NAME" | grep -qE '^[A-Z][a-zA-Z0-9]*$'; then
            echo "WARNING: React components should use PascalCase: $FILENAME. ACTION: Rename to PascalCase and update imports, then retry." >&2
          fi
          ;;
        md)
          PARENT_DIR=$(basename "$DIRNAME")
          case "$PARENT_DIR" in
            agents|skills|hooks) ;; # lowercase-kebab in .claude subdirs
            *)
              if ! echo "$NAME" | grep -qE '^[A-Z][a-zA-Z0-9]*(-[A-Z][a-zA-Z0-9]*)*$'; then
                echo "WARNING: Markdown docs should use Title-Kebab-Case: $FILENAME. ACTION: Rename to Title-Kebab-Case (e.g., My-Document.md), then retry." >&2
              fi
              ;;
          esac
          ;;
      esac
    fi
    ;;
esac

exit 0

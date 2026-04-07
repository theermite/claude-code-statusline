#!/bin/bash
# Unified Write|Edit PreToolUse guard — all checks in one script
# Reduces Claude Code UI noise (1 hook entry instead of 5)
# Compatible: Git Bash on Windows

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
      echo "BLOCKED: .env.example must exist alongside $FILENAME. Create it first."
      exit 2
    fi
    ;;
esac

# === RING 1: LOCALSTORAGE JWT BLOCK ===
if echo "$INPUT" | grep -qiE "localStorage\.(set|get)Item.*(token|jwt|auth|session)"; then
  echo "BLOCKED: JWT tokens must use httpOnly cookies, not localStorage."
  exit 2
fi

# === RING 1: SECRETS IN FILES ===
if echo "$INPUT" | grep -qE 'sk_live_[a-zA-Z0-9]{10,}'; then
  echo "BLOCKED: Stripe live key detected. Use environment variables."
  exit 2
fi
if echo "$INPUT" | grep -qE 'ghp_[a-zA-Z0-9]{36}'; then
  echo "BLOCKED: GitHub token detected. Use environment variables."
  exit 2
fi
if echo "$INPUT" | grep -qE 'PRIVATE KEY'; then
  echo "BLOCKED: Private key detected. Use secret management."
  exit 2
fi

# === RING 1: GITHUB ACTIONS SHA PINNING ===
if echo "$FILE_PATH" | grep -qE '\.github/workflows/.*\.yml$'; then
  if echo "$INPUT" | grep -qE 'uses:.*@(v[0-9]|main|master|latest)'; then
    echo "BLOCKED: GitHub Actions must be pinned to SHA, not tags."
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
      echo "VEILLE GUARD: Dependency versions in $FILENAME — verify via npm/pypi/web (training data is months stale)."
    fi
    ;;
  Dockerfile|Dockerfile.*)
    CONTENT=$(echo "$INPUT" | sed -n 's/.*"new_string" *: *"\([^"]*\)".*/\1/p' | head -1)
    if [ -z "$CONTENT" ]; then
      CONTENT=$(echo "$INPUT" | sed -n 's/.*"content" *: *"\([^"]*\)".*/\1/p' | head -1)
    fi
    if echo "$CONTENT" | grep -qE 'FROM .+:[0-9]+'; then
      echo "VEILLE GUARD: Docker image version in $FILENAME — verify via Docker Hub (training data is months stale)."
    fi
    ;;
esac

# === RING 1: LEGO LIBRARY GUARD (warning only) ===
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
        echo "LEGO GUARD: '$COMP_NAME' already exists in @shinkofa/ui. Import it instead of redefining. If extending, add a project-specific prefix (e.g., App$COMP_NAME)."
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
        echo "i18n GUARD: Hardcoded user-facing string detected in JSX attribute. Use @shinkofa/i18n keys via the labels prop pattern."
      fi
      # Detect hardcoded text content in JSX tags (>Word word<)
      if echo "$I18N_CONTENT" | grep -qE '>[A-Z\xC0-\xFF][a-zA-Z\xC0-\xFF ]{3,}<'; then
        echo "i18n GUARD: Hardcoded user-facing text detected in JSX. Use @shinkofa/i18n keys via the labels prop pattern."
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
            echo "WARNING: Python files should use snake_case: $FILENAME"
          fi
          ;;
        sh)
          if ! echo "$NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
            echo "WARNING: Bash scripts should use kebab-case: $FILENAME"
          fi
          ;;
        ts|js)
          if ! echo "$NAME" | grep -qE '^[a-z][a-zA-Z0-9]*$'; then
            echo "WARNING: TS/JS utility files should use camelCase: $FILENAME"
          fi
          ;;
        tsx|jsx)
          if ! echo "$NAME" | grep -qE '^[A-Z][a-zA-Z0-9]*$'; then
            echo "WARNING: React components should use PascalCase: $FILENAME"
          fi
          ;;
        md)
          PARENT_DIR=$(basename "$DIRNAME")
          case "$PARENT_DIR" in
            agents|skills|hooks) ;; # lowercase-kebab in .claude subdirs
            *)
              if ! echo "$NAME" | grep -qE '^[A-Z][a-zA-Z0-9]*(-[A-Z][a-zA-Z0-9]*)*$'; then
                echo "WARNING: Markdown docs should use Title-Kebab-Case: $FILENAME"
              fi
              ;;
          esac
          ;;
      esac
    fi
    ;;
esac

exit 0

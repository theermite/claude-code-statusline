#!/bin/bash
# Unified Write|Edit PostToolUse guard — all checks in one script
# Reduces Claude Code UI noise (1 hook entry instead of 3)
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
FILE_PATH=$(echo "$FILE_PATH" | awk '{gsub(/\\\\/, "/"); print}')

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# === RING 0 #6: FILE SIZE MAX 300 LINES ===
# Exclude: tests, configs, migrations, generated files, lock files
SKIP_SIZE=false
echo "$FILE_PATH" | grep -qE '\.(test|spec|stories)\.(ts|tsx|js|jsx)$' && SKIP_SIZE=true
echo "$FILE_PATH" | grep -qE '(migrations?|seed|fixture)/' && SKIP_SIZE=true
echo "$FILE_PATH" | grep -qE '\.(lock|svg|csv|sql)$' && SKIP_SIZE=true
echo "$FILE_PATH" | grep -qE '(config|\.config)\.' && SKIP_SIZE=true
echo "$FILE_PATH" | grep -qE '/dist/' && SKIP_SIZE=true
echo "$FILE_PATH" | grep -qE 'validation[s\-]' && SKIP_SIZE=true
if [ "$SKIP_SIZE" = false ]; then
  LINES=$(wc -l < "$FILE_PATH")
  if [ "$LINES" -gt 300 ]; then
    echo "BLOCKED: File $FILE_PATH has $LINES lines (max 300). RECOVERY: Split this file into smaller modules. Extract logical sections into separate files, update imports, then retry. Each file must be under 300 lines." >&2
    exit 2
  fi
fi

# === RING 0 #4: UTF-8 ENCODING ENFORCEMENT (Bug #5 fix 2026-04-09) ===
# Check BOM
HEADER=$(xxd -l 3 -p "$FILE_PATH" 2>/dev/null)
if [ "$HEADER" = "efbbbf" ]; then
  echo "BLOCKED: UTF-8 BOM detected in $FILE_PATH. RECOVERY: Re-write the file content without BOM. Use Write tool with the same content (Claude Code writes UTF-8 without BOM by default). Retry immediately." >&2
  exit 2
fi
# Check for non-UTF-8 encoding (UTF-16 LE/BE markers)
if [ "$HEADER" = "fffe00" ] || [ "$HEADER" = "feff00" ]; then
  echo "BLOCKED: Non-UTF-8 encoding detected in $FILE_PATH (UTF-16). RECOVERY: Re-write the file using the Write tool (outputs UTF-8 by default). If the source content has special chars, ensure they are valid UTF-8. Retry immediately." >&2
  exit 2
fi
# Validate UTF-8 on text files (skip binary)
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.py|*.sh|*.md|*.json|*.yaml|*.yml|*.toml|*.css|*.scss|*.html|*.sql|*.env*)
    if command -v iconv >/dev/null 2>&1; then
      if ! iconv -f UTF-8 -t UTF-8 "$FILE_PATH" >/dev/null 2>&1; then
        echo "BLOCKED: Invalid UTF-8 sequences in $FILE_PATH. RECOVERY: Read the file, identify non-UTF-8 characters (often copy-pasted from external sources), replace them with proper UTF-8 equivalents, re-write the file. Retry immediately." >&2
        exit 2
      fi
    fi
    ;;
esac

# === RING 1: CONSOLE.LOG GUARD (skip test/spec files) ===
if echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx)$'; then
  if ! echo "$FILE_PATH" | grep -qE '\.(test|spec|stories)\.(ts|tsx|js|jsx)$'; then
    COUNT=$(grep -c 'console\.log' "$FILE_PATH" 2>/dev/null || echo 0)
    if [ "$COUNT" -gt 0 ]; then
      echo "WARNING: $COUNT console.log found in $FILE_PATH. ACTION: Remove all console.log statements (replace with proper logger if debug output is needed). Continue with the current task, but fix these before committing." >&2
    fi
  fi
fi

exit 0

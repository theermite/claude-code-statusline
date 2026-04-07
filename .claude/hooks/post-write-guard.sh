#!/bin/bash
# Unified Write|Edit PostToolUse guard — all checks in one script
# Reduces Claude Code UI noise (1 hook entry instead of 3)
# Compatible: Git Bash on Windows

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
    echo "BLOCKED: File $FILE_PATH has $LINES lines (max 300). Split this file."
    exit 2
  fi
fi

# === RING 0 #4: UTF-8 BOM CHECK ===
HEADER=$(xxd -l 3 -p "$FILE_PATH" 2>/dev/null)
if [ "$HEADER" = "efbbbf" ]; then
  echo "BLOCKED: UTF-8 BOM detected in $FILE_PATH. Must be UTF-8 without BOM."
  exit 2
fi

# === RING 1: CONSOLE.LOG GUARD (skip test/spec files) ===
if echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx)$'; then
  if ! echo "$FILE_PATH" | grep -qE '\.(test|spec|stories)\.(ts|tsx|js|jsx)$'; then
    COUNT=$(grep -c 'console\.log' "$FILE_PATH" 2>/dev/null || echo 0)
    if [ "$COUNT" -gt 0 ]; then
      echo "WARNING: $COUNT console.log in $FILE_PATH. Remove before production."
    fi
  fi
fi

exit 0

#!/bin/bash
# PostToolUse hook: shellcheck для отредактированных .sh файлов.
# Не блокирует workflow — предупреждения идут в stderr.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE" == *.sh ]] && [[ -f "$FILE" ]]; then
  shellcheck "$FILE" >&2 || true
fi

exit 0

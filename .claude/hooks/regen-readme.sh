#!/bin/bash
# PostToolUse hook: перегенерирует README.md, если был изменён hypr/*.conf
# или ansible/roles/packages/vars/main.yml. Дублирует pre-commit hook,
# но срабатывает сразу после правки — README остаётся синхронным.

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

case "$FILE" in
  */hypr/*.conf|*/ansible/roles/packages/vars/main.yml)
    cd "$CLAUDE_PROJECT_DIR" || exit 0
    python3 scripts/generate_docs.py >/dev/null 2>&1 || true
    ;;
esac

exit 0

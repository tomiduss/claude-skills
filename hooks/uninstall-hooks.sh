#!/usr/bin/env bash
set -euo pipefail

# Remove Linear workflow hooks from ~/.claude/settings.json
# Removes entries whose command points to this directory.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Nothing to do: $SETTINGS_FILE not found"
  exit 0
fi

# Remove hook entries whose command contains this directory path
CLEANED=$(jq --arg dir "$SCRIPT_DIR" '
  if .hooks then
    .hooks |= with_entries(
      .value |= map(
        .hooks |= map(select(.command | tostring | contains($dir) | not))
        | select(.hooks | length > 0)
      )
      | select(.value | length > 0)
    )
    | if (.hooks | length) == 0 then del(.hooks) else . end
  else
    .
  end
' "$SETTINGS_FILE")

echo "$CLEANED" | jq . > "$SETTINGS_FILE"

echo "✓ Linear workflow hooks removed from $SETTINGS_FILE"

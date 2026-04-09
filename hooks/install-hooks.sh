#!/usr/bin/env bash
set -euo pipefail

# Install Linear workflow hooks into ~/.claude/settings.json
# Usage: ./install-hooks.sh [--dry-run]
#
# Adds UserPromptSubmit and SessionStart hooks that auto-detect Linear issues
# and inject context for the linear-workflow skill.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

# Ensure jq is available
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

# Ensure settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Error: $SETTINGS_FILE not found"
  exit 1
fi

# Make hook scripts executable
chmod +x "$SCRIPT_DIR/detect-linear-issue.sh"
chmod +x "$SCRIPT_DIR/branch-issue-context.sh"

# Build the hooks JSON to merge
HOOKS_JSON=$(cat <<EOF
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${SCRIPT_DIR}/detect-linear-issue.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "${SCRIPT_DIR}/branch-issue-context.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOF
)

if $DRY_RUN; then
  echo "Would merge the following hooks into $SETTINGS_FILE:"
  echo ""
  echo "$HOOKS_JSON" | jq .
  echo ""
  echo "Current settings hooks:"
  jq '.hooks // "none"' "$SETTINGS_FILE"
  exit 0
fi

# Merge hooks into existing settings (preserves everything else)
# If hooks already exist, this deep-merges the arrays
MERGED=$(jq --argjson new_hooks "$HOOKS_JSON" '
  # Deep merge: for each event in new_hooks.hooks, append to existing array or create it
  .hooks = ((.hooks // {}) as $existing |
    ($new_hooks.hooks | to_entries | reduce .[] as $entry (
      $existing;
      .[$entry.key] = ((.[$entry.key] // []) + $entry.value)
    ))
  )
' "$SETTINGS_FILE")

# Write back
echo "$MERGED" | jq . > "$SETTINGS_FILE"

echo "✓ Hooks installed into $SETTINGS_FILE"
echo ""
echo "Installed hooks:"
echo "  • UserPromptSubmit: detect-linear-issue.sh (auto-detects ZON-* in prompts)"
echo "  • SessionStart: branch-issue-context.sh (injects context on zon-* branches)"
echo ""
echo "Verify with: /hooks in Claude Code"
echo "Remove with: ./uninstall-hooks.sh"

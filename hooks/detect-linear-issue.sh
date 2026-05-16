#!/bin/bash
# Hook: UserPromptSubmit
# Detects Linear issue IDs (ZON-*) in user prompts and injects context
# so Claude uses the linear-workflow skill automatically.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Match ZON-<number> pattern (case-insensitive)
if echo "$PROMPT" | grep -iqE '\bZON-[0-9]+\b'; then
  ISSUE_ID=$(echo "$PROMPT" | grep -ioE '\bZON-[0-9]+\b' | head -1 | tr '[:lower:]' '[:upper:]')
  echo "{\"hookSpecificOutput\": {\"hookEventName\": \"UserPromptSubmit\", \"additionalContext\": \"The user referenced Linear issue ${ISSUE_ID}. Use the linear-workflow skill (invoke via Skill tool) to handle this request. Fetch the issue details first, then act on whatever the user asked.\"}}"
  exit 0
fi

exit 0

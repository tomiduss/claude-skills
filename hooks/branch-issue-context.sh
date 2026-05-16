#!/bin/bash
# Hook: SessionStart (matcher: startup)
# When starting a session on a zon-* branch, injects context about the active issue.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Get current branch name
BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)

# Match zon-<number> in branch name (case-insensitive)
if echo "$BRANCH" | grep -iqE 'zon-[0-9]+'; then
  ISSUE_ID=$(echo "$BRANCH" | grep -ioE 'zon-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]')
  echo "{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"You are on branch '${BRANCH}' which is linked to Linear issue ${ISSUE_ID}. If the user's request relates to this issue, use the linear-workflow skill to fetch context. The linear-agent-workflow skill is available for autonomous execution patterns.\"}}"
  exit 0
fi

exit 0

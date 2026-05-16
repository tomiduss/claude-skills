#!/usr/bin/env bash
# Value-function byte-identity check between role fragments and standalone subagents.
# The only invariant enforced is that the **value function sentence** is byte-identical
# between the two representations. Everything else (tool lists, output format, framing)
# is intentionally allowed to differ. See stress-tester finding B.4 in the recovered
# research logs for the rationale.
set -u
fail=0

# Array format: "role_name|fragment_path|subagent_path"
ROLES=(
  "pragmatist|skills/multi-agent-council/references/roles/pragmatist.md|.claude/agents/pragmatist.md"
)

extract_value_function() {
  local file="$1"
  # Role fragment format: "**Value function:** ..."
  # Subagent format: "**Your value function:** ..."
  grep -E '\*\*(Your v|V)alue function:\*\*' "$file" \
    | head -n1 \
    | sed -E 's/^.*\*\*(Your v|V)alue function:\*\*[[:space:]]*//'
}

for entry in "${ROLES[@]}"; do
  name=$(echo "$entry" | cut -d'|' -f1)
  frag=$(echo "$entry" | cut -d'|' -f2)
  agent=$(echo "$entry" | cut -d'|' -f3)

  if [ ! -f "$frag" ]; then
    echo "FAIL: $name — fragment file missing: $frag"; fail=1; continue
  fi
  if [ ! -f "$agent" ]; then
    echo "FAIL: $name — subagent file missing: $agent"; fail=1; continue
  fi

  vf_frag=$(extract_value_function "$frag")
  vf_agent=$(extract_value_function "$agent")

  if [ -z "$vf_frag" ] || [ -z "$vf_agent" ]; then
    echo "FAIL: $name — could not extract value function from one or both files"
    fail=1; continue
  fi

  if [ "$vf_frag" = "$vf_agent" ]; then
    echo "OK:   $name — value function byte-identical"
  else
    echo "FAIL: $name — value function diverged"
    echo "       fragment: $vf_frag"
    echo "       subagent: $vf_agent"
    fail=1
  fi
done

exit $fail

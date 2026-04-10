#!/usr/bin/env bash
# Static assertions for hardened multi-agent-council prompts.
# Exits non-zero if any check fails. Run from the repo root.
set -u
TL="skills/multi-agent-council/references/team-lead-prompt.md"
DL="skills/multi-agent-council/references/deliberator-prompt.md"
PM="skills/multi-agent-council/references/patterns/pre-mortem.md"
JD="skills/multi-agent-council/references/patterns/judge.md"
SK="skills/multi-agent-council/SKILL.md"
fail=0

check() {
  local label="$1" file="$2" pattern="$3" expect="$4"
  if [ ! -f "$file" ]; then
    echo "FAIL: $label (file missing: $file)"; fail=1; return
  fi
  if grep -qE "$pattern" "$file"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then
    echo "FAIL: $label (expected $expect, got $found)"
    fail=1
  else
    echo "OK:   $label"
  fi
}

### team-lead-prompt.md — Task 1.a/1.b/1.c ###
check "1.a — old 'full text, not summaries' directive removed"              "$TL" "full text, not summaries" absent
check "1.a — digest-only Round 2 directive present"                         "$TL" "Round 1 Digest.*not the raw position papers" present
check "1.a — peer-context 2k-token cap present"                             "$TL" "2,?000.token|peer.context.*cap" present
check "1.b — shutdown deadline present (30s)"                               "$TL" "shutdown.*deadline|within 30 seconds" present
check "1.b — presume-dead fallback present"                                 "$TL" "presumed.*dead|proceed with.*TeamDelete" present
check "1.c — Dispatch Accounting section present"                           "$TL" "Dispatch Accounting" present
check "1.c — Known gaps surfacing present"                                  "$TL" "Known gaps" present

### deliberator-prompt.md — Task 1.d/1.e ###
check "1.d — TOKEN_BUDGET placeholder present"                              "$DL" "\[TOKEN_BUDGET\]" present
check "1.d — budget-consumed reporting required"                            "$DL" "Budget consumed|actual budget consumed" present
check "1.e — named-claim requirement in Round 2 present"                    "$DL" "name the.*claim|quote the specific claim" present
check "1.e — weak 'Update if warranted' directive removed"                  "$DL" "^.*Update if warranted.*$" absent

exit $fail

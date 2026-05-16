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

### pre-mortem.md — Task 2 ###
check "2.1 — old 'reasoning and tradeoffs' inheritance removed"             "$PM" "reasoning and tradeoffs documented by the core pattern" absent
check "2.1 — old 'dissent from core rounds' inheritance removed"            "$PM" "dissent or unresolved disagreements from the core rounds" absent
check "2.1 — bias-isolation statement present"                              "$PM" "no access to the core council's reasoning|proposal artifact only" present
check "2.2 — team-member dispatch (not Agent tool) specified"               "$PM" "added to the team|team-member dispatch|via TeamCreate|via the existing team" present
check "2.2 — old 'spawns .* via.*Agent tool' removed"                       "$PM" "spawns.*via the Agent tool" absent

### SKILL.md complexity gate — Task 3 ###
check "3.1 — old 'warning, not a block' removed"                            "$SK" "the gate is a warning, not a block" absent
check "3.1 — structural gate requires 2 named tradeoffs"                    "$SK" "at least 2 meaningful tradeoffs|name 2 tradeoffs" present
check "3.2 — inline cost tier table present"                                "$SK" "Simple.*tier.*10k|Baseline tier estimates" present
check "3.2 — compound cost language present"                                "$SK" "compound.*(cost|estimate)" present
check "3.3 — modifiers individually disableable"                            "$SK" "individually disableable|toggle.*modifier" present
check "3.3 — refuse to spawn fallback present"                              "$SK" "refuse to spawn|direct analysis instead" present

### judge.md — Task 4 ###
check "4.1 — judge.md exists with title"                                    "$JD" "^# Judge" present
check "4.1 — judge is optional/opt-in"                                      "$JD" "optional|opt-in" present
check "4.1 — judge is dispatched as team member"                            "$JD" "added to the team|team-member dispatch|general-purpose.*team_name|team member" present
check "4.1 — judge never sees the team lead's synthesis"                    "$JD" "not see.*team lead.*synthesis|never receives the synthesis" present
check "4.1 — judge sees raw Round 1/Round 2"                                "$JD" "raw Round 1.*Round 2" present
check "4.1 — falsifiable rubric only"                                       "$JD" "citation existence|citation.claim mapping" present
check "4.1 — hard cap of 1 revision"                                        "$JD" "1 revision|one revision|single revision" present
check "4.1 — non-blocking on judge failure"                                 "$JD" "non-blocking|judge unavailable" present

exit $fail

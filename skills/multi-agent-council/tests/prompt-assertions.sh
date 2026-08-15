#!/usr/bin/env bash
# Static assertions for the multi-agent-council skill.
# Verifies the agent-teams architecture: the lead is the main session, the
# execution path follows from round count (Path A subagents / Path B teammates),
# and modifier agents are one-shot subagents.
# Exits non-zero if any check fails. Run from the repo root.
set -u
SK="skills/multi-agent-council/SKILL.md"
OG="skills/multi-agent-council/references/orchestration-guide.md"
DL="skills/multi-agent-council/references/deliberator-prompt.md"
CN="skills/multi-agent-council/references/patterns/council.md"
PM="skills/multi-agent-council/references/patterns/pre-mortem.md"
JD="skills/multi-agent-council/references/patterns/judge.md"
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

### Architecture — the lead is the main session ###
check "arch — SKILL declares the lead is the session running the skill"     "$SK" "You are the council lead" present
check "arch — no separate team-lead agent is spawned"                       "$SK" "Spawn the .*team lead" absent
check "arch — old 'agent-teams infrastructure' framing removed"             "$SK" "Use agent-teams infrastructure to create" absent
check "arch — orchestration-guide.md exists"                                "$OG" "^# Council Orchestration Guide" present

# team-lead-prompt.md must be gone (renamed to orchestration-guide.md)
if [ -f "skills/multi-agent-council/references/team-lead-prompt.md" ]; then
  echo "FAIL: arch — team-lead-prompt.md should have been renamed to orchestration-guide.md"; fail=1
else
  echo "OK:   arch — team-lead-prompt.md removed (renamed to orchestration-guide.md)"
fi

### Two execution paths ###
check "paths — Path A is one-shot subagents"                                "$SK" "Path A.*subagent" present
check "paths — Path B is teammates"                                         "$SK" "Path B.*teammate" present
check "paths — Path A deliberators get no team_name"                        "$SK" "no .team_name" present
check "paths — Path B deliberators get team_name"                           "$SK" "team_name: .council" present
check "paths — execution path follows from round count"                     "$SK" "execution path follows from .*round count" present

### Tier table — Simple allows 2-4 deliberators ###
check "tier — Simple tier allows 2-4 deliberators"                          "$SK" "Simple.*2-4" present
check "tier — Baseline tier estimates table present"                        "$SK" "Baseline tier estimates" present
check "tier — stale 'Opus 4.6 team lead' estimate removed"                  "$SK" "Opus 4.6 team lead" absent

### Complexity gate (existing behaviour must survive) ###
check "gate — structural gate requires 2 named tradeoffs"                   "$SK" "at least 2 meaningful tradeoffs|name 2 tradeoffs" present
check "gate — 'warning, not a block' framing stays removed"                 "$SK" "the gate is a warning, not a block" absent
check "gate — compound cost language present"                               "$SK" "compound.*(cost|estimate)" present
check "gate — modifiers individually disableable"                           "$SK" "individually disableable" present
check "gate — refuse-to-spawn fallback present"                             "$SK" "refuse to spawn|direct analysis instead" present

### orchestration-guide.md — Path B protocol ###
check "orch — declares the lead is not a separate agent"                    "$OG" "council lead" present
check "orch — digest-only Round 2 directive (not raw papers)"               "$OG" "Round 1 Digest.*not the raw" present
check "orch — old 'full text, not summaries' directive absent"              "$OG" "full text, not summaries" absent
check "orch — peer-context 2k-token cap present"                            "$OG" "2,?000.token" present
check "orch — Dispatch accounting section present"                          "$OG" "Dispatch [Aa]ccounting" present
check "orch — Known gaps surfacing present"                                 "$OG" "Known gaps" present
check "orch — 30s shutdown deadline present"                                "$OG" "30 seconds" present
check "orch — presume-dead fallback present"                                "$OG" "presumed dead" present
check "orch — TeamDelete-fails-with-active-members warning present"         "$OG" "fails while any teammate is still active" present

### deliberator-prompt.md — dual mode ###
check "delib — [MODE] placeholder present"                                  "$DL" "\[MODE\]" present
check "delib — [LEAD_NAME] placeholder present"                             "$DL" "\[LEAD_NAME\]" present
check "delib — [TOKEN_BUDGET] placeholder present"                          "$DL" "\[TOKEN_BUDGET\]" present
check "delib — teammates deliver via SendMessage"                           "$DL" "SendMessage" present
check "delib — Round 2 marked teammate-only"                                "$DL" "Round 2.*teammate.*mode only" present
check "delib — budget-consumed reporting required"                          "$DL" "actual budget consumed" present
check "delib — named-claim requirement in Round 2 present"                  "$DL" "quote the specific claim" present
check "delib — weak 'Update if warranted' directive absent"                 "$DL" "Update if warranted" absent

### council.md — round count maps to path ###
check "council — single vs multi-round path note present"                   "$CN" "Path A.*subagent" present
check "council — 'spawn all agents via TeamCreate' error removed"           "$CN" "Spawn all agents via TeamCreate" absent

### pre-mortem.md — Red-Team is a one-shot subagent ###
check "premortem — Red-Team spawned as a one-shot subagent"                 "$PM" "one-shot subagent" present
check "premortem — old team-member dispatch removed"                        "$PM" "via the existing .TeamCreate. infrastructure" absent
check "premortem — bias-isolation statement present"                        "$PM" "no access to the core council's reasoning" present

### judge.md — Judge is a one-shot subagent ###
check "judge — judge.md exists with title"                                  "$JD" "^# Judge" present
check "judge — Judge is optional / opt-in"                                  "$JD" "optional|opt-in" present
check "judge — Judge spawned as a one-shot subagent"                        "$JD" "one-shot subagent" present
check "judge — Judge spawned after Round 2 is collected"                    "$JD" "after Round 2 is collected" present
check "judge — Judge never sees the team lead's synthesis"                  "$JD" "never receives the synthesis" present
check "judge — falsifiable rubric (citation existence) present"             "$JD" "[Cc]itation existence" present
check "judge — hard cap of one revision"                                    "$JD" "one revision|1 revision" present
check "judge — non-blocking on judge failure"                               "$JD" "non-blocking" present
check "judge — stale team-lead-prompt.md reference removed"                 "$JD" "team-lead-prompt" absent

exit $fail

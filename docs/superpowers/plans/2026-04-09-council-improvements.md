# Multi-Agent Council Skill Hardening Implementation Plan

> **For agentic workers:** REQUIRED: Use `superpowers:subagent-driven-development` (if subagents available) or `superpowers:executing-plans` to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden `skills/multi-agent-council/` against the 3 blocker-level failure modes and 2 left-on-floor findings surfaced by a research council (role-promotion researcher, trends researcher, adversarial stress-tester). Ship the three blockers, close the two unaddressed gaps, and pilot the Pragmatist role as a standalone reusable subagent with an explicit kill criterion.

**Architecture:** In-place edits to 4 existing skill files + 3 new files in the skill + 1 new standalone subagent at the repo root. **All changes preserve the existing `TeamCreate` dispatch model** — the Judge and Red-Team agents are added as **team members** (same mechanism as deliberators), not one-shot subagents via the Agent tool. This unifies dispatch and avoids reintroducing the kind of "second code path" we rejected under Blocker E.1.

**Tech Stack:** Markdown (skill authoring), Bash (static assertion scripts), agent-teams infrastructure (`TeamCreate`, `SendMessage`, team-member dispatch) — all already in use by the existing skill.

---

## Dependencies

Explicit dependencies this plan has on other skills and infrastructure:

| Dependency | Type | Why |
|---|---|---|
| **`agent-teams` (Claude Code experimental feature)** | Hard, runtime | The multi-agent-council skill uses `TeamCreate` + `SendMessage` + team-member dispatch for all council members. Judge and Red-Team modifiers are added to the team via the same mechanism. Without this, the skill cannot run at all. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. |
| **`superpowers:subagent-driven-development`** OR **`superpowers:executing-plans`** | Hard, one-time (plan execution) | Required to execute this plan's tasks. Pick one based on your harness — both produce the same final state. Not a runtime dependency of the resulting skill. |
| **`agent-teams:parallel-debugging`** | Soft, cross-link only | This plan explicitly rejects importing the "Hypothesis Council" pattern as a new core pattern and instead cross-links this existing skill. If the user does not have it, the cross-link is dead but the council still runs. |
| **`.claude/agents/pragmatist.md`** (new, created by this plan) | Hard, pilot only | The Pragmatist standalone subagent created in Task 5. This is a **separate product** from the council — it's used for solo code reviews outside any deliberation — and it is not invoked by the council. |

---

## Research inputs

The original research reports were written to `/tmp/` during the council session and **were not recoverable** as files after the session ended. The agent session logs (containing the messages each agent sent, including key findings and blocker descriptions) **were recovered** and live at:

- `docs/superpowers/plans/2026-04-09-council-improvements-research/e791ae67-861f-47b7-92b2-0c86d569e91a.jsonl` — main session log
- `docs/superpowers/plans/2026-04-09-council-improvements-research/e791ae67-861f-47b7-92b2-0c86d569e91a copy/subagents/*.jsonl` — one log file per agent per dispatch (researcher-agents × 2, researcher-web × 3, stress-tester × 3)

Citations in this plan that previously pointed to `/tmp/researcher-agents-report.md`, `/tmp/researcher-web-report.md`, and `/tmp/stress-tester-critique.md` have been **replaced with inline quotes** from the recovered agent messages, with pointers to the relevant jsonl logs for deeper traceability. See the inline quotes at each task for the load-bearing findings.

---

## Scope — what IS and IS NOT being built

### In scope (this plan)

1. **Blocker E.1** — Drop hybrid dispatch. Council continues to use fragment injection only for its own roles. Standalone subagents (Task 5) are a **separate product** that the council never invokes.
2. **Blocker E.2** — Optional Judge **team member** (not one-shot subagent): non-mandatory, never sees the team lead's synthesis, falsifiable rubric only, 1 revision cap, non-blocking on failure. (Task 4)
3. **Blocker E.3** — Compound cost estimator + structural complexity gate + individually disableable modifiers, all **inlined into SKILL.md Step 1** (not a separate reference file). (Task 3)
4. **Left on floor by both researchers — A.2** Digest-only Round 2 injection (fixes N² context growth). (Task 1)
5. **Left on floor by both researchers — A.4** Pre-mortem Red-Team agent is a team member with enforced bias isolation (only sees the proposal artifact + code). (Task 2)
6. **Per-agent token budget + strengthened divergence check** (C.2, C.3). (Task 1)
7. **Shutdown timeout + dispatch accounting** (A.6, C.8). (Task 1)
8. **Pragmatist pilot standalone subagent** — separate product, with byte-identity test and 14-day kill criterion. (Task 5)

### Explicitly NOT in scope (deferred or rejected)

- **Hybrid dispatch for standalone agents in the council** — rejected per Blocker E.1.
- **A second dispatch path (one-shot Agent tool) for modifier agents** — rejected. The Judge and Red-Team modifiers use team-member dispatch via the existing `TeamCreate` infrastructure. This was a subtle bug in the original plan draft that this revision fixes.
- **Deliberation Ledger (P1.1)** — deferred. High surface area; revisit after Pragmatist pilot passes.
- **Stall detection / re-plan loop (P1.2)** — deferred. Requires the ledger.
- **Hypothesis Council pattern (P1.3)** — rejected. Cross-link `agent-teams:parallel-debugging` from the skill instead.
- **Dynamic composition / A-HMAD (P2.2)** — deferred. Interesting but unvalidated.
- **Cross-Examination modifier (P2.1)** — deferred.
- **Canonical source inversion** (making `.claude/agents/*.md` the source of truth and generating fragments) — rejected. Two hand-maintained artifacts with a byte-identity test is the correct design.
- **Big-bang promotion of 10 roles** — rejected. Only Pragmatist pilots, gated on a 14-day kill criterion before any other roles are considered.
- **Opus-lead / Sonnet-deliberators model split (P0.4)** — deferred until model routing support is confirmed.
- **Separate `cost-model.md` reference file** — rejected after review. The cost model is short enough to inline directly in SKILL.md Step 1 where it is consulted. Progressive disclosure adds no value here.
- **Separate `reference-suite.md` test documentation file** — rejected after review. Manual tests are documented inline in the "Post-plan verification" section of this plan.
- **`custom-role-template.md` rejection doc** — rejected after review. Git log answers "why not two paths?"

---

## Task dependency order

```
Task 1 (harden council prompts)          ─┐
                                           ├─→ Task 3 (structural gate + cost model)
Task 2 (pre-mortem fix + team dispatch)   ─┤         │
                                           │         ▼
                                           │    Task 4 (Judge modifier, team member)
                                           │
                                           └─→ Task 5 (Pragmatist pilot, standalone)
```

**Tasks 1 and 2 are independent** (different files) and could theoretically run in parallel, but each is short enough that serial is cleaner. Task 3 depends on Task 1 (for the token budget placeholder the gate populates). Task 4 depends on Task 3 (the gate enables/disables the Judge modifier). Task 5 is independent of the council work and can run any time after Task 1.

**5 tasks total, down from 11 in the first draft.** The consolidation is purely structural — every change from the original plan that addresses a blocker or left-on-floor finding is still present. The cuts were all organizational wrappers that did not carry their weight: a separate cost-model.md file, a separate kill-criterion doc, a rejection-record markdown in the custom-role-template, and a stand-alone test-suite file.

---

## Task 1: Harden council prompts

**Files:**
- Modify: `skills/multi-agent-council/references/team-lead-prompt.md`
- Modify: `skills/multi-agent-council/references/deliberator-prompt.md`
- Create: `skills/multi-agent-council/tests/prompt-assertions.sh`

Five hardening edits to the two core prompt files:
- **1.a** — Digest-only Round 2 injection (fixes A.2 N² context growth) — `team-lead-prompt.md`
- **1.b** — Shutdown timeout (fixes A.6 hang) — `team-lead-prompt.md`
- **1.c** — Dispatch accounting rule (C.8) — `team-lead-prompt.md`
- **1.d** — Per-agent token budget placeholder + budget reporting (C.3) — `deliberator-prompt.md`
- **1.e** — Strengthened divergence check: Round 2 updates must name a specific other-agent claim (C.2) — `deliberator-prompt.md`

### Research citation for this task

From researcher-web (recovered log `agent-ae0efafc32d52b1ba.jsonl`, timestamp 2026-04-09T14:26:08Z):

> "Anthropic's multi-agent research system is the closest production analogue and gives four P0 recommendations: (a) independent judge with rubric, (b) explicit scaling-effort gate with per-agent tool budgets (they embed this in prompts and cite ~15× token cost vs. chat) ... (d) anti-sycophancy divergence check in Round 2 (backed by the 2025 'Talk Isn't Always Cheap' paper which documents the #1 failure mode as agents softening positions to reach consensus)."

From stress-tester's initial baseline read (recovered log `agent-aeb5bbce4aba09f3f.jsonl` / `agent-ac8321fc47176ffcf.jsonl`):

> "No bounded context budget — Round 2 injects 'full text, not summaries' of all Round N-1 papers into every agent (N² token growth). Shutdown protocol has no timeout and no failure path if an agent never ACKs."

### Steps

- [ ] **Step 1: Create the tests directory**

```bash
mkdir -p skills/multi-agent-council/tests
```

- [ ] **Step 2: Write the consolidated assertion script**

Create `skills/multi-agent-council/tests/prompt-assertions.sh`:

```bash
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
```

(Further checks for Tasks 2-5 are appended to this file as each task is implemented. Keep the script as the single source of truth for static assertions.)

- [ ] **Step 3: Run the script — confirm it fails**

```bash
bash skills/multi-agent-council/tests/prompt-assertions.sh
```

Expected: 11 FAIL lines (the T2-T5 checks are not yet present, but will be added later — for this task, all 11 existing lines should fail).

- [ ] **Step 4: Apply edit 1.a — digest-only Round 2 injection**

In `skills/multi-agent-council/references/team-lead-prompt.md`, replace the current Round 2 dispatch bullet (around line 54-57, starting with "6. After the user checkpoint...") with:

```markdown
6. After the user checkpoint, send Round 2 directives to each deliberator via `SendMessage`:
   - **Include the Round 1 Digest you produced in step 3, not the raw position papers.** The digest is bounded (2-3 sentences per agent + tension points); raw papers grow N² across rounds and will overflow agent context by Round 3 of any deliberation with 4+ agents. See stress-tester finding A.2 in the recovered logs.
   - Hard cap: the peer-context block passed to any single deliberator must fit within a **2,000-token budget**. If the digest exceeds this, compress further — drop non-load-bearing citations, keep the tension points.
   - Include any user-injected context or redirections from the checkpoint.
   - Instruct each agent to follow the Round 2 protocol from their prompt.
```

- [ ] **Step 5: Apply edit 1.b — shutdown timeout**

In the same file, replace the current `### Shutdown` section (lines 78-82) with:

```markdown
### Shutdown

13. After delivering the proposal, send `shutdown_request` to each deliberator **and to any modifier agents** (Judge, Red-Team) that were added to the team.
14. Wait for acknowledgment with a **hard shutdown deadline of 30 seconds** from dispatch. After the deadline, any agent that has not acknowledged is presumed dead.
15. For each non-acknowledging agent, proceed with `TeamDelete` regardless and log the anomaly under a "Shutdown anomalies" section in the Proposal Document. Do not block waiting for dead agents — the user must never be forced to manually clean up a zombie team.
16. Report completion to the user.
```

- [ ] **Step 6: Apply edit 1.c — dispatch accounting rule**

In the same file, insert a new section **between** `### Round 1 — Collect and digest` and `### Round 2 — Cross-pollinate and collect` (right after the current step 5):

```markdown
### Dispatch Accounting (runs every round)

Before each round, record the expected respondents in a private accounting list — this list must include every deliberator **plus any modifier agents** (Judge, Red-Team) that have been added to the team. After the round:

- If any team member has not produced a response after a grace period (60 seconds from the last respondent, or 3 minutes from dispatch, whichever comes first), mark that agent as a **silent drop**.
- Retry the silent drop **once** with an explicit prompt hint: "Your Round N response was not received. Please produce it now, or reply with a one-sentence explanation of why you cannot."
- If the retry also fails, escalate to the user by name: "Agent `<name>` is not responding. Expected: `<what it was expected to produce>`. Proceed without it, or retry manually?"
- At synthesis time: any agent that never produced a required response must appear in the Proposal Document under a **Known gaps** section, named and with its expected contribution noted. A missing Contrarian, Falsifier, or Judge is a quality failure, not a speed optimization.
```

- [ ] **Step 7: Apply edit 1.d — per-agent token budget in deliberator prompt**

In `skills/multi-agent-council/references/deliberator-prompt.md`, replace the current `### Tools at your disposal` block (lines 37-42) with:

```markdown
### Tools at your disposal

- **`Read`**, **`Glob`**, **`Grep`** — explore the codebase, find patterns, trace dependencies
- **`Bash`** — run analysis commands, check metrics, inspect configurations
- **`WebSearch`** and **`WebFetch`** — research approaches, patterns, prior art, benchmarks

### Research budget

You have a **research budget of [TOKEN_BUDGET] tokens for this round**. The budget covers tool-call inputs + outputs + your own reasoning. Track your own consumption as you go. When you approach the budget, stop investigating and write the position paper with what you have.

- Do not reason abstractly — but do not loop either. A well-scoped Round 1 is ≤15 tool calls for a Simple council, ≤25 for a Complex one.
- If you hit the budget without enough evidence for a position, produce a "budget exceeded, provisional position" paper that says so explicitly. Do not fabricate confidence you did not earn.
- Report **actual budget consumed** (approximate is fine — "~8k tokens, 12 tool calls") at the end of your position paper. The team lead tracks this for future calibration.
```

The `[TOKEN_BUDGET]` placeholder is populated by the team lead at dispatch, based on the complexity-gate tier chosen in Task 3 (Simple: 10k, Moderate: 20k, Complex: 35k, Very Complex: 50k).

- [ ] **Step 8: Apply edit 1.e — strengthened divergence check**

In the same file, replace the current `## Round 2 — Respond to other agents` section (lines 69-77) with:

```markdown
## Round 2 — Respond to other agents

You will receive the Round 1 **Digest** (not the raw position papers — they are too long). The digest lists each agent's position, key evidence, and points of tension. You must:

1. **Acknowledge** the single strongest counterargument to your position. You must **name the agent and quote the specific claim** you are responding to — not "another agent argued that complexity is worth it" but "the Visionary's claim at `docs/arch.md:42` that the caching layer would pay for itself within one quarter."
2. **Hold or update — with structural evidence.** Position changes must satisfy a two-part check:
   a. You must **name a specific claim from another agent** that caused your update. Generic references ("the discussion caused me to reconsider") are sycophancy and will be flagged by the team lead.
   b. You must **cite new information** you did not have in Round 1: another agent's finding, user-checkpoint input, or a file you had not read in Round 1.
   If you cannot satisfy both parts, **hold your position**. Softening without cited new evidence is sycophancy. The council's value function diversity only works if agents hold ground when the evidence does not actually change.
3. **Hold ground with evidence** — for remaining disagreements, explain specifically why you still hold your position. Cite evidence, not conviction.

Your Round 2 response must be ≤300 words and must include:
- The named counter-claim you are responding to (author + quote + citation)
- Your hold-or-update decision with the required justification
- Any remaining tension points where you still disagree, with evidence
```

- [ ] **Step 9: Run the assertion script — confirm all 11 Task 1 checks pass**

```bash
bash skills/multi-agent-council/tests/prompt-assertions.sh
```

Expected: 11 OK lines for the Task 1 section. (Tasks 2-5 checks will still be absent from the script at this point.)

- [ ] **Step 10: Commit**

```bash
git add skills/multi-agent-council/references/team-lead-prompt.md \
        skills/multi-agent-council/references/deliberator-prompt.md \
        skills/multi-agent-council/tests/prompt-assertions.sh
git commit -m "council: harden prompts (A.2 digest-only, A.6 timeout, C.2/C.3 budget+divergence, C.8 accounting)"
```

---

## Task 2: Fix pre-mortem bias leak + convert Red-Team to team-member dispatch

**Files:**
- Modify: `skills/multi-agent-council/references/patterns/pre-mortem.md`
- Modify: `skills/multi-agent-council/tests/prompt-assertions.sh` (append checks)

The current pre-mortem contaminates the "fresh" Red-Team agent by feeding it the core council's reasoning and tradeoffs (`pre-mortem.md:22-26`). Fix the bias leak **and** fix the dispatch mechanism: the Red-Team agent is added as a **team member** (via the same `TeamCreate` infrastructure as deliberators) so it participates in the dispatch accounting rule from Task 1.c, respects the shutdown timeout from Task 1.b, and receives its isolated context via `SendMessage` exactly like any other council member.

### Why team-member dispatch (not Agent tool)

An earlier draft of this plan said the team lead would spawn the Red-Team agent "via the Agent tool." That was wrong for three reasons:

1. **Second dispatch path.** The council already uses `TeamCreate` for everything. Introducing a one-shot subagent path for modifier agents creates a second code path — the exact kind of "hybrid dispatch" rejected under Blocker E.1. One mechanism, no branching.
2. **Context explosion.** A one-shot agent has to receive all its context in a single prompt at spawn time. For the Red-Team that means cramming the proposal + problem statement into one wall of text. A team member receives context via `SendMessage`, which is bounded and can be structured.
3. **No accounting coverage.** The dispatch accounting rule from Task 1.c tracks team members. A one-shot subagent is invisible to it — if it crashes or drops silently, there is no automatic recovery. Team-member dispatch inherits all the safety rails from Task 1 for free.

### Research citation

From stress-tester (recovered log, baseline reading of `patterns/pre-mortem.md:22-26`):

> "Pre-mortem's 'fresh perspective' is unenforceable. The mandate gives the red-team agent the converged proposal AND the reasoning and tradeoffs documented by the core pattern AND any dissent from the core rounds. That means the red-team agent inherits all the framing of the core council — the specific tradeoffs they chose to document, the specific language they chose to describe them. A 'fresh' agent that has read the proposal is already contaminated by it. The 'fresh' claim is aspirational, not structural."

### Steps

- [ ] **Step 1: Append pre-mortem assertions to `prompt-assertions.sh`**

Add to `skills/multi-agent-council/tests/prompt-assertions.sh` before the final shell `exit` line:

```bash
### pre-mortem.md — Task 2 ###
check "2.1 — old 'reasoning and tradeoffs' inheritance removed"             "$PM" "reasoning and tradeoffs documented by the core pattern" absent
check "2.1 — old 'dissent from core rounds' inheritance removed"            "$PM" "dissent or unresolved disagreements from the core rounds" absent
check "2.1 — bias-isolation statement present"                              "$PM" "no access to the core council's reasoning|proposal artifact only" present
check "2.2 — team-member dispatch (not Agent tool) specified"               "$PM" "added to the team|team-member dispatch|via TeamCreate|via the existing team" present
check "2.2 — old 'spawns .* via.*Agent tool' removed"                       "$PM" "spawns.*via the Agent tool" absent

exit $fail
```

(The `exit $fail` line should already be at the bottom of the script — move it to below the new checks.)

- [ ] **Step 2: Run the script — confirm Task 2 checks fail**

```bash
bash skills/multi-agent-council/tests/prompt-assertions.sh
```

Expected: Task 1 checks OK, Task 2 checks FAIL.

- [ ] **Step 3: Replace the entire `### Step 1 — Spawn Red-Team Agent` section**

In `skills/multi-agent-council/references/patterns/pre-mortem.md`, replace the current Step 1 (lines 18-26) with:

```markdown
### Step 1 — Add the Red-Team agent to the council team

The Red-Team agent is added as a **team member** via the existing `TeamCreate` infrastructure used for deliberators. It is not spawned as a one-shot subagent via the Agent tool — doing so would create a second dispatch path and would bypass the dispatch accounting rule in `team-lead-prompt.md`.

Dispatch specifics:

- `subagent_type`: `general-purpose`
- `team_name`: the same team the council is already running on
- `name`: `red-team`
- Prompt: use the Red-Team prompt template below (append to `references/deliberator-prompt.md` or inline here — implementation choice)

The team lead then communicates with the Red-Team agent via `SendMessage` exactly like any deliberator. The agent participates in the dispatch accounting rule (it is in the expected-respondents list), the shutdown timeout (it acknowledges `shutdown_request` or is presumed dead), and the team deletion protocol.

### Step 1.1 — Send the Red-Team agent its isolated context

Once added to the team, the Red-Team agent receives a single `SendMessage` from the team lead containing **only**:

- The **converged proposal artifact** itself — the Proposal Document's final recommendation and scope sections, **stripped of the "we considered / we rejected" reasoning sections**. Only the outcome, not the deliberation.
- The **problem statement** as the user originally provided it.
- An explicit instruction to use `Read`, `Glob`, `Grep` on the codebase to investigate failure modes from the code, not from the council's framing.

The Red-Team agent is **explicitly denied** (not included in the message, not available through any other channel):

- The Round 1 position papers
- The Round 1 Digest
- The Round 2 responses or Round 2 Summary
- The tradeoff discussion from the core deliberation
- Any dissent notes from the core rounds

The Red-Team agent's mandate, included in the same message: **"The proposal was implemented and it failed badly. Do not question whether it failed — it did. Work backwards from failure, using only the proposal artifact and the code, not any council's reasoning about it."**

**Why this matters:** a "fresh" agent that has read the council's analysis is already anchored on the tradeoffs the council chose to frame. The pre-mortem's value comes specifically from the failure modes the council **did not** think about — which requires not knowing what the council **did** think about. See stress-tester finding A.4 in the recovered research logs under `docs/superpowers/plans/2026-04-09-council-improvements-research/`.
```

- [ ] **Step 4: Run the script — confirm Task 2 checks pass**

```bash
bash skills/multi-agent-council/tests/prompt-assertions.sh
```

Expected: all Task 1 and Task 2 checks OK.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-agent-council/references/patterns/pre-mortem.md \
        skills/multi-agent-council/tests/prompt-assertions.sh
git commit -m "council: pre-mortem bias fix + team-member dispatch (A.4)"
```

---

## Task 3: Structural complexity gate + inline cost model in `SKILL.md`

**Files:**
- Modify: `skills/multi-agent-council/SKILL.md` (the "Complexity gate" block around lines 43-46)
- Modify: `skills/multi-agent-council/tests/prompt-assertions.sh` (append checks)

Blocker E.3 requires a **structural** gate (not advisory) that surfaces compound cost and lets the user toggle individual modifiers. The cost model is small enough (two tables + toggle surface) that it belongs **inline** in SKILL.md Step 1 where the gate consults it — no separate reference file.

### Research citation

From stress-tester E.3 (recovered logs):

> "Each recommendation individually names its cost. None of them add up the costs together. My back-of-envelope estimate puts a Complex council at 3-4× the current baseline, and 45-60× vs. a single Claude Opus run. Researcher-web's complexity gate surfaces the current '~15×' figure but will be outdated the day these recommendations ship. Users will burn tokens they didn't budget for. Required mitigation: compound cost estimator lives in the complexity gate. The gate is structural — user cannot proceed past it without either accepting the cost in writing or downgrading the configuration. Each optional feature must be individually disableable."

### Steps

- [ ] **Step 1: Append gate assertions to `prompt-assertions.sh`**

```bash
### SKILL.md complexity gate — Task 3 ###
check "3.1 — old 'warning, not a block' removed"                            "$SK" "the gate is a warning, not a block" absent
check "3.1 — structural gate requires 2 named tradeoffs"                    "$SK" "at least 2 meaningful tradeoffs|name 2 tradeoffs" present
check "3.2 — inline cost tier table present"                                "$SK" "Simple.*tier.*10k|Baseline tier estimates" present
check "3.2 — compound cost language present"                                "$SK" "compound.*(cost|estimate)" present
check "3.3 — modifiers individually disableable"                            "$SK" "individually disableable|toggle.*modifier" present
check "3.3 — refuse to spawn fallback present"                              "$SK" "refuse to spawn|direct analysis instead" present
```

- [ ] **Step 2: Run the script — confirm Task 3 checks fail**

Expected: Task 1 and 2 checks OK, Task 3 checks FAIL.

- [ ] **Step 3: Replace the Complexity gate block in `SKILL.md`**

In `skills/multi-agent-council/SKILL.md`, replace the entire "Complexity gate" paragraph (current lines 43-46, starting with "**Complexity gate:** Assess whether a full council is warranted.") with:

````markdown
**Complexity gate (structural, not advisory):** A council is a heavyweight tool — base token cost ranges from 5× single-Opus at Simple tier to 50× at Very Complex tier, and modifiers stack on top — and must not be spawned without written justification and explicit cost acceptance.

The gate blocks spawning unless the user satisfies **all three** of the following:

#### 1. Name at least 2 meaningful tradeoffs

Tradeoffs must be specific. "Scale vs. cost" is generic and not acceptable. "Postgres row-level security vs. application-level auth — RLS centralizes policy but blocks multi-tenant sharding; app-level scales but fragments policy across services" is acceptable. Write these in the skill dialogue before proceeding.

If the user cannot name 2 meaningful tradeoffs, **refuse to spawn the council** and offer direct analysis instead:

> "I don't see 2 distinct tradeoffs that warrant a full council here. Want me to analyze this directly — single pass, no council overhead? Or if you think the tradeoffs are there, rephrase them more specifically and I'll check again."

#### 2. Pick a tier (shows baseline cost)

**Baseline tier estimates — no modifiers:**

| Tier | Meets | Deliberators | Rounds | Tool budget/agent | Est. tokens | ≈ cost vs single-Opus |
|---|---|---|---|---|---|---|
| **Simple** | ≤2 tradeoffs | 2 | 1 + synthesis | ~10k | ~50k total | ~5× |
| **Moderate** | 3-4 tradeoffs | 3 | 2 + synthesis | ~20k | ~150k total | ~15× |
| **Complex** | 5+ tradeoffs or high stakes | 4 | 2 + synthesis | ~35k | ~300k total | ~30× |
| **Very Complex** | cross-domain, asymmetric info | 3 × 3 slices | 2 + synthesis | ~50k | ~500k total | ~50× |

Estimates assume Sonnet 4.6 deliberators + Opus 4.6 team lead. The team lead populates `[TOKEN_BUDGET]` in `references/deliberator-prompt.md` with the per-agent column value for the chosen tier.

#### 3. Pick modifiers (shows compound cost)

**Modifier cost add-ons — all individually disableable:**

| Modifier | Default | Add-on cost | Notes |
|---|---|---|---|
| Judge (`patterns/judge.md`) | off below Complex, opt-in at/above Complex | +30-50k tokens | Optional, non-blocking. See Task 4. |
| Pre-mortem (`patterns/pre-mortem.md`) | off | +40-60k tokens | Adds one Red-Team team member + patch synthesis. |
| Minority Report (`patterns/minority-report.md`) | off | +20-30k tokens | Preserves a dissenting voice in the proposal. |

Show the user a compound estimate before spawning:

```
Tier: Complex (4 deliberators, 2 rounds, ~300k tokens)
  + Judge modifier:      +40k
  + Pre-mortem modifier: +50k
  Total estimate:        ~390k tokens (~40× single-Opus cost)

Reduce by disabling modifiers:
  Council with Judge only:      ~340k
  Council with Pre-mortem only: ~350k
  Council with no modifiers:    ~300k
```

The user must explicitly accept the total **or** choose a reduced configuration. Every modifier is individually disableable — the baseline council (no modifiers) must always be runnable at the tier's advertised cost. No feature is baked so tightly that it cannot be turned off.

Proceed with the council only after all three conditions are satisfied.
````

- [ ] **Step 4: Run the script — confirm Task 3 checks pass**

Expected: all Task 1, 2, and 3 checks OK.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-agent-council/SKILL.md skills/multi-agent-council/tests/prompt-assertions.sh
git commit -m "council: structural complexity gate with inline compound cost model (E.3)"
```

---

## Task 4: Optional Judge modifier (as team member)

**Files:**
- Create: `skills/multi-agent-council/references/patterns/judge.md`
- Modify: `skills/multi-agent-council/references/patterns-index.md` (register judge modifier)
- Modify: `skills/multi-agent-council/tests/prompt-assertions.sh` (append checks)

Blocker E.2 specifies the Judge's design: **optional**, sees **only raw Round 1/Round 2 positions** (never the team lead's synthesis), uses a **falsifiable rubric only**, caps at **1 revision**, **non-blocking** on failure, and — this is the key correction from the original plan draft — dispatched as a **team member**, not a one-shot subagent.

### Research citation

From researcher-web's key finding (recovered `agent-ae0efafc32d52b1ba.jsonl`):

> "Biggest structural gap identified: no independent judge. The team lead currently orchestrates AND synthesizes, which couples debate performance to the verdict. Anthropic's research system, the agent-as-a-judge literature, and the simhacker/moollm@debate skill all isolate the evaluator."

From stress-tester's critique of the researcher's judge design (recovered logs):

> "The judge as specified is another SPOF, reads the team lead's synthesis and will anchor on it, has a subjective rubric that cannot be falsified, and can enter infinite-ish revision loops. Required mitigation: Judge is optional, does not see the team lead's synthesis (re-synthesizes independently from raw Round 1/Round 2), rubric is reduced to falsifiable items only, hard cap of 1 revision, judge failure must not block delivery."

### Why team-member dispatch (not Agent tool)

Same three reasons as Task 2 for the Red-Team: unified dispatch, bounded context via `SendMessage`, and automatic accounting coverage. The Judge joins the council team when the modifier is enabled at the gate, participates in the shutdown protocol, and is tracked by the dispatch accounting rule.

### Steps

- [ ] **Step 1: Append Judge assertions to `prompt-assertions.sh`**

```bash
### judge.md — Task 4 ###
check "4.1 — judge.md exists with title"                                    "$JD" "^# Judge" present
check "4.1 — judge is optional/opt-in"                                      "$JD" "optional|opt-in" present
check "4.1 — judge is dispatched as team member"                            "$JD" "added to the team|team-member dispatch|general-purpose.*team_name|team member" present
check "4.1 — judge never sees the team lead's synthesis"                    "$JD" "not see.*team lead.*synthesis|never receives the synthesis" present
check "4.1 — judge sees raw Round 1/Round 2"                                "$JD" "raw Round 1.*Round 2" present
check "4.1 — falsifiable rubric only"                                       "$JD" "citation existence|citation.claim mapping" present
check "4.1 — hard cap of 1 revision"                                        "$JD" "1 revision|one revision|single revision" present
check "4.1 — non-blocking on judge failure"                                 "$JD" "non-blocking|judge unavailable" present
```

- [ ] **Step 2: Run the script — confirm Task 4 checks fail**

- [ ] **Step 3: Create `references/patterns/judge.md`**

```markdown
# Judge

**Type:** Modifier (optional, layered on any core pattern)
**Best for:** High-stakes deliberations where an independent audit of the team lead's synthesis is worth the cost
**Default:** Disabled. Enabled only at the complexity gate when the user opts in. Not enabled by default below Complex tier.

## What it is

The team lead is both the orchestrator and the synthesizer of the council — which means the team lead has every incentive to present the deliberation as "converged" and to edit dissent for cohesion. The Judge is an **independent audit pass** that re-synthesizes from the raw Round 1 and Round 2 position papers **without seeing the team lead's synthesis**, then compares structural properties of the two syntheses. Divergence is the bias signal.

An earlier draft of this modifier was rejected as a sycophantic SPOF because it would have seen the team lead's synthesis and anchored on it, had a subjective rubric, and could loop indefinitely. This version fixes all three issues by (a) never letting the Judge see the synthesis, (b) using only falsifiable rubric items, and (c) capping revisions at 1.

## When to enable

- High-stakes deliberations where the downside of a biased synthesis is worse than the token cost of an audit
- Deliberations where the team lead has been used repeatedly with the same role set and may have learned unconscious preferences
- When the user explicitly wants a "second opinion" before acting on a proposal

## When to leave disabled

- Moderate or Simple tier councils (not worth the compound cost)
- Exploratory runs — the Judge is for final deliverables, not iteration
- When the user has already decided the direction and wants the council as documentation

## Structure

### Step 1 — Add the Judge to the council team

The Judge is added as a **team member** via the existing `TeamCreate` infrastructure used for deliberators. It is not spawned as a one-shot subagent via the Agent tool.

Dispatch specifics:

- `subagent_type`: `general-purpose`
- `team_name`: the same team the council is running on
- `name`: `judge`
- Prompt: the Judge prompt template (see bottom of this file)

The Judge is added **when the modifier is enabled at the complexity gate** (see `SKILL.md` Step 1), at the same time deliberators are being spawned — not lazily after Round 2.

### Step 2 — The team lead dispatches inputs to the Judge via `SendMessage`

After Round 2 is collected (so the Judge has full raw material), the team lead sends **one** `SendMessage` to the Judge containing:

- The **raw Round 1 position papers** (all deliberators, full text)
- The **raw Round 2 responses** (all deliberators, full text)
- The **problem statement** and any user-injected checkpoint context
- An instruction to use `Read`, `Glob`, `Grep` to verify deliberator citations against the actual code

The Judge is **explicitly denied**:

- The team lead's Round 1 Digest
- The team lead's Round 2 Summary
- The team lead's synthesis (**this is the critical isolation**; the Judge must never see the synthesis it is auditing)

### Step 3 — Judge produces its own independent synthesis

The Judge produces an independent Proposal Document from the raw positions using the same format at `references/proposal-document.md`. Length ≤800 words. It sends the result back to the team lead via `SendMessage`.

### Step 4 — Team lead produces its own synthesis (in parallel or after)

The team lead produces its synthesis per the standard flow. Order does not matter as long as neither reads the other. Because both are team members, this can happen in parallel.

### Step 5 — Falsifiable rubric comparison (team lead side)

The team lead compares its synthesis against the Judge's synthesis using **only falsifiable rubric items**:

1. **Citation existence** — every claim in the team lead's synthesis must cite a specific position paper section. The Judge's synthesis must cite the same. Any uncited claim is a flag.
2. **Citation-claim mapping** — each citation must actually support the claim it is attached to. The Judge verifies this by reading the cited source.
3. **Tradeoff naming** — the team lead's synthesis must name each tradeoff explicitly ("choosing X means accepting Y will be worse"). Missing tradeoffs are flagged.
4. **Dissent preservation** — if any deliberator held a position into Round 2 that was not adopted, both syntheses must surface this under a dissent section. A synthesis that drops Round 2 dissent fails this check.

**Subjective criteria are explicitly excluded.** Items like "honest tradeoffs," "disproportionate favoring," and "steelmanned dissent" were in an earlier draft and were cut — they are not falsifiable and led to coin-flip verdicts.

### Step 6 — Divergence handling (hard cap of 1 revision)

- **Both pass + structurally similar** (same top recommendation, same tradeoffs named, same dissent preserved): ship the team lead's synthesis with a "Judge approved" stamp.
- **Judge flags a rubric failure in the team lead's synthesis**: team lead gets **exactly one** revision pass directly addressing the Judge's specific objection. The Judge does not re-run.
- **Judge and team lead disagree on the top recommendation or named tradeoffs**: the user sees **both syntheses** side by side, with the Judge's specific objection. The Judge is not the authority — the user decides.
- **The Judge never runs more than once.** No revision loops.

### Step 7 — Non-blocking on failure

If the Judge crashes, times out, exceeds its budget, or otherwise cannot produce a synthesis:

- Ship the team lead's synthesis with a "Judge unavailable: [reason]" stamp.
- Log the failure under "Shutdown anomalies" in the Proposal Document.
- **Never block delivery on the Judge.** The Judge is a quality enhancement, not a gate.

The dispatch accounting rule in `team-lead-prompt.md` catches Judge silent drops and handles the retry-then-escalate flow automatically.

## Budget

The Judge's budget is a fixed add-on per `SKILL.md` Step 1 — typically 30-50k tokens. This covers input (Round 1 + Round 2 + problem statement, ~15-25k tokens) + research tokens (~15-25k) + output (~5k).

## Output

When enabled, the Judge adds these sections to the Proposal Document:

1. **Judge rubric** — 4-item checklist (citation existence, citation-claim mapping, tradeoff naming, dissent preservation) with pass/fail and specific objections.
2. **Judge divergence summary** — where the Judge's independent synthesis differed from the team lead's, with specific claim-level citations.

If the Judge approved, the rubric section is included but the divergence summary is omitted.
If the Judge was unavailable, a single "Judge unavailable: [reason]" line replaces both sections.

## Judge prompt template

Use when dispatching the Judge team member:

```
You are the **Judge** on a multi-agent deliberation council. You are NOT a deliberator — you have no value function and no position on the problem. Your job is to independently synthesize a proposal from the raw deliberator outputs and then compare structural properties of your synthesis against whatever the team lead produces (which you will not see).

Your sole inputs:
- The raw Round 1 position papers: [INJECTED_VIA_SENDMESSAGE]
- The raw Round 2 responses: [INJECTED_VIA_SENDMESSAGE]
- The problem statement: [GOAL]
- Codebase access via Read, Glob, Grep — use this to verify deliberator citations against the actual code.

You are explicitly denied access to the team lead's Round 1 Digest, Round 2 Summary, and final synthesis. If you somehow receive them by mistake, do not read them — reply to the team lead with an error message.

Your output is a Proposal Document in the same format as the team lead would produce (see references/proposal-document.md), length ≤800 words, based solely on the raw deliberator outputs you were given.

You do not revise your own output. You produce it once and send it back via SendMessage. The team lead will do the rubric comparison.

Failure modes you must avoid:
- Do not second-guess your own verdict because it might disagree with the team lead
- Do not try to predict what the team lead will say and pre-emptively agree
- Do not produce a synthesis longer than 800 words — conciseness is a signal of clarity
- Do not skip citation verification — the rubric depends on it

You have a research budget of [TOKEN_BUDGET] tokens (set by the team lead based on council tier, typically 30-50k).
```

## Failure mode to watch

The Judge is still an LLM, still subject to the biases deliberators are. It is **not** a source of truth — it is a second independent pass whose **disagreement** with the team lead is the signal. Treat Judge approvals as "no obvious bias caught," not "synthesis is correct." Treat Judge rejections as "investigate this specific objection," not "the team lead was wrong."
```

- [ ] **Step 4: Register the Judge modifier in `patterns-index.md`**

Read the current `skills/multi-agent-council/references/patterns-index.md` and add an entry for `judge.md` under the modifier section, following the format of `pre-mortem.md` and `minority-report.md`. The entry should identify Judge as: modifier, optional opt-in at the gate, high-stakes deliberations requiring independent synthesis audit.

- [ ] **Step 5: Run the script — confirm Task 4 checks pass**

- [ ] **Step 6: Commit**

```bash
git add skills/multi-agent-council/references/patterns/judge.md \
        skills/multi-agent-council/references/patterns-index.md \
        skills/multi-agent-council/tests/prompt-assertions.sh
git commit -m "council: add optional Judge modifier as team member (blocker E.2)"
```

---

## Task 5: Pragmatist pilot — standalone subagent + byte-identity test + kill criterion

**Files:**
- Create: `.claude/agents/pragmatist.md` (at repo root — this is a Claude Code subagent definition)
- Create: `skills/multi-agent-council/tests/value-function-check.sh`
- Modify: `skills/multi-agent-council/SKILL.md` (add a brief pilot status note near the bottom)

**Important design point (stress-tester E.1):** The Pragmatist standalone subagent is a **separate product** from the council. The council does **not** invoke it via `subagent_type`. The council continues to use fragment injection from `references/roles/pragmatist.md`. This avoids the hybrid-dispatch contradiction between the standalone system prompt and the council's Round 1/Round 2 output contract.

### Research citation

From researcher-agents (recovered `agent-a15bf43ad648c5ed9.jsonl` / `agent-a5f49d9aea28a6aee.jsonl`):

> "Of 14 roles, 9 are strong standalone candidates. But the role files are NOT subagent-ready — they're prompt fragments that rely on deliberator-prompt.md for framing. The best architecture is HYBRID, not pure subagent replacement. Publish .claude/agents/*.md for the reusable roles AND keep references/roles/*.md for council-internal use. The only invariant that must hold between the two is the value function sentence."

From stress-tester B.6:

> "Promote incrementally. Do not attempt a big-bang rewrite. But incrementalism without a kill criterion is just slow-motion big-bang. Test gate for going past Phase 1: after Phase 1 pilot, define a falsifiable exit test. Over 2 weeks of real use, the standalone must be invoked ≥5 times outside the council, and ≥3 of those invocations must produce outputs the user kept. If the test fails, the rest of the promotion plan is abandoned, not 'adjusted.'"

### Steps

- [ ] **Step 1: Create the tests/value-function-check.sh script**

```bash
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
```

- [ ] **Step 2: Run the script — confirm it fails (subagent file missing)**

```bash
bash skills/multi-agent-council/tests/value-function-check.sh
```

Expected: FAIL (subagent file missing), exit non-zero.

- [ ] **Step 3: Create `.claude/agents/pragmatist.md`**

```markdown
---
name: pragmatist
description: >
  Use for code reviews, proposal audits, and design reviews where you want
  a "least change, ship fastest, lowest risk" lens applied before committing
  to an approach. Pragmatist actively resists over-engineering, names simpler
  alternatives with file:line evidence, and measures the scope of proposed
  changes. Trigger phrases: "pragmatist review", "least-change alternative",
  "is this worth the scope", "audit this proposal for over-engineering".
  Do NOT use for: exploratory design, greenfield architecture, or problems
  where boldness is required — use Visionary or First Principles for those.
  Do NOT use inside the multi-agent-council skill — the council uses
  fragment injection from references/roles/pragmatist.md, not this subagent.
tools: Read, Glob, Grep, Bash
model: sonnet
---

# Pragmatist

You are the Pragmatist — a code reviewer and proposal auditor invoked for solo use outside of any multi-agent council. This is a standalone product; it is not invoked by the `multi-agent-council` skill.

**Your value function:** Optimize for least change, fastest path to ship, lowest risk. Actively resist over-engineering.

This value function is a hard constraint on your identity, not a preference. You cannot abandon it, soften it to sound reasonable, or defer to "but the team really wants this." If the proposal adds complexity that does not earn its keep, say so with specific evidence. If a simpler path exists, name it with file:line citations.

## Your lens

You see every proposal through cost-of-change. Your core question is: **"what's the minimum modification that solves this?"** You treat complexity as a liability. Every new abstraction, every new file, every new dependency must justify itself against the alternative of doing less.

## How you work

You are a read-only advisor. You do not edit code. You do not run migrations. You do not touch production. Your tools (`Read`, `Glob`, `Grep`, `Bash`) are for investigation only — reading files, searching for patterns, running analysis commands like `git log`, `wc -l`, or `rg --stats`. You never invoke `Bash` in a way that mutates state.

### Investigation checklist

When invoked on a proposal, walk through these steps in order:

1. **Map the proposed change scope.** Count the files that will be touched, the interfaces that will change, the tests that will need updating. Cite specifically: `src/auth/middleware.ts:42-89`, not "the auth layer."
2. **Search for existing solutions.** Does the codebase already solve this problem somewhere? Use `Grep` to find existing patterns. If there is an existing solution that could be extended, say so.
3. **Check git history.** Has this problem been tackled before and abandoned? Use `git log --all --grep=<keyword>` and check for related decisions.
4. **Find the minimum viable alternative.** Given the proposal, what is the smallest change that solves the same problem? One-line edit in an existing file, extending an existing function, a config change instead of code, or doing nothing if the cost exceeds the benefit.
5. **Measure the risk surface.** What could the proposal break? Which tests exercise the affected code? Are there uncovered paths?

### Output contract

Produce a **Pragmatist Review** with these sections:

```
## Pragmatist Review: [subject]

### Minimum viable alternative
[The smallest change that solves this — specific files, line counts, concrete actions. If the proposal already IS the minimum, say so.]

### Scope of the proposed approach
[How many files? How many interfaces? How many tests? What is the blast radius? Cite specific files.]

### Evidence of existing solutions
[What already exists in the codebase that partially or fully solves this? Cite specific files.]

### Recommendation
[One of: (a) proceed as proposed, (b) proceed with this specific simplification, (c) reconsider — a simpler alternative exists, (d) do nothing — the cost exceeds the benefit. Be specific about your reasoning.]

### Tradeoffs accepted
[If your recommendation is adopted, what gets worse? Name the tradeoffs explicitly.]
```

## Rules you must follow

1. Do not soften your verdict to sound reasonable. If the proposal is over-engineered, say so.
2. Do not recommend "further investigation" as a way of deferring a decision. Pick a direction or explicitly state that you cannot from the information available.
3. Do not cite generic principles ("KISS", "YAGNI"). Cite specific evidence — files, line counts, existing patterns, git history.
4. Do not add scope to the proposal. Your job is to shrink it, not grow it.
5. If a simpler alternative exists but requires tradeoffs the user has explicitly accepted, note the alternative but respect the user's decision.

## Relationship to the multi-agent-council skill

The `multi-agent-council` skill has a Pragmatist **role** that shares this value function sentence. The role fragment at `skills/multi-agent-council/references/roles/pragmatist.md` is used by the council via fragment injection into its deliberator prompt. This standalone subagent is a **separate product** — the council does not invoke it. The two representations are intentionally separate because:

- The council's Pragmatist has a Round 1/Round 2 output contract that conflicts with this standalone's code-review output contract.
- The council's Pragmatist participates in cross-agent deliberation; this standalone works solo.
- The only invariant that must hold is the **value function sentence** ("Optimize for least change, fastest path to ship, lowest risk. Actively resist over-engineering.") — enforced by `skills/multi-agent-council/tests/value-function-check.sh`.

If you need a Pragmatist inside a council deliberation, invoke the council skill directly — do not invoke this subagent.

## Pilot status

This is a **14-day pilot**. Success criteria live in `skills/multi-agent-council/SKILL.md` under "Pilot status" — 5+ real invocations outside the council, 3+ kept outputs. Failure → this file is deleted and the 10-role promotion plan is abandoned (not adjusted to a different role).
```

- [ ] **Step 4: Run the value-function check — confirm it passes**

```bash
bash skills/multi-agent-council/tests/value-function-check.sh
```

Expected: `OK: pragmatist — value function byte-identical`, exit 0.

- [ ] **Step 5: Sanity-check the byte-identity test by breaking it intentionally**

Temporarily add a trailing space to the subagent's value function sentence, re-run the test, confirm FAIL, then revert:

```bash
# Use git to revert
git checkout .claude/agents/pragmatist.md
bash skills/multi-agent-council/tests/value-function-check.sh
# Expected: OK, exit 0
```

- [ ] **Step 6: Add the pilot status note to `SKILL.md`**

In `skills/multi-agent-council/SKILL.md`, add a new `## Pilot status` section immediately before `## Reference files` near the bottom:

```markdown
## Pilot status

As of the commit landing this section, the **Pragmatist** role is being piloted as a **standalone reusable subagent** at `.claude/agents/pragmatist.md`. It is a **separate product** from the council — the council continues to use fragment injection from `references/roles/pragmatist.md` and does not invoke the standalone subagent.

The pilot has a **14-day exit test** with PASS/FAIL criteria:

**PASS** (all must hold):
1. The standalone Pragmatist has been invoked **at least 5 times** in real tasks outside the council.
2. At least **3** of those invocations produced outputs the user kept (acted on, merged, or preserved).
3. `tests/value-function-check.sh` has been passing continuously — no drift between fragment and subagent value function sentences.
4. No PR has attempted to wire the standalone into the council dispatch path. (Blocker E.1 — the council uses fragment injection only.)

**FAIL** (any one triggers failure):
1. Fewer than 5 real invocations, OR fewer than 3 kept outputs.
2. Value-function byte-identity test failed at any point during the pilot.
3. Someone attempted to make the council invoke the standalone via `subagent_type` (Blocker E.1 violation).
4. Maintenance burden exceeded 2 PRs in 14 days to keep the subagent aligned with council-side role changes.

**What happens on PASS:** begin considering the next role for promotion. Do **not** promote multiple roles at once. Pick one role (Stress Tester or Falsifier are the strongest candidates per the researcher-agents report), run another 14-day pilot with the same criteria.

**What happens on FAIL:** delete `.claude/agents/pragmatist.md`, remove its entry from `tests/value-function-check.sh`, and **abandon the 10-role promotion plan**. Do not retry with a different role — if Pragmatist (the most obviously reusable role) did not earn its keep, the abstraction is wrong. Any future retry must start with a new research pass addressing *why* the first pilot failed.

**Why a kill criterion:** incrementalism without one is slow-motion big-bang. A pre-registered exit test is the only way to get honest evidence about whether the standalone abstraction is worth the 10× maintenance burden of promoting all viable roles. See stress-tester finding B.6 in the recovered research logs at `docs/superpowers/plans/2026-04-09-council-improvements-research/`.
```

- [ ] **Step 7: Commit**

```bash
git add .claude/agents/pragmatist.md \
        skills/multi-agent-council/tests/value-function-check.sh \
        skills/multi-agent-council/SKILL.md
git commit -m "council: Pragmatist standalone pilot + byte-identity test + kill criterion"
```

---

## Post-plan verification

After all 5 tasks complete, run the full static-check suite:

```bash
cd /Users/tomasdussaillant/repos/skills
bash skills/multi-agent-council/tests/prompt-assertions.sh
bash skills/multi-agent-council/tests/value-function-check.sh
```

Both must exit 0.

### Reference test suite (manual, expensive — execute before promoting any other role)

The stress-tester's critique specified 10 tests the implementation must survive. Implementing all 10 as executable tests is out of scope for this plan (some require running actual councils, which is expensive and non-deterministic). The static checks above cover the regression surface; the manual tests below cover the behavioral surface and should be executed at least once before considering this plan "shipped" and before promoting any additional roles to standalone subagents.

**Execute manual tests A, B, and E at minimum.** The others are documented for completeness and for the future.

- **Test A — SPOF recovery.** Spawn a Complex council, let it reach Round 2, manually kill the team lead process. Verify: deliberators don't hang (shutdown deadline fires), user gets a legible error, no zombie team. Catches: shutdown timeout (Task 1.b) working end-to-end.
- **Test B — Judge thrash.** Prepare two synthetic Proposal Documents — one with intentional buried dissent, one without. Run each through the Judge 5 times. Expected: buried-dissent fails dissent preservation consistently; clean passes all 4 rubric items consistently. Catches: falsifiable rubric is actually falsifiable (Task 4).
- **Test C — Context overflow.** Run Very Complex council on a 100k-token codebase. Expected: no context overflow anywhere. Catches: N² fix from Task 1.a working under load.
- **Test D — Adversarial input.** Run council on a contradictory problem. Expected: proposal names the contradiction in tradeoffs. Catches: divergence check (Task 1.e) + structural gate (Task 3) working together.
- **Test E — Silent drop + accounting.** Spawn a 4-deliberator council, inject a failure in one deliberator mid-Round-1. Expected: dispatch accounting rule catches it, retries once, and if the retry fails surfaces under Known gaps. Catches: Task 1.c working end-to-end.
- **Test F — Budget enforcement.** Run with a low per-agent token budget (5k). Expected: deliberators acknowledge the budget and produce provisional papers instead of blowing through it. Catches: Task 1.d working via self-tracking.
- **Test G — Reproducibility.** Same council, same problem, twice. Expected: meaningfully similar outputs (same top recommendation, overlapping tradeoffs). Catches: skill isn't under-determined.
- **Test H — Cost regression.** Reference problem (to be captured on first run), ±20% bound on token count. Catches: silent cost growth in future PRs.
- **Test I — Hybrid dispatch prohibition.** `grep -r '.claude/agents/' skills/multi-agent-council/` must return no matches outside documentation/test files. Catches: Blocker E.1 reintroduction.
- **Test J — Reference problem definition.** The first person to run Tests C-H should capture the problem statement, expected tier, and expected output shape in a commit to `skills/multi-agent-council/tests/reference-problem.md` so future runs are reproducible.

### Post-commit sanity review

Re-read the four modified files with fresh eyes:

- `SKILL.md` — structural gate is genuinely blocking, not a soft warning with different words
- `team-lead-prompt.md` — digest-only Round 2 directive is unambiguous, shutdown deadline is explicit, accounting rule names modifier agents
- `deliberator-prompt.md` — divergence check requires naming a specific claim, budget placeholder is populated at dispatch
- `patterns/pre-mortem.md` — Red-Team is explicitly a team member, explicitly denied the core council's reasoning
- `patterns/judge.md` — Judge is explicitly a team member, explicitly denied the team lead's synthesis, rubric is falsifiable only
- `.claude/agents/pragmatist.md` — framed as a standalone product with no coupling to the council

---

## What this plan does NOT address (explicit deferrals)

These items from the recovered research logs are deferred to a follow-up plan:

- **A.1 — Team lead SPOF recovery.** Checkpointing Round 1 Digest + Round 2 Summary + partial synthesis to a file for rehydration. Requires designing a serialization format.
- **A.5 — Structural value-function enforcement via LLM check.** A small evaluator agent that verifies Round 2 positions are not framing-dependent. Requires a prompt-agnosticism test.
- **Deliberation Ledger (P1.1).** Deferred until after the Pragmatist pilot validates whether the canonical-source approach is worth the maintenance burden.
- **Stall detection + re-plan loop (P1.2).** Requires the ledger.
- **Hypothesis Council pattern (P1.3).** Rejected in favor of cross-linking `agent-teams:parallel-debugging` from the skill.
- **Dynamic composition / A-HMAD (P2.2).** Deferred as P2.
- **Cross-Examination modifier (P2.1).** Deferred as P2.
- **Opus-lead / Sonnet-deliberators model split (P0.4).** Deferred until model-routing support is confirmed in the Claude Code harness.

---

## Execution

Plan complete and saved to `docs/superpowers/plans/2026-04-09-council-improvements.md`. Ready to execute?

**If your harness has subagents (Claude Code default):** Use `superpowers:subagent-driven-development` — fresh subagent per task with two-stage review. Cleanest approach for this plan given each task is self-contained.

**If your harness does NOT have subagents:** Execute in the current session using `superpowers:executing-plans` — batch execution with user checkpoints between tasks.

Either approach produces the same final state. Pick based on harness capabilities.

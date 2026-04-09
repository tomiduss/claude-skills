# Multi-Agent Council Skill Hardening Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden `skills/multi-agent-council/` against the failure modes surfaced by a 3-agent research council (role-promotion researcher, trends researcher, adversarial stress-tester), shipping the three stress-tester-identified blockers plus the highest-value "left-on-floor" findings.

**Architecture:** In-place edits to 4 existing skill files (`SKILL.md`, `team-lead-prompt.md`, `deliberator-prompt.md`, `patterns/pre-mortem.md`) + 4 new reference/test files (`references/cost-model.md`, `references/patterns/judge.md`, `.claude/agents/pragmatist.md`, `tests/` scripts). Every change preserves the skill's core principles: value-function diversity, evidence-based deliberation, human-in-the-loop checkpoints. The changes harden the skill against sycophantic convergence, unbounded token cost, and single-point-of-failure synthesis.

**Tech Stack:** Markdown (skill authoring), Bash (byte-identity test script, cost-regression test script), grep-based content assertions.

**Research inputs:**
- `/tmp/researcher-agents-report.md` — role-to-subagent promotion analysis
- `/tmp/researcher-web-report.md` — multi-agent orchestration trend survey
- `/tmp/stress-tester-critique.md` — adversarial critique with 16 mitigations + 10-test suite

---

## Scope — What IS and IS NOT being built

### In scope (this plan)

1. **Blocker E.1** — Drop hybrid dispatch. Council uses fragment injection only. Standalone subagents are a separate product. (Task 10)
2. **Blocker E.2** — Optional judge modifier: non-mandatory, falsifiable rubric only, no synthesis access, 1 revision cap, non-blocking on failure. (Task 6)
3. **Blocker E.3** — Compound cost estimator + structural complexity gate + individually disableable features. (Tasks 4, 5)
4. **Left on floor by both researchers — A.2** Digest-only Round 2 injection (fixes N² context growth). (Task 1)
5. **Left on floor by both researchers — A.4** Pre-mortem restricted to proposal + code only, not reasoning. (Task 3)
6. **Per-agent token budget + strengthened divergence check** (C.2, C.3). (Task 2)
7. **Shutdown timeout + dispatch accounting** (A.6, C.8). (Task 1)
8. **Pragmatist pilot standalone subagent** — separate product, with kill-criterion exit test (B.6, C.11). (Tasks 7, 8, 9)
9. **Reference test suite** — subset of stress-tester's 10 tests, operationalized. (Task 11)

### Explicitly NOT in scope (deferred or rejected)

- **Hybrid dispatch for standalone agents in the council** — rejected per Blocker E.1. Standalone subagents are a separate product.
- **Deliberation Ledger (P1.1)** — deferred. High surface area, enables other features but is not required for the P0 changes. Revisit after Pragmatist pilot passes.
- **Stall detection + re-plan loop (P1.2)** — deferred. Requires the ledger.
- **Hypothesis Council pattern (P1.3)** — rejected. Cross-link `agent-teams:parallel-debugging` from the skill instead of importing the pattern.
- **Dynamic composition / A-HMAD (P2.2)** — deferred. Interesting but unvalidated.
- **Cross-Examination modifier (P2.1)** — deferred. Wait for user evidence that Round 2 is too broad.
- **Canonical source inversion** (making `.claude/agents/*.md` the source of truth and generating fragments) — rejected per stress-tester B.4. Two hand-maintained artifacts with a byte-identity test for the value function sentence is the correct design.
- **Big-bang promotion of 10 roles** — rejected. Only Pragmatist in this plan, gated on kill criterion before any others are promoted.
- **Opus-lead / Sonnet-deliberators model split (P0.4)** — deferred. Downgraded to P2 per stress-tester C.4. Add only when model routing support is confirmed in the infrastructure.

---

## Task Dependency Order

```
Task 1 (team-lead-prompt hardening)  ──┐
Task 2 (deliberator-prompt hardening) ─┤
Task 3 (pre-mortem fix)              ──┤
                                        ├──→ Task 4 (cost-model.md)
                                        │         │
                                        │         ▼
                                        │    Task 5 (structural gate in SKILL.md)
                                        │         │
                                        │         ▼
                                        │    Task 6 (optional judge modifier)
                                        │
                                        └──→ Task 7 (Pragmatist subagent)
                                                  │
                                                  ▼
                                             Task 8 (byte-identity test)
                                                  │
                                                  ▼
                                             Task 9 (pilot kill criterion doc)

Task 10 (rejection documentation) — any time
Task 11 (reference test suite)    — after Tasks 1-6
```

Execute top-to-bottom. Tasks 1-3 are independent content edits to separate files and could in principle be parallelized, but in a serial session each is short enough that sequential is cleaner.

---

## Task 1: Harden `team-lead-prompt.md`

**Files:**
- Modify: `skills/multi-agent-council/references/team-lead-prompt.md`
- Test: `skills/multi-agent-council/tests/team-lead-prompt.sh` (create)

This task makes three related hardening edits to the same file:
- **1.a** — Digest-only Round 2 injection (fixes A.2 N² context growth)
- **1.b** — Shutdown timeout (fixes A.6 hang)
- **1.c** — Dispatch accounting rule (C.8 + A.6)

- [ ] **Step 1: Create the tests directory**

```bash
mkdir -p /Users/tomasdussaillant/repos/skills/skills/multi-agent-council/tests
```

- [ ] **Step 2: Write failing assertions for all 3 changes**

Create `skills/multi-agent-council/tests/team-lead-prompt.sh`:

```bash
#!/usr/bin/env bash
# Assertions for hardened team-lead-prompt.md
# Exits non-zero if any check fails.
set -u
PROMPT="skills/multi-agent-council/references/team-lead-prompt.md"
fail=0

check() {
  local label="$1" pattern="$2" expect="$3"
  if grep -qE "$pattern" "$PROMPT"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then
    echo "FAIL: $label (expected $expect, got $found)"
    fail=1
  else
    echo "OK:   $label"
  fi
}

# 1.a — Digest-only Round 2 injection (A.2 fix)
check "A.2 — old 'full text, not summaries' directive removed" \
  "full text, not summaries" absent
check "A.2 — digest-only Round 2 directive present" \
  "Round 1 Digest.*not the raw position papers" present
check "A.2 — peer-context token cap present" \
  "peer.context.*token.*cap|2,?000.token" present

# 1.b — Shutdown timeout (A.6 fix)
check "A.6 — shutdown deadline present" \
  "shutdown.*deadline|within.*(30|sixty).*second" present
check "A.6 — 'proceed with TeamDelete after deadline' clause" \
  "proceed with .TeamDelete|presumed.*dead" present

# 1.c — Dispatch accounting rule (C.8)
check "C.8 — accounting rule present" \
  "Dispatch Accounting|expected respondents" present
check "C.8 — known gaps section in proposal" \
  "Known gaps" present

exit $fail
```

- [ ] **Step 3: Run the test — confirm it fails (all 7 checks)**

```bash
bash skills/multi-agent-council/tests/team-lead-prompt.sh
```

Expected: 7 FAIL lines, exit non-zero.

- [ ] **Step 4: Apply edit 1.a — digest-only Round 2 injection**

In `skills/multi-agent-council/references/team-lead-prompt.md`, replace the current line 54-57 (Round 2 dispatch bullet) with:

```markdown
6. After the user checkpoint, send Round 2 directives to each deliberator via `SendMessage`:
   - **Include the Round 1 Digest you produced in step 3, not the raw position papers.** The digest is bounded (2-3 sentences per agent + tension points); raw papers grow N² across rounds and will overflow agent context by Round 3 of any deliberation with 4+ agents.
   - Hard cap: the peer-context block passed to any single deliberator must fit within a 2,000-token budget. If the digest exceeds this, compress further — drop non-load-bearing citations, keep the tension points.
   - Include any user-injected context or redirections from the checkpoint.
   - Instruct each agent to follow the Round 2 protocol from their prompt.
```

- [ ] **Step 5: Apply edit 1.b — shutdown timeout**

In the same file, replace the current "### Shutdown" section (lines 78-82) with:

```markdown
### Shutdown

13. After delivering the proposal, send `shutdown_request` to each deliberator.
14. Wait for acknowledgment from each agent, with a **hard shutdown deadline of 30 seconds** from dispatch. After the deadline, any agent that has not acknowledged is presumed dead.
15. For each non-acknowledging agent, proceed with `TeamDelete` regardless and log the anomaly under "Shutdown anomalies" in the proposal document. Do not block waiting for dead agents — the user must not be made to manually clean up a zombie team.
16. Report completion to the user.
```

- [ ] **Step 6: Apply edit 1.c — dispatch accounting rule**

In the same file, insert a new section between "### Round 1 — Collect and digest" and "### Round 2 — Cross-pollinate and collect" (before current line 52):

```markdown
### Dispatch Accounting (runs every round)

Before each round, record the expected respondents in a private accounting list. After the round:

- If any deliberator has not produced a response after a grace period (60 seconds from the last respondent, or 3 minutes from dispatch, whichever comes first), mark that agent as a **silent drop**.
- Retry the silent drop **once** with an explicit prompt hint: "Your Round N response was not received. Please produce it now, or reply with a one-sentence explanation of why you cannot."
- If the retry also fails, escalate to the user with the specific agent name and what it was expected to produce. Do not silently synthesize around the missing voice — a missing Contrarian or Falsifier is a quality failure, not a speed optimization.
- At synthesis time: any deliberator that never produced a Round 2 response must appear in the Proposal Document under a **Known gaps** section, named and with their expected contribution noted.
```

- [ ] **Step 7: Run the test — confirm all 7 checks pass**

```bash
bash skills/multi-agent-council/tests/team-lead-prompt.sh
```

Expected: 7 OK lines, exit 0.

- [ ] **Step 8: Commit**

```bash
git add skills/multi-agent-council/references/team-lead-prompt.md skills/multi-agent-council/tests/team-lead-prompt.sh
git commit -m "council: harden team-lead prompt (A.2 N² fix, A.6 shutdown timeout, C.8 accounting)"
```

---

## Task 2: Harden `deliberator-prompt.md`

**Files:**
- Modify: `skills/multi-agent-council/references/deliberator-prompt.md`
- Test: `skills/multi-agent-council/tests/deliberator-prompt.sh` (create)

This task makes two edits to the deliberator prompt:
- **2.a** — Per-agent token budget line (C.3 + A.3)
- **2.b** — Strengthened divergence check in Round 2 (C.2 + A.5)

- [ ] **Step 1: Write failing assertions**

Create `skills/multi-agent-council/tests/deliberator-prompt.sh`:

```bash
#!/usr/bin/env bash
set -u
PROMPT="skills/multi-agent-council/references/deliberator-prompt.md"
fail=0
check() {
  local label="$1" pattern="$2" expect="$3"
  if grep -qE "$pattern" "$PROMPT"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then
    echo "FAIL: $label"
    fail=1
  else
    echo "OK:   $label"
  fi
}

# 2.a — Token budget
check "C.3 — token budget placeholder present" \
  "\[TOKEN_BUDGET\]|budget of .* tokens" present
check "C.3 — budget reporting required in position paper" \
  "Budget consumed|token.*consumption" present

# 2.b — Divergence check (named specific claim, not just "new evidence")
check "C.2 — Round 2 update must name a specific other-agent claim" \
  "name the specific.*claim|identify the claim you are updating against" present
check "old weak 'update if warranted' directive removed" \
  "Update if warranted" absent

exit $fail
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
bash skills/multi-agent-council/tests/deliberator-prompt.sh
```

Expected: 4 FAIL, exit non-zero.

- [ ] **Step 3: Apply edit 2.a — token budget**

In `skills/multi-agent-council/references/deliberator-prompt.md`, replace the current "### Tools at your disposal" block (lines 37-42) with:

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

(The `[TOKEN_BUDGET]` placeholder is populated by the team lead at dispatch based on the complexity gate tier — see Task 4.)

- [ ] **Step 4: Apply edit 2.b — strengthened divergence check**

In the same file, replace the current "## Round 2 — Respond to other agents" section (lines 69-77) with:

```markdown
## Round 2 — Respond to other agents

You will receive the Round 1 Digest (not the raw position papers — they are too long). The digest lists each agent's position, key evidence, and points of tension. You must:

1. **Acknowledge** the single strongest counterargument to your position. You must **name the agent and quote the specific claim** you are responding to — not "another agent argued that complexity is worth it" but "the Visionary's claim at [file:line or URL] that the caching layer would pay for itself within one quarter."
2. **Hold or update — with structural evidence.** Position changes must satisfy a two-part check:
   a. You must **name a specific claim from another agent** that caused your update (not "the discussion caused me to reconsider" — name the claim, cite its source).
   b. You must **cite new information** you did not have in Round 1: another agent's finding, user-checkpoint input, or a file you had not read in Round 1.
   If you cannot satisfy both parts, **hold your position**. Softening without cited new evidence is sycophancy, and the team lead will flag it.
3. **Hold ground with evidence** — for remaining disagreements, explain specifically why you still hold your position. Cite evidence, not conviction.

Your Round 2 response must be ≤300 words and must include:
- The named counter-claim you are responding to (author + quote)
- Your hold-or-update decision with the required justification
- Any remaining tension points where you still disagree, with evidence
```

- [ ] **Step 5: Run the test — confirm all 4 checks pass**

```bash
bash skills/multi-agent-council/tests/deliberator-prompt.sh
```

Expected: 4 OK, exit 0.

- [ ] **Step 6: Commit**

```bash
git add skills/multi-agent-council/references/deliberator-prompt.md skills/multi-agent-council/tests/deliberator-prompt.sh
git commit -m "council: add token budget + strengthened divergence check to deliberator prompt"
```

---

## Task 3: Fix pre-mortem bias leak (A.4)

**Files:**
- Modify: `skills/multi-agent-council/references/patterns/pre-mortem.md:18-26`
- Test: `skills/multi-agent-council/tests/pre-mortem.sh` (create)

The current pre-mortem pattern contaminates the "fresh" red-team agent by feeding it the core council's reasoning and tradeoffs. Restrict the red-team agent to the proposal artifact + code only.

- [ ] **Step 1: Write failing assertion**

Create `skills/multi-agent-council/tests/pre-mortem.sh`:

```bash
#!/usr/bin/env bash
set -u
FILE="skills/multi-agent-council/references/patterns/pre-mortem.md"
fail=0
check() {
  local label="$1" pattern="$2" expect="$3"
  if grep -qE "$pattern" "$FILE"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then
    echo "FAIL: $label"
    fail=1
  else
    echo "OK:   $label"
  fi
}

check "old 'reasoning and tradeoffs' inheritance removed" \
  "reasoning and tradeoffs documented by the core pattern" absent
check "old 'dissent from core rounds' inheritance removed" \
  "dissent or unresolved disagreements from the core rounds" absent
check "bias-isolation note present" \
  "no access to the core council's reasoning|proposal artifact only" present
check "codebase access still granted" \
  "(codebase|code)" present

exit $fail
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
bash skills/multi-agent-council/tests/pre-mortem.sh
```

Expected: first 3 FAIL, last OK, exit non-zero.

- [ ] **Step 3: Apply the edit**

In `skills/multi-agent-council/references/patterns/pre-mortem.md`, replace the current "### Step 1 — Spawn Red-Team Agent" section (lines 18-26) with:

```markdown
### Step 1 — Spawn Red-Team Agent

The team lead spawns a single red-team agent via the Agent tool. This agent is deliberately isolated from the core council's reasoning — a fresh perspective is the point, and the current skill has a bias-leak bug where reading the council's framing contaminates the agent's analysis.

The red-team agent receives **only**:

- The **converged proposal artifact** itself (the Proposal Document's final recommendation and scope sections, stripped of any "we considered" or "we rejected" reasoning)
- The **problem statement** as the user originally provided it
- **Codebase access** via `Read`, `Glob`, `Grep` tools — the red-team agent should rediscover failure modes from the code, not from the council's framing

The red-team agent is **explicitly denied**:

- The Round 1 position papers
- The Round 2 summary
- The tradeoff discussion from the core deliberation
- Any dissent notes from the core rounds

The red-team agent's mandate: the proposal was implemented and it failed badly. Do not question whether it failed — it did. Work backwards from failure, using **only the proposal artifact and the code**, not the council's reasoning about it.

**Why this matters:** a "fresh" agent that has read the council's own analysis is already anchored on the tradeoffs the council chose to frame. The pre-mortem's value comes specifically from the failure modes the council *didn't* think about — which requires not knowing what the council *did* think about. See `/tmp/stress-tester-critique.md` §A.4 for the original finding.
```

- [ ] **Step 4: Run the test — confirm all 4 checks pass**

```bash
bash skills/multi-agent-council/tests/pre-mortem.sh
```

Expected: 4 OK, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-agent-council/references/patterns/pre-mortem.md skills/multi-agent-council/tests/pre-mortem.sh
git commit -m "council: restrict pre-mortem red-team to proposal artifact only (A.4 bias fix)"
```

---

## Task 4: Create `cost-model.md` reference

**Files:**
- Create: `skills/multi-agent-council/references/cost-model.md`
- Test: `skills/multi-agent-council/tests/cost-model.sh` (create)

This is the compound cost estimator that the structural complexity gate (Task 5) will consult. Blocker E.3 requires that users see a compound cost before proceeding, with each optional feature individually disableable.

- [ ] **Step 1: Write failing assertion**

Create `skills/multi-agent-council/tests/cost-model.sh`:

```bash
#!/usr/bin/env bash
set -u
FILE="skills/multi-agent-council/references/cost-model.md"
fail=0
check() {
  local label="$1" pattern="$2" expect="$3"
  if [ -f "$FILE" ] && grep -qE "$pattern" "$FILE"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then
    echo "FAIL: $label"
    fail=1
  else
    echo "OK:   $label"
  fi
}
check "file exists with header"        "# Council Cost Model" present
check "Simple tier estimate"            "Simple.*tier" present
check "Moderate tier estimate"          "Moderate.*tier" present
check "Complex tier estimate"           "Complex.*tier" present
check "Very Complex tier estimate"      "Very Complex.*tier" present
check "judge cost add-on line"          "Judge modifier.*token" present
check "pre-mortem cost add-on line"     "Pre-mortem modifier.*token" present
check "disableability table"            "individually disableable|Disable.*feature" present
check "cost regression test reference"  "cost regression test|±20%" present
exit $fail
```

- [ ] **Step 2: Run the test — confirm file does not exist yet**

```bash
bash skills/multi-agent-council/tests/cost-model.sh
```

Expected: 9 FAIL.

- [ ] **Step 3: Create the cost model reference**

Create `skills/multi-agent-council/references/cost-model.md`:

```markdown
# Council Cost Model

This reference is consulted by the complexity gate in `SKILL.md` Step 1. It translates a proposed council configuration into a **compound token budget** that the user must see and accept before the council runs.

This file exists because each individual recommendation names its own cost but none add up the compound cost. Blocker E.3 in `/tmp/stress-tester-critique.md` surfaced that a Complex council with all P0+P1 items enabled costs ~3-4× the baseline, or ~45-60× a single Claude Opus run — versus the "~15×" figure cited in Anthropic's public post. Users should not be surprised.

## Base tier estimates (no modifiers)

These are baseline estimates for the core Council pattern. Modifiers layer on top (see next section).

| Tier | Description | Deliberators | Rounds | Tool calls/agent | Est. tokens (input+output) | Baseline cost signal |
|---|---|---|---|---|---|---|
| **Simple tier** | ≤2 meaningful tradeoffs | 2 | 1 + synthesis | 5-10 | ~50k | ~5× single-Opus |
| **Moderate tier** | 3-4 tradeoffs | 3 | 2 + synthesis | 10-15 | ~150k | ~15× single-Opus |
| **Complex tier** | 5+ tradeoffs or high stakes | 4 | 2 + synthesis | 15-25 | ~300k | ~30× single-Opus |
| **Very Complex tier** | cross-domain, asymmetric info | 3 × 3 slices | 2 + synthesis | 15-25 | ~500k | ~50× single-Opus |

Estimates assume Claude Sonnet 4.6 deliberators and a Claude Opus 4.6 team lead. Adjust proportionally for other models.

## Modifier cost add-ons (optional features)

Each modifier is **individually disableable** at the gate. The user can run any council tier without any modifier. Modifier costs compound — enabling all of them on Complex tier puts you at ~3-4× the base tier cost.

| Modifier | Additional cost | Notes |
|---|---|---|
| **Judge modifier** | +30-50k tokens | Adds one independent agent pass + up to 1 revision. Non-blocking on failure. See `patterns/judge.md`. |
| **Pre-mortem modifier** | +40-60k tokens | Adds one red-team agent + patch synthesis. See `patterns/pre-mortem.md`. |
| **Minority report modifier** | +20-30k tokens | Preserves a dissenting voice in the proposal. See `patterns/minority-report.md`. |
| **Asymmetric info pattern** | already in tier cost | Handled by choosing Very Complex tier. |

## Compound cost surface at the gate

The complexity gate (see `SKILL.md` Step 1) must show the user a compound estimate like:

```
Tier: Complex (4 deliberators, 2 rounds, ~300k tokens)
  + Judge modifier:     +40k
  + Pre-mortem modifier: +50k
  Total estimate:        ~390k tokens (~40× single-Opus cost)

Disable modifiers to reduce cost:
  - Council with Judge only:     ~340k
  - Council with Pre-mortem only: ~350k
  - Council with no modifiers:    ~300k
```

The user must explicitly accept the total or choose a reduced configuration.

## Individually disableable features

The gate exposes flags the user can set before spawning the council:

- `council.judge.enabled` — default `false` for Moderate and below, `true` for Complex/Very Complex. User-overridable.
- `council.pre_mortem.enabled` — default `false`. User-enabled for high-stakes decisions.
- `council.minority_report.enabled` — default `false`. User-enabled when dissent preservation matters.

No feature is baked so tightly that it cannot be turned off. The baseline council (no modifiers) must always be runnable at the tier's advertised cost.

## Cost regression test

A cost regression test lives at `tests/cost-regression.sh`. It runs the reference problem through a Moderate-tier council and asserts the total token count is within **±20%** of the expected value. Any change to the skill that pushes the reference run outside ±20% must be explicitly acknowledged in the PR description — silent cost growth is a bug.

See `tests/cost-regression.sh` for the reference problem and current expected range.
```

- [ ] **Step 4: Run the test — confirm all 9 checks pass**

```bash
bash skills/multi-agent-council/tests/cost-model.sh
```

Expected: 9 OK, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-agent-council/references/cost-model.md skills/multi-agent-council/tests/cost-model.sh
git commit -m "council: add compound cost model reference (blocker E.3)"
```

---

## Task 5: Make complexity gate structural in `SKILL.md`

**Files:**
- Modify: `skills/multi-agent-council/SKILL.md:37-46`
- Test: `skills/multi-agent-council/tests/skill-gate.sh` (create)

The current complexity gate is a soft warning (`SKILL.md:46` says "the gate is a warning, not a block"). Blocker E.3 and finding A.7 require a structural gate that cannot be clicked through — it demands a written justification citing tradeoffs, shows the compound cost, and offers individually disableable modifiers.

- [ ] **Step 1: Write failing assertion**

Create `skills/multi-agent-council/tests/skill-gate.sh`:

```bash
#!/usr/bin/env bash
set -u
FILE="skills/multi-agent-council/SKILL.md"
fail=0
check() {
  local label="$1" pattern="$2" expect="$3"
  if grep -qE "$pattern" "$FILE"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then
    echo "FAIL: $label"; fail=1
  else
    echo "OK:   $label"
  fi
}
check "old 'warning, not a block' language removed" "the gate is a warning, not a block" absent
check "structural gate requires written justification" "written justification|name at least 2" present
check "gate references cost-model.md" "cost-model.md" present
check "gate surfaces compound token estimate" "compound.*(estimate|cost|budget)" present
check "modifier disable surface present" "disable.*modifier|toggle.*modifier" present
exit $fail
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
bash skills/multi-agent-council/tests/skill-gate.sh
```

Expected: most checks FAIL.

- [ ] **Step 3: Apply the edit**

In `skills/multi-agent-council/SKILL.md`, replace the current "Complexity gate" block (lines 43-46) with:

```markdown
**Complexity gate (structural, not advisory):** Assess whether a full council is warranted. A council is a heavyweight tool — runs in the 5×-50× single-Opus cost range depending on tier (see `references/cost-model.md`) — and must not be spawned without a written justification.

The gate blocks spawning unless the user can satisfy **all three** of the following:

1. **Name at least 2 meaningful tradeoffs.** These must be specific tradeoffs the council will help surface. "Scale vs. cost" is generic and is not acceptable. "Postgres row-level security vs. application-level auth — the first centralizes policy but blocks multi-tenant sharding; the second scales but fragments policy across services" is acceptable. Write these in the skill dialogue before proceeding.
2. **Pick a tier.** Read `references/cost-model.md` and pick Simple / Moderate / Complex / Very Complex based on the tradeoff count and stakes. The gate shows the baseline token estimate for the chosen tier.
3. **Pick modifiers.** Choose which optional modifiers (Judge, Pre-mortem, Minority Report) are enabled. The gate shows the **compound cost estimate** with all chosen modifiers added in, and shows the incremental cost of each modifier so the user can toggle and compare. No modifier is enabled by default below Complex tier. Every modifier is individually disableable — the baseline council (no modifiers) must always be runnable.

If the user cannot name 2 meaningful tradeoffs, or declines to accept the compound cost, **refuse to spawn the council** and offer to proceed with direct analysis instead:

> "I don't see 2 distinct tradeoffs that warrant a full council here. Want me to analyze this directly — single pass, no council overhead? Or if you think the tradeoffs are there, rephrase them more specifically and I'll check again."

The goal of the structural gate is not to frustrate users — it is to prevent the skill from being invoked on problems that do not need it, because invoking it carries a real and measurable token cost.

Proceed only if all three conditions are satisfied.
```

- [ ] **Step 4: Run the test — confirm all 5 checks pass**

```bash
bash skills/multi-agent-council/tests/skill-gate.sh
```

Expected: 5 OK, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-agent-council/SKILL.md skills/multi-agent-council/tests/skill-gate.sh
git commit -m "council: structural complexity gate with compound cost (blocker E.3, A.7)"
```

---

## Task 6: Add optional Judge modifier pattern

**Files:**
- Create: `skills/multi-agent-council/references/patterns/judge.md`
- Modify: `skills/multi-agent-council/references/patterns-index.md` (register the modifier)
- Test: `skills/multi-agent-council/tests/judge-pattern.sh` (create)

Blocker E.2 specifies the design: the judge is **optional**, receives **only raw Round 1/Round 2 positions** (never the synthesis), uses a **falsifiable rubric only**, caps at **1 revision**, and is **non-blocking on failure**.

- [ ] **Step 1: Write failing assertion**

Create `skills/multi-agent-council/tests/judge-pattern.sh`:

```bash
#!/usr/bin/env bash
set -u
FILE="skills/multi-agent-council/references/patterns/judge.md"
IDX="skills/multi-agent-council/references/patterns-index.md"
fail=0
check() {
  local label="$1" target="$2" pattern="$3" expect="$4"
  if [ -f "$target" ] && grep -qE "$pattern" "$target"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then echo "FAIL: $label"; fail=1; else echo "OK:   $label"; fi
}

check "judge.md exists" "$FILE" "# Judge" present
check "judge is optional/opt-in" "$FILE" "optional|opt-in" present
check "judge does NOT see the synthesis" "$FILE" "not see the (team lead'?s )?synthesis|never receives the synthesis" present
check "judge sees only raw Round 1/Round 2 positions" "$FILE" "raw Round 1.*Round 2" present
check "falsifiable rubric only (citation existence + mapping)" "$FILE" "citation existence|citation.claim mapping" present
check "hard cap of 1 revision" "$FILE" "1 revision|one revision|single revision" present
check "non-blocking on judge failure" "$FILE" "non-blocking|judge unavailable" present
check "registered in patterns-index.md" "$IDX" "judge\.md|Judge modifier" present
exit $fail
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
bash skills/multi-agent-council/tests/judge-pattern.sh
```

Expected: 8 FAIL.

- [ ] **Step 3: Create `patterns/judge.md`**

```markdown
# Judge

**Type:** Modifier (optional, layered on any core pattern)
**Best for:** High-stakes decisions where the user wants an independent sanity check on the team lead's synthesis
**Default:** Disabled. The gate enables it only for Complex/Very Complex tiers and only if the user opts in.

## What it is

The team lead is both the orchestrator and the synthesizer of the council — which means the team lead has every incentive to present the deliberation as "converged" and edit dissent for cohesion. The Judge is an independent pass that re-synthesizes from the raw Round 1 and Round 2 position papers **without seeing the team lead's synthesis**, then compares the two. Divergence between the team lead's synthesis and the judge's independent re-synthesis is the bias signal.

This modifier is a deliberately minimal design. An earlier draft of this modifier (critiqued at `/tmp/stress-tester-critique.md` §E.2) was rejected as a sycophantic SPOF because the judge would have seen the synthesis and anchored on it, had a subjective rubric, and could loop indefinitely. This version fixes all three issues.

## When to enable

- High-stakes deliberations where the downside of a biased synthesis is worse than the token cost of a second pass
- Deliberations where the team lead is known to favor certain value functions (e.g., when the same team lead has been used repeatedly with the same set of roles and may have learned unconscious preferences)
- When the user explicitly wants a "second opinion" audit of a council's proposal before acting on it

## When to leave disabled

- Moderate or Simple tier councils (not worth the compound cost)
- Any case where the user has already decided the direction and wants the council as documentation only — the judge adds cost without changing action
- When running the council multiple times for exploration (the judge is for final deliverables, not exploration passes)

## Structure

### Step 1 — Spawn the Judge

The team lead spawns a single Judge agent via the Agent tool **after** Round 2 is collected but **before** the team lead's synthesis is produced. The Judge receives:

- The **raw Round 1 position papers** (all deliberators, full text, not the digest)
- The **raw Round 2 responses** (all deliberators, full text)
- The **problem statement** and any user-injected context
- **Codebase access** (`Read`, `Glob`, `Grep`) to verify citations the deliberators made

The Judge is **explicitly denied**:

- The team lead's Round 1 Digest
- The team lead's Round 2 Summary
- The team lead's synthesis (it does not exist yet at this point, and the Judge must never see it even if the order changes)

This is the critical design point: if the Judge reads the synthesis, it will anchor on it and rubber-stamp. The Judge must never see the synthesis it is auditing.

### Step 2 — Judge produces its own synthesis

The Judge produces an independent synthesis from the raw positions, using the same Proposal Document format the team lead uses (see `references/proposal-document.md`). Length ≤800 words.

### Step 3 — Team lead produces its synthesis

In parallel (or afterwards — order does not matter as long as neither reads the other), the team lead produces its own synthesis per the standard flow.

### Step 4 — Falsifiable rubric comparison

The team lead compares its synthesis against the Judge's synthesis using a **falsifiable rubric only**:

1. **Citation existence** — every claim in the team lead's synthesis must cite a specific position paper section. The Judge's synthesis must cite the same.
2. **Citation-claim mapping** — each citation must actually support the claim it is attached to. The Judge verifies this against the raw papers.
3. **Tradeoff naming** — the team lead's proposal must name each tradeoff explicitly ("choosing X means accepting Y will be worse"). The Judge's proposal must do the same. Missing tradeoffs are flagged.
4. **Dissent preservation** — if any deliberator held a position into Round 2 that was not adopted, both syntheses must surface this under a dissent section. A synthesis that drops Round 2 dissent fails this check.

**Subjective criteria are explicitly excluded.** The earlier draft included "honest tradeoffs," "disproportionate favoring," and "steelmanned dissent" — these are not falsifiable and were rejected.

### Step 5 — Divergence handling (hard cap of 1 revision)

- If the Judge's synthesis passes all 4 rubric items and is structurally similar to the team lead's synthesis (same top recommendation, same tradeoffs named, same dissent preserved): **ship the team lead's synthesis** with a "Judge approved" stamp.
- If the Judge flags a rubric failure in the team lead's synthesis: the team lead gets **exactly one revision pass**. The Judge does not re-run. The revision must directly address the Judge's specific objection.
- If the Judge's synthesis and the team lead's synthesis differ on the top recommendation or on which tradeoffs were named: the user sees **both syntheses** side by side, with the Judge's specific objection, and decides which to act on. The Judge is not the authority — the user is.
- **The Judge never runs more than once.** No revision loops. No "keep judging until it agrees."

### Step 6 — Non-blocking on failure

If the Judge crashes, times out, exceeds its budget, or otherwise cannot produce a synthesis:

- **Ship the team lead's synthesis** with a "Judge unavailable" stamp in the Proposal Document.
- Log the failure under "Shutdown anomalies" so the user can retry the Judge separately if they want.
- **Never block delivery on the Judge.** The Judge is a quality enhancement, not a gate on the council's output.

## Budget

The Judge's budget is a fixed add-on per `references/cost-model.md` — typically 30-50k tokens. This covers input (Round 1 + Round 2 + problem statement, ~15-25k tokens) plus the Judge's own research tokens (~15-25k) plus output (~5k).

## Output

When enabled, the Judge adds two sections to the Proposal Document:

1. **Judge rubric** — a 4-item checklist (citation existence, citation mapping, tradeoff naming, dissent preservation) with pass/fail and specific objections
2. **Judge divergence summary** — where the Judge's independent synthesis differed from the team lead's, with specific claim-level citations

If the Judge stamped "approved," the rubric section is included but the divergence summary is omitted.

If the Judge was unavailable, a single "Judge unavailable: [reason]" line replaces both sections.

## Failure mode to watch

The Judge is still an LLM, and still subject to the same biases the deliberators are. It is **not** a source of truth — it is a second independent pass whose disagreement with the team lead is the signal. Treat Judge approvals as "no obvious bias caught," not "synthesis is correct." Treat Judge rejections as "investigate this specific objection," not "the team lead was wrong."

See `/tmp/stress-tester-critique.md` §C.1 and §E.2 for the original critique that shaped this design.
```

- [ ] **Step 4: Register the modifier in `patterns-index.md`**

Read the current `skills/multi-agent-council/references/patterns-index.md` and add a row for `judge.md` under the modifier section. Use the existing modifier entries (e.g., `pre-mortem.md`, `minority-report.md`) as the format template. The row should identify Judge as: `modifier`, `optional, opt-in at the gate`, `high-stakes deliberations needing an independent synthesis audit`.

- [ ] **Step 5: Run the test — confirm all 8 checks pass**

```bash
bash skills/multi-agent-council/tests/judge-pattern.sh
```

Expected: 8 OK, exit 0.

- [ ] **Step 6: Commit**

```bash
git add skills/multi-agent-council/references/patterns/judge.md skills/multi-agent-council/references/patterns-index.md skills/multi-agent-council/tests/judge-pattern.sh
git commit -m "council: add optional Judge modifier (blocker E.2 redesign)"
```

---

## Task 7: Create standalone Pragmatist pilot subagent

**Files:**
- Create: `.claude/agents/pragmatist.md`
- Test: `skills/multi-agent-council/tests/pragmatist-subagent.sh` (create)

**Important design note (stress-tester E.1):** The Pragmatist standalone subagent is a **separate product** from the council. The council does **not** invoke it via `subagent_type`. The council continues to use fragment injection from `references/roles/pragmatist.md`. This avoids the hybrid-dispatch contradiction between the standalone system prompt and the council's Round 1/Round 2 contract.

- [ ] **Step 1: Write failing assertion**

Create `skills/multi-agent-council/tests/pragmatist-subagent.sh`:

```bash
#!/usr/bin/env bash
set -u
FILE=".claude/agents/pragmatist.md"
fail=0
check() {
  local label="$1" pattern="$2" expect="$3"
  if [ -f "$FILE" ] && grep -qE "$pattern" "$FILE"; then found="present"; else found="absent"; fi
  if [ "$found" != "$expect" ]; then echo "FAIL: $label"; fail=1; else echo "OK:   $label"; fi
}

check "frontmatter: name"         "^name: pragmatist" present
check "frontmatter: description"  "^description:" present
check "frontmatter: tools whitelist (read-only)" "^tools:.*Read" present
check "frontmatter: no Write tool (read-only advisor)" "^tools:.*Write" absent
check "value function sentence matches role fragment" "Optimize for least change, fastest path to ship, lowest risk\\. Actively resist over-engineering\\." present
check "standalone framing (not council deliberator)" "code reviewer|proposal auditor|solo use" present
check "explicit note: not invoked by the council" "not invoked by the council|separate product" present

exit $fail
```

- [ ] **Step 2: Run the test — confirm it fails**

```bash
bash skills/multi-agent-council/tests/pragmatist-subagent.sh
```

Expected: most checks FAIL.

- [ ] **Step 3: Create `.claude/agents/pragmatist.md`**

```markdown
---
name: pragmatist
description: >
  Use for code review, proposal audits, and design reviews where you want
  a "least change, ship fastest, lowest risk" lens applied before committing
  to an approach. Pragmatist will actively resist over-engineering, name
  simpler alternatives, and measure the scope of proposed changes.
  Trigger phrases: "pragmatist review", "least-change alternative",
  "is this worth the scope", "audit this proposal for over-engineering".
  Do NOT use for: exploratory design, greenfield architecture, problems
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

You are a read-only advisor. You do not edit code. You do not run migrations. You do not touch production. Your tools (Read, Glob, Grep, Bash) are for investigation only — reading files, searching for patterns, running analysis commands like `git log`, `wc -l`, or `rg --stats`. You never invoke `Bash` in a way that mutates state.

### Investigation checklist

When invoked on a proposal, walk through these steps in order:

1. **Map the proposed change scope.** Count the files that will be touched, the interfaces that will change, the tests that will need updating. Cite specifically: `src/auth/middleware.ts:42-89`, not "the auth layer."
2. **Search for existing solutions.** Does the codebase already solve this problem somewhere? Use Grep to find existing patterns. If there is an existing solution that could be extended, say so.
3. **Check git history and issue trackers.** Has this problem been tackled before and abandoned? What was the reason? Use `git log --all --grep=<keyword>` and check for related decisions.
4. **Find the minimum viable alternative.** Given the proposal, what is the smallest change that solves the same problem? It might be (a) one-line edit in an existing file, (b) extending an existing function, (c) a config change instead of code, (d) doing nothing if the cost exceeds the benefit.
5. **Measure the risk surface.** What could the proposal break? Which tests exercise the affected code? Are there any uncovered paths?

### Output contract

Produce a **Pragmatist Review** with these sections:

```
## Pragmatist Review: [subject]

### Minimum viable alternative
[What is the smallest change that solves this? Be specific — file paths, line counts, concrete actions. If the proposal already IS the minimum viable alternative, say so explicitly.]

### Scope of the proposed approach
[How many files? How many interfaces? How many tests? What is the blast radius? Cite specific files.]

### Evidence of existing solutions
[What already exists in the codebase that partially or fully solves this? Cite specific files.]

### Recommendation
[One of: (a) proceed as proposed, (b) proceed with this specific simplification, (c) reconsider — a simpler alternative exists, (d) do nothing — the cost exceeds the benefit. Be specific about your reasoning.]

### Tradeoffs accepted
[If your recommendation is adopted, what gets worse? Name the tradeoffs explicitly — do not hide them.]
```

## Rules you must follow

1. Do not soften your verdict to sound reasonable. If the proposal is over-engineered, say so.
2. Do not recommend "further investigation" as a way of deferring a decision. Pick a direction or explicitly state that you cannot from the information available.
3. Do not cite generic principles ("KISS", "YAGNI"). Cite specific evidence — files, line counts, existing patterns, git history.
4. Do not add scope to the proposal. Your job is to shrink it, not grow it.
5. If a simpler alternative exists but requires tradeoffs the user has explicitly accepted, note the alternative but respect the user's decision.

## Relationship to the multi-agent-council skill

The `multi-agent-council` skill at `skills/multi-agent-council/` has a Pragmatist **role** that shares this value function sentence. The role fragment at `skills/multi-agent-council/references/roles/pragmatist.md` is used by the council via fragment injection into its deliberator prompt. This standalone subagent is a **separate product** — it is not invoked by the council. The two representations are intentionally separate because:

- The council's Pragmatist has a Round 1/Round 2 output contract (position papers) that conflicts with this standalone's code-review output contract.
- The council's Pragmatist participates in cross-agent deliberation; this standalone works solo.
- The only invariant that must hold between the two is the **value function sentence** ("Optimize for least change, fastest path to ship, lowest risk. Actively resist over-engineering.") — see `tests/value-function-check.sh` which enforces byte-identity.

If you need a Pragmatist inside a council deliberation, invoke the council skill directly — do not invoke this subagent.
```

- [ ] **Step 4: Run the test — confirm all 7 checks pass**

```bash
bash skills/multi-agent-council/tests/pragmatist-subagent.sh
```

Expected: 7 OK, exit 0.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/pragmatist.md skills/multi-agent-council/tests/pragmatist-subagent.sh
git commit -m "council: add standalone Pragmatist pilot subagent (separate from council)"
```

---

## Task 8: Add value-function byte-identity test

**Files:**
- Create: `skills/multi-agent-council/tests/value-function-check.sh`

Per stress-tester B.4, the only invariant that must hold between the role fragment (`references/roles/pragmatist.md`) and the standalone subagent (`.claude/agents/pragmatist.md`) is the **value function sentence**. Everything else (tool lists, output format, framing) is intentionally different and must not be tested for equality.

- [ ] **Step 1: Write the test script**

Create `skills/multi-agent-council/tests/value-function-check.sh`:

```bash
#!/usr/bin/env bash
# Value-function byte-identity check between role fragments and standalone subagents.
# The only invariant enforced here is that the **value function sentence** is
# byte-identical between the two representations. Everything else is
# intentionally allowed to differ (output contracts, tool lists, framing).
#
# If a new role gets a standalone subagent, add its pair to the ROLES array below.

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

  if [ -z "$vf_frag" ]; then
    echo "FAIL: $name — could not extract value function from $frag"; fail=1; continue
  fi
  if [ -z "$vf_agent" ]; then
    echo "FAIL: $name — could not extract value function from $agent"; fail=1; continue
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

- [ ] **Step 2: Run the test — confirm it passes for Pragmatist**

```bash
bash skills/multi-agent-council/tests/value-function-check.sh
```

Expected: `OK: pragmatist — value function byte-identical`, exit 0.

- [ ] **Step 3: Intentionally break the identity — confirm the test catches it**

Temporarily modify the standalone subagent's value function sentence (add a trailing space, for example), re-run the test, and confirm it fails:

```bash
# Add a trailing space (non-whitespace-sensitive to eyes, but the test should catch it)
# After confirming the failure, revert the change with git checkout.
```

Expected: FAIL message showing the divergence.

Then revert the change:

```bash
git checkout .claude/agents/pragmatist.md
bash skills/multi-agent-council/tests/value-function-check.sh
```

Expected: OK, exit 0.

- [ ] **Step 4: Commit**

```bash
git add skills/multi-agent-council/tests/value-function-check.sh
git commit -m "council: add value-function byte-identity test for role/subagent pairs"
```

---

## Task 9: Document Pragmatist pilot kill criterion

**Files:**
- Create: `skills/multi-agent-council/tests/pilot-exit-criteria.md`
- Modify: `skills/multi-agent-council/SKILL.md` (add pilot status note)

Per stress-tester B.6, the Pragmatist pilot must have a **falsifiable exit test** — not a vague "see how it goes." If the test fails, the pilot is abandoned, not "adjusted." No other roles get promoted to standalone subagents until Pragmatist passes.

- [ ] **Step 1: Create the exit criteria document**

Create `skills/multi-agent-council/tests/pilot-exit-criteria.md`:

```markdown
# Pragmatist Standalone Subagent — Pilot Exit Criteria

## Status

**Pilot start date:** (fill in on landing) — the day the standalone Pragmatist at `.claude/agents/pragmatist.md` is merged.
**Pilot evaluation date:** pilot start + 14 calendar days.
**Pilot owner:** (user/repo owner makes the final decision)

## Purpose

This document defines the **falsifiable exit test** for the Pragmatist standalone subagent pilot. Per `/tmp/stress-tester-critique.md` §B.6, promoting 10 roles to standalone subagents is a commitment to 10× maintenance burden without evidence that the first one earns its keep. The pilot exists to produce that evidence — or to produce the evidence that the approach does not work, and should be abandoned.

## The exit test

At the pilot evaluation date, the pilot is judged PASS or FAIL against these criteria:

### PASS criteria (all must hold)

1. **Real usage outside the council.** The standalone Pragmatist has been invoked at least **5 times** in real tasks (not contrived test runs), outside of the `multi-agent-council` skill. Usage is counted from any source — direct `subagent_type: pragmatist` invocations, user-triggered reviews, agentic workflows that dispatch it.
2. **Valuable outputs.** Of those 5+ invocations, at least **3** produced outputs the user kept (the recommendation was acted on, merged, or preserved as reference). Outputs that were discarded, overridden, or contradicted the user's judgment do not count.
3. **No drift from council Pragmatist.** The `value-function-check.sh` test has been passing continuously. No PR has modified the value function sentence in either the fragment or the subagent.
4. **No hybrid-dispatch creep.** No code change anywhere in the repo has attempted to make the council invoke the standalone subagent via `subagent_type` — the two must remain separate products per Blocker E.1.

### FAIL criteria (any one triggers failure)

1. The standalone Pragmatist has been invoked fewer than 5 times in real usage.
2. Fewer than 3 of those invocations produced outputs the user kept (i.e., users invoked it but found its output unhelpful or wrong more often than not).
3. The value function identity test has been failing continuously, indicating drift in either direction.
4. Someone (human or agent) has tried to wire the standalone into the council dispatch path, which is a Blocker E.1 violation.
5. Maintenance burden was higher than expected — more than 2 PRs in the 14-day window were needed to keep the subagent aligned with council-side role changes.

## What happens on PASS

- Document the pass result in this file.
- Begin considering the next role for promotion. Do **not** promote multiple roles at once. Pick the next-highest-value role from researcher-agents' Tier 1 list and run another 14-day pilot with the same exit criteria.
- Roles to consider next (ordered by researcher-agents' priority + stress-tester's "most safely standalone-compatible"):
  1. Stress Tester (value: adversarial code review, useful outside deliberation)
  2. Falsifier (value: hypothesis testing, similar to Stress Tester but broader)
  3. Archaeologist (value: historical context, useful for large refactors)

## What happens on FAIL

- Revert `.claude/agents/pragmatist.md` — delete the file and remove it from the repo.
- Revert any test scripts that depended on the standalone existing (`value-function-check.sh` entries for Pragmatist).
- Document the FAIL result in this file with the specific criteria that failed.
- **Abandon the 10-role promotion plan.** Do not retry with a different role. The failure mode is structural, not role-specific — if Pragmatist (the most obviously reusable role) did not earn its keep, the abstraction is wrong.
- If there is appetite to retry later, it must start with a new research pass that addresses *why* the first pilot failed — not just "try a different role."

## Why a kill criterion

Incrementalism without a kill criterion is just slow-motion big-bang. If we promote Pragmatist without a test we are obligated to honor, and it is mediocre, we will still promote the other 9 because we have already committed to the direction. A pre-registered exit test is the only way to get honest evidence about whether the standalone abstraction is worth the maintenance burden.

See `/tmp/stress-tester-critique.md` §B.6 for the original critique.
```

- [ ] **Step 2: Add pilot status note to `SKILL.md`**

In `skills/multi-agent-council/SKILL.md`, add a new section just before the "## Reference files" section near the end:

```markdown
## Pilot status

As of (fill in on landing), the Pragmatist role is being piloted as a **standalone reusable subagent** at `.claude/agents/pragmatist.md`. The standalone is a **separate product** from the council — the council continues to use fragment injection from `references/roles/pragmatist.md` and does not invoke the standalone subagent.

The pilot has a 14-day exit test documented in `tests/pilot-exit-criteria.md`. **No other roles will be promoted to standalone subagents until the Pragmatist pilot passes its exit test.** See that file for PASS/FAIL criteria.

```

- [ ] **Step 3: Commit**

```bash
git add skills/multi-agent-council/tests/pilot-exit-criteria.md skills/multi-agent-council/SKILL.md
git commit -m "council: document Pragmatist pilot kill criterion (14-day exit test)"
```

---

## Task 10: Document explicit rejections in `custom-role-template.md`

**Files:**
- Modify: `skills/multi-agent-council/references/custom-role-template.md`

Researcher-agents proposed splitting `custom-role-template.md` into two paths (fragment-only vs. standalone subagent) with a "coherence check" gating which path applies. Stress-tester rejected this because it formalizes the hybrid-dispatch broken middle path. The skill should document that the split was considered and explicitly rejected.

- [ ] **Step 1: Add the rejection note**

At the top of `skills/multi-agent-council/references/custom-role-template.md`, add a section immediately after the title/first paragraph:

```markdown
## Design note — why this guide is not split into two paths

An earlier research pass (see `/tmp/researcher-agents-report.md` §4) proposed splitting this authoring guide into two paths:
- **Path 1** — fragment-only custom role (the current path)
- **Path 2** — full standalone reusable subagent with its own `.claude/agents/*.md` file

The split was **rejected** after adversarial review (see `/tmp/stress-tester-critique.md` §B.2, §B.5, and §E.1). The core reason: making the council's dispatch path branch on "does a standalone subagent file exist for this role" creates a hybrid dispatch architecture where some roles follow a standalone system prompt and others follow a fragment-injected prompt, with silent inconsistencies in output contracts across roles. This is architecturally incoherent and will produce bugs that look like "the council just gave a weird answer."

Instead, the council uses **fragment injection only**. Standalone subagents (see the Pragmatist pilot at `.claude/agents/pragmatist.md`) are a **separate product** that users can invoke outside the council for solo use. The two representations share only the value function sentence (enforced by `tests/value-function-check.sh`) and are intentionally different in every other dimension.

This guide therefore covers **only fragment-authoring** — the path that works inside the council. If you want to publish a role as a reusable standalone subagent as well, that is a separate authoring task (see `.claude/agents/pragmatist.md` as a reference) and is gated on the Pragmatist pilot exit test in `tests/pilot-exit-criteria.md`.

```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-agent-council/references/custom-role-template.md
git commit -m "council: document why custom-role-template stays fragment-only (E.1)"
```

---

## Task 11: Add reference test suite (subset of stress-tester's 10 tests)

**Files:**
- Create: `skills/multi-agent-council/tests/reference-suite.md`

The stress-tester specified 10 tests the implementation must pass. Implementing all 10 as executable tests is out of scope for this plan (some require running actual councils, which is expensive and non-deterministic). This task documents the full suite and operationalizes the 5 that can be statically checked.

- [ ] **Step 1: Create the reference suite document**

Create `skills/multi-agent-council/tests/reference-suite.md`:

```markdown
# Council Reference Test Suite

This suite operationalizes the 10 tests from `/tmp/stress-tester-critique.md` Appendix. Some tests are implemented as static checks (grep-based) that run in CI; others are manual reference runs that require spawning an actual council and are documented here for humans to execute when validating a significant skill change.

## Static checks (automated)

These run on every skill change and gate merges.

### Test 1 — Hybrid dispatch prohibition check
**Source:** stress-tester §B.5, §E.1 and test #6 in the appendix.
**Implementation:** `tests/hybrid-dispatch-check.sh` (not yet created — add in a follow-up if needed)
**Purpose:** Fail if any code path in the council skill reads `.claude/agents/` to decide how to dispatch a role. This prevents reintroduction of the rejected hybrid-dispatch architecture.
**Pass condition:** no references to `.claude/agents/` in `SKILL.md`, `team-lead-prompt.md`, `deliberator-prompt.md`, or any pattern file.

### Test 2 — Prompt hardening checks (currently implemented)
**Source:** all tasks 1-6 of this plan.
**Implementation:** `tests/team-lead-prompt.sh`, `tests/deliberator-prompt.sh`, `tests/pre-mortem.sh`, `tests/cost-model.sh`, `tests/skill-gate.sh`, `tests/judge-pattern.sh`.
**Purpose:** Verify that the prompt hardening edits from this plan are present and have not been accidentally reverted.
**Pass condition:** each script exits 0.

### Test 3 — Value function byte-identity
**Source:** stress-tester §B.4.
**Implementation:** `tests/value-function-check.sh`.
**Purpose:** Enforce that the value function sentence is byte-identical between a role fragment and its corresponding standalone subagent.
**Pass condition:** script exits 0 for all role/subagent pairs in the array.

### Test 4 — Pragmatist subagent loads
**Source:** Task 7.
**Implementation:** `tests/pragmatist-subagent.sh`.
**Purpose:** Verify the standalone subagent has valid frontmatter, no Write tool, and the expected framing.
**Pass condition:** script exits 0.

## Manual reference runs (documented, executed on significant changes)

These are expensive and non-deterministic. Document the expected qualitative outcomes. Run them when a change is suspected to affect any of the behaviors they catch.

### Manual Test A — SPOF test (stress-tester appendix #1)
**Procedure:** Spawn a council, let it reach Round 2, then manually kill the team lead process. Verify:
- Deliberators do not hang forever (shutdown deadline enforces this — see Task 1.b).
- User gets a legible error, not silent hang.
- No zombie team members remain.

### Manual Test B — Judge thrash test (stress-tester appendix #2)
**Procedure:** Prepare two synthetic Proposal Documents — one with intentional "buried dissent" (a strong minority position footnoted away), one without. Run each through the Judge (Task 6) 5 times.
**Expected:** the buried-dissent document should consistently fail the "dissent preservation" rubric item. The clean document should consistently pass all 4 rubric items.
**Failure signal:** if the Judge produces inconsistent verdicts across the 5 runs, the rubric is still too subjective — revisit Task 6's falsifiable rubric design.

### Manual Test C — Context overflow test (stress-tester appendix #3)
**Procedure:** Run a Very Complex tier council on a problem that requires reading a ~100k-token codebase.
**Expected:** no agent's context overflows. The team lead's synthesis fits within its budget. The digest-only Round 2 injection (Task 1.a) keeps N² growth bounded.
**Failure signal:** any OutOfContext error from any agent. If this happens, revisit the peer-context 2,000-token cap in Task 1.a.

### Manual Test D — Adversarial input test (stress-tester appendix #4)
**Procedure:** Run a council on a problem statement containing contradictory requirements (e.g., "build an API that is both eventually consistent and strongly consistent").
**Expected:** the proposal names the contradiction explicitly in the "tradeoffs" section. It does not paper over the contradiction. The Judge (if enabled) flags any synthesis that papers over it.
**Failure signal:** the council produces a proposal that does not name the contradiction.

### Manual Test E — Silent drop test (stress-tester appendix #5)
**Procedure:** Spawn a council with 4 deliberators. Inject a failure into one deliberator mid-Round-1 (kill the process, or make it return an error).
**Expected:** the Dispatch Accounting rule (Task 1.c) catches the drop. The team lead retries once. If the retry fails, the Proposal Document surfaces the missing deliberator under "Known gaps."
**Failure signal:** the proposal is silently synthesized without mentioning the missing deliberator.

### Manual Test F — Budget test (stress-tester appendix #7)
**Procedure:** Run a council with a very low per-deliberator token budget (e.g., 5k).
**Expected:** deliberators acknowledge the budget limit in their position papers ("budget exceeded, provisional position") rather than blowing through the budget.
**Failure signal:** a deliberator runs significantly over the budget. If this happens, the budget instruction in `deliberator-prompt.md` is not being followed — the per-agent self-tracking needs structural enforcement (future work).

### Manual Test G — Reproducibility test (stress-tester appendix #8)
**Procedure:** Run the same council twice on the same problem with the same seed.
**Expected:** outputs are meaningfully similar — same top recommendation, overlapping tradeoff names, consistent dissent preservation.
**Failure signal:** wildly different outputs between runs. If this happens, the skill is under-determined and the user has no way to debug divergent results. Consider adding a "deliberation trace" output field per stress-tester action item #16.

### Manual Test H — Cost regression test (stress-tester appendix #9)
**Procedure:** Run a designated reference problem (to be defined — see below) through a Moderate-tier council. Measure the total token count.
**Expected:** total token count within ±20% of the expected value (expected value to be captured on first run and stored in `tests/cost-regression-baseline.md`).
**Failure signal:** >20% deviation. This must be explicitly acknowledged in any PR that triggers it — silent cost growth is a bug.

### Manual Test I — Stall detection determinism (stress-tester appendix #10)
**Procedure:** Not yet applicable — stall detection is deferred per this plan's scope decisions. Document when stall detection lands.

### Manual Test J — Reference problem definition
**Purpose:** Define the canonical reference problem used by Tests C, D, E, F, G, H.
**Content:** A problem statement, expected tier, expected tool budget, and a short description of the expected output shape. This should be filled in by the first reviewer who runs a Manual Test.

## Test status

At the time of this plan landing, the static checks (Tests 1-4) are implemented. Manual tests are documented but have not been executed. Before any follow-up promotion of additional roles to standalone subagents, at least Manual Tests A, B, and E should have been executed at least once and their results recorded in this document.
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-agent-council/tests/reference-suite.md
git commit -m "council: document reference test suite (10 stress-tester tests)"
```

---

## Post-plan verification

After all 11 tasks are complete, run the full static-check suite to confirm nothing regressed:

```bash
cd /Users/tomasdussaillant/repos/skills
bash skills/multi-agent-council/tests/team-lead-prompt.sh
bash skills/multi-agent-council/tests/deliberator-prompt.sh
bash skills/multi-agent-council/tests/pre-mortem.sh
bash skills/multi-agent-council/tests/cost-model.sh
bash skills/multi-agent-council/tests/skill-gate.sh
bash skills/multi-agent-council/tests/judge-pattern.sh
bash skills/multi-agent-council/tests/pragmatist-subagent.sh
bash skills/multi-agent-council/tests/value-function-check.sh
```

All eight scripts must exit 0.

Additionally, re-read the changed files with fresh eyes and confirm:
- `SKILL.md` — the structural gate is genuinely blocking, not a soft warning with different words
- `team-lead-prompt.md` — the digest-only Round 2 directive is unambiguous, and the shutdown deadline is explicit
- `deliberator-prompt.md` — the divergence check requires naming a specific claim, not just "new evidence"
- `patterns/pre-mortem.md` — the red-team agent is explicitly denied the core council's reasoning
- `patterns/judge.md` — the judge is optional, falsifiable, and non-blocking
- `.claude/agents/pragmatist.md` — frames itself as a standalone product with no coupling to the council

## What this plan does NOT address (explicit deferrals)

These items from `/tmp/stress-tester-critique.md` are deferred to a follow-up plan:

- **A.1 Team lead SPOF recovery** — checkpointing the Round 1 Digest + Round 2 Summary + partial synthesis to a file for recovery. Requires designing a serialization format and a rehydration path.
- **A.5 Structural value-function enforcement** — an LLM-based check that the agent's Round 2 position is not framed-dependent. Requires a small evaluator subagent and a prompt-agnosticism test.
- **Ledger infrastructure** — deferred until after Pragmatist pilot validates the canonical-source approach.
- **Stall detection** — requires ledger.
- **Hypothesis Council pattern** — rejected in favor of cross-linking `agent-teams:parallel-debugging`.
- **Dynamic composition (A-HMAD)** — deferred as P2.
- **Cross-Examination modifier** — deferred as P2.
- **Opus-lead / Sonnet-deliberators model split** — deferred until model routing support is confirmed.

## Execution

Plan complete and saved to `docs/superpowers/plans/2026-04-09-council-improvements.md`. Ready to execute?

**If harness has subagents:** Use `superpowers:subagent-driven-development` — fresh subagent per task + two-stage review.
**If harness does NOT have subagents:** Execute in current session using `superpowers:executing-plans` — batch execution with checkpoints.

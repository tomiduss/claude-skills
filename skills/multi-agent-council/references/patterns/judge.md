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
- The team lead's synthesis (**this is the critical isolation**; the Judge must never receives the synthesis it is auditing)

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

If the Judge crashes, times out, exceeds its budget, or otherwise cannot produce a synthesis, delivery is non-blocking — the Judge cannot hold up shipping:

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

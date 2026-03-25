# Minority Report

**Type:** Modifier (layers on top of a core pattern)
**Best for:** Preserving dissent after a high-stakes convergence so future teams understand why reasonable people disagreed

## What It Is

A dedicated dissent agent writes the strongest possible case against the final proposal. The goal is not to reverse the decision — it is to produce a document that will be attached to the decision record. If the decision turns out to be wrong in six months, the minority report should make it obvious that the concerns were raised and understood at the time.

## When to Add

- After any high-stakes convergence where a minority position was overruled
- When the council reached consensus but one agent's concerns were set aside rather than resolved
- For irreversible or expensive-to-reverse decisions (public API commitments, data model changes, vendor lock-in)
- When the team wants a formal record of what was traded away

## Structure

### Step 1 — Spawn Dissent Agent

The team lead spawns a single dissent agent via TeamCreate. This agent receives:

- The converged proposal
- The full council reasoning from the core deliberation
- The minority position or unresolved disagreements from the core rounds
- The tradeoffs that were explicitly accepted

The dissent agent's mandate: write the strongest possible case against the decision. Steelman the opposition. No strawmen.

### Step 2 — Dissent Analysis

The dissent agent produces a minority report containing:

1. **Strongest argument against** — the single most compelling reason this decision is wrong. Must be steelmanned: present it as a reasonable person would, not as a caricature. If the argument is strong enough, a reader should feel genuinely uncertain about the decision after reading it.
2. **Failure conditions** — the specific, observable conditions under which this decision will turn out to be wrong. Not vague ("if requirements change") but concrete ("if monthly active users exceed 50k before the caching layer is in place").
3. **Early warning signals** — what to monitor at 30, 60, and 90 days. Specific metrics, behaviors, or events that would indicate the decision is failing. Each signal should have a threshold: "if X exceeds Y, revisit this decision."
4. **The alternative and its cost** — what the dissenting position would have recommended instead, and what that alternative would have cost. Be honest about both sides: the alternative has costs too.

### Step 3 — Team Lead Integration

The team lead does not edit or weaken the dissent. Instead, the team lead:

1. Attaches the minority report to the proposal document as-is
2. Adds a response section: which points the majority acknowledges, which it disagrees with and why
3. Incorporates the early warning signals into the monitoring plan
4. Sets a calendar trigger: revisit the decision if any early warning signal fires

### User Checkpoint

Present the minority report to the user. The user decides:

- Accept and attach to the decision record (default)
- Act on a point from the dissent that changes the proposal
- Dismiss a specific point with documented reasoning

## Output

The modifier adds the following sections to the proposal document:

1. **Minority report** — the full dissent analysis, unedited
2. **Majority response** — acknowledgments and rebuttals
3. **Monitoring triggers** — early warning signals with thresholds and revisit dates

## Notes

- The dissent agent should not have been part of the core deliberation. Fresh eyes produce stronger dissent.
- A good minority report feels uncomfortable to read. If it does not, the dissent agent was not trying hard enough or the decision is genuinely robust.
- The minority report's value is realized only if it is preserved. It must be attached to the decision record, not summarized or paraphrased away.
- This modifier pairs well with the Pre-mortem. The pre-mortem finds failure modes; the minority report argues against the fundamental direction. They surface different kinds of risk.

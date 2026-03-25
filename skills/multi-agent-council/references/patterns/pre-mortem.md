# Pre-mortem

**Type:** Modifier (layers on top of a core pattern)
**Best for:** Stress-testing a proposal after initial convergence, before finalizing

## What It Is

A red-team pass that runs after a core pattern has produced a converged proposal. A dedicated red-team agent assumes the proposal was implemented and failed, then works backwards to identify the failure modes that were visible at decision time but ignored. The team lead then patches the proposal to close the top risks.

## When to Add

- After the council converges on a direction and the proposal looks solid — that is precisely when blind spots are most dangerous
- Before finalizing any high-stakes decision (infrastructure changes, data model redesigns, public API commitments)
- When the convergence was suspiciously fast or unanimous — fast agreement often means shared blind spots

## Structure

### Step 1 — Spawn Red-Team Agent

The team lead spawns a single red-team agent via TeamCreate. This agent receives:

- The converged proposal from the core deliberation
- The reasoning and tradeoffs documented by the core pattern
- Any dissent or unresolved disagreements from the core rounds

The red-team agent's mandate: the proposal was implemented and it failed badly. Do not question whether it failed — it did. Work backwards from failure.

### Step 2 — Red-Team Analysis

The red-team agent produces a post-mortem from six months in the future containing:

1. **Three most likely failure modes** — specific and mechanistic, not generic. "Poor adoption" is not acceptable; "engineers bypass the new validation layer because it adds 200ms to the feedback loop and there's no enforcement mechanism" is.
2. **False assumptions** — assumptions baked into the proposal that turned out to be wrong. What did the team believe that the future proved false?
3. **Warning signs visible now** — signals that were available at decision time but were ignored or downweighted. What should the team have been watching?
4. **What a different team would have done** — an alternative approach that avoids the identified failure modes. Not necessarily better overall, but specifically better at avoiding these failures.

### Step 3 — Patch Synthesis

The team lead reviews the red-team analysis and produces a **patch synthesis**: the minimum changes to the original proposal that close the top two failure modes. Rules:

- Do not start over. Patch, do not rebuild.
- Each patch must directly address a specific failure mode from the red-team analysis.
- If a failure mode cannot be mitigated without fundamentally changing the approach, flag it explicitly and let the user decide whether to accept the risk or change direction.
- Add monitoring or trigger conditions for any failure mode that the patch reduces but does not eliminate.

### User Checkpoint

Present the red-team analysis and patch synthesis to the user. The user decides:

- Accept the patches and finalize the proposal
- Reject a patch and accept the risk (with documented reasoning)
- Reopen the core deliberation if the red-team analysis reveals a fundamental problem

## Output

The modifier adds two sections to the proposal document:

1. **Red-team analysis** — the full post-mortem output
2. **Patches applied** — the changes made to the original proposal in response, with traceability to the specific failure modes they address

## Notes

- The red-team agent should not have participated in the core deliberation. A fresh perspective is the point.
- The most valuable pre-mortems find failure modes that arise from the interaction of individually reasonable decisions — things that only break when combined.
- If the red-team analysis is weak (generic risks, no mechanisms), the proposal may genuinely be robust — or the red-team agent may need more context. Give it access to the codebase if it did not have it.

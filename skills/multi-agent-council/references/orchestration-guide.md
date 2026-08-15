# Council Orchestration Guide (Path B — multi-round)

You are the **council lead** — the session running the multi-agent-council skill. You orchestrate the council directly; you are not a separate agent and you cannot delegate the lead role (in Claude Code's agent-teams model the lead is fixed to the session that created the team). You collect positions, surface tension, run the user checkpoints, and synthesize. You orchestrate, you do not advocate — you have no value function and no position on the problem.

This guide is the round-by-round protocol for a **multi-round (Path B) council**, where deliberators are spawned as teammates. A single-round (Path A) council does not need this guide — it has one research round and goes straight to synthesis (see `SKILL.md` Steps 3-6).

You already have the goal, context, council composition, and deliberation pattern from Steps 1-2. If the selected pattern specifies a different round structure (context isolation for Asymmetric Info, time horizons for Temporal), follow the pattern — it overrides the defaults below.

## Round 1 — Collect and digest

1. Wait for every deliberator teammate to deliver its Round 1 position paper. Teammates deliver by `SendMessage` — a teammate's plain output is not visible to you. A teammate going idle after sending is expected, not a failure.
2. Collect every position paper in full.
3. Create a **Round 1 Digest** containing:
   - Each agent's position summarized in 2-3 sentences
   - Key evidence each agent uncovered (preserve citations)
   - **Points of tension** — where agents directly contradict each other, with the specific claims in conflict
4. Present the digest to the user.
5. **Pause for user checkpoint** — wait for user input before proceeding. The user may inject context or constraints, ask agents to investigate specific areas, redirect the deliberation, or approve proceeding to Round 2.

## Dispatch accounting (runs every round)

Before each round, record the expected respondents in a private list — every deliberator plus any modifier subagent you have dispatched. After the round:

- If a teammate has not responded after a grace period (60 seconds from the last respondent, or 3 minutes from dispatch, whichever comes first), `SendMessage` it once more: "Your Round N response was not received. Please send it now, or reply with one sentence on why you cannot."
- If that retry also fails, escalate to the user by name: "Agent `<name>` is not responding. Expected: `<deliverable>`. Proceed without it, or retry?"
- At synthesis, any agent that never produced a required response appears in the Proposal Document under a **Known gaps** section — named, with its expected contribution noted. A missing Contrarian, Falsifier, or Judge is a quality failure, not a speed optimization.

## Round 2 — Cross-pollinate and collect

6. After the checkpoint, `SendMessage` Round 2 directives to each deliberator teammate:
   - Include the **Round 1 Digest** you produced in step 3, **not the raw position papers**. The digest is bounded (2-3 sentences per agent + tension points); raw papers grow N² across rounds and overflow agent context by Round 3 of any deliberation with 4+ agents.
   - Hard cap: the peer-context block sent to any single deliberator must fit within a **2,000-token budget**. If the digest exceeds this, compress further — drop non-load-bearing citations, keep the tension points.
   - Include any user-injected context or redirections from the checkpoint.
7. Collect all Round 2 responses (delivered by `SendMessage`).
8. Create a **Round 2 Summary** containing:
   - Where positions converged, and what evidence drove convergence
   - Where positions remain in tension, and why neither side yielded
   - Any positions that shifted, and what caused the shift
9. Present the Round 2 Summary to the user.
10. **Pause for final user checkpoint** — the user may request additional rounds or approve synthesis.

## Synthesis

11. After the final checkpoint, produce the **Proposal Document** using the format in `references/proposal-document.md`.
12. The proposal must:
    - Faithfully represent what the council found — do not editorialize
    - Preserve dissenting perspectives that survived deliberation
    - Make tradeoffs explicit, not hidden
    - Include concrete implementation scope if the problem warrants it

## Shutdown

13. After delivering the proposal, `SendMessage` a `shutdown_request` to each deliberator teammate. (Modifier agents — Red-Team, Judge — are one-shot subagents, not teammates; they already terminated when they returned their artifact, so there is nothing to shut down.)
14. Wait for acknowledgment with a **hard deadline of 30 seconds** from dispatch. After the deadline, any teammate that has not acknowledged is presumed dead.
15. Call `TeamDelete` to remove the team — but it **fails while any teammate is still active**. Confirm every teammate has shut down (or is presumed dead and no longer running) before calling it. If `TeamDelete` reports remaining members, re-send shutdown to them and retry. Log any anomaly under a "Shutdown anomalies" section in the Proposal Document — never force the user to manually clean up a zombie team.
16. Report completion to the user.

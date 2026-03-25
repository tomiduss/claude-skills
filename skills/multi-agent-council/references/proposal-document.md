# Proposal Document Format

This is the final artifact of a council deliberation. The team lead produces this after all rounds and user checkpoints are complete.

---

```markdown
# Proposal: [one-sentence summary of the recommended direction]

## Problem / Goal
[What we explored and why — 2-3 sentences establishing context and stakes]

## Exploration

### [Role 1 Name] — [position summary in ~5 words]
- [Key finding with citation]
- [Key finding with citation]
- [Proposed approach]
- [Primary tradeoff accepted]

### [Role 2 Name] — [position summary in ~5 words]
- [...]

<!-- One subsection per deliberator. Preserve their evidence and citations. -->

## Recommended approach
[Synthesized recommendation — the direction that best balances the competing
perspectives. 1-2 paragraphs. This is the team lead's synthesis, not any
single agent's position. Explain why this balance was chosen.]

## Tradeoffs documented
[What we are accepting and what we are giving up. Be explicit about costs.
Each tradeoff should name which value function it works against and why
the council accepted the cost anyway.]

## Dissenting perspectives preserved
[Minority positions that survived deliberation — agents who held ground
through Round 2 with evidence. These are valuable context for future
revisits. Include the key evidence that sustained each dissent.]

## Implementation scope
[If applicable — what needs to be built, rough shape of the work, key
components and boundaries. This section feeds directly into
writing-plans-for-teams as the input for plan generation.]

## Review triggers
[Specific, measurable conditions that should cause revisiting this proposal.
Each trigger must be falsifiable — someone should be able to check whether
it has fired.]

<!-- Examples of good triggers:
- "If p95 latency exceeds 200ms for 3 consecutive days"
- "If the team grows past 5 engineers before Phase 2 is complete"
- "If monthly storage costs exceed $X"

Examples of bad triggers:
- "If things change significantly"
- "If performance becomes a problem"
- "If the team feels it's not working" -->
```

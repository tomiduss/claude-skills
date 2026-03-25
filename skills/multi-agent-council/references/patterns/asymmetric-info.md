# Asymmetric Info

**Type:** Core pattern
**Best for:** Problems where different stakeholders hold different context and no single person has the full picture

## What It Is

Each agent holds a different slice of context and is restricted from accessing the others' information. Unlike the Council pattern where agents share context but differ in value functions, here agents share value functions but differ in information. The deliberation forces collaboration: no agent can solve the problem alone because each is missing critical pieces.

## When to Use

- Cross-functional decisions where engineering, product, and ops each hold context the others lack
- Problems where the right answer depends on combining information that currently lives in silos
- Situations where past proposals failed because they optimized for one slice while ignoring another

## Typical Context Slices

The three default slices. Adapt based on the actual problem.

**Agent A — Codebase only:** Sees the current code, architecture, and technical constraints. Has no information about business requirements or infrastructure limitations.

**Agent B — Requirements only:** Sees product goals, user stories, success metrics, and business constraints. Has no visibility into the codebase or deployment environment.

**Agent C — Ops/Infra only:** Sees deployment architecture, SLAs, monitoring, operational capacity, and infrastructure constraints. Has no visibility into the codebase or product requirements.

## Round Structure

### Round 1 — Isolated Proposals (parallel)

Each agent receives only its assigned context slice plus the shared goal. Agents work in parallel. Each agent:

1. Proposes an approach based exclusively on what it knows
2. Explicitly states what it is assuming about the context it cannot see
3. Lists the questions it would need answered to have full confidence in its proposal

**Team lead responsibilities:**
- Spawn agents via TeamCreate with strict context boundaries — each agent receives only its designated slice
- Enforce isolation: do not leak context between agents during Round 1
- Collect all Round 1 outputs
- Create a digest highlighting where proposals conflict and where assumptions diverge

### User Checkpoint 1

Present the Round 1 digest to the user. Highlight:

- Where agents made conflicting assumptions about context they could not see
- Where proposals are incompatible because of missing information
- Gaps that none of the agents can fill (the user may need to provide additional context)

The user can reveal additional context, correct false assumptions, or add a fourth context slice if needed.

### Round 2 — Information Sharing (parallel)

Context boundaries are lifted. Each agent receives all other agents' Round 1 positions and context via SendMessage. Each agent must:

1. Identify which of its Round 1 assumptions were wrong
2. Identify what it now knows that changes its recommendation
3. Respond to gaps in other agents' understanding — correct their assumptions about its domain
4. Produce a revised proposal that accounts for the full picture

**Team lead responsibilities:**
- Distribute all Round 1 positions and the originally-siloed context to all agents
- Include any additional context from the user checkpoint
- Collect all Round 2 outputs

### User Checkpoint 2

Present Round 2 results. By this point, agents should have a shared understanding. The user confirms whether the combined picture is accurate before synthesis.

## Synthesis

The team lead produces a proposal document containing:

1. **Full picture map** — the combined understanding from all context slices, including where slices conflicted and how conflicts were resolved
2. **Recommendation** — a proposal that accounts for all three slices
3. **Information gaps closed** — which Round 1 assumptions turned out to be wrong and how the recommendation changed as a result
4. **Remaining blind spots** — context that no agent held and that the user did not provide
5. **Cross-slice dependencies** — decisions that require ongoing coordination between the domains (e.g., "if the API contract changes, ops must update the load balancer config")

## Notes

- The power of this pattern is in Round 1's isolation. Resist the urge to give agents more context than their slice — the value comes from seeing what they assume when they do not know.
- This pattern works especially well when the user suspects that a previous decision failed because one perspective dominated.

# Council

**Type:** Core pattern
**Best for:** General multi-perspective exploration — the default when no specialized pattern fits

## What It Is

The foundational deliberation pattern. All agents share the same goal and the same context, but each holds a different value function that constrains how it reasons. The value comes from structural disagreement: agents cannot converge prematurely because their value functions make certain conclusions impossible.

## When to Use

- Default choice for any problem that benefits from multiple perspectives
- Architecture decisions, design tradeoffs, strategic direction
- Any time the team needs to surface tradeoffs that a single perspective would gloss over

## Round Structure

### Round 1 — Independent Research (parallel)

Each agent receives the goal, the relevant context, and its assigned role (value function + research directives from the role reference). Agents work in parallel. Each agent:

1. Investigates the problem through its specific lens
2. Reads relevant code, docs, or context as directed by its research directives
3. Produces a position: a concrete recommendation with reasoning grounded in its value function

All Round 1 work is parallel. Agents do not see each other's output during this round.

**Team lead responsibilities:**
- Spawn all agents via TeamCreate with their role assignments and the shared goal/context
- Send each agent its research directive via SendMessage
- Collect all Round 1 outputs
- Create a digest summarizing each agent's position for the user

### User Checkpoint 1

Present the Round 1 digest to the user. This is the point where the user can:

- Inject tacit knowledge that agents lack ("We tried X last year and it failed because...")
- Redirect exploration ("Agent B is on the wrong track — we can't change the database schema")
- Add constraints that were not in the original context
- Ask a specific agent to dig deeper on a point

Wait for user input before proceeding to Round 2.

### Round 2 — Cross-Examination (parallel)

Each agent receives all other agents' Round 1 positions via SendMessage. Each agent must:

1. Identify the strongest point from each other agent
2. Respond to counterarguments against its own position
3. Revise, hold, or strengthen its recommendation — with explicit reasoning for the choice
4. Flag any new information or argument that changed its thinking

Agents work in parallel but with full visibility into each other's positions.

**Team lead responsibilities:**
- Distribute all Round 1 positions to every agent
- Include any user-injected context from Checkpoint 1
- Collect all Round 2 outputs

### User Checkpoint 2 — Bifurcation Point

Present Round 2 results to the user. At this point the deliberation has usually revealed one of three states:

1. **Convergence** — agents largely agree. Proceed to synthesis.
2. **Productive disagreement** — agents disagree on specific tradeoffs. The user picks a direction.
3. **Fundamental divergence** — agents are solving different problems. The user reframes or narrows the goal.

Wait for user input before synthesizing.

## Synthesis

The team lead produces a proposal document containing:

1. **Recommendation** — the chosen direction in one sentence
2. **Agent contributions** — what each agent contributed to the final decision
3. **Tradeoffs accepted** — what the recommendation gives up, stated explicitly
4. **Unresolved disagreements** — any points where agents did not converge, and why they do not block the decision
5. **Next steps** — concrete actions to implement the recommendation

## Notes

- The quality of a Council deliberation depends on role selection. See the roles index for composition heuristics.
- If Round 2 produces strong convergence on a high-stakes decision, consider adding the Pre-mortem or Minority Report modifier before finalizing.

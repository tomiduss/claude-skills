# Temporal

**Type:** Core pattern
**Best for:** Decisions with tech debt implications, long-term sustainability concerns, or tension between shipping now and building right

## What It Is

Three agents evaluate the same problem from different time horizons. Each agent optimizes exclusively for its horizon and is not allowed to compromise with the others. The deliberation makes tech debt tradeoffs explicit by showing exactly what each timeline gains and what it sacrifices.

## When to Use

- Build-vs-buy decisions
- "Quick fix now vs. proper solution later" tensions
- Architecture decisions that create or resolve tech debt
- Any decision where the team says "we'll fix it later" — this pattern makes "later" concrete

## Agents

**Agent NOW:** Optimize for this sprint. What ships fastest with the least risk? Ignore long-term consequences. Treat the current codebase, team capacity, and constraints as fixed.

**Agent Q+1:** Optimize for next quarter. What sets the team up best for the next three months? Allowed to accept short-term cost for medium-term payoff. Thinks about the next 2-3 features the team will build.

**Agent FUTURE:** Optimize for two years out. Ignore current constraints entirely — team size, deadlines, existing code. Think about sustainability, maintainability, and what the system needs to look like at 10x scale.

## Round Structure

### Round 1 — Horizon Proposals (parallel)

Each agent receives the goal, context, and its assigned time horizon. Agents work in parallel. Each agent:

1. Proposes an approach optimized exclusively for its horizon
2. States what it is deliberately ignoring (the other horizons' concerns)
3. Describes the expected state of the system at its target time

**Team lead responsibilities:**
- Spawn agents via TeamCreate, each assigned a single time horizon
- Enforce horizon discipline: agents must not hedge or try to balance timelines
- Collect all Round 1 outputs
- Create a digest contrasting the three proposals

### User Checkpoint 1

Present the three proposals side by side. Ask the user:

- Which time horizon matters most for this decision?
- Are there hard constraints that make one horizon non-negotiable? (e.g., "we must ship by Friday" locks in NOW; "we're hiring 5 engineers next quarter" changes Q+1)
- Is there a hybrid the user already has in mind?

### Round 2 — Cross-Horizon Critique (parallel)

Each agent receives all other agents' Round 1 positions via SendMessage. Each agent must:

1. Critique the other horizons' proposals from its own perspective
2. Specifically name what the other proposals sacrifice on its timeline
3. Identify any point of genuine compatibility — where its horizon's needs can be met without undermining the others
4. Produce a "cost statement": if the team chooses a different horizon, what exactly does that cost from this agent's perspective?

**Team lead responsibilities:**
- Distribute all Round 1 positions to every agent
- Include the user's horizon priority from Checkpoint 1
- Collect all Round 2 outputs

### User Checkpoint 2

Present the cross-horizon critique and confirm direction before synthesis.

## Synthesis

The team lead produces a proposal document containing:

1. **Tradeoff matrix** — a table showing what each horizon gains and sacrifices under the recommended approach
2. **Recommendation** — the chosen path with explicit horizon weighting (e.g., "optimize for Q+1 with NOW constraints respected")
3. **Debt receipt** — if the recommendation favors a shorter horizon, document the debt being taken on:
   - Estimated effort to undo or redo this decision in 18 months
   - Which future features become harder or impossible
   - The earliest point at which this will become a problem
   - Specific trigger conditions for revisiting the decision
4. **Migration path** — if applicable, how the NOW solution evolves toward the FUTURE solution over time

## Notes

- The debt receipt is the most valuable output. Attach it to the decision record so future teams understand what was traded and why.
- If the user picks NOW and the debt receipt is large, consider running the Pre-mortem modifier to stress-test the short-term choice.

# Six Hats

**Type:** Modifier (layers on top of a core pattern)
**Best for:** Sequential, thorough exploration of a single problem from every cognitive angle

## What It Is

Six cognitive modes applied in a fixed sequence, based on Edward de Bono's Six Thinking Hats framework. Each mode enforces a strict constraint on how agents reason — the Black Hat cannot express optimism, the Yellow Hat cannot raise risks. The value is in exhaustive coverage: the sequence guarantees that facts, intuition, risks, benefits, alternatives, and synthesis all receive dedicated attention rather than being mixed together.

## When to Add

- When a problem needs exhaustive exploration rather than adversarial debate
- When the team tends to jump to solutions without fully mapping the problem space
- When emotional or intuitive reactions are being suppressed in favor of "rational" analysis
- For complex problems where mixing analytical modes leads to confusion or premature convergence

## The Six Hats

Applied in this fixed sequence:

1. **White Hat — Facts only.** What do we know for certain? What data exists? What is missing? No interpretation, no opinion, no extrapolation. Just verifiable facts.

2. **Red Hat — Gut reaction.** What feels right or wrong about this? No justification required or permitted. Pure intuition. This is the only mode where "I don't like it" is a complete answer.

3. **Black Hat — Risks and critique.** What could go wrong? What are the weaknesses? Pure devil's advocate. Must be specific — generic risks like "poor adoption" are not acceptable. Name the mechanism of failure.

4. **Yellow Hat — Benefits and optimism.** What is the best case? What value does each option create? What opportunities does this open? Cannot raise risks — that was Black Hat's job.

5. **Green Hat — Creative alternatives.** What alternatives have not been considered? Lateral thinking only. No evaluation of alternatives is permitted — only generation. Quantity over quality.

6. **Blue Hat — Synthesis.** Meta-cognitive. Stands above the other hats and synthesizes their outputs. Notes where hats conflicted and how the conflicts resolve. Produces the final assessment.

## Structure

### Execution Options

The team lead can run Six Hats in two ways depending on the situation:

**Option A — Single agent, sequential modes.** One agent cycles through all six hats in order. Best when the problem is well-scoped and does not require deep research at each stage. Faster, but each hat gets less depth.

**Option B — Team rotation.** The team lead applies each hat to all agents in the council sequentially. All agents wear the White Hat together, then all wear Red, and so on. Best when the problem is complex and benefits from multiple perspectives within each mode. Richer, but takes longer.

In both cases, the sequence is fixed. Do not reorder the hats.

### Round-by-Round

For each hat in sequence:

1. The team lead announces the current hat and its constraints via SendMessage
2. Agents produce output strictly within that hat's constraints — breaking character is not permitted
3. The team lead collects the hat's output before moving to the next hat

### User Checkpoints

The team lead pauses after every two hats (after Red, after Yellow) to share progress with the user. The user can:

- Inject additional facts for the White Hat to consider (retroactively added)
- Ask for deeper exploration on a specific hat before moving on
- Skip remaining hats if the picture is already clear

## Synthesis

The Blue Hat (always the team lead) produces the final assessment:

1. **Facts established** — the White Hat foundation
2. **Intuitive signals** — what the Red Hat surfaced that analysis alone would miss
3. **Risk map** — Black Hat concerns organized by severity and likelihood
4. **Value map** — Yellow Hat benefits organized by impact
5. **Alternatives generated** — Green Hat options that merit further investigation
6. **Conflicts and resolution** — where hats contradicted each other and how the Blue Hat resolves the tension
7. **Recommendation** — a direction informed by all six perspectives

## Output

The modifier produces a structured Six Hats analysis that can stand alone or be appended to a core pattern's proposal as an additional analytical pass.

## Notes

- The strict sequencing is the point. Do not let agents mix modes — an agent wearing the Yellow Hat who says "but the risk is..." has broken the framework.
- The Red Hat is often the most valuable and most neglected. Gut reactions from experienced engineers contain compressed pattern-matching that analytical modes cannot replicate. Give it real weight.
- Green Hat alternatives should be genuinely creative, not minor variations. If the Green Hat only produces "do the same thing but slightly differently," push for more divergent thinking.
- Six Hats works well as a modifier after Council when the council converged quickly and the team wants to verify nothing was missed.

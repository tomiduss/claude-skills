---
name: multi-agent-council
description: >
  Structured multi-agent deliberation for complex, multi-tradeoff problems —
  architecture design, system proposals, high-stakes decisions. Spawns
  competing-perspective agents that research and argue from constrained
  value functions. Trigger: "run a council", "council this", "explore from
  multiple angles", "design a council for". Heavyweight — do NOT trigger
  for simple questions or problems with one obvious direction.
---

# Multi-Agent Council

Spawn a team of research agents with competing value functions to explore complex problems through structured deliberation. Agents independently investigate the codebase, search the web, and argue from constrained perspectives — producing an evidence-based proposal that's been stress-tested before a single line of code is written.

## Core concept

The power of a council comes from **institutionalized disagreement**. Agents don't just have different opinions — they have different *value functions* that make certain conclusions structurally impossible. A Pragmatist cannot fall in love with an elegant solution. A Minimalist cannot propose adding code. This prevents groupthink at the identity level, not the instruction level.

Unlike abstract deliberation, these agents **actively research** — they grep the codebase, read files, search the web. A Pragmatist who can measure actual complexity while arguing "this isn't worth it" produces better analysis than one reasoning in the abstract.

The human stays in the loop as the **carrier of tacit knowledge** — context that exists nowhere in any document. Enter at checkpoints between rounds, not continuously.

---

## Workflow

### Step 1 — Understand the problem

Ask at most 3 clarifying questions to extract:
- **What is the goal or problem?** (Be specific — "design an access policy system" not "think about access")
- **What constraints exist?** (Timeline, team size, existing commitments, tech stack)
- **Preferred deliberation pattern?** If the user has one, use it. If not, suggest one based on the problem type.

**Complexity gate (structural, not advisory):** A council is a heavyweight tool — base token cost ranges from 5× single-Opus at Simple tier to 50× at Very Complex tier, and modifiers stack on top — and must not be spawned without written justification and explicit cost acceptance.

The gate blocks spawning unless the user satisfies **all three** of the following:

#### 1. Name at least 2 meaningful tradeoffs

Tradeoffs must be specific. "Scale vs. cost" is generic and not acceptable. "Postgres row-level security vs. application-level auth — RLS centralizes policy but blocks multi-tenant sharding; app-level scales but fragments policy across services" is acceptable. Write these in the skill dialogue before proceeding.

If the user cannot name 2 meaningful tradeoffs, **refuse to spawn the council** and offer direct analysis instead:

> "I don't see 2 distinct tradeoffs that warrant a full council here. Want me to analyze this directly — single pass, no council overhead? Or if you think the tradeoffs are there, rephrase them more specifically and I'll check again."

#### 2. Pick a tier (shows baseline cost)

**Baseline tier estimates — no modifiers:**

| Tier | Meets | Deliberators | Rounds | Tool budget/agent | Est. tokens | ≈ cost vs single-Opus |
|---|---|---|---|---|---|---|
| **Simple** | ≤2 tradeoffs | 2 | 1 + synthesis | ~10k | ~50k total | ~5× |
| **Moderate** | 3-4 tradeoffs | 3 | 2 + synthesis | ~20k | ~150k total | ~15× |
| **Complex** | 5+ tradeoffs or high stakes | 4 | 2 + synthesis | ~35k | ~300k total | ~30× |
| **Very Complex** | cross-domain, asymmetric info | 3 × 3 slices | 2 + synthesis | ~50k | ~500k total | ~50× |

Estimates assume Sonnet 4.6 deliberators + Opus 4.6 team lead. The team lead populates `[TOKEN_BUDGET]` in `references/deliberator-prompt.md` with the per-agent column value for the chosen tier.

#### 3. Pick modifiers (shows compound cost)

**Modifier cost add-ons — all individually disableable:**

| Modifier | Default | Add-on cost | Notes |
|---|---|---|---|
| Judge (`patterns/judge.md`) | off below Complex, opt-in at/above Complex | +30-50k tokens | Optional, non-blocking. See Task 4. |
| Pre-mortem (`patterns/pre-mortem.md`) | off | +40-60k tokens | Adds one Red-Team team member + patch synthesis. |
| Minority Report (`patterns/minority-report.md`) | off | +20-30k tokens | Preserves a dissenting voice in the proposal. |

Show the user a compound estimate before spawning:

```
Tier: Complex (4 deliberators, 2 rounds, ~300k tokens)
  + Judge modifier:      +40k
  + Pre-mortem modifier: +50k
  Total estimate:        ~390k tokens (~40× single-Opus cost)

Reduce by disabling modifiers:
  Council with Judge only:      ~340k
  Council with Pre-mortem only: ~350k
  Council with no modifiers:    ~300k
```

The user must explicitly accept the total **or** choose a reduced configuration. Every modifier is individually disableable — the baseline council (no modifiers) must always be runnable at the tier's advertised cost. No feature is baked so tightly that it cannot be turned off.

Proceed with the council only after all three conditions are satisfied.

### Step 2 — Select pattern and compose council

**Pattern selection:**
1. If the user specified a pattern → use it
2. If not → read `references/patterns-index.md`, recommend a pattern based on problem type, and explain why
3. The user can override

Read `references/patterns-index.md` for the pattern library. Three core patterns and four modifier patterns that can layer on top.

**Council composition:**
Read `references/roles-index.md` to select 2-4 roles. Consider:
- Roles must be in **genuine tension** — two agents who would always agree are one agent
- Match roles to the problem type using the composition heuristics in the index
- For domain-specific needs, read `references/custom-role-template.md` and create a tailored role

Read only the individual role files needed from `references/roles/`.

### Step 3 — Execute or export

**Detect mode** based on how the user phrased their request:
- "run a council", "council this", "explore this" → **Execute mode** (default)
- "design a council", "give me the prompts", "export the council" → **Design mode**

#### Execute mode (default)

Use agent-teams infrastructure to create and run the council:

1. `TeamCreate("council-{topic-slug}")`
2. Spawn the **team lead** (synthesizer/orchestrator):
   - `general-purpose` agent
   - Read `references/team-lead-prompt.md` for the prompt template
   - Populate placeholders: `[AGENT_LIST]`, `[GOAL]`, `[CONTEXT]`, `[PATTERN_NAME]`, `[PATTERN_STRUCTURE]`
   - Read `references/proposal-document.md` and inject into `[PROPOSAL_FORMAT]`
3. Spawn **2-4 deliberators**:
   - `general-purpose` agents
   - Read `references/deliberator-prompt.md` for the shared prompt template
   - For each agent, read its role file from `references/roles/` and map:
     - `# Title` → `[ROLE_NAME]`
     - `**Value function:**` line → `[VALUE_FUNCTION]`
     - `## Lens` section → `[ROLE_LENS]`
     - `## Research directives` section → `[RESEARCH_DIRECTIVES]`
   - Populate `[GOAL]` and `[CONTEXT]` with the shared problem context

Then continue to Step 4.

#### Design mode

Output the fully populated prompt package — no agents spawned. Read `references/deliberator-prompt.md` and `references/team-lead-prompt.md`, substitute all placeholders with the actual goal, context, role details, and pattern structure, then present:

1. **Team lead prompt** — fully populated, ready to paste
2. **Each deliberator prompt** — fully populated with value function, lens, and research directives injected
3. **Round structure** — how many rounds, what happens in each, when the user intervenes
4. **Pattern-specific guidance** — any special instructions from the selected pattern

The user can take these prompts to Claude.ai, another AI tool, or customize them before running.

After outputting, the workflow is complete — skip Steps 4-7.

### Step 4 — Round 1: Parallel research and position papers

All deliberators research simultaneously. Each agent:
- Investigates the problem from their value function's perspective
- Reads code, searches the web, traces patterns — gathering real evidence
- Produces a position paper (≤400 words) with file:line citations and URL references

Team lead collects all position papers and presents a digest to the user.

### Step 5 — User checkpoint and Round 2

Pause for user input. The user can:
- Inject tacit knowledge ("the reason we built it this way was...")
- Ask a specific agent to explore something further
- Redirect the deliberation

Team lead sends Round 2 directives to each deliberator with the other agents' positions. In Round 2, each agent must:
- Acknowledge the strongest counterargument to their position
- Update their position if the evidence warrants it
- Flag remaining disagreements with supporting evidence

### Step 6 — Synthesis and proposal

Team lead synthesizes all rounds into a **Proposal Document**. Read `references/proposal-document.md` for the output format.

Then shut down the council: send `shutdown_request` to each agent, wait for responses, `TeamDelete`.

### Step 7 — Pipeline handoff (conditional)

If the proposal has implementation scope, suggest:
> "This proposal has clear implementation work. Want me to feed it into a plan for team execution?"

If yes → invoke `writing-plans-for-teams` with the proposal document as context, which can then feed into `agent-team-driven-development`.

If no → deliver the proposal document and done.

---

## Key principles

**Value functions over opinions** — A role's identity should make certain conclusions structurally impossible, not just unlikely. "Be skeptical" is weak. "You cannot propose adding code — only removing it" is a value function.

**Evidence over abstraction** — Agents have full tool access. They should cite specific files, code patterns, metrics, and external references. An unsupported opinion is a waste of a council seat.

**Natural tension is a feature** — When composing a council, verify that roles are in genuine tension. See "Natural tension with" in each role file.

**The human is an agent** — The user carries organizational memory, political context, and tacit knowledge. Design the deliberation so they enter at checkpoints, not continuously.

**Document the dissent** — Minority positions are as valuable as the recommendation. When the plan fails, the analysis of why was already done.

---

## Reference files

- `references/roles-index.md` — Role library index with value functions and composition heuristics
- `references/roles/*.md` — Individual role files with lens and research directives
- `references/patterns-index.md` — Pattern library index
- `references/patterns/*.md` — Individual pattern files with prompt templates
- `references/deliberator-prompt.md` — Shared prompt template for spawning deliberator agents
- `references/team-lead-prompt.md` — Prompt template for the synthesizer/orchestrator
- `references/custom-role-template.md` — Guide for creating domain-specific roles
- `references/proposal-document.md` — Output format for the proposal document

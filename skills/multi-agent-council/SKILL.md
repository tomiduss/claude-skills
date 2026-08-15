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

| Tier | Meets | Deliberators | Rounds / execution | Tool budget/agent | Est. tokens | ≈ cost vs single-Opus |
|---|---|---|---|---|---|---|
| **Simple** | ≤2 tradeoffs | 2-4 | 1 round → Path A (subagents) | ~10k | ~50-90k total | ~5-9× |
| **Moderate** | 3-4 tradeoffs | 3 | 2 rounds → Path B (teammates) | ~20k | ~150k total | ~15× |
| **Complex** | 5+ tradeoffs or high stakes | 4 | 2 rounds → Path B (teammates) | ~35k | ~300k total | ~30× |
| **Very Complex** | cross-domain, asymmetric info | 3 × 3 slices | 2 rounds → Path B (teammates) | ~50k | ~500k total | ~50× |

Estimates assume Sonnet 4.6 deliberators. The **lead is the session running this skill** — there is no separate lead agent to budget for. Deliberator count is chosen in Step 2 (2-4 roles) by how many perspectives the problem needs; the figure above is typical, not a cap. The execution path follows from round count — see Step 3. Populate `[TOKEN_BUDGET]` in `references/deliberator-prompt.md` with the per-agent value for the chosen tier.

#### 3. Pick modifiers (shows compound cost)

**Modifier cost add-ons — all individually disableable:**

| Modifier | Default | Add-on cost | Notes |
|---|---|---|---|
| Judge (`patterns/judge.md`) | off below Complex, opt-in at/above Complex | +30-50k tokens | Optional, non-blocking one-shot subagent. See `patterns/judge.md`. |
| Pre-mortem (`patterns/pre-mortem.md`) | off | +40-60k tokens | Adds one Red-Team subagent + patch synthesis. |
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

#### How a council runs — read before spawning

**You are the council lead.** In Claude Code's agent-teams model the lead is the session running this skill, fixed for the team's lifetime — you cannot spawn a lead, and a teammate cannot become one. *You* collect positions, run the user checkpoints, and synthesize. Do not spawn a separate "team-lead" agent: a teammate has no channel to the user and cannot run the checkpoints this skill depends on.

The execution path follows from **round count**:

- **Path A — single-round council** (Simple tier, or any 1-round pattern). Deliberators are **one-shot subagents** — the `Agent` tool with **no `team_name`**. Each runs once and returns its position paper as the tool result. No team, no `SendMessage`, no shutdown.
- **Path B — multi-round council** (Moderate tier and up, or any pattern with 2+ rounds). Deliberators are **teammates** — the `Agent` tool **with `team_name`** — so they persist and carry their Round 1 investigation into Round 2. An `Agent` call without `team_name` is a one-shot subagent whose name becomes unaddressable once it finishes; using one for a multi-round council breaks Round 2.

**Modifier agents (Pre-mortem Red-Team, Judge, Minority-Report dissent, Stakeholder personas) are always one-shot subagents** — each runs once and returns one artifact. Only multi-round deliberators are teammates.

Mechanics that bite if ignored:
- Spawn all agents that share a round **in a single message** so they run concurrently.
- A teammate's plain output is invisible to you — it must `SendMessage` its result. A subagent's final message returns to you automatically.
- Address teammates by `name`, never by ID. Teammates go idle between turns — that is normal, not a failure.
- `TeamDelete` fails while any teammate is still active — shut them all down first.

#### Execute mode — Path A (single-round)

1. Spawn the 2-4 deliberators as subagents — one `Agent` call each, all **in one message** for a parallel Round 1:
   - `subagent_type: "general-purpose"`, `model:` per tier, `name:` the role slug
   - **no `team_name`**
   - `prompt:` from `references/deliberator-prompt.md`, placeholders filled, `[MODE]` set to `subagent`
2. Each subagent returns its position paper as the tool result. Continue to Step 4 — you digest and run the checkpoint.
3. There is no Round 2. After the checkpoint, synthesize (Step 6). Spawn any modifier as a one-shot subagent when its pattern file directs.

#### Execute mode — Path B (multi-round)

1. `TeamCreate(team_name: "council-{topic-slug}", description: "...")`. From the result note `lead_agent_id`; the part before `@` is `[LEAD_NAME]` — deliberators use it to report back to you.
2. Spawn the 2-4 deliberators as teammates — one `Agent` call each, all **in one message**:
   - `subagent_type: "general-purpose"`, `model:` per tier
   - `team_name: "council-{topic-slug}"`, `name:` the role slug (e.g. `archaeologist`)
   - `prompt:` from `references/deliberator-prompt.md`, placeholders filled, `[MODE]` set to `teammate`, `[LEAD_NAME]` filled
3. Read `references/orchestration-guide.md` — your round-by-round protocol as lead — and continue to Step 4.

**Filling the deliberator prompt** (both paths): read each role file from `references/roles/` and map `# Title` → `[ROLE_NAME]`, the `**Value function:**` line → `[VALUE_FUNCTION]`, `## Lens` → `[ROLE_LENS]`, `## Research directives` → `[RESEARCH_DIRECTIVES]`. Fill `[GOAL]`, `[CONTEXT]`, and `[TOKEN_BUDGET]` (the per-agent value for the tier).

#### Design mode

Output the fully populated prompt package — no agents spawned. Read `references/deliberator-prompt.md`, substitute all placeholders with the actual goal, context, and role details, then present:

1. **Each deliberator prompt** — fully populated with value function, lens, and research directives
2. **Round structure** — how many rounds, what happens in each, when the user intervenes; for a multi-round council, include the orchestration protocol from `references/orchestration-guide.md`
3. **Pattern-specific guidance** — any special instructions from the selected pattern

The user can take these prompts to Claude.ai, another tool, or customize them before running.

After outputting, the workflow is complete — skip Steps 4-7.

### Step 4 — Round 1: Parallel research and position papers

All deliberators research simultaneously. Each agent:
- Investigates the problem from their value function's perspective
- Reads code, searches the web, traces patterns — gathering real evidence
- Produces a position paper (≤400 words) with file:line citations and URL references

Collect all position papers — as tool results (Path A) or via `SendMessage` (Path B) — and present a **Round 1 Digest** to the user. For Path B, follow the digest format in `references/orchestration-guide.md`.

### Step 5 — User checkpoint and Round 2

Pause for user input at the checkpoint. The user can:
- Inject tacit knowledge ("the reason we built it this way was...")
- Ask a specific agent to explore something further
- Redirect the deliberation

**Path A (single-round) stops here** — after the checkpoint, go to Step 6. If the user wants a point explored deeper, spawn a fresh subagent for that targeted question.

**Path B (multi-round):** `SendMessage` Round 2 directives to each deliberator teammate — include the Round 1 Digest (not raw papers) and any user-injected context. In Round 2, each agent must:
- Acknowledge the strongest counterargument to their position
- Update their position only with cited new evidence, or hold with evidence
- Flag remaining disagreements with supporting evidence

`references/orchestration-guide.md` has the dispatch, digest, and accounting detail.

### Step 6 — Synthesis and proposal

Synthesize all rounds into a **Proposal Document**. Read `references/proposal-document.md` for the output format.

- **Path A:** nothing to tear down — the deliberator subagents terminated when they returned their papers.
- **Path B:** shut down the council — `SendMessage` a `shutdown_request` to each teammate, wait for acknowledgment (30-second deadline), then `TeamDelete`. `TeamDelete` fails while any teammate is still active, so confirm they are all down first. Log any straggler under "Shutdown anomalies" in the Proposal Document.

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
- `references/orchestration-guide.md` — Round-by-round protocol the lead follows for a multi-round (Path B) council
- `references/custom-role-template.md` — Guide for creating domain-specific roles
- `references/proposal-document.md` — Output format for the proposal document

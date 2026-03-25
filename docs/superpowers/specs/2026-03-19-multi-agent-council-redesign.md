# Multi-Agent Council Redesign

**Date:** 2026-03-19
**Status:** Draft
**Scope:** Redesign the `multi-agent-council` skill from a prompt-template generator into a live agent-teams-powered deliberation system with pipeline integration.

---

## Problem

The current `multi-agent-council` skill generates copy-paste prompts for deliberation councils but never actually runs them. It lives inside Claude Code — an environment with full agent orchestration capabilities — yet hands the user an assembly-required kit. Additionally:

- Its triggering description is too broad, auto-activating on any "help me think" request
- It frames everything as a "decision" when the real use case is broader: research, design exploration, proposal development
- Role and pattern files load all content at once (~767 lines) instead of using progressive disclosure
- There is no connection to downstream execution (plan writing, team implementation)

## Goals

1. Make the skill **spawn real agents** that research the codebase, search the web, and argue from constrained value functions
2. Reframe from "decision-making" to **complex problem exploration and proposal development**
3. Make triggering **on-demand** — users explicitly invoke this for heavyweight deliberation
4. Implement **progressive disclosure** — index files + individual role/pattern files
5. Connect to the **execution pipeline**: council → `writing-plans-for-teams` → `agent-team-driven-development`

## Non-Goals

- Defining new agent-teams agent types (we use `general-purpose`)
- Replacing agent-teams infrastructure (we consume it)
- Auto-triggering on simple questions

---

## Architecture

### Execution Model

The skill uses `agent-teams` infrastructure to spawn real agents:

```
TeamCreate("council-{topic-slug}")

Spawn team-lead:
  - general-purpose agent
  - Orchestrates rounds, manages user checkpoints, synthesizes

Spawn 2-4 deliberators:
  - general-purpose agents
  - Each gets: value function + research directives + shared goal/context
  - Each can use: Read, Glob, Grep, Bash, WebSearch, WebFetch
```

Agents are general-purpose with value-function prompts. The value function constrains *what conclusions are structurally possible*, while full tool access enables *evidence-based research*.

### Workflow (7 steps)

**Step 1 — Interview (≤3 questions)**
Extract:
- What's the goal or problem?
- What constraints exist?
- Preferred deliberation pattern? (or skill suggests)

Then: complexity gate. If the problem is trivially simple, warn the user that a full council may be overkill. Proceed if they confirm.

**Step 2 — Select pattern + compose council**
- If user specified a pattern → use it
- If not → recommend based on problem type, explain why
- User can override

Pattern types:
- 3 core patterns: Council, Asymmetric Info, Temporal
- 4 modifier patterns (layer on top): Pre-mortem, Stakeholder Sim, Minority Report, Six Hats

Read `roles-index.md` to select 2-4 roles. Read only the individual role files needed.

**Step 3 — Spawn council via agent-teams**
- `TeamCreate` with council name
- Spawn team-lead with synthesizer prompt
- Spawn 2-4 deliberators using shared `deliberator-prompt.md` template + role-specific lens from individual role file

**Step 4 — Round 1: Parallel research + position papers**
All deliberators research simultaneously. Each produces an evidence-based position paper (≤400 words with file/URL citations). Team lead collects and presents a digest to the user.

**Step 5 — User checkpoint + Round 2**
User injects tacit knowledge or asks for specific exploration. Team lead sends Round 2 directives with other agents' positions. Agents must:
- Acknowledge the strongest counterargument
- Update their position if evidence warrants
- Flag remaining disagreements with evidence

**Step 6 — Synthesis → Proposal Document**
Team lead produces structured proposal document. Then: `team-shutdown` → cleanup.

**Step 7 — Pipeline handoff (conditional)**
If the problem implies implementation work, suggest feeding the proposal into `writing-plans-for-teams`. If user agrees → invoke. If not → deliver proposal and done.

### Pipeline Integration

```
multi-agent-council          writing-plans-for-teams      agent-team-driven-development
     Deliberate                      Plan                         Execute
   "Explore this"              "How to build it"                "Build it"
        │                            │                              │
   Proposal Document ──────→  Implementation Plan ──────→   Team Execution
```

The proposal document's "Implementation scope" section becomes the input context for plan writing.

---

## File Structure

```
multi-agent-council/
├── SKILL.md                          # Core workflow (~120 lines)
├── references/
│   ├── roles-index.md                # Name + value function + when to use (~40 lines)
│   ├── roles/
│   │   ├── pragmatist.md
│   │   ├── visionary.md
│   │   ├── domain-expert.md
│   │   ├── archaeologist.md
│   │   ├── minimalist.md
│   │   ├── analogist.md
│   │   ├── first-principles.md
│   │   ├── falsifier.md
│   │   ├── stress-tester.md
│   │   ├── contrarian.md
│   │   ├── economist.md
│   │   ├── regulator.md
│   │   ├── anthropologist.md
│   │   ├── ethicist.md
│   │   └── integrator.md
│   ├── patterns-index.md             # Pattern name + when to use (~30 lines)
│   ├── patterns/
│   │   ├── council.md
│   │   ├── asymmetric-info.md
│   │   ├── temporal.md
│   │   ├── pre-mortem.md
│   │   ├── stakeholder-sim.md
│   │   ├── minority-report.md
│   │   └── six-hats.md
│   ├── deliberator-prompt.md         # Shared agent spawn template
│   ├── team-lead-prompt.md           # Synthesizer/orchestrator prompt
│   ├── custom-role-template.md       # Guide for creating domain-specific roles
│   └── proposal-document.md          # Output format template
```

### Progressive Disclosure

1. SKILL.md always loads (~120 lines)
2. `roles-index.md` loads during composition (~40 lines)
3. Only selected role files load (2-4 × ~25 lines)
4. Only selected pattern file loads (~40 lines)
5. Prompt templates load at spawn time (~60 lines)

Worst-case context: ~360 lines (down from ~767).

### Individual Role File Format

```markdown
# [Role Name]

**Value function:** [one sentence]
**Natural tension with:** [roles]
**Best for:** [problem types]

## Lens

[2-3 lines describing what this agent uniquely attends to]

## Research directives

[What this agent should look for in the codebase/web when investigating]
```

---

## Key Design Principles

**Value functions over opinions** — A role's identity makes certain conclusions structurally impossible. "Be skeptical" is weak. "You cannot propose adding code — only removing it" is a value function.

**Evidence-based deliberation** — Agents don't just think — they research. A Pragmatist who can grep for complexity metrics while arguing "this isn't worth it" produces better analysis than one reasoning abstractly.

**Natural tension is a feature** — Roles in a council must be in genuine tension. Two agents who would always agree are one agent.

**The human is an agent** — The user carries organizational memory, political context, and tacit knowledge. They enter at checkpoints (between rounds), not continuously.

**Complexity gate** — The skill always spawns agents, but warns if the problem seems too simple. The user decides whether to proceed.

---

## Proposal Document Format

```markdown
# Proposal: [one sentence]

## Problem / Goal
[What we're exploring and why]

## Exploration
### [Role 1] — [position summary + key evidence]
### [Role 2] — [position summary + key evidence]
### [Role N] — ...

## Recommended approach
[Synthesized recommendation from team lead]

## Tradeoffs documented
[What we're accepting and what we're giving up]

## Dissenting perspectives preserved
[Minority positions that survived deliberation — these are valuable]

## Implementation scope
[If applicable — what needs to be built, rough shape of the work]

## Review triggers
[Conditions that should cause revisiting this proposal]
```

---

## Triggering Description

```
Run structured multi-agent deliberation on complex problems —
architecture design, system proposals, strategic exploration,
or high-stakes decisions. Spawns 2-4 research agents with distinct
value functions that independently explore the codebase, research
approaches, and argue from competing perspectives.
Use when the user explicitly wants multi-perspective deliberation:
"run a council", "explore this from multiple angles", "I want agents
to research and propose", "council this".
Heavyweight skill — do NOT trigger for simple questions.
Outputs: evidence-based proposal with tradeoff documentation,
optionally feeding into writing-plans-for-teams for execution.
```

---

## What Changed

| Aspect | Before | After |
|---|---|---|
| Execution | Outputs prompts to paste | Spawns real agents via agent-teams |
| Agent capability | Abstract thinkers | Research agents with codebase/web access |
| Framing | Decision-making | Problem exploration + proposal |
| Triggering | Auto-trigger on broad phrases | On-demand, explicit invocation |
| Role loading | All 15 roles in one 347-line file | Index + 15 individual files, progressive disclosure |
| Pattern loading | All 7 in one 283-line file | Index + 7 individual files |
| Prompt templates | 15 copy-paste blocks | 1 shared template + per-role lens |
| Pipeline | Isolated | Feeds into writing-plans → agent-team-driven-dev |
| Complexity gate | None | Warns if problem is too simple |
| Total context | ~767 lines worst case | ~360 lines worst case |

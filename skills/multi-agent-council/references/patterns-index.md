# Pattern Index

Deliberation patterns define how agents interact, what rounds look like, and how synthesis works. Pick a pattern based on the shape of the problem, not the topic.

## All Patterns

| Pattern | Type | Best For | How It Works |
|---|---|---|---|
| Council | Core | General multi-perspective exploration | All agents share context but hold different value functions; two rounds of parallel debate then synthesis |
| Asymmetric Info | Core | Problems where different stakeholders hold different context | Each agent sees only one slice of context; collaboration forces the full picture to emerge |
| Temporal | Core | Decisions with tech debt or long-term sustainability implications | Three agents optimize for different time horizons; tradeoff matrix makes debt explicit |
| Pre-mortem | Modifier | Stress-testing a proposal after initial convergence | Red-team agent assumes the plan failed and writes the post-mortem from 6 months out |
| Stakeholder Sim | Modifier | User-facing systems, API/DX design | Agents role-play the humans who will live with the decision — new dev, on-call engineer, end user |
| Minority Report | Modifier | Documenting dissent after a high-stakes convergence | Dissent agent writes the strongest possible case against the final proposal |
| Six Hats | Modifier | Sequential, thorough exploration of a single problem | Six cognitive modes applied in order: facts, intuition, risks, benefits, alternatives, synthesis |

## Core Patterns vs. Modifiers

**Core patterns** define the full deliberation structure from start to finish — round structure, agent interactions, synthesis format. Every deliberation uses exactly one core pattern.

**Modifier patterns** layer on top of a core pattern to add a specific analytical pass. They run after (or during) a core deliberation. A single deliberation can use multiple modifiers. Example: Council + Pre-mortem + Minority Report.

## Quick Selection

If you are not sure which pattern to use, start with **Council**. It is the default and works well for most problems. Add modifiers only when the problem shape demands it — pre-mortem for high-stakes proposals, stakeholder sim for user-facing work, minority report when preserving dissent matters.

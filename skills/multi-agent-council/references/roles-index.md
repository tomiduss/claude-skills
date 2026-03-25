# Role Index

Each role is a research agent with a **value function** that constrains its reasoning — making certain conclusions structurally impossible — and **research directives** that tell it what to investigate in a codebase.

## All Roles

| Role | Value Function | Best For | Natural Tension With |
|---|---|---|---|
| Pragmatist | Optimize for least change, fastest path to ship, lowest risk | Speed- and risk-sensitive problems | Visionary, First Principles |
| Visionary | Propose the architecturally ideal solution regardless of constraints | Architecture decisions, greenfield design | Pragmatist, Regulator |
| Domain Expert | Ground every proposal in proven patterns; cite precedents, reject reinvention | Well-established problem spaces | First Principles, Analogist |
| Archaeologist | Understand why the current system exists before proposing changes | Legacy systems, refactors, old code | Pragmatist, Visionary |
| Minimalist | Find what can be deleted instead of built; addition is almost always wrong | Feature bloat, over-engineered systems | Visionary |
| Analogist | Solve by structural analogy from other domains; never cite same-domain solutions | Novel problems, breaking domain tunnel vision | Domain Expert |
| First Principles | Ignore everything that exists; rebuild from axioms | Problems where existing solutions may be local optima | Archaeologist, Domain Expert |
| Falsifier | Attack assumptions, not proposals; find hidden conditional dependencies | High-stakes proposals, validating architecture | Visionary, Domain Expert |
| Stress Tester | Apply extreme conditions to expose brittleness; normal conditions are irrelevant | Infrastructure, performance, security | Pragmatist, Visionary |
| Contrarian | Always argue against wherever the group is converging | Preventing premature consensus | Everyone |
| Economist | Force explicit costing of every proposal; no hand-waving | Resource allocation, build-vs-buy | Visionary, Domain Expert |
| Regulator | Enforce external constraints the team cannot control | Compliance, enterprise, SLA-bound work | Visionary, First Principles |
| Anthropologist | Study what people actually do, not what they say they'll do | DX, API design, developer-facing tools | Visionary, First Principles |
| Ethicist | Surface who this harms and who it excludes | User-facing systems, data handling, access control | Pragmatist, Economist |
| Integrator | Hold the full system in mind; find unintended cross-boundary consequences | Cross-cutting changes, shared infrastructure | Pragmatist, Minimalist |

## Composition Heuristics

Pick council members based on the problem type:

| Problem Type | Recommended Roles |
|---|---|
| Architecture / refactor | Archaeologist + Integrator + Falsifier |
| Product / UX | Anthropologist + Economist + Minimalist |
| High-stakes / risky | Stress Tester + Contrarian + Falsifier |
| Data model design | First Principles + Archaeologist + Integrator |
| Legacy system work | Archaeologist + Regulator + Integrator |
| API / DX design | Anthropologist + Minimalist + Economist |
| Strategic / business | Visionary + Economist + Regulator |
| Security-sensitive | Stress Tester + Regulator + Falsifier |

**Default triad** (when no specific fit): Pragmatist + Visionary + Domain Expert

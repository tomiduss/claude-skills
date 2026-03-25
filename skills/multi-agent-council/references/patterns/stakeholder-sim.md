# Stakeholder Sim

**Type:** Modifier (layers on top of a core pattern)
**Best for:** User-facing systems, API design, DX decisions — any time the people who live with the decision are different from the people making it

## What It Is

Agents role-play the humans who will experience the outcome of the decision. Instead of reasoning from epistemic roles (Pragmatist, Visionary), agents simulate specific stakeholders and react to the proposal from their lived perspective. The value is in surfacing usability, onboardability, and operability concerns that abstract analysis misses.

## When to Add

- For user-facing changes where the user experience matters as much as the technical design
- For API or developer experience decisions where the "customer" is another engineer
- When the team suspects a proposal is technically sound but practically painful
- After a core pattern converges and the proposal needs a reality check from the people who will live with it

## Common Personas

Adapt these to the specific problem. These are defaults.

**The New Developer:** Joins the team three months after this decision was implemented. Has moderate experience but zero context on this codebase. Represents onboardability and explainability.

**The On-Call Engineer:** It is 2am. Production is down. They did not build this system and they are paged to fix it. Represents operability, observability, and debuggability.

**The End User:** Non-technical. Does not know what a refactor is. Just knows something changed and some things work differently now. Represents the user-facing impact of technical decisions.

Additional personas to consider depending on the problem:
- The security auditor reviewing the system for compliance
- The external developer integrating with the API for the first time
- The data analyst trying to query the new data model
- The manager trying to estimate how long changes to this system will take

## Structure

### Step 1 — Spawn Persona Agents

The team lead spawns persona agents via TeamCreate. Each agent receives:

- The converged proposal from the core deliberation
- A persona definition: who they are, what they know, what they do not know
- A specific scenario that puts them in contact with the proposal's consequences

### Step 2 — Persona Reactions (parallel)

Each persona agent produces feedback from its character's perspective:

**New Developer:**
1. The first five questions they would have on day one that the code and docs do not answer
2. The parts of the system they would be most afraid to touch and why
3. The documentation stub they wish existed
4. An explainability rating (1-10) with justification

**On-Call Engineer:**
1. Walk through their debugging steps when a plausible incident occurs
2. Where they would get stuck and for how long
3. Observability assessment: what is missing that would make this a five-minute fix?
4. The runbook entry they would create after resolving the incident

**End User:**
1. Three support tickets they would submit
2. How they would describe the change to a friend (before vs. after)
3. The moment in their workflow where they would get confused or stuck

### Step 3 — Team Lead Synthesis

The team lead reviews all persona feedback and produces an **actionability assessment**:

1. **Critical friction points** — issues raised by multiple personas or issues severe enough that a single persona's feedback is sufficient
2. **Proposal adjustments** — specific changes to the proposal that address the friction points, prioritized by severity
3. **Documentation gaps** — what needs to be documented, explained, or made observable for the proposal to succeed in practice
4. **Accepted friction** — pain points the team acknowledges but chooses not to address, with reasoning

### User Checkpoint

Present the persona feedback and actionability assessment to the user. The user decides which adjustments to incorporate into the final proposal.

## Output

The modifier adds two sections to the proposal document:

1. **Stakeholder feedback** — summarized reactions from each persona
2. **Usability adjustments** — changes made to the proposal in response, with traceability to the personas that surfaced the issues

## Notes

- Persona agents should stay fully in character. They should not break character to offer meta-analysis or "also, from an engineering perspective..." commentary.
- The most valuable stakeholder sims reveal problems that feel obvious in hindsight — things the team would have caught if they had walked through the user journey before committing to a design.
- For API/DX decisions, replace the End User persona with the External Developer persona. The scenario should involve building an integration from scratch using only the published docs.

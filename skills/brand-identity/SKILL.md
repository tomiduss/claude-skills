---
name: brand-identity
description: >
  Build complete brand identity systems for apps and websites using a coordinated
  agent team. Covers brand strategy, visual research, design exploration, and
  production-ready design tokens. Use this skill whenever the user wants to create
  a brand identity, refresh/redesign an existing brand, find design inspiration
  and references, build a visual identity system, create brand guidelines, or
  generate a design system with tokens. Also activate when users mention
  "branding", "brand guidelines", "visual identity", "design system from scratch",
  "brand refresh", "moodboard", or "design inspiration for my app".
  Does NOT build component libraries, Storybook setups, or full design systems
  with interactive components — only the identity foundation (strategy, tokens,
  guidelines) that those systems inherit from.
---

# Brand Identity Builder

Build cohesive brand identity systems through a coordinated agent team. The skill
orchestrates specialized agents — researchers, a visual designer, and a design
system architect — led by a Brand Director who conducts discovery, synthesizes
research, and manages user checkpoints.

**Scope:** This skill produces the *identity foundation* — brand strategy,
visual direction, design tokens, and guidelines. It does not build component
libraries, Storybook setups, or interactive pattern documentation. Those are
downstream efforts that build on the foundation this skill creates.

## Workflows

| Workflow | Trigger | Agents | Output |
|----------|---------|--------|--------|
| **Build New** | "create brand identity", "branding for my app" | 4 | Full brand system |
| **Brand Refresh** | "redesign brand", "modernize branding", "evolve identity" | 4 | Evolved brand system |
| **Research Only** | "find inspiration", "design references", "moodboard" | 2 | Moodboard + references |

## Phase Overview

```
Build New:     Discovery → Research → [checkpoint] → Visual Variants → [checkpoint] → Design System
Brand Refresh: Audit → Research → [checkpoint] → Visual Variants → [checkpoint] → Design System
Research Only: Brief → Research → [checkpoint] → Moodboard delivered
```

Checkpoints are where the user reviews artifacts (moodboard, variants) and
provides direction before the team continues.

## Team Composition

Read `references/agent-roles.md` for spawn prompts and file ownership boundaries.

| Agent | `description` | Role | Owns |
|-------|--------------|------|------|
| **Brand Director** | (you, orchestrator) | Interview, strategy, research synthesis, checkpoints | `brand-brief.md`, `research/` top-level files |
| **Mobbin Researcher** | `mobbin-researcher` | Mobbin patterns + screenshots | `research/mobbin/` |
| **Web Researcher** | `web-researcher` | Competitors, designsystems.surf, Dribbble | `research/web/` |
| **Visual Designer** | `visual-designer` | HTML variant pages | `variants/` |
| **Design System Architect** | `design-system-architect` | Tokens, config, guidelines | `output/` |

The Brand Director is you — the orchestrating agent. You conduct the interview,
write the brief, spawn researchers, synthesize their findings into the moodboard,
run checkpoints, and spawn downstream agents.

**Naming:** Use the exact `description` values from the table when spawning
agents via the Task tool — this is what the user sees in the chat UI. See
`references/agent-roles.md` for spawning mechanics (including agent-teams mode).

## Output Directory Structure

```
brand-identity/
├── brand-brief.md              # Strategy document (Brand Director)
├── research/
│   ├── mobbin/                 # mobbin-researcher's domain
│   │   ├── screenshots/
│   │   └── findings.md
│   ├── web/                    # web-researcher's domain
│   │   ├── screenshots/
│   │   └── findings.md
│   ├── moodboard.html          # Visual moodboard (Brand Director)
│   ├── references.md           # Consolidated references (Brand Director)
│   └── research-findings.md    # Synthesized analysis (Brand Director)
├── variants/                   # visual-designer's domain
│   ├── variant-a.html
│   ├── variant-b.html
│   ├── variant-c.html
│   └── variant-d.html          # (optional)
└── output/                     # design-system-architect's domain
    ├── tailwind.config.js
    ├── tokens.css
    ├── brand-guidelines.md
    └── typography.css
```

---

## Workflow: Build New Identity

### Phase 1: Discovery (Brand Director — you)

Conduct a focused interview. Don't ask everything at once — start with the
essentials and let the conversation flow.

**Start with these questions:**
1. What's the app/site name? Does it have meaning or story behind it?
2. What does it do, in one sentence?
3. Who uses it? (age, profession, context)
4. Name 2-3 competitors or similar products
5. Any aesthetic preferences? ("clean and minimal", "bold and playful", etc.)
6. Are there existing brand assets (logo, colors, fonts) to work with?

Read `references/brand-frameworks.md` for strategy frameworks (positioning,
archetypes, personality) to deepen the brief if the user engages.

**Produce:** `brand-brief.md` — a concise creative brief covering:
- Brand purpose and positioning
- Target audience
- Brand personality (3-5 adjectives)
- Aesthetic direction
- Competitors to research
- Constraints (existing assets, tech stack, accessibility needs)

### Phase 2: Research (parallel gatherers → Brand Director synthesis)

Research is split into parallel gathering and then synthesis by you.

**Step 1: Spawn gatherers in parallel**

Before spawning, check what browser tools are available (see "Browser & Research
Tools" below). Then spawn the appropriate researchers simultaneously (same
message, two Task tool calls):

```
┌─ mobbin-researcher (if Claude in Chrome available)  → research/mobbin/
│
├─ web-researcher (Playwright)                        → research/web/
│
└─ (both run in parallel)
```

If Mobbin is not available, tell the user and proceed with `web-researcher` only.

Each gatherer produces:
- Screenshots saved to their `screenshots/` subdirectory
- A `findings.md` with annotated references (URL, screenshot filename, why it's
  relevant, specific elements worth noting)

**Screenshots are essential.** If a researcher encounters permission issues with
browser tools, it must immediately report back. You should then ask the user:
"The researcher needs Playwright/browser permissions to capture screenshots.
Can you approve?" Do not silently fall back to text-only output.

**Step 2: Synthesize (Brand Director — you)**

Once both gatherers complete, read their findings and screenshots. You produce:

- **`research/moodboard.html`** — A visual HTML page with **embedded screenshots**
  (use `<img>` tags with relative paths to screenshot files, e.g.,
  `<img src="mobbin/screenshots/app-name.png">`), color swatches extracted from
  references, typography samples, and brief annotations. This must be a genuinely
  visual artifact — not a list of links.
- **`research/references.md`** — Consolidated annotated reference list from all sources
- **`research/research-findings.md`** — Synthesized analysis: common patterns,
  color themes, typography trends, layout patterns, differentiation opportunities,
  and 2-3 recommended directions for visual variants

**Checkpoint 1:** Open the moodboard in the user's browser. Ask:
- "Which references resonate most?"
- "Anything that's completely off-direction?"
- "Any specific elements you want to explore further?"

Capture their feedback before proceeding.

### Phase 3: Visual Exploration (Visual Designer)

Spawn `visual-designer` with: the brand brief, research findings, and user
feedback from checkpoint 1.

The designer builds **3-4 distinct visual directions** as self-contained HTML
pages. Each should feel like a real landing page or app screen — not a mockup.
Bold choices, distinctive typography, intentional color, memorable details.

Each variant should explore a genuinely different direction:
- Different color palettes
- Different typographic personalities
- Different spatial/layout approaches
- Different mood and energy

**Checkpoint 2:** Present variants to the user. Ask:
- "Which direction feels right?"
- "Anything to combine from multiple variants?"
- "What would you change?"

### Phase 4: Design System (Design System Architect)

Spawn `design-system-architect` with: the brand brief, chosen variant (or
combined direction), and user feedback from checkpoint 2.

The architect produces:
1. **`output/tailwind.config.js`** — Full Tailwind config (colors, typography, spacing, shadows)
2. **`output/tokens.css`** — CSS custom properties for non-Tailwind projects
3. **`output/typography.css`** — Font imports and type scale utilities
4. **`output/brand-guidelines.md`** — Comprehensive brand guidelines

---

## Workflow: Brand Refresh

Same phases as Build New, but Phase 1 replaces the interview with an **audit**:

### Phase 1: Audit + Discovery (Brand Director — you)

1. **Scan the existing codebase** for current design patterns:
   - Tailwind config, CSS variables, theme files
   - Current fonts, colors, spacing
   - Component patterns and visual language

2. **Interview the user** about what's working and what isn't:
   - What feels dated or inconsistent?
   - What should be preserved (brand equity)?
   - What's the refresh scope: minor (polish), major (evolution), or full rebrand?

3. **Produce the brief** with an additional "Current State" section documenting
   existing patterns and what to keep vs. evolve.

Phases 2-4 proceed as in Build New, informed by audit findings.

---

## Workflow: Research Only

Lighter workflow — Brand Director + research agents only.

### Phase 1: Brief (Brand Director — you)

Quick interview:
- What are you exploring? (industry, aesthetic, specific patterns)
- What's the context? (new project, redesign, competitive research)
- Any specific references to start from?

### Phase 2: Research

Same as Build New Phase 2 — spawn gatherers in parallel, then synthesize.
Cast a wider net since the user is exploring, not building toward a specific brand.

### Delivery

Present the moodboard and research findings. No further phases.

---

## Spawning Agents

Use the Task tool to spawn each agent. The `description` field is what appears
in the chat UI — always use the exact agent name from the Team Composition table.

```
Task tool:
  description: "web-researcher"         # ← user sees this in the chat
  subagent_type: "general-purpose"
  prompt: "..."                         # ← spawn prompt from agent-roles.md
```

All agents use `general-purpose` subagent type — they need full tool access.

**Spawn prompt contents** — always include:
1. The role definition from `references/agent-roles.md`
2. The brand brief contents
3. Previous phase outputs they need (research findings, user feedback, etc.)
4. Clear file ownership boundaries
5. The absolute path to the output directory

**Execution order:**

```
Phase 2a: mobbin-researcher ──┐
                              ├─ (parallel)
Phase 2b: web-researcher ─────┘
                              ↓
Phase 2c: Brand Director synthesizes research
                              ↓
          checkpoint 1 (user reviews moodboard)
                              ↓
Phase 3:  visual-designer
                              ↓
          checkpoint 2 (user picks direction)
                              ↓
Phase 4:  design-system-architect
```

**Model selection:** Use the most capable model (default) for `visual-designer`
and `design-system-architect`. Researchers can use a faster model if available.

If agent-teams infrastructure is available (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
and the `Teammate` tool), see `references/agent-roles.md` for team spawning details.

## Browser & Research Tools

**Mobbin** requires Claude in Chrome with `tabs_context` MCP for authenticated
access. If a login screen appears, let the user handle it. If Mobbin is
unavailable, notify the user and proceed with web research only.

**Playwright** is the primary browser tool for all other sites (competitors,
designsystems.surf, Dribbble, Awwwards). Screenshots are essential — if
permissions are denied, ask the user to approve.

**Fallback:** If no browser tools are available, use WebSearch + WebFetch.
The moodboard will rely on text descriptions and color swatches instead of
embedded screenshots.

---

## Key Principles

- **Strategy before pixels.** The brief drives everything. A clear brief means
  better research, better variants, better output.

- **Show, don't tell.** The moodboard and variants are visual artifacts the user
  can react to. HTML with real typography and color eliminates ambiguity.

- **Bold choices over safe defaults.** Avoid the generic "startup blue with Inter
  font" trap. Each variant should have a clear point of view.

- **Production-ready output.** The design tokens and Tailwind config should work
  in a real project immediately. Not aspirational documentation — actual code.

- **Respect existing equity.** In refreshes, identify what's working before
  changing anything. Brand recognition has value.

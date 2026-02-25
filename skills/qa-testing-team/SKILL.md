---
name: qa-testing
description: >
  Use ONLY when the user explicitly requests a multi-agent QA team to test a web application.
  Trigger phrases: /qa-testing, "run QA team", "spawn QA agents", "multi-agent QA",
  "QA testing team", "parallel browser testing team". Do NOT activate for general testing
  requests, single-agent browser testing, writing Playwright tests, or casual mentions of
  "test my app" — those are handled by other tools. This skill requires deliberate invocation.
---

# QA Testing — Multi-Agent Browser Testing Orchestrator

Coordinate a team of specialized QA agents, each with its own isolated Playwright browser
instance, to test a live web application in parallel. Produces a consolidated report with
prioritized findings, screenshots as evidence, and optionally generates reusable Playwright
test specs.

## When to Use

- User explicitly asks for a **QA team** or **multi-agent testing**
- User invokes `/qa-testing`
- User wants **parallel browser testing** across multiple app areas
- User needs a **comprehensive QA audit** covering functional + UX + accessibility + mobile

## When NOT to Use

- **Single test or quick check** — Use `playwright-cli` skill or browser tools directly
- **Writing Playwright test files** — Use `playwright-cli` skill
- **Code review or static analysis** — Use code review agents
- **Unit/integration testing** — Use standard test runners
- **Backend/API-only testing** — No browser needed, wrong tool
- **App has < 3 routes** — Overhead of multi-agent setup isn't worth it; test manually

## Prerequisites

- `@playwright/mcp@latest` available via npx
- The application under test must be running (skill does NOT manage dev servers)
- Claude Code with subagent spawning capability (Task tool)

Read `references/role-catalog.md` before assembling the team.
Read `references/playwright-mcp-setup.md` before configuring browser instances.
Read `references/report-templates.md` before producing the final report.

---

## Phase 1: Interview & Discovery

When the user invokes `/qa-testing`, begin an interactive interview to gather context.
Do NOT skip this phase — missing information leads to wasted agent runs and false positives.

### Required Information

Gather these answers before proceeding. If information is missing, ask for it.

#### 1. Application Under Test
- **Base URL** — e.g., `http://localhost:3000` or `https://staging.example.com`
- **Backend URL** (if separate) — e.g., `http://localhost:8090`
- **Framework** — Auto-detect from `package.json` if available (Next.js, Vite, Remix, etc.)

#### 2. What to Test
Determine the scope. Ask the user which applies:

- **"I have user stories / test plan"** — User provides a document or describes flows
- **"Inspect my codebase"** — Discover routes, pages, and components automatically:
  - Use Glob to find route files (e.g., `src/app/**/page.tsx` for Next.js App Router)
  - Use Grep to identify auth patterns (middleware, session checks)
  - Use Read on route files to understand page structure
  - Count total pages to estimate team size
- **"Test everything"** — Combine codebase inspection with smart defaults

#### 3. Authentication
- **No auth needed** — Public-only testing
- **Credentials provided** — User gives email/password pairs and role descriptions
- **Storage state file** — User provides a `storage-state.json` path (from a previous `npx playwright codegen --save-storage` session)

For each auth role (e.g., admin, regular user, premium user), gather separate credentials
or storage state. Each role may need its own agent or agent set.

#### 4. Scope & Focus
Ask what matters most — this determines team composition:

- Functional testing (do features work?)
- UX / design audit (does it look right?)
- Brand compliance (does it match guidelines?)
- Accessibility (WCAG compliance)
- Mobile / responsive (breakpoint testing)
- Performance perception (loading states, transitions)
- Automated test generation (produce .spec.ts files)

#### 5. Project-Specific Context
- **Brand guidelines file** — Path to brand docs if UX/brand audit is needed
- **Design system** — CSS tokens file, Tailwind config, etc.
- **Known issues to skip** — So agents don't re-report known bugs
- **Generated code paths to ignore** — e.g., `src/api/generated/`

### Discovery Shortcuts

If the user says "just test it" or gives minimal info, auto-discover using Claude Code tools:

```
# Detect framework
Read package.json → check for next, vite, remix, svelte, astro

# Find route structure (Next.js App Router example)
Glob("src/app/**/page.tsx") → list all pages

# Count pages to estimate scope
Count results from Glob

# Check for auth patterns
Grep("middleware|getServerSession|useSession|cookies\\(\\)", path: "src/", glob: "*.ts")

# Find existing test files
Glob("**/*.spec.ts") or Glob("**/*.test.ts")
```

---

## Phase 2: Team Assembly

Based on interview answers, select agents from the role catalog and assign browser instances.

### Principles

1. **One browser per browser-using agent** — Never share Playwright instances between agents.
   This prevents the #1 source of false positives: one agent's navigation disrupting another's.
2. **Not all agents need browsers** — Code-level analysts (Grep, Read) don't need Playwright.
3. **QA Lead never uses a browser** — It coordinates, collects, and synthesizes only.
4. **Team size scales with scope** — 2 agents for a 5-page app, 4+ for a 30-page platform.
5. **Assign skills to agents** — Each agent should invoke relevant skills based on its role.
   See the role catalog for skill assignments.

### Team Composition Logic

```
IF scope includes functional testing:
  ADD functional-qa agent(s) — 1 per major app section (admin, user, public)
  ASSIGN browser: playwright-qa-{N}

IF scope includes UX / brand audit:
  ADD ux-analyst agent (code-level, no browser needed for Grep/Read work)
  OPTIONALLY ADD ux-browser agent if visual screenshots needed
  ASSIGN skills: ui-ux-pro-max, web-design-guidelines, tailwind-design-system

IF scope includes mobile / responsive:
  ADD mobile-qa agent with specific viewport config
  ASSIGN browser: playwright-qa-{N} (configured with mobile viewport)

IF scope includes accessibility:
  ADD accessibility-qa agent
  ASSIGN browser: playwright-qa-{N}
  Focus: keyboard nav, ARIA, contrast, screen reader semantics

IF scope includes automated test generation:
  ADD test-writer agent (no browser — writes code, runs via CLI)
  ASSIGN skill: playwright-cli

ALWAYS ADD qa-lead as coordinator (no browser)
```

### Browser Instance Configuration

For each browser-using agent, configure an isolated Playwright MCP server.
See `references/playwright-mcp-setup.md` for the full `.mcp.json` template, viewport
variants, storage state setup, and troubleshooting.

### Permissions Setup

See `references/playwright-mcp-setup.md` for the permissions configuration needed
in `.claude/settings.json` to avoid approval prompts during testing.

---

## Phase 3: Task Assignment & Execution

### QA Lead Responsibilities

The QA Lead agent:

1. **Creates tasks** for each agent with clear scope boundaries
2. **Assigns page ownership** — No two browser agents visit the same page simultaneously.
   This is the browser equivalent of file ownership in code teams.
3. **Sequences dependencies** — e.g., if an agent must create test users before others can test
   authenticated flows, that agent starts first.
4. **Monitors progress** via `team-status`
5. **Collects findings** from all agents when they complete
6. **Runs validation pass** before finalizing (see Phase 4)
7. **Produces final report** with consolidated, deduplicated, prioritized findings

### Agent Workflow (per browser-using agent)

Each agent follows this protocol for every page it tests:

```
1. Navigate to the page
2. browser_snapshot → understand page structure (accessibility tree)
3. browser_take_screenshot → capture visual evidence (save with descriptive filename)
4. browser_console_messages (level: "error") → check for JS errors
5. Interact with all interactive elements (forms, buttons, links, dropdowns)
6. Verify expected behavior
7. Document any issues found with:
   - Severity (P0-P3)
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshot filename as evidence
   - Console errors if relevant
8. Move to next page
```

### Agent Communication Protocol

Agents communicate with qa-lead via the agent-teams messaging system:

- **Finding report**: Agent sends structured finding as it discovers issues (don't wait until end)
- **Blocker alert**: If an agent is blocked (e.g., can't login), notify qa-lead immediately
- **Completion signal**: Agent reports when all assigned tasks are done
- **Credential relay**: If one agent creates test accounts, send credentials to qa-lead for distribution

### Skill Invocation

Each agent should invoke relevant skills based on its role. Include skill invocation
instructions in the agent's prompt:

```
# Example: UX analyst agent prompt excerpt
Invoke these skills as needed during your audit:
- Skill(ui-ux-pro-max) — for design quality evaluation
- Skill(web-design-guidelines) — for Web Interface Guidelines compliance
- Skill(tailwind-design-system) — for design system consistency
- Skill(ux-researcher-designer) — for UX research frameworks
```

```
# Example: Test writer agent prompt excerpt
Invoke these skills for test generation:
- Skill(playwright-cli) — for Playwright CLI patterns and test structure
- Skill(vercel-react-best-practices) — for understanding component patterns to test
```

---

## Phase 4: Validation & Report

### Cross-Reference Validation (CRITICAL)

Before finalizing the report, the QA Lead MUST perform a validation pass to catch
false positives. This is the most important quality gate.

**Check for testing artifacts vs real bugs:**

1. **Redirect inconsistency check**: If Agent A reports "page X redirects to page Y" and
   Agent B was navigating to page Y at the same time → likely a browser isolation failure,
   NOT a real bug. Flag as "Needs manual verification."

2. **Duplicate detection**: Two agents may find the same issue on different pages (e.g.,
   a global navigation bug). Deduplicate and credit both reporters.

3. **Environment vs application bugs**: Distinguish between:
   - App bugs (broken features, wrong behavior)
   - Environment issues (backend down, stale data, network timeout)
   - Testing artifacts (browser context bleed, race conditions in test setup)

4. **Severity calibration**: Review all P0/P1 issues critically. A P0 must be reproducible
   and block core functionality. If only one agent observed it, suggest retest.

### Report Production

Produce two outputs:

1. **`QA_REPORT.md`** — Human-readable consolidated report
2. **`qa-findings.json`** — Machine-parseable findings for automation

See `references/report-templates.md` for the exact templates to use.

#### Output Directory

All outputs for a QA session go in a single session directory under `docs/qa-testing-outputs/`.
The directory name should be a short, human-readable snake_case title describing the session.

**Naming convention:** `{scope}_{date}` or a descriptive title from the user.

Examples:
- `docs/qa-testing-outputs/full_qa_2026_02_16/`
- `docs/qa-testing-outputs/admin_panel_mobile_audit/`
- `docs/qa-testing-outputs/post_launch_regression/`

```
{project_root}/docs/qa-testing-outputs/{session_name}/
├── QA_REPORT.md              # Consolidated human-readable report
├── qa-findings.json           # Machine-parseable findings
├── screenshots/               # Evidence screenshots organized by area
└── traces/                    # Playwright traces per agent
    ├── agent-1/
    ├── agent-2/
    └── agent-3/
```

Ask the user for a session name, or auto-generate one from the scope and date.

### Post-Report Actions

After delivering the report, offer the user:

1. **Generate automated tests** for bugs found (invoke `playwright-cli` skill)
2. **Re-test specific failures** with a single focused agent
3. **Cross-browser testing** (re-run with `--browser firefox` or `--browser webkit`)
4. **Create fix tasks** from findings (if project management tools are connected)

---

## Mode: Automated Test Generation

When the user requests automated test generation (either from interview or post-report):

1. Spawn a `test-writer` agent (no browser needed — it writes code)
2. The agent uses `Skill(playwright-cli)` for patterns and best practices
3. For each finding or user flow, generate a `.spec.ts` file in `tests/qa/`
4. Run the tests with `npx playwright test tests/qa/ --workers=3 --reporter=html`
5. Review results and iterate on failing tests
6. Final output: committed test files that can run in CI

This mode can run independently or as a follow-up to exploratory QA.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Sharing browser instances between agents | Each agent gets its own `playwright-qa-{N}` MCP server. See `references/playwright-mcp-setup.md`. |
| Skipping the validation pass (Phase 4) | QA Lead MUST cross-reference findings before finalizing. Unvalidated reports contain false positives. |
| Not assigning page ownership | Two agents visiting the same page causes interference. QA Lead assigns exclusive page sets. |
| Reporting testing artifacts as real bugs | Redirect issues when agents share pages are almost always test artifacts, not app bugs. |
| Spawning too many agents for a small app | 2-3 routes? Use 1-2 agents max. Multi-agent overhead only pays off at 5+ pages. |
| Agents waiting until end to report | Report findings as discovered. Waiting causes lost context and delays blocker resolution. |
| Not setting up permissions in settings.json | Without wildcard MCP permissions, agents get interrupted by approval prompts constantly. |

---

## Quick Start Examples

**Minimal invocation:**
```
/qa-testing
> Base URL: http://localhost:3000
> Scope: Test everything
> Auth: admin@example.com / password123
```

**Targeted invocation:**
```
/qa-testing
> Base URL: https://staging.myapp.com
> Focus: Mobile UX + accessibility only
> Auth: storage-state at ./auth/user.json
> Brand guidelines: ./docs/BRAND.md
```

**Test generation only:**
```
/qa-testing --mode=generate-tests
> Base URL: http://localhost:3000
> User stories: ./docs/USER_STORIES.md
> Auth: test@example.com / test123
```

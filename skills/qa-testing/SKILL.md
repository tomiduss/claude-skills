---
name: qa-testing
description: >
  Use when the user explicitly requests a multi-agent QA team to test a running
  web application in parallel across roles (functional, mobile, accessibility,
  UX, test generation). Triggers: /qa-testing, "QA team", "parallel browser
  testing". Do NOT activate for single-agent browser testing, writing Playwright
  specs alone, or casual "test my app" requests.
---

# QA Testing — Multi-Agent Browser Testing Orchestrator

Coordinate a team of specialized QA subagents, each driving an isolated browser
session, to test a live web application in parallel. Produces a consolidated
report with prioritized findings, screenshots as evidence, and optionally
generates reusable Playwright test specs.

This skill is **an orchestration wrapper** — it does not teach agents how to
drive a browser. That's the job of the `playwright-cli` skill, which every
browser-using tester invokes.

## Prerequisites

- **`playwright-cli` skill** — hard dependency. If missing, ask the user to run
  `playwright-cli install --skills` from the project root.
- **Target application is running.** This skill does not manage dev servers.
- **`Agent` tool available** to dispatch testers as subagents.

## When to Use

- User explicitly asks for a **QA team** or **multi-agent testing**
- User invokes `/qa-testing`
- User wants **parallel browser testing** across multiple app areas
- User needs a **comprehensive QA audit** (functional + UX + accessibility + mobile)

## When NOT to Use

- **Single test or quick check** — use `playwright-cli` skill directly
- **Writing Playwright test specs alone** — use `playwright-cli` skill directly
- **Code review or static analysis** — wrong tool
- **Unit/integration testing** — use standard test runners
- **Backend/API-only testing** — no browser needed
- **App has < 3 routes** — multi-agent overhead isn't worth it

## Core Principles

1. **One session per browser-using tester.** Every tester gets a dedicated
   `-s=qa-{N}` namespace in `playwright-cli`. Sharing sessions causes the #1
   source of false positives: one agent's navigation disrupts another's.
2. **Page ownership is exclusive.** Two testers must never visit the same page
   at the same time. The lead enforces this at composition time.
3. **The lead never touches a browser.** It interviews, composes the team,
   spawns testers, collects return values, validates, and writes the report.
4. **Validation pass before report.** The lead cross-references findings to
   catch testing artifacts before publishing.
5. **Testers delegate browser mechanics to `playwright-cli`.** This skill
   documents *when* and *why*; the CLI skill documents *how*.
6. **Model split with explicit `model:` parameter.** The main context (the
   lead) runs on opus; every tester `Agent` spawn sets `model: "sonnet"`
   explicitly. Never rely on inheritance — a test run proved it silently
   keeps testers on whatever the parent was running.

## Architecture

```
Main context (opus)  ◄── this IS the lead. Interviews, composes,
     │                     spawns, collects, validates, reports.
     │
     ├── Agent(qa-1, sonnet) ──► browser session qa-1 ──► findings
     ├── Agent(qa-2, sonnet) ──► browser session qa-2 ──► findings
     └── Agent(qa-3, sonnet) ──► browser session qa-3 ──► findings
                                 (parallel; block until all return)

          filesystem as shared state:
          - auth/*.json      (state-save files from auth setup)
          - screenshots/...  (evidence written by testers)
          - findings aggregated from return values at end
```

**There is no separate `qa-lead` subagent.** The main context plays the lead
directly. **There is no mid-run messaging between testers.** Coordination
happens through (a) the filesystem for shared artifacts and (b) structured
`Agent` return values at the end of each tester's run. This skill deliberately
uses plain subagents instead of the Claude Code agent-teams feature — QA
testers audit disjoint slices of the app and never need to debate or relay
findings mid-flight, so the team framework's coordination machinery is
overhead without payoff here.

## Workflow

```
Phase 1: Interview       → gather scope, auth, focus
Phase 2: Team Assembly   → pick roles, assign sessions & pages, spawn
Phase 3: Execution       → testers return findings; lead collects
Phase 4: Validation      → cross-reference, deduplicate, produce report
```

---

## Phase 1: Interview & Discovery

Run an interactive interview before anything else. **Do not skip it** —
missing information causes wasted tester runs and false positives.

**Read `references/interview.md`** for the question schema, required
information, codebase discovery patterns, and interview shortcuts.

If the user says "just test it" or "test everything", run the codebase
discovery step from that reference first and use the result to propose a
scope for confirmation before continuing to Phase 2.

---

## Phase 2: Team Assembly

Based on the interview, compose the team, assign sessions and pages, then
spawn.

**Before assembling, read:**
- `references/session-isolation.md` — session naming, viewport conventions,
  auth state flow, output directory structure
- `references/role-catalog.md` — role definitions and the **Base Tester
  Prompt** every browser tester extends

### Composition

- **Lead**: the main context (opus). No separate spawn.
- **Functional testing**: one `functional-qa` per major section (admin,
  user, public) — each with its own `-s=qa-{N}` session
- **Admin panel**: `admin-qa` (functional-qa variant for CRUD workflows)
- **UX / brand audit**: `ux-analyst` (code-level primary, browser optional)
- **Mobile / responsive**: `mobile-qa` with mobile viewport
- **Accessibility**: `accessibility-qa` (keyboard nav + snapshot tree)
- **Automated test generation**: `test-writer` (no browser — writes code)
- **Optional**: `performance-qa`, `security-qa`

Every tester runs on **sonnet**. See `role-catalog.md` for per-role prompts.

### Team Sizing

| App size | Browser testers |
|---|---|
| < 3 routes | Don't use this skill — test manually |
| 3–10 routes | 1–2 |
| 10–30 routes | 3–4 |
| 30+ routes | 4–6 (more causes coordination drag) |

### Spawning

For every tester, issue a separate `Agent` tool call **in the same turn** so
they run in parallel. The `model:` parameter is **required** — never omit it
and never rely on inheritance.

```
Agent({
  description: "qa-1 admin polls tester",
  subagent_type: "general-purpose",
  model: "sonnet",                      // REQUIRED — never inherit
  name: "qa-1-admin",
  prompt: "<Base Tester Prompt + role-specific additions from
           references/role-catalog.md, with {N}=1, assigned pages,
           auth instructions, and session_dir interpolated>"
})
```

**Spawn order:**
1. If auth setup is needed, run **that single Agent call first and
   sequentially**, wait for its return, and capture the state file path from
   its output.
2. Bake that state file path into every tester prompt in the batch.
3. Spawn the full tester batch in one parallel turn.
4. Block until all testers return.

The main context can do other work (e.g., prepare the report skeleton) while
the batch runs, but the next phase depends on all return values.

---

## Phase 3: Execution

### Lead Responsibilities

1. Compose each tester's prompt from the Base Tester Prompt + role additions
2. Assign explicit page ownership to each tester in its prompt
3. Spawn auth setup sequentially if needed; then spawn the tester batch
4. Wait for all testers to return
5. Parse return values into a unified findings collection
6. Run the Phase 4 validation pass
7. Write the final report

### Per-Tester Workflow

Every browser-using tester follows this protocol for each assigned page:

1. Navigate to the page (using its `-s=qa-{N}` session)
2. Take a snapshot to understand structure
3. Capture a screenshot as visual evidence
4. Check console for errors
5. Interact with all interactive elements
6. Verify expected behavior
7. Record each issue (severity, reproduction, expected vs actual, evidence)
8. Move to the next assigned page

**Exact commands live in the `playwright-cli` skill.** Every tester invokes
`Skill(playwright-cli)` at startup and prefixes every command with its
session flag (e.g., `playwright-cli -s=qa-2 goto ...`).

### Coordination Mechanics

This skill uses **filesystem + Agent return values** for coordination — not
a message bus. Plan Phase 3 around this constraint:

- **Credential handoff**: auth-setup runs sequentially first and returns
  the state file path. The lead bakes that path into each tester's prompt
  before spawning the batch. No mid-run handoff.
- **Findings**: testers return them as structured output at the end of
  their run. The lead parses all return values together.
- **Blockers**: testers return early with a `blocker:` note in their
  output. The lead decides whether to spawn a follow-up Agent call after
  the batch completes.
- **Observability**: no live visibility. The main context only sees tester
  output when the Agent call returns. For long runs, prefer fewer testers
  with larger page batches to reduce wall-clock uncertainty.
- **Page ownership**: fully decided before spawning. You cannot rebalance
  mid-run. If a tester finishes early, its capacity is lost for this batch.

---

## Phase 4: Validation & Report

### Cross-Reference Validation (CRITICAL)

Before finalizing, the lead **must** perform a validation pass. This is the
primary quality gate.

1. **Redirect inconsistency check** — if tester A reports "page X redirects
   to page Y" and tester B was navigating to page Y around the same wall
   clock, flag as possible session isolation failure (not a real bug); mark
   for manual retest.
2. **Duplicate detection** — two testers may find the same global issue on
   different pages. Deduplicate and credit both reporters.
3. **Environment vs app bugs** — distinguish app bugs from environment
   issues (backend down, stale data) and testing artifacts.
4. **Severity calibration** — review every P0/P1 critically. A P0 must be
   reproducible. Single-observer P0s get flagged for retest.

### Report Production

Produce two outputs:

1. `QA_REPORT.md` — human-readable consolidated report
2. `qa-findings.json` — machine-parseable for automation

**Read `references/report-templates.md` for the exact templates.**

### Output Directory

```
docs/qa-testing-outputs/{YYYY_MM_DD}_{scope}/
├── QA_REPORT.md
├── qa-findings.json
├── auth/                 ← state-save files (ephemeral)
├── screenshots/          ← evidence, grouped by area
└── traces/qa-1, qa-2, …
```

Ask the user for a session name, or auto-generate from scope + date.

### Post-Report Actions

After delivering, offer:
1. Generate automated tests from findings (spawn `test-writer`)
2. Re-test specific failures with a single focused Agent call
3. Cross-browser re-run (`playwright-cli open --browser=firefox`)
4. Create fix tasks from findings (if PM tools connected)

---

## Mode: Automated Test Generation

Spawn one `test-writer` agent (no browser). See its full prompt and
workflow in `references/role-catalog.md` under `test-writer`. Feed it the
findings or user stories and it produces `.spec.ts` files under
`tests/qa/`. This mode runs independently or as a follow-up to exploratory
QA.

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| Sharing a session namespace across testers | Every tester gets its own `qa-{N}`. See `session-isolation.md`. |
| Skipping Phase 4 validation | Unvalidated reports contain false positives. The cross-reference pass is the primary quality gate. |
| Not assigning exclusive page ownership | Two testers on the same page → interference that looks like bugs. |
| Reporting testing artifacts as real bugs | "Random redirects" + overlapping sessions = artifact, not bug. |
| Spawning too many testers for a small app | < 3 routes? Don't use this skill. < 10? Max 2 browser testers. |
| Duplicating `playwright-cli` command docs in this skill | This skill is orchestration-only. Delegate mechanics to the dependency. |
| Omitting `model:` on `Agent` spawns (inheritance happens silently) | The `model:` parameter is **required** on every tester spawn. See Phase 2. |
| Spawning a separate `qa-lead` subagent | The main context IS the lead. There is no separate spawn. |
| Expecting mid-run communication between testers | Coordination is through filesystem and return values only. Plan Phase 3 around this. |
| Rebalancing page ownership after spawning the batch | Can't happen — there's no mid-run control plane. Rebalance on the next spawn. |

---

## Quick Start Examples

**Minimal invocation**
```
/qa-testing
> Base URL: http://localhost:3000
> Scope: Test everything
> Auth: admin@example.com / password123
```

**Targeted audit**
```
/qa-testing
> Base URL: https://staging.myapp.com
> Focus: Mobile UX + accessibility
> Auth: storage-state at ./qa-config/user.json
> Brand guidelines: ./docs/BRAND.md
```

**Test generation only**
```
/qa-testing --mode=generate-tests
> Base URL: http://localhost:3000
> User stories: ./docs/USER_STORIES.md
> Auth: test@example.com / test123
```

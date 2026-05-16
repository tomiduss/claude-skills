# Session Isolation — Multi-Agent Conventions for `playwright-cli`

This reference documents **the QA team conventions layered on top of the
`playwright-cli` skill** — session naming, viewport rules, authentication
state handoff, and output directory structure.

**All browser command syntax lives in the `playwright-cli` skill.** This
document assumes you have already invoked `Skill(playwright-cli)`. If you
haven't, stop reading and invoke it first.

## Contents

- [Why Isolation Matters](#why-isolation-matters)
- [Session Naming Convention](#session-naming-convention) — `qa-{N}` scheme
- [Viewport Conventions](#viewport-conventions) — desktop, mobile, tablet sizes
- [Authentication State Flow](#authentication-state-flow) — patterns A, B, C
- [Output Directory Structure](#output-directory-structure) — what goes where
- [Session Lifecycle](#session-lifecycle) — start, end, cleanup
- [Troubleshooting](#troubleshooting) — common failures and fixes
- [What this document does NOT cover](#what-this-document-does-not-cover)

---

## Why Isolation Matters

When multiple agents share a single browser session, one agent's navigation
disrupts another's. This manifests as "random redirects" that look like bugs
but are really coordination failures. **This is the #1 source of wasted QA time.**

`playwright-cli`'s `-s=name` flag gives each session its own cookies, storage,
and navigation history. Our convention is: **every browser-using agent gets
its own session namespace.** No exceptions.

---

## Session Naming Convention

Session names must be **unique per QA run** to prevent collision with stale
sessions from a prior run. The lead generates a 6-character hex **run ID**
at the start of Phase 2 and bakes it into every session name:

```bash
# Generate run ID (lead does this once at Phase 2 start)
RUN_ID=$(openssl rand -hex 3)   # e.g., "a3f9e2"
```

| Session name | Used by | Purpose |
|---|---|---|
| `qa-{runId}-1` | First browser-using tester | Per-tester isolation |
| `qa-{runId}-2` | Second browser-using tester | Per-tester isolation |
| `qa-{runId}-{N}` | Tester `N` | Per-tester isolation |
| `qa-{runId}-auth` | One-shot login session | Auth state generation (see below) |

Example with `runId = a3f9e2`:

```
playwright-cli -s=qa-a3f9e2-2 goto https://app.example.com/admin
playwright-cli -s=qa-a3f9e2-2 snapshot
playwright-cli -s=qa-a3f9e2-2 click e5
```

**Agents never share sessions and never use the unnamed default session** — the
unnamed session is shared across processes and will cause interference.

### Why unique IDs?

Without a run ID, session `qa-1` from yesterday's crashed run might still be
alive as an unclosed browser process. A new run using the same name reconnects
to the stale browser with old cookies, navigation history, and auth state.
The run ID makes accidental reuse impossible.

### Pre-run hygiene

The lead should check for stale sessions before spawning testers:

```
playwright-cli list
```

If any `qa-*` sessions appear, warn the user and offer cleanup:

```
playwright-cli close-all        # if only QA sessions are expected
# or individually:
playwright-cli -s=qa-<old>-1 close
playwright-cli -s=qa-<old>-2 close
```

---

## Viewport Conventions

Viewports are set per-session using `playwright-cli -s=qa-{N} resize W H` after
the first `open` or `goto`.

| Role | Viewport | Command |
|---|---|---|
| Desktop (default) | 1280 × 720 | `playwright-cli -s=qa-{N} resize 1280 720` |
| Large desktop | 1920 × 1080 | `playwright-cli -s=qa-{N} resize 1920 1080` |
| Tablet | 768 × 1024 | `playwright-cli -s=qa-{N} resize 768 1024` |
| Mobile | 375 × 812 | `playwright-cli -s=qa-{N} resize 375 812` |
| Small mobile | 320 × 568 | `playwright-cli -s=qa-{N} resize 320 568` |

Mobile-qa agents resize to 375×812 at session start. Responsive testing loops
through multiple sizes within a single session.

---

## Config File & Output Directory

The lead writes a per-run config file **before** spawning any tester. This
ensures all automatic output (snapshots, console logs, network logs, traces)
lands in the session directory without per-command path arguments.

### Setup (lead does this in Phase 2, after creating the session dir)

```bash
# 1. Create the session directory structure
SESSION_DIR="{project_root}/docs/qa-testing-outputs/{YYYY_MM_DD}_{scope}_{runId}"
mkdir -p "$SESSION_DIR"/{auth,screenshots,traces}

# 2. Write the config file
cat > "$SESSION_DIR/cli.config.json" << EOF
{
  "outputDir": "$SESSION_DIR",
  "outputMode": "file"
}
EOF
```

### What each setting does

| Setting | Effect |
|---|---|
| `outputDir` | Base directory for all automatic output files (snapshots, console logs, network logs, traces) |
| `outputMode: "file"` | Forces console messages and network logs to be written as files (default is stdout). Free forensic evidence on every page visit. |

### How testers use it

Every tester opens its session with `--config`:

```
playwright-cli -s=qa-{runId}-{N} open {base_url} --config={SESSION_DIR}/cli.config.json
```

After opening, the config applies to all subsequent commands in that session.
Testers do **not** need to pass `--config` on every command — only on `open`.

### Path rules for screenshots

**Critical**: `outputDir` applies to automatic files (snapshots, logs, traces)
but does **NOT** apply to `screenshot --filename`. Screenshot filenames resolve
against the agent's CWD, not outputDir.

**Rule: always use absolute paths for screenshots.**

```
playwright-cli -s=qa-{runId}-2 screenshot --filename={SESSION_DIR}/screenshots/admin/dashboard.png
```

**The target directory must pre-exist** — `playwright-cli` does not create
intermediate directories. The lead must `mkdir -p` the expected screenshot
subdirectories when creating the session dir, or the tester must mkdir before
its first screenshot in a new area.

### What lands where

After a run, the session directory looks like this:

```
{SESSION_DIR}/
├── cli.config.json                      ← config file (written by lead)
├── page-2026-04-12T14-*.yml             ← auto snapshots (from outputDir)
├── console-2026-04-12T14-*.log          ← auto console logs (from outputMode)
├── auth/                                ← state-save files
├── screenshots/                         ← evidence (from --filename absolute paths)
│   ├── admin/
│   │   └── dashboard-kpi-missing.png
│   └── user-flows/
│       └── registro-form-broken.png
└── traces/                              ← from tracing-start/stop
```

---

## Authentication State Flow

### Pattern A — credentials in hand

The QA lead has login credentials. One agent handles auth setup before others
start testing authenticated pages:

1. Lead spawns one-shot `auth-setup` task:
   ```
   playwright-cli -s=qa-{runId}-auth open {login_url}
   playwright-cli -s=qa-{runId}-auth snapshot
   playwright-cli -s=qa-{runId}-auth fill e{email_ref} "admin@example.com"
   playwright-cli -s=qa-{runId}-auth fill e{pw_ref} "password123"
   playwright-cli -s=qa-{runId}-auth click e{submit_ref}
   # verify successful login via snapshot
   playwright-cli -s=qa-{runId}-auth state-save {session_dir}/auth/admin-state.json
   playwright-cli -s=qa-{runId}-auth close
   ```
2. Lead messages downstream agents: "auth state saved at
   `{session_dir}/auth/admin-state.json`"
3. Each downstream agent loads the state into its own session **before**
   navigating anywhere:
   ```
   playwright-cli -s=qa-{runId}-2 state-load {session_dir}/auth/admin-state.json
   playwright-cli -s=qa-{runId}-2 goto {base_url}/admin
   ```

### Pattern B — pre-existing storage state

The user provides a `storage-state.json` from a prior `playwright codegen` run
or similar. Skip Pattern A's setup step; distribute the path directly to all
authenticated-pages agents.

### Pattern C — per-role credentials

Multiple auth roles (admin, user, premium). Run auth setup once per role:

```
{session_dir}/auth/admin-state.json
{session_dir}/auth/user-state.json
{session_dir}/auth/premium-state.json
```

Assign each agent the state file matching its role.

### When state expires

Sessions expire on the application's cookie/token TTL. If an agent starts
getting redirected to `/login`, it should signal the lead, which re-runs the
auth setup and redistributes the new state file.

---

## Output Directory Structure

One session directory per QA run. Session name is short snake_case, date-prefixed
for chronological sorting:

```
{project_root}/docs/qa-testing-outputs/{YYYY_MM_DD}_{scope}/
├── QA_REPORT.md
├── qa-findings.json
├── auth/                          ← state-save files (ephemeral)
│   ├── admin-state.json
│   └── user-state.json
├── screenshots/                   ← screenshot evidence, grouped by area
│   ├── admin/
│   ├── user-flows/
│   └── mobile/
└── traces/                        ← playwright-cli tracing output
    ├── qa-{id}-1/
    ├── qa-{id}-2/
    └── qa-{id}-3/
```

Examples of full directory names:
- `docs/qa-testing-outputs/2026_04_09_full_qa/`
- `docs/qa-testing-outputs/2026_04_09_admin_panel_mobile_audit/`
- `docs/qa-testing-outputs/2026_04_09_post_launch_regression/`

### Screenshot naming

Agents save screenshots with descriptive names relative to the session's
`screenshots/` directory:

```
playwright-cli -s=qa-{runId}-2 screenshot --filename={session_dir}/screenshots/admin/dashboard-kpi-missing.png
```

Pattern: `{area}/{page}-{issue-description}.png`

### Tracing

Agents that need traces wrap the session in `tracing-start` / `tracing-stop`.
The trace output path is set by the `playwright-cli` skill — the lead should
tell the agent to move the resulting trace file into
`{session_dir}/traces/qa-{N}/` before closing the session.

---

## Session Lifecycle

### Start of a run

The lead does not start sessions itself. Each agent issues its first
`playwright-cli -s=qa-{N} open` when it begins work. Sessions persist across
commands until explicitly closed.

### End of a run

Every agent **must** close its session when finished:

```
playwright-cli -s=qa-{runId}-2 close
```

If an agent crashes or forgets, the lead (or the user) can sweep leftover
sessions after the run:

```
playwright-cli list            # see what's still alive
playwright-cli close-all       # graceful shutdown of all sessions
playwright-cli kill-all        # force-kill if close-all fails
```

**Always clean up between runs.** Stale sessions from a prior run will pollute
the next one with leftover cookies/state.

---

## Troubleshooting

### "Random redirects" in a report

Another agent is using the same session name, or an agent is using the unnamed
default session. Verify every command in that agent's transcript has its
`-s=qa-{N}` flag. This is always a configuration error, not an app bug.

### Session list shows unexpected names

Stale sessions from a prior QA run. Run `playwright-cli close-all` between
runs, or `kill-all` if close-all hangs.

### Storage state file missing or empty

The auth setup agent either failed to verify its login, or wrote to the wrong
path. Check its transcript for the `snapshot` after login — should show the
authenticated UI, not the login form.

### Browser fails to launch

Managed by `playwright-cli`. See its skill for install troubleshooting.

### Agent can't see elements it expects

Between commands, the page may have re-rendered and element refs (`e5`, `e12`)
changed. Re-issue `snapshot` before every interaction block. The element IDs
from an old snapshot are not stable across navigations or significant DOM
updates.

---

## What this document does NOT cover

Every `playwright-cli` command (syntax, flags, semantics) lives in the
`playwright-cli` skill. If you need to know how `state-save` or `tracing-start`
actually works, invoke that skill. This document only layers QA team
conventions on top.

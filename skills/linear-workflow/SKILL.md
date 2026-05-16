---
name: linear-workflow
description: >
  Manage Linear issues for the Zona Cóndores team (ZON). Use PROACTIVELY whenever
  the user mentions a Linear issue ID (ZON-*), asks to create/update/query issues,
  references "linear" or "issue", or discusses task planning and work breakdown.
  Also trigger when the user wants to organize features across repos, create specs,
  or manage the Idea → Spec → Feature lifecycle. Uses Linear MCP tools (linear-server).
  Do NOT use for general git operations or code-only tasks that don't involve Linear.
---

# Linear Workflow

Manage Linear issues for the **Zona Cóndores** team using Linear MCP tools (`linear-server`).

## Quick Reference

| Key | Value |
|-----|-------|
| Team | Zona Cóndores |
| Team key | ZON |
| Workflow states | Triage → Backlog → Todo → In Progress → In Review → Done / Canceled |
| Language | Issue titles and descriptions in **Spanish** |

## Operations

### 1. Query an Issue

When the user references an issue ID (e.g., "ZON-34"):

1. Fetch with `mcp__linear-server__get_issue`, passing `includeRelations: true`
2. Present a compact summary:
   - **Title**, **status**, **priority**
   - **Labels** grouped by type (type label / scope labels / domain labels)
   - **Assignee**
   - **Description** (full text)
   - **Relations**: blocked by, blocks, related issues
   - **Branch name** (`gitBranchName`) if available
3. If the description references a spec or plan file, mention the path so the user can read it

If the user just wants a quick status, keep it to 2-3 lines. If they want details, show everything.

### 2. Create an Issue

Walk through these fields — skip what's obvious from context, ask for what's missing:

**a) Type label** (exactly one — read `references/conventions.md` § Labels for definitions):
- Feature, Improvement, Bug, Idea, Spec, Administrativa

**b) Scope labels** (one or more):
- Backend, Frontend, Mobile, Diseño, DevOps

**c) Domain label** (optional):
- Challenges, Pagos y Suscripciones, Integraciones, Comunicaciones, Sponsors, Usuario Final, Usuario Admin, AI Agent, Code Quality

**d) Title**: Concise, Spanish, starts with a verb.
- Single-repo: "Agregar campo has_challenge a MemberPollRead"
- Cross-repo: "Diseñar sistema de notificaciones (web + mobile)"

**e) Description**: Include what to do, which files/areas, acceptance criteria. Link spec files when they exist.

**f) Status**: Start at **Triage** or **Backlog** (max **Todo**). Never assign In Progress at creation.

**g) Priority**: Urgent / High / Normal / Low — ask if not obvious.

Create with `mcp__linear-server__save_issue`. After creation, report the issue ID and URL.

### 3. Update an Issue

Common patterns:

| Action | How |
|--------|-----|
| Status transition | `save_issue` with new `statusId` — use `list_issue_statuses` to get IDs |
| Add comment | `save_comment` — for progress, decisions, blockers |
| Add/change labels | `save_issue` with `labelIds` |
| Add relations | `save_issue` with relation fields (blockedBy, blocks) |
| Assign | `save_issue` with `assigneeId` |

When updating status, respect the workflow order. Don't skip states unless the user explicitly asks.

### 4. Feature Lifecycle

Read `references/conventions.md` § Feature Lifecycle for the full progression. The short version:

```
Idea → Spec issue → Spec doc produced → Implementation issues (with scope labels)
```

**When to create a Linear Project** (not just issues):
- Feature touches 2+ repositories
- Will need more than 5 implementation issues
- Has a timeline or milestone

Use `mcp__linear-server__save_project` for projects. Link child issues via relations.

### 5. Batch Operations

When the user asks to break down a feature or spec into issues:
1. Read the spec/plan document first
2. Propose the issue breakdown (titles + type + scope labels) before creating
3. Wait for user approval
4. Create all issues, then set up dependency relations between them
5. If a project was created, link all issues to it

## Branch Naming

Branches auto-link to Linear when they contain the issue ID:
- Format: `tomasdussaillant/zon-XX-description`
- Prefer pulling `gitBranchName` from the Linear issue metadata
- PRs target `develop` (or the repo's base branch)

## Per-Project Configuration

Each repo's `workflow.md` rule specifies:
- Which **scope label** to auto-apply (Backend, Frontend, etc.)
- The **base branch** for PRs
- Any repo-specific conventions

When creating issues from within a repo, auto-apply that repo's scope label unless the user specifies otherwise.

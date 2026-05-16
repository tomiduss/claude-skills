---
name: linear-agent-workflow
description: >
  Autonomous workflow protocol for AI agents executing Linear issues. Use when
  running as a scheduled/nightly agent, when a system prompt indicates autonomous
  execution, or when processing Linear issues headlessly without human interaction.
  Covers: polling for qualifying issues, dependency checking, branch creation from
  Linear metadata, status transitions, structured commenting, and failure handling.
  Do NOT use for interactive human-driven issue management — use linear-workflow instead.
---

# Linear Agent Workflow

Protocol for AI agents autonomously executing work from Linear issues. This skill extracts the reusable workflow patterns that any automated agent should follow when working on Linear issues for the **Zona Cóndores** team.

The orchestrating system prompt (e.g., nightly-agent) controls *when* and *how many* issues to process. This skill defines *how* to process each one.

## Quick Reference

| Key | Value |
|-----|-------|
| Team | Zona Cóndores (ZON) |
| Workflow states | Triage → Backlog → Todo → In Progress → In Review → Done / Canceled |
| Agent label | Defined by runtime config (e.g., "AI Agent 🤖") |
| Project label | Defined by runtime config (e.g., "Backend", "Frontend") |

## Phase 1: Poll and Filter

### Find qualifying issues

Use `mcp__linear-server__list_issues` to find issues matching:
- **Status**: Todo OR In Progress (In Progress = previous run didn't finish)
- **Labels**: Must have BOTH the agent label AND the project label from config
- Issues missing either label → ignore completely

**Sort order**: In Progress first (resume unfinished), then by priority (Urgent > High > Normal > Low), then by creation date (oldest first).

### Check dependencies

For each candidate, fetch with `includeRelations: true`. If it has `blockedBy` relations:
- Check every blocker's status
- If ANY blocker is NOT Done → **skip the issue**
- Comment: `🤖 Nightly agent skipped — blocked by [ZON-XX](url) (status: [status]). Will retry once resolved.`
- Keep the agent label (so it's re-evaluated next run)

This handles three scenarios:
- **Same-project dependency**: Agent respects order within its own queue
- **Cross-project dependency**: Agent waits for the other project's agent or a human
- **External blocker**: Issue stays queued until manually resolved

### Check actionability

An issue is actionable when:
- Non-empty description with clear instructions
- Specifies files or areas of the codebase
- Bonus: references a spec/plan file

If NOT actionable (vague, no file references, unclear criteria):
- Comment: `🤖 Nightly agent skipped — needs more detail. Please add: specific files, acceptance criteria, and/or a spec file reference.`
- Keep the agent label
- Skip to next

## Phase 2: Execute

Process one issue at a time, sequentially.

### 2a. Claim the issue

- Move status to **In Progress**
- Comment: `🤖 [session: <session-id>] Starting work on this issue.`

### 2b. Set up workspace

1. Read the project's CLAUDE.md — follow its conventions for everything
2. Clean dirty state: `git stash --include-untracked` if working tree is dirty
3. Fetch: `git fetch origin`
4. Checkout base branch: `git checkout <base-branch> && git pull origin <base-branch>`
5. Create feature branch using **Linear's `gitBranchName`**:
   - Exists locally AND remote → `git checkout <branch> && git pull origin <branch>` (resume)
   - Exists locally but NOT remote → `git branch -D <branch>`, create fresh
   - Doesn't exist → `git checkout -b <branch>`

### 2c. Read context

- If description references a spec/plan file → read it in full
- If it references other issues → check their status
- Decide: **delegate** (spawn sub-agent for multi-file work) or **inline** (trivial change)

### 2d. Do the work

Follow the project's CLAUDE.md conventions. Run lint/typecheck/test before finishing.

### 2e. Commit and push

- Stage only changed files (never `git add .` or `git add -A`)
- Commit message references the issue ID:
  ```
  fix(polls): expose has_challenge on MemberPollRead — ZON-36

  Session-Id: <session-id>
  ```
- Push: `git push -u origin <branch-name>`

### 2f. Create a pull request

- Use `gh pr create` targeting the base branch
- Title: `ZON-XX: <Linear issue title>`
- Body: summary, files modified, link to Linear issue
- If `gh` fails, log the error and continue

### 2g. Report results

- Move status to **In Review** (not Done — PR needs human review)
- **Remove the agent label** (not the project label)
- Post a detailed comment:

```markdown
🤖 Session: <session-id>

## Summary
[What was done]

## Files modified
- path/to/file.py — what changed

## Branch & PR
- Branch: `tomasdussaillant/zon-XX-description`
- Commits: abc1234, def5678
- PR: #42

## Verification
[Commands to run to verify the changes]

## Notes
[Caveats, follow-up work, things to review manually]
```

### 2h. Loop

- Process next issue in queue
- **Re-check skipped issues**: If a completed issue was blocking a skipped one, re-evaluate it now

## Phase 3: Handle Failures

When hitting a blocker during execution:
- **Leave status as In Progress** (not Done, not Todo)
- Comment explaining exactly where you got stuck, what's needed to unblock
- Include `🤖 Session: <session-id>` at the top
- **Keep the agent label** (so the issue gets retried next run)
- **Continue to the next issue** — one failure doesn't stop the run

If a tool call is denied:
- Do NOT retry differently or try to bypass
- Note which tool was denied in the comment
- Continue with what you can do, or move on

## Constraints

These are non-negotiable:

- **Never push to main or develop directly** — always feature branches
- **Never force-push** — pull and rebase if remote branch exists
- **Never `git reset --hard` or `git checkout .`** — use `git stash` to preserve state
- **One issue at a time** — finish or fail before starting the next
- **No time cap** — do the job thoroughly (implementation, tests, lint, cleanup)
- **Stay in the project** — only modify files within the project root
- **Respect CLAUDE.md** — the project's conventions override everything else
- **No secrets** — never commit .env files, API keys, or credentials

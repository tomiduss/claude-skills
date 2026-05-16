# Agent Commenting Conventions

Standard formats for Linear comments posted by automated agents.

## Comment Templates

### Claiming an issue
```
🤖 [session: <session-id>] Starting work on this issue.
```

### Skipped — blocked by dependency
```
🤖 Nightly agent skipped this issue — it is blocked by [ZON-XX](url) which is currently in [status]. Will retry once all blockers are resolved.
```

### Skipped — not actionable
```
🤖 Nightly agent skipped this issue — the description needs more detail before it can be executed autonomously. Please add: specific files to modify, acceptance criteria, and/or a reference to a spec file.
```

### Completed successfully
```markdown
🤖 Session: <session-id>

## Summary
[1-3 sentences: what was done]

## Files modified
- `path/to/file.py` — [what changed]
- `path/to/test.py` — [test coverage added]

## Branch & PR
- Branch: `tomasdussaillant/zon-XX-description`
- Commits: `abc1234`, `def5678`
- PR: #42 (or "PR creation failed: [reason]")

## Verification
```bash
pytest -k "test_name"        # Run specific tests
ruff check path/to/file.py   # Lint check
```

## Notes
[Caveats, follow-up work, things needing manual review — omit if none]
```

### Failed / blocked during execution
```markdown
🤖 Session: <session-id>

## Status: Blocked

## What was attempted
[What the agent tried to do]

## Where it got stuck
[Exact error, missing dependency, unclear requirement]

## What's needed to unblock
- [Specific action item 1]
- [Specific action item 2]

## Files modified (if any)
- `path/to/file.py` — [partial change, may need cleanup]
```

## Rules

- Always include the session ID — it links back to the agent's log for debugging
- Keep summaries factual and concise — no filler, no apologies
- File paths should be relative to the project root
- Commit hashes should be short form (7 chars)
- If the PR link is unavailable (gh failed), say so explicitly
- Verification commands should be copy-pasteable

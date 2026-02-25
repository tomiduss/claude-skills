# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is a **skills repository** — a collection of Claude Code agent skills (prompt-based tools) designed to be installed into projects. The long-term vision is a marketplace where skills can be discovered, versioned, and added to any project.

## Repository Structure

Each skill lives in its own top-level directory:

```
{skill-name}/
├── SKILL.md                # Main skill definition (frontmatter + instructions)
└── references/             # Supporting reference documents loaded by the skill
    ├── *.md
    └── ...
```

## Skill Anatomy

A skill is defined by a `SKILL.md` file with two parts:

1. **YAML frontmatter** — metadata that Claude Code uses to decide when to activate the skill:
   ```yaml
   ---
   name: skill-name
   description: >
     When to use this skill. Include trigger phrases and anti-patterns
     (when NOT to use). This text appears in the skill registry.
   ---
   ```

2. **Markdown body** — the full instructions Claude follows when the skill is invoked. Typically structured as phases (interview/discovery, execution, output).

### Reference Files

Skills can load additional context from `references/` using `Read` directives in the body (e.g., "Read `references/role-catalog.md` before assembling the team"). These break large skills into focused, reusable documents.

## Conventions

- **Skill directory names** use kebab-case matching the `name` field in frontmatter
- **Reference files** are markdown, named descriptively in kebab-case
- **Trigger phrases** in the description should include both positive triggers and explicit "when NOT to use" guidance to prevent false activations
- Skills should be self-contained — all context an agent needs must be in the SKILL.md and its references, not in external docs
- Skills that orchestrate multi-agent teams should define agent roles, communication protocols, and output formats in their references

## Writing Skills

When creating or modifying skills, use the `superpowers:writing-skills` skill which provides the full workflow for authoring, testing, and validating skills.

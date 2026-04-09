# Zona Cóndores — Linear Conventions

Reference document for issue taxonomy, naming, and lifecycle rules.

## Labels

### Type labels (exactly one per issue)

| Label | When to use |
|-------|-------------|
| **Feature** | New capability — often cross-concern (backend + frontend + mobile) |
| **Improvement** | Enhancement to an existing feature |
| **Bug** | Something broken in production or staging |
| **Idea** | Blue-sky future concept, no commitment yet |
| **Spec** | Task that produces a design doc, plan, or spec |
| **Administrativa** | Non-code ops (e.g., "set up Mercado Pago account", "sign contract") |

### Scope labels (one or more, as applicable)

| Label | Repo / area |
|-------|-------------|
| **Backend** | zona-condor (FastAPI) |
| **Frontend** | zonacondor-ui (Next.js) |
| **Mobile** | Mobile app |
| **Diseño** | UI/UX design work |
| **DevOps** | Infrastructure, deployment, CI/CD |

### Domain labels (optional, for filtering)

Challenges · Pagos y Suscripciones · Integraciones · Comunicaciones · Sponsors · Usuario Final · Usuario Admin · AI Agent · Code Quality

## Issue Titles

- Concise, in **Spanish**
- Start with a verb: *Crear, Definir, Investigar, Diseñar, Agregar, Corregir, Implementar*
- Cross-repo features include context: "Diseñar sistema de notificaciones (web + mobile)"
- Bug titles describe the symptom: "Corregir error de validación en formulario de pago"

## Issue Descriptions

- **Features/Improvements**: What to do, which files/areas, acceptance criteria, affected repos
- **Specs**: Reference output file path (e.g., `project-docs/specs/2026-04-01-notifications-spec.md`)
- **Bugs**: Steps to reproduce, expected vs actual behavior, environment
- **Ideas**: Context, motivation, rough scope — no implementation detail needed
- Link related docs from `project-docs/` when they exist

### Good description template (for actionable issues)

```markdown
## What to do
[Clear description of the change]

## Files / Areas
- path/to/file.py — what to change
- path/to/other.py — what to change

## Acceptance criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Existing tests pass

## References
- Spec: project-docs/specs/YYYY-MM-DD-name.md
- Related: ZON-XX
```

## Feature Lifecycle

```
Idea (label: Idea)
  → "Crear spec de alto nivel para [feature]" (label: Spec)
    → High-level spec produced in project-docs/specs/
      → If large (2+ repos, >5 issues):
          Create a Linear Project
          → Break into repo-specific issues (Feature + scope labels)
      → If small (1 repo, ≤5 issues):
          Create implementation issues directly
```

### Lifecycle rules

1. **Ideas stay loose** — don't over-specify. Just capture the concept and motivation.
2. **Specs produce documents** — the output is a file in `project-docs/specs/`. When complete, update the spec issue description with the file path.
3. **Implementation issues are concrete** — they have file paths, acceptance criteria, and a single scope label.
4. **Splitting**: When a large issue gets broken into smaller ones, mark the original as Done and reference the new issues in a comment.

### Dependencies

- Use Linear's **"blocked by" / "blocks"** relations
- Parent specs link to child implementation issues via relations
- In the spec description, list expected child issues

## Workflow States

| State | Meaning |
|-------|---------|
| Triage | Needs review — not yet prioritized |
| Backlog | Accepted, not scheduled |
| Todo | Ready to pick up — clear enough to start |
| In Progress | Actively being worked on |
| In Review | PR open, awaiting review |
| Done | Merged and deployed (or spec delivered) |
| Canceled | Won't do — add a comment explaining why |

### Rules

- Issues start at **Triage** or **Backlog** (max **Todo** for well-defined work)
- Only the person (or agent) picking up the work moves it to **In Progress**
- **In Review** means a PR exists and is linked
- Moving to **Done** means the work is verified, not just committed

## When to Create a Linear Project

- Feature touches **2+ repositories**
- Will require **more than 5 implementation issues**
- Has a **timeline or milestone** attached
- Examples: "Sistema de Notificaciones", "Family Plan", "Rewards v2"

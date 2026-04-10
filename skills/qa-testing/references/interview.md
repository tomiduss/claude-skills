# Interview & Discovery — QA Run Setup Questions

This reference contains the full interview schema used in Phase 1 of the
qa-testing skill. Use it during the initial interaction with the user to
gather everything needed before composing the team.

## Contents

- [Required Information](#required-information) — 5 question groups
- [Codebase Discovery](#codebase-discovery) — framework, routes, auth patterns
- [Interview Shortcuts](#interview-shortcuts) — common interaction patterns
- [Anti-patterns](#anti-patterns) — what to avoid

---

## Required Information

Gather all five sections before moving to Phase 2. If the user skips a
section, ask for it explicitly — **do not guess or proceed without it.**
Missing information here is the root cause of most wasted tester runs.

### 1. Application under test

- **Base URL** — e.g., `http://localhost:3000` or `https://staging.example.com`
- **Backend URL** (if separate) — e.g., `http://localhost:8090`
- **Framework** — auto-detect from `package.json` if available (Next.js,
  Vite, Remix, SvelteKit, Astro, etc.)

### 2. What to test

Determine scope. Pick one:

- **"I have user stories / test plan"** — user provides a document or
  describes flows verbally
- **"Inspect my codebase"** — auto-discover routes, pages, and components
  using the patterns in the next section
- **"Test everything"** — combine codebase inspection with smart defaults
  based on framework and detected auth patterns

### 3. Authentication

Per role (admin, regular user, premium user, etc.):

- **No auth needed** — public-only testing
- **Credentials provided** — user gives email/password pairs and role labels
- **Storage state file** — user provides a `storage-state.json` path (from a
  prior `playwright codegen --save-storage` session or similar)

For each auth role, gather separate credentials or state files. If multiple
roles are needed, plan to run an auth-setup agent per role sequentially
before the tester batch — see SKILL.md Phase 2 spawn order.

### 4. Scope & focus

Determines team composition:

- **Functional testing** — do features work?
- **UX / design audit** — does it look right?
- **Brand compliance** — does it match guidelines?
- **Accessibility** — WCAG 2.1 AA compliance
- **Mobile / responsive** — breakpoint testing
- **Performance perception** — loading states, transitions
- **Automated test generation** — produce `.spec.ts` files

Multiple focuses are fine and common. "Functional + accessibility + mobile"
is a typical audit scope.

### 5. Project-specific context

- **Brand guidelines file** — path to brand docs if UX/brand audit is selected
- **Design system** — CSS tokens file, Tailwind config, etc.
- **Known issues to skip** — so testers don't re-report known bugs
- **Generated code paths to ignore** — e.g., `src/api/generated/`
- **Session name** — short snake_case label for the output directory. If
  unclear, auto-generate from scope + date (e.g., `2026_04_10_full_qa`)

---

## Codebase Discovery

When the user says "inspect my codebase" or "just test it", run these
discovery steps before finalizing the interview. The output informs team
sizing, auth detection, and focus selection.

### Framework detection

```
Read package.json
```

Check `dependencies` for: `next`, `vite`, `@remix-run/`, `svelte`, `astro`.
This determines the routing convention used in the next step. If multiple
framework dependencies are present (e.g., a Vite app with a legacy
`next.config.js`), ask the user which one is authoritative — don't guess.

### Route enumeration

| Framework | Glob pattern |
|---|---|
| Next.js App Router | `src/app/**/page.tsx` and `app/**/page.tsx` |
| Next.js Pages Router | `src/pages/**/*.tsx` and `pages/**/*.tsx` |
| Vite / React Router | `src/routes/**/*.tsx` (convention-dependent) |
| Remix | `app/routes/**/*.tsx` |
| SvelteKit | `src/routes/**/+page.svelte` |
| Astro | `src/pages/**/*.astro` |

Run the appropriate `Glob` and count results. Use the route count to size
the team per the table in SKILL.md Phase 2.

### Auth pattern identification

```
Grep("middleware|getServerSession|useSession|cookies\\(\\)", path: "src/", glob: "*.{ts,tsx}")
```

If matches appear, the app has auth. Follow up: ask the user for
credentials or storage state. If no matches, proceed as a public-only run.

### Existing test coverage

```
Glob("**/*.spec.ts")
Glob("**/*.test.ts")
```

Note what's already tested so the team can focus on uncovered areas. If
the user has extensive existing tests, suggest test generation mode to
complement rather than duplicate.

---

## Interview Shortcuts

Common interaction patterns that short-circuit the full interview:

- **Minimal case** — user provides base URL, scope = "test everything",
  auth = credentials. Run codebase discovery, propose scope for
  confirmation, move to Phase 2.
- **Targeted case** — user provides base URL, specific focus (e.g.,
  "accessibility only"), and auth. Skip codebase discovery and compose a
  narrower team directly.
- **Re-run case** — user says "re-test the failures from last run". Read
  the prior `qa-findings.json`, identify failed page/test combinations,
  spawn a single focused tester with those as its assigned pages. No full
  team needed.
- **Test generation only** — user already has findings and wants automated
  tests. Skip team composition; spawn one `test-writer` agent directly.

---

## Anti-patterns

- **Do not spawn testers before the interview is complete.** Missing
  information (especially auth) causes testers to waste time on blocked
  pages. Every "half an hour lost to a login redirect" starts here.
- **Do not assume the framework.** Always check `package.json`. A
  Vite-based app in a repo with a leftover `next.config.js` from a
  migration will fool naïve detection.
- **Do not run discovery on `node_modules/` or generated directories.**
  Scope globs to the project's source directory. Generated files produce
  noise and distort the team sizing estimate.
- **Do not combine unrelated focuses into a single tester.** If the scope
  has functional + accessibility + mobile, spawn distinct specialists, not
  one generalist. Specialists produce better findings because their
  prompt checklist is role-specific.

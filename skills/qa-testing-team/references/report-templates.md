# Report Templates — QA Testing Output Formats

Two report formats are produced: a human-readable markdown report and a
machine-parseable JSON findings file.

---

## QA_REPORT.md Template

```markdown
# QA Report — {App Name}

**Date:** {YYYY-MM-DD}
**Environment:** {base_url} ({additional_services_if_any})
**Branch:** {git_branch}
**QA Team:** {agent_names_comma_separated}
**Coordinator:** qa-lead

---

## Executive Summary

{2-3 sentence overview: total issues found, critical blockers, overall assessment}

**Key Metrics:**
- **{N} Critical (P0)** — {brief description}
- **{N} High (P1)** — {brief description}
- **{N} Medium (P2)** — {brief description}
- **{N} Low (P3)** — {brief description}
- **Test Coverage** — {pages_tested}/{total_pages} pages ({percentage}%)

**Production Readiness:** {READY | NOT READY — {reason}}

---

## Critical Issues (P0)

### {N}. {Issue Title}
**Severity:** Critical (P0) — {BLOCKER if applicable}
**Page:** `{route}`
**Reporter:** {agent_name}

**Description:**
{Clear description of the problem}

**Impact:**
{Business/user impact}

**Steps to Reproduce:**
1. {step}
2. {step}
3. {step}

**Expected:** {what should happen}
**Actual:** {what actually happens}

**Evidence:** {screenshot_filename}, {console_error_if_relevant}

**Recommendation:** {suggested fix approach}

---

{Repeat for each P0 issue}

## High Issues (P1)

{Same structure as P0}

## Medium Issues (P2)

{Same structure. Can be more concise — skip Steps to Reproduce
if the issue is self-evident from the description.}

## Low Issues (P3)

{Brief descriptions, grouped by type. No need for full reproduction steps.}

---

## UX Recommendations

{Include this section only if a ux-analyst was part of the team}

### Overall UX Score: {N}/10

{Brief justification}

### Quick Wins (High Impact, Low Effort)
1. {recommendation} — Effort: {estimate}
2. {recommendation} — Effort: {estimate}

### Longer-Term Improvements
1. {recommendation} — Effort: {estimate}

---

## Accessibility Summary

{Include this section only if an accessibility-qa was part of the team}

### WCAG 2.1 AA Compliance: {PASS | PARTIAL | FAIL}

| Criterion | Status | Notes |
|-----------|--------|-------|
| 1.1.1 Non-text Content | {Pass/Fail} | {details} |
| 1.4.3 Contrast | {Pass/Fail} | {details} |
| 2.1.1 Keyboard | {Pass/Fail} | {details} |
| 2.4.1 Bypass Blocks | {Pass/Fail} | {details} |
| {etc.} | | |

---

## Mobile & Responsive Summary

{Include this section only if a mobile-qa was part of the team}

| Page | Mobile (375) | Tablet (768) | Desktop (1280) |
|------|:---:|:---:|:---:|
| {page} | Pass/Fail | Pass/Fail | Pass/Fail |

---

## Test Coverage Summary

| Area | Tests Run | Pass | Fail | Blocked | Agent |
|------|:---------:|:----:|:----:|:-------:|-------|
| {area} | {n} | {n} | {n} | {n} | {agent_name} |
| **Total** | **{n}** | **{n}** | **{n}** | **{n}** | |

---

## Agent Reports

### {agent_name} — {role}
- **Status:** {Complete | Partial | Blocked}
- **Pages Tested:** {N}/{N}
- **Issues Found:** {breakdown by severity}
- **Blocked By:** {reason, if applicable}

{Repeat for each agent}

---

## Testing Blocked

{List any test areas that could not be completed and why}

---

## Validation Notes

{QA Lead's cross-reference validation observations}

- {Any findings flagged as potential testing artifacts}
- {Conflicting reports between agents and resolution}
- {Findings that need manual verification}

---

## Next Steps

1. {Triage P0 issues}
2. {Fix and retest}
3. {Additional testing recommended}

---

## Environment Details

**Framework:** {detected_framework}
**Test Credentials:** {roles_tested, no actual passwords}
**Browsers:** Chromium (via Playwright)
**Viewports Tested:** {list}
**Traces:** Available in `docs/qa-testing-outputs/{session_name}/traces/agent-{N}/` — open with `npx playwright show-trace`

---

**Report By:** qa-lead
**Date:** {YYYY-MM-DD}
**Contributing Agents:** {list}
```

---

## qa-findings.json Schema

The JSON findings file is designed for automation — parsing findings into tickets,
tracking regressions across runs, and feeding into test generation.

```json
{
  "$schema": "qa-findings-v1",
  "metadata": {
    "date": "2026-02-16",
    "app_name": "My App",
    "base_url": "http://localhost:3000",
    "branch": "develop",
    "framework": "next.js",
    "team": ["qa-lead", "admin-qa", "user-qa", "mobile-qa"],
    "duration_minutes": 45,
    "pages_tested": 24,
    "pages_total": 26
  },
  "summary": {
    "p0_count": 2,
    "p1_count": 1,
    "p2_count": 5,
    "p3_count": 3,
    "total_findings": 11,
    "production_ready": false,
    "overall_score": 7.5
  },
  "findings": [
    {
      "id": "QA-001",
      "severity": "P0",
      "title": "Registration page redirects randomly",
      "page": "/registro",
      "reporter": "user-qa",
      "description": "Registration page redirects to other pages during interaction",
      "steps_to_reproduce": [
        "Navigate to /registro",
        "Wait for form to load",
        "Observe redirect to different route"
      ],
      "expected": "Registration form remains stable",
      "actual": "Page redirects to /planes after 2-3 seconds",
      "evidence": {
        "screenshots": ["user-flows/registro-redirect.png"],
        "console_errors": [],
        "network_errors": []
      },
      "recommendation": "Check useEffect hooks for navigation side effects",
      "validation_status": "confirmed",
      "validation_notes": "Reproduced by two agents independently"
    }
  ],
  "coverage": [
    {
      "area": "Admin Panel",
      "agent": "admin-qa",
      "tests_run": 12,
      "passed": 10,
      "failed": 2,
      "blocked": 0,
      "pages": ["/admin", "/admin/users", "/admin/challenges"]
    }
  ],
  "blocked_tests": [
    {
      "area": "Authentication Flows",
      "reason": "Login page not rendering (QA-002)",
      "blocked_by": "QA-002",
      "agent": "user-qa"
    }
  ],
  "validation": {
    "cross_reference_check": true,
    "potential_false_positives": [
      {
        "finding_id": "QA-005",
        "reason": "Only observed by one agent, may be timing-dependent",
        "recommendation": "Manual retest recommended"
      }
    ],
    "confirmed_real_bugs": ["QA-001", "QA-002", "QA-003"],
    "testing_artifacts_detected": 0
  }
}
```

### Finding Severity Definitions

| Severity | Label | Definition | SLA |
|----------|-------|------------|-----|
| P0 | Critical | Core feature completely broken. Blocks user flow. No workaround. | Fix before release |
| P1 | High | Feature works but with significant problems. Workaround exists. | Fix in current sprint |
| P2 | Medium | Minor functional issues, UI glitches. Does not block usage. | Fix in next sprint |
| P3 | Low | Polish items, text issues, minor inconsistencies. | Backlog |

### Validation Status Values

| Status | Meaning |
|--------|---------|
| `confirmed` | Reproduced by multiple agents or manually verified by QA Lead |
| `likely_real` | Single agent report, consistent with expected behavior pattern |
| `needs_verification` | May be a testing artifact — manual retest recommended |
| `false_positive` | Determined to be a testing artifact, excluded from report |

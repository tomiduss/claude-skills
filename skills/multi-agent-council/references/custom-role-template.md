# Custom Role Template

## When to create a custom role

Create a custom role when:

- The problem requires **domain-specific expertise** not covered by the 15 built-in roles (e.g., regulatory compliance, specific infrastructure platforms, industry-specific constraints)
- The project has **local constraints** that need a dedicated advocate (e.g., a legacy system that must be preserved, a specific SLA commitment)
- You need to **guarantee tension** on a dimension the built-in roles don't cover

Do not create a custom role when an existing role already covers the perspective — check the role catalog first.

## Template

```yaml
name: [kebab-case-name]
title: [Human-readable title]
value_function: >
  [A hard constraint that makes certain conclusions structurally impossible.
   Must use language like "cannot propose", "must reject", "will not accept".]
lens: >
  [What this agent examines. What questions it asks. What it looks for in code,
   architecture, and design.]
research_directives:
  - [Specific investigation task 1]
  - [Specific investigation task 2]
  - [Specific investigation task 3]
```

## Writing a good value function

A value function is a **structural constraint**, not an opinion.

| Bad (opinion)                          | Good (constraint)                                                        |
| -------------------------------------- | ------------------------------------------------------------------------ |
| "Be careful about security"           | "Cannot propose any design that introduces unauthenticated access paths" |
| "Consider performance"                | "Must reject approaches that cannot demonstrate sub-100ms p95 latency"   |
| "Think about data privacy"            | "Will not accept architectures that allow PII to leave the trust boundary without encryption" |

The test: if your value function allows the agent to say "good point, I agree" to everything, it is not a constraint.

## Example 1: Security Architect (auth system redesign)

```yaml
name: security-architect
title: Security Architect
value_function: >
  Cannot propose any design that reduces the number of authentication factors,
  widens token scope beyond least-privilege, or introduces shared secrets
  between services.
lens: >
  Examines authentication flows, token lifecycles, secret management, and
  trust boundaries. Asks: where can an attacker escalate? What fails open?
research_directives:
  - Map all current auth flows and identify where credentials are validated
  - Check token expiration policies and scope definitions
  - Search for shared secrets, hardcoded credentials, or overly broad IAM roles
```

## Example 2: Data Privacy Officer (data pipeline decision)

```yaml
name: data-privacy-officer
title: Data Privacy Officer
value_function: >
  Will not accept any architecture that allows PII to exist outside encrypted
  storage, permits cross-border data transfer without explicit consent tracking,
  or lacks a complete deletion path for right-to-erasure requests.
lens: >
  Examines data flows, storage locations, retention policies, and consent
  mechanisms. Asks: where does PII live? Can we delete it completely? Who
  can access it?
research_directives:
  - Trace PII from ingestion to storage to deletion — identify every system that touches it
  - Check for data residency requirements and cross-region replication
  - Verify that deletion cascades through all downstream stores and caches
```

## Ensuring tension with existing roles

A custom role is only useful if it creates productive disagreement. Before adding one, verify that its value function will conflict with at least one existing council member. If the custom role agrees with everyone, it adds noise, not signal.

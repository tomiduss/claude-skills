# Playwright MCP Setup — Browser Isolation for QA Agents

This reference documents how to configure isolated Playwright MCP browser instances
for parallel QA agent execution.

## The Problem

When multiple agents share a single Playwright MCP server, one agent's navigation
disrupts another's. This causes false positives — "random redirects" that look like
bugs but are actually agent interference. **This is the #1 source of wasted QA time.**

## The Solution

Each browser-using agent gets its own Playwright MCP server instance, running as a
separate stdio process with an in-memory isolated browser profile.

---

## .mcp.json Configuration

Generate one entry per browser-using agent. All agents use stdio transport (no `--port`
needed), so each is a separate process with full isolation.

### Template (per agent)

```json
{
  "playwright-qa-{N}": {
    "command": "npx",
    "args": [
      "@playwright/mcp@latest",
      "--isolated",
      "--headless",
      "--browser", "chrome",
      "--caps", "vision,pdf",
      "--viewport-size", "{VIEWPORT}",
      "--timeout-action", "10000",
      "--timeout-navigation", "30000",
      "--grant-permissions", "geolocation", "clipboard-read", "clipboard-write",
      "--output-dir", "{SESSION_DIR}/traces/agent-{N}",
      "--save-trace",
      "--test-id-attribute", "data-testid",
      "--codegen", "typescript"
    ]
  }
}
```

### With Storage State (authenticated sessions)

Add `--storage-state` when agents need pre-authenticated sessions:

```json
"args": [
  "@playwright/mcp@latest",
  "--isolated",
  "--storage-state", "{PROJECT_ROOT}/qa-config/storage-state.json",
  ...rest of args
]
```

### Viewport Variants

| Agent Role        | Viewport         | Flag                     |
|-------------------|------------------|--------------------------|
| Desktop (default) | 1280x720         | `--viewport-size 1280x720` |
| Mobile            | 375x812          | `--viewport-size 375x812`  |
| Tablet            | 768x1024         | `--viewport-size 768x1024` |
| Large Desktop     | 1920x1080        | `--viewport-size 1920x1080` |

---

## Full Example: 3-Agent Team

For a team with: admin-qa (desktop), user-qa (desktop), mobile-qa (mobile):

```json
{
  "mcpServers": {
    "playwright-qa-1": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--isolated",
        "--headless",
        "--browser", "chrome",
        "--caps", "vision,pdf",
        "--viewport-size", "1280x720",
        "--timeout-action", "10000",
        "--timeout-navigation", "30000",
        "--grant-permissions", "geolocation", "clipboard-read", "clipboard-write",
        "--output-dir", "./docs/qa-testing-outputs/{session_name}/traces/agent-1",
        "--save-trace",
        "--test-id-attribute", "data-testid",
        "--codegen", "typescript"
      ]
    },
    "playwright-qa-2": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--isolated",
        "--headless",
        "--browser", "chrome",
        "--caps", "vision,pdf",
        "--viewport-size", "1280x720",
        "--timeout-action", "10000",
        "--timeout-navigation", "30000",
        "--grant-permissions", "geolocation", "clipboard-read", "clipboard-write",
        "--output-dir", "./docs/qa-testing-outputs/{session_name}/traces/agent-2",
        "--save-trace",
        "--test-id-attribute", "data-testid",
        "--codegen", "typescript"
      ]
    },
    "playwright-qa-3": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--isolated",
        "--headless",
        "--browser", "chrome",
        "--caps", "vision,pdf",
        "--viewport-size", "375x812",
        "--timeout-action", "10000",
        "--timeout-navigation", "30000",
        "--grant-permissions", "geolocation", "clipboard-read", "clipboard-write",
        "--output-dir", "./docs/qa-testing-outputs/{session_name}/traces/agent-3",
        "--save-trace",
        "--test-id-attribute", "data-testid",
        "--codegen", "typescript"
      ]
    }
  }
}
```

---

## Permissions (settings.json)

Add wildcard permissions so Claude Code doesn't prompt for each tool call.
These go in `.claude/settings.json` or `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__playwright-qa-1__*",
      "mcp__playwright-qa-2__*",
      "mcp__playwright-qa-3__*",
      "mcp__playwright-qa-4__*",
      "mcp__playwright-qa-5__*"
    ]
  }
}
```

Pre-allow up to 5 to cover most team configurations. Unused entries are harmless.

---

## Generating Storage State

If the application requires authentication, generate a storage state file before
running the QA team:

```bash
# Interactive: opens a browser, you log in manually, state is saved
npx playwright codegen --save-storage=./qa-config/admin-storage.json http://localhost:3000/login

# For multiple roles, generate separate files
npx playwright codegen --save-storage=./qa-config/user-storage.json http://localhost:3000/login
```

Then reference the appropriate file in each agent's `--storage-state` arg.

---

## Output Structure

All outputs for a QA session live in a single session directory. The session name is a
short, human-readable snake_case title (e.g., `full_qa_2026_02_16`, `admin_panel_audit`).

```
{project_root}/docs/qa-testing-outputs/{session_name}/
├── QA_REPORT.md              # Consolidated human-readable report
├── qa-findings.json           # Machine-parseable findings
├── screenshots/               # Evidence screenshots organized by area
└── traces/                    # Playwright traces per agent
    ├── agent-1/
    │   ├── trace.zip          # Open with: npx playwright show-trace trace.zip
    │   └── *.png
    ├── agent-2/
    └── agent-3/
```

Auth storage state (if generated) goes in `{project_root}/qa-config/` (reusable across sessions).

---

## Troubleshooting

### Agent reports "random redirects"
Another agent is using the same browser instance. Verify each agent has its own
`playwright-qa-{N}` tool prefix. This is ALWAYS a configuration error, not an app bug.

### Browser fails to launch
Run `npx playwright install chromium` to ensure the browser binary is installed.

### Storage state expired
Re-generate with `npx playwright codegen --save-storage`. Sessions expire based on
the application's cookie/token TTL.

### Traces not saving
Verify `--output-dir` points to a writable directory. Create it before running:
`mkdir -p docs/qa-testing-outputs/{session_name}/traces/agent-{1,2,3}`

---

## Alternative: Config File Approach

For complex configurations, use a JSON config file instead of CLI args:

```json
// qa-config/agent-1.json
{
  "browser": {
    "browserName": "chromium",
    "isolated": true,
    "launchOptions": {
      "headless": true
    },
    "contextOptions": {
      "viewport": { "width": 1280, "height": 720 },
      "permissions": ["geolocation", "clipboard-read", "clipboard-write"],
      "storageState": "./qa-config/admin-storage.json",
      "locale": "es-CL",
      "timezoneId": "America/Santiago"
    }
  },
  "capabilities": ["core", "vision", "pdf"],
  "saveTrace": true,
  "outputDir": "./docs/qa-testing-outputs/{session_name}/traces/agent-1",
  "testIdAttribute": "data-testid",
  "timeouts": {
    "action": 10000,
    "navigation": 30000
  },
  "codegen": "typescript"
}
```

Then reference it:
```json
{
  "playwright-qa-1": {
    "command": "npx",
    "args": ["@playwright/mcp@latest", "--config", "./qa-config/agent-1.json"]
  }
}
```

The config file approach is better when you need locale, timezone, geolocation
coordinates, or other `contextOptions` not available as CLI flags.

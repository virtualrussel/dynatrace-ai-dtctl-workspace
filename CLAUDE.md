# Dynatrace AI Workspace — Session Briefing

## Environment

| | |
|---|---|
| **MCP server** | `dynatrace-mcp` → `https://YOUR_TENANT_ID.apps.dynatrace.com` |

Run `bash setup.sh` to configure this workspace on first use.

## Global Rule

**Always start with problems — never run broad log searches.**
Broad queries without problem context hit Dynatrace's 500GB scan limit and return zero results.
All investigation workflows enforce this automatically.

## Tool Priority

**Default to MCP tools and the `dt-obs-*` / `dt-app-*` / `dt-dql-essentials` skills** for telemetry reads, problem and RCA analysis, log and trace exploration, and dashboard/notebook content lookups.

Use the `dtctl` skill for:
- Resource lifecycle: `apply`, `delete`, `share`, `unshare`, `history`, `restore`
- Workflow / function / analyzer execution (`dtctl exec`)
- Bulk or scripted operations and CI/CD-style automation
- Tasks not exposed via MCP, or when the user explicitly asks for the CLI

When both paths can satisfy a request, prefer MCP.

**Never substitute one resource type for another to fit an available tool.** If the user asks for a dashboard and only a notebook tool is available via MCP, route to `dtctl` for the dashboard. Refusal-then-route is preferred over delivering a different artifact than requested.

## Prompts

Type `@` to access these slash commands:

| Prompt | When to use |
|---|---|
| `/health-check` | Routine service health — metrics, problems, deployments, vulnerabilities |
| `/daily-standup` | Morning report across services — today vs yesterday comparison |
| `/daily-standup-notebook` | Standup report + Dynatrace notebook creation + dtctl verification |
| `/investigate-error` | Error-focused investigation from a service name |
| `/troubleshoot-problem` | Deep 7-step investigation into a specific Dynatrace problem |
| `/incident-response` | Full triage of all active problems during a live incident |
| `/performance-regression` | Before vs after deployment comparison with rollback/hotfix recommendation |

## Skills

Domain knowledge skills are installed in `.agents/skills/`. They load automatically when relevant — no manual loading required.

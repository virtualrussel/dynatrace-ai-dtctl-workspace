# Dynatrace AI Workspace — Session Briefing

## Environment

| | |
|---|---|
| **MCP server** | `dynatrace-mcp` → https://YOUR_TENANT_ID.apps.dynatrace.com |

Replace `YOUR_TENANT_ID` in `.vscode/mcp.json` and `.mcp.json` with your Dynatrace tenant ID before use.

## Global Rule

**Always start with problems — never run broad log searches.**
Broad queries without problem context hit Dynatrace's 500GB scan limit and return zero results.
All investigation workflows enforce this automatically.

## Prompts

Type `/` in Copilot Chat to access these slash commands:

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

13 domain knowledge skills are installed in `.agents/skills/`. They load automatically when relevant — no manual loading required.

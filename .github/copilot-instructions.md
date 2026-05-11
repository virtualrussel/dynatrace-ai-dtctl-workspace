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

Domain knowledge skills are installed in `.agents/skills/`. They load automatically when relevant — no manual loading required.

| Skill | What It Covers |
|---|---|
| `dt-dql-essentials` | DQL syntax, common pitfalls, query patterns — load before any DQL |
| `dt-obs-problems` | Davis Problems, root cause analysis, impact assessment |
| `dt-obs-logs` | Log queries, filtering, pattern analysis, error classification |
| `dt-obs-tracing` | Distributed traces, spans, failure detection, log correlation |
| `dt-obs-services` | RED metrics, SLA tracking, runtime monitoring (Java, .NET, Node.js, Python, PHP, Go) |
| `dt-obs-hosts` | Host and process metrics, CPU, memory, disk, containers |
| `dt-obs-kubernetes` | Pods, workloads, nodes, labels, ingress, PVCs |
| `dt-obs-aws` | EC2, RDS, Lambda, ECS/EKS, VPC, cost optimization |
| `dt-obs-azure` | Azure VMs, AKS, SQL, storage, networking, serverless, cost optimization |
| `dt-obs-gcp` | Compute Engine, GKE, Cloud Run, Pub/Sub, VPC, IAM, resource management |
| `dt-obs-frontends` | RUM, Web Vitals, user sessions, mobile crashes |
| `dt-obs-predictive-analytics` | Forecasting, trend detection, anomaly identification, capacity planning |
| `dt-app-dashboards` | Dashboard JSON creation and modification |
| `dt-app-notebooks` | Notebook creation and analytics workflows |
| `dt-migration` | Classic entity DQL → Smartscape migration |
| `dtctl` | CLI commands for managing Dynatrace resources from the terminal |

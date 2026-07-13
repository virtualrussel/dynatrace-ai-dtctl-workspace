# Dynatrace AI Workspace — Session Briefing

## Environment

|                |                 |
| -------------- | --------------- |
| **MCP server** | `dynatrace-mcp` |

## Global Rule

**Always start with problems — never run broad log searches.** Broad queries without problem context hit Dynatrace's 500GB scan limit and return zero results.
All investigation workflows enforce this automatically.

Consult [docs/CHEATSHEET.md](../docs/CHEATSHEET.md) first for workflow selection and operational guardrails before choosing a prompt, skill, or writing any DQL.

## Tool Priority

**Default to MCP tools and the relevant `dt-*` domain skill** for telemetry reads, problem and RCA analysis, log and trace exploration, dashboard/notebook content lookups, security findings, and cost analysis. Skills load automatically based on relevance — no manual selection needed.

Use the `dtctl` skill for:

- Resource lifecycle: `apply`, `delete`, `share`, `unshare`, `history`, `restore`
- Workflow execution (`dtctl exec workflow`)
  - Prefer structured input with `--input '{"key":"value"}'` (v0.30.0+)
  - Legacy `--params key=value` still supported but deprecated
- Bulk or scripted operations and CI/CD-style automation
- Validating DQL syntax before execution (`dtctl verify query`)
- Tasks not exposed via MCP, or when the user explicitly asks for the CLI

When both paths can satisfy a request, prefer MCP.

**Never substitute one resource type for another to fit an available tool.** If the user asks for a dashboard and only a notebook tool is available via MCP, route to `dtctl` for the dashboard. Refusal-then-route is preferred over delivering a different artifact than requested.

## Prompts

Type `/` to run these slash commands:

| Prompt                    | When to use                                                               |
| ------------------------- | ------------------------------------------------------------------------- |
| `/health-check`           | Routine service health — metrics, problems, deployments, vulnerabilities  |
| `/daily-standup`          | Morning report across services — today vs yesterday comparison            |
| `/daily-standup-notebook` | Standup report + Dynatrace notebook creation + dtctl verification         |
| `/investigate-error`      | Error-focused investigation from a service name                           |
| `/troubleshoot-problem`   | Deep 7-step investigation into a specific Dynatrace problem               |
| `/incident-response`      | Full triage of all active problems during a live incident                 |
| `/performance-regression` | Before vs after deployment comparison with rollback/hotfix recommendation |

## Skills

Domain knowledge skills are installed in `.agents/skills/`. They load automatically when relevant — no manual loading required.

| Skill                         | What It Covers                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| `dt-dql-essentials`           | DQL syntax, common pitfalls, query patterns — load before any DQL                    |
| `dt-obs-problems`             | Davis Problems, root cause analysis, impact assessment                               |
| `dt-obs-logs`                 | Log queries, filtering, pattern analysis, error classification                       |
| `dt-obs-tracing`              | Distributed traces, spans, failure detection, log correlation                        |
| `dt-obs-services`             | RED metrics, SLA tracking, runtime monitoring (Java, .NET, Node.js, Python, PHP, Go) |
| `dt-obs-hosts`                | Host and process metrics, CPU, memory, disk, containers                              |
| `dt-obs-kubernetes`           | Pods, workloads, nodes, labels, ingress, PVCs                                        |
| `dt-obs-aws`                  | EC2, RDS, Lambda, ECS/EKS, VPC, cost optimization — **full feature parity with Azure/GCP** |
| `dt-obs-azure`                | Azure VMs, AKS, SQL, storage, networking, serverless, cost optimization              |
| `dt-obs-gcp`                  | Compute Engine, GKE, Cloud Run, Pub/Sub, VPC, IAM, resource management               |
| `dt-obs-frontends`            | RUM, Web Vitals, user sessions, mobile crashes                                       |
| `dt-obs-predictive-analytics` | Forecasting, trend detection, anomaly identification, capacity planning              |
| `dt-obs-genai`                | LLM/GenAI observability — golden signals, token/cost analytics, agent signals, conversation analytics, guardrails, evaluations |
| `dt-obs-log-semantic-mapping` | Suggest and validate semantic dictionary mappings for audit log integrations         |
| `dt-sec-insights`             | Security events — vulnerabilities (RVA/RAP), MITRE ATT&CK detections, posture (KSPM/CSPM/VSPM) |
| `dt-sec-semantic-mapping`     | Suggest and validate semantic dictionary mappings for new security integrations      |
| `dt-obs-android`              | Instrument Android projects with the Dynatrace Mobile Agent                          |
| `dt-obs-flutter`              | Integrate the Dynatrace Flutter Plugin                                               |
| `dt-obs-ios-sdk`              | Set up the Dynatrace iOS SDK via Swift Package Manager                              |
| `dt-obs-react-native`         | Integrate the Dynatrace React Native Plugin (bare RN and Expo)                       |
| `dt-app-dashboards`           | Dashboard JSON creation and modification                                             |
| `dt-app-notebooks`            | Notebook creation and analytics workflows                                            |
| `dt-migration`                | Classic entity DQL → Smartscape migration                                            |
| `dt-alerting`                 | Anomaly detector setup, alert event history, problem denoising, workflow notifications |
| `dt-js-runtime`               | Dynatrace server-side JS runtime — function contract, SDK catalog, fetch, limits     |
| `dt-platform-costs`           | DPS billing/usage analysis — cost breakdown, spend ranking, chargeback, drill-down    |
| `dtctl`                       | CLI commands for managing Dynatrace resources (v0.32.0+ required)                   |

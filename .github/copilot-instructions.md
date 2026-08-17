# Dynatrace AI Workspace — Session Briefing

## Environment

|                |                 |
| -------------- | --------------- |
| **MCP server** | `dynatrace-mcp` |

## Global Rule

- Start incident, error, and known-problem investigations with Davis Problems to establish the affected entities and timeframe.
- Never query logs or spans without both an entity scope and a bounded timeframe. Unbounded high-volume searches can hit Dynatrace's 500GB scan limit.
- Bounded metric, inventory, known-entity, deployment-comparison, and document queries do not require a Davis Problem.
- Verify proposed DQL with `dtctl verify query '<dql>'` before executing against Grail — whether via MCP or `dtctl query` directly. It catches parse errors locally without consuming scan budget.

Consult [docs/CHEATSHEET.md](../docs/CHEATSHEET.md) first for workflow selection and operational guardrails before choosing a prompt, skill, or writing any DQL.

## Tool Priority

**Default to MCP tools and the relevant `dt-*` domain skill** for telemetry reads, problem and RCA analysis, log and trace exploration, supported document lookups, security findings, and cost analysis. Skills load automatically based on relevance — no manual selection needed.

Use the `dtctl` skill for:

- Resource lifecycle: `apply`, `delete`, `share`, `unshare`, `history`, `restore`
- Notebook and dashboard creation or updates; load `dt-app-notebooks` or `dt-app-dashboards` for structure, then deploy with `dtctl apply`
- Workflow execution (`dtctl exec workflow`)
  - Prefer structured input with `--input '{"key":"value"}'` (v0.30.0+)
  - Legacy `--params key=value` still supported but deprecated
- Settings discovery and validated mutation (`--validate-only` before create/edit/delete)
- Bulk or scripted operations and CI/CD-style automation
- Validating DQL syntax before execution (`dtctl verify query`)
- Tasks not exposed via MCP, or when the user explicitly asks for the CLI

When both paths can satisfy a request, prefer MCP.

**Never substitute one resource type for another to fit an available tool.** The current MCP server does not create notebooks, dashboards, workflows, or settings. Route those lifecycle operations to `dtctl` and use the relevant domain skill for structure and intent.

**Treat MCP `401` and `403` responses as authorization failures, never as evidence that no telemetry exists.** Identify the failed capability and missing Platform Token scope, distinguish identity IAM or Grail policy restrictions, and continue only with authorized capabilities. Use [docs/PERMISSIONS.md](../docs/PERMISSIONS.md) as the authoritative permission reference.

## Prompts

Type `/` to run these slash commands:

Before executing a bundled prompt, apply its portable runtime contract from [docs/PROMPT_CONTRACTS.md](../docs/PROMPT_CONTRACTS.md). The contract defines required skills, capability classes, scope, stopping conditions, and authorization-failure behavior without relying on client-specific tool names.

| Prompt                    | When to use                                                               |
| ------------------------- | ------------------------------------------------------------------------- |
| `/health-check`           | Routine service health — metrics, problems, deployments, vulnerabilities  |
| `/daily-standup`          | Morning report across services — today vs yesterday comparison            |
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
| `dt-obs-network-devices`      | SNMP-monitored network devices (switches, routers, firewalls, load balancers) — Smartscape topology, device/interface metrics, SNMP trap and syslog analysis |
| `dt-obs-network-flows`        | Network flow analysis across OneAgent flows, NetFlow/IPFIX/sFlow, and cloud VPC flow logs — top talkers, communication dependencies, connection health |
| `dt-obs-frontends`            | RUM, Web Vitals, user sessions, mobile crashes                                       |
| `dt-obs-predictive-analytics` | Forecasting, trend detection, anomaly identification, capacity planning              |
| `dt-obs-genai`                | LLM/GenAI observability — golden signals, token/cost analytics, agent signals, conversation analytics, guardrails, evaluations |
| `dt-obs-log-semantic-mapping` | Suggest and validate semantic dictionary mappings for audit log integrations         |
| `dt-sec-insights`             | Security events — vulnerabilities (RVA/RAP), MITRE ATT&CK detections, posture (KSPM/CSPM/VSPM) |
| `dt-sec-semantic-mapping`     | Suggest and validate semantic dictionary mappings for new security integrations      |
| `dt-sec-contextualization`    | Resolve security signals/IoC matches to runtime entities across topology levels     |
| `dt-sec-ioc-hunting`          | Hunt threat-intel indicators of compromise across logs and spans with a threat-exposure score |
| `dt-obs-compliance-assistant` | EU DORA compliance posture — compliance score, CIF health, incident lifecycle, and ICT risk inputs (vulnerabilities, misconfigurations) |
| `dt-setup-android`            | Instrument Android projects with the Dynatrace Mobile Agent                          |
| `dt-setup-flutter`            | Integrate the Dynatrace Flutter Plugin                                               |
| `dt-setup-ios`                | Set up the Dynatrace iOS SDK via Swift Package Manager                              |
| `dt-setup-react-native`       | Integrate the Dynatrace React Native Plugin (bare RN and Expo)                       |
| `dt-app-dashboards`           | Dashboard JSON creation and modification                                             |
| `dt-app-notebooks`            | Notebook creation and analytics workflows                                            |
| `dt-obs-analytics`            | Analyze dashboards/notebooks with Davis analyzers (anomaly detection, novelty, correlation) |
| `dt-obs-ext-monitors`         | Ingest 3rd-party test/monitor results into Grail via the platform events ingest API  |
| `dt-migration`                | Classic entity DQL → Smartscape migration                                            |
| `dt-alerting`                 | Anomaly detector setup, alert event history, problem denoising, workflow notifications |
| `dt-js-runtime`               | Dynatrace server-side JS runtime — function contract, SDK catalog, fetch, limits     |
| `dt-platform-costs`           | DPS billing/usage analysis — cost breakdown, spend ranking, chargeback, drill-down    |
| `dtctl`                       | CLI commands for managing Dynatrace resources (v0.38.0+ required)                   |

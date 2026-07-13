# Dynatrace AI Workspace — Cheat Sheet

**Use this to pick the right workflow, not write DQL.**

---

## When to use which workflow

| Situation | Start here | What you get back |
|-----------|------------|-------------------|
| Something is broken right now | `/incident-response` | All active problems prioritized by business impact, with mitigation steps and a shareable incident report |
| You have a specific problem ID | `/troubleshoot-problem` | 7-step RCA: scoped logs → error classification → trace timeline → root cause hypothesis |
| Error rates spiked after a deploy | `/performance-regression` | Before/after metrics comparison, bottleneck span, and a rollback or hotfix recommendation |
| Investigating error noise from a service | `/investigate-error [service-name]` | Top 3 error patterns with example logs, related traces, and remediation suggestions |
| Routine service health check | `/health-check [service-name]` | RED metrics, active problems, recent deployments, top slow endpoints, vulnerabilities |
| Morning catch-up across all services | `/daily-standup` | Per-service health status, today vs yesterday comparison, and action items |
| Standup + notebook for sharing | `/daily-standup-notebook` | Same as `/daily-standup` plus a Dynatrace notebook created and verified via dtctl |

---

## Workflow chaining

Most investigations follow this escalation path:

```
/daily-standup           → spot anomalies
  → /health-check        → confirm which service
    → /investigate-error → find the root cause
      → /troubleshoot-problem → deep-dive a specific problem
```

For live incidents, skip straight to `/incident-response` — it triages all active problems at once.

For deploys that went wrong, use `/performance-regression` — it compares before/after and recommends rollback or hotfix.

---

## Skills — what they unlock

Skills are loaded automatically when relevant. You can also ask for one directly.

| Ask about... | Skill used |
|---|---|
| Service error rates, latency, throughput | `dt-obs-services` |
| Kubernetes pods, workloads, crash loops | `dt-obs-kubernetes` |
| Host CPU, memory, disk, processes | `dt-obs-hosts` |
| Frontend performance, Web Vitals, RUM | `dt-obs-frontends` |
| Distributed traces, request flows | `dt-obs-tracing` |
| Log search and pattern analysis | `dt-obs-logs` |
| Problem RCA and impact scope | `dt-obs-problems` |
| AWS resources and infrastructure | `dt-obs-aws` |
| Azure resources and infrastructure | `dt-obs-azure` |
| GCP resources and infrastructure | `dt-obs-gcp` |
| Forecasting, capacity planning, anomaly detection | `dt-obs-predictive-analytics` |
| Vulnerabilities, MITRE ATT&CK detections, compliance posture | `dt-sec-insights` |
| LLM/GenAI cost, latency, tokens, agent or conversation analytics | `dt-obs-genai` |
| Mapping vendor audit logs to the Dynatrace semantic dictionary | `dt-obs-log-semantic-mapping` |
| Mapping new security vendor data to the Dynatrace semantic dictionary | `dt-sec-semantic-mapping` |
| Instrumenting a mobile app (Android / iOS / Flutter / React Native) | `dt-obs-android` / `dt-obs-ios-sdk` / `dt-obs-flutter` / `dt-obs-react-native` |
| Dashboards — create or modify | `dt-app-dashboards` |
| Notebooks — create or modify | `dt-app-notebooks` |
| Migrating classic entity DQL to Smartscape | `dt-migration` |
| Alerting, anomaly detectors, problem notifications | `dt-alerting` |
| Dynatrace JS runtime functions and SDKs | `dt-js-runtime` |
| DPS billing, cost breakdown, chargeback | `dt-platform-costs` |
| Terminal / CLI operations | `dtctl` |
| Writing any DQL query | `dt-dql-essentials` (always load first) |

---

## dtctl — terminal companion

`dtctl` is the CLI-side of this workspace (all dtctl examples below are terminal commands). Use it when you want to verify, query, or manage resources from the terminal rather than through chat.

| Task | Command |
|------|---------|
| Verify connection | `dtctl doctor` |
| Run a DQL query | `dtctl query --client-context "workspace-quick-check" 'fetch dt.davis.problems \| filter event.status == "ACTIVE"'` |
| Verify DQL syntax only | `dtctl verify query --client-context "workspace-quick-check" 'fetch dt.davis.problems \| limit 5'` |
| List workflows | `dtctl get workflows` |
| List notebooks | `dtctl get notebooks` |
| Filter notebook lookup precisely | `dtctl get notebooks --filter 'name == "<notebook-name>"' --sort "-modificationInfo.lastModifiedTime"` |
| Include extra document metadata | `dtctl get documents --add-fields "originExtensionId,labels,shareInfo.isShared"` |
| Switch environments | `dtctl config use-context production` / `dtctl config use-context sprint` |

- Filter/reshape command output in-place: `dtctl query ... -o json --jq '<jq expr>'` (v0.30.0+) — no external jq required; table/csv output is auto-promoted to JSON.

- Large query results (v0.32.0+): dtctl spills big results to a local file and returns a summary instead of the full payload. Use `dtctl inspect <file> --schema|--stats|--sample|--page|--jq` to dig into that same result — this is a *local* operation, it does not re-scan Grail. If you need a different slice of data already fetched, reach for `inspect`, not another query.

- Large exports (v0.31.0+): `dtctl query ... -o jsonl` or `-o parquet` for results headed to external analytics tooling (DuckDB/pandas), not for agent consumption.

- Workflow listing: use `--filter`, `--started-since`/`--started-until`, and `--limit` (v0.29.0+) so agents request scoped lists and avoid large payloads.

- Config trust: per-project `.dtctl.yaml` is treated as untrusted by default; aliases and pre/post-apply hooks are ignored unless using global config, `--config`, or the `DTCTL_CONFIG` (v0.34.0+) environment variable. Agents should rely on explicit contexts or flags unless `DTCTL_CONFIG` points at a workspace you control.

- Command catalog: `dtctl commands` defaults to a compact TOON overview (v0.34.0+, previously JSON) — cheaper on agent context. Use `--brief` for scopes/flag types or `--full` for the exhaustive catalog.

- Restricting the exposed surface: a command profile (`--profile query|investigate` on a context, or `DTCTL_PROFILE=...`, v0.34.0+) trims which commands `dtctl commands`/`--help` advertise and hard-blocks the rest — useful for a narrowly-scoped agent, but client-side only (not a security boundary).

- Scan-limit feedback: agent mode now flags DQL scan-limit truncation explicitly with data-reduction advice (v0.33.0+) instead of returning a silent partial/empty result — treat it as "narrow the query," not "no data."

The AI workflows and dtctl point at the same environment — use chat for investigation, dtctl for spot-checks and verification.

---

## When workflows stop short

These are expected behaviours, not errors:

| What you see | Why | What to do |
|---|---|---|
| "No active problems found" | No problems in last 7 days | Widen to recently closed problems, or check you're on the right environment |
| "No regression threshold exceeded" | `/performance-regression` found no signal | Trust the result — or re-run with a narrower timeframe if you suspect a specific window |
| "Could not correlate to a local file" | `/performance-regression` found the bottleneck span but no matching code | The slow code may be in a dependency or a service not in this workspace |
| Query returns 0 results | Filters too tight, or wrong entity | Verify the service name with `/health-check` first |
| 500GB scan limit hit | Log query too broad | A workflow should have scoped it — if writing your own query, add entity filter + tighter timeframe |

---

## Key rules

**Start with problems. Never open-ended log searches.**
All workflows enforce this. If you skip it, you'll hit the 500GB scan limit.

**Scope everything to a problem timeframe.**
Workflows extract the timeframe automatically. If you're writing your own query, use ±5 min around the incident window.

**Let the workflow drive DQL. Don't write queries from scratch.**
Ask: *"What were the error patterns during the last problem on [service]?"* — not *"Write a DQL query for..."*

---

## Useful natural language prompts

These work well when you're not sure which workflow to reach for:

- *"Are there any active problems right now?"*
- *"What happened to [service] in the last hour?"*
- *"Show me the slowest endpoints for [service] since the last deployment"*
- *"Create a notebook summarising today's incidents"*
- *"What's the root cause of problem [ID]?"*
- *"Compare [service] performance before and after [deploy time]"*

---

## Session targeting

MCP server: `dynatrace-mcp` → `https://YOUR_TENANT_ID.apps.dynatrace.com`

Run `bash setup.sh` to configure on first use. For subsequent URL changes, edit `.vscode/mcp.json` and regenerate: `jq '{"mcpServers": .servers}' .vscode/mcp.json > .mcp.json`.

**Claude Code CLI:** run `claude` from the workspace directory — MCP config is in `.mcp.json` and the server starts automatically.

---

**MCP server:** dynatrace-mcp | **Last Updated:** July 13, 2026

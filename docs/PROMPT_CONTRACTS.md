# Prompt Contracts

This registry defines how the six bundled upstream prompts use workspace skills and Dynatrace capabilities. The prompt files remain byte-for-byte upstream; these contracts provide the portable runtime requirements shared by GitHub Copilot and Claude Code.

## Shared Contract

- Prefer `dynatrace-mcp` for supported live telemetry reads and analysis. Use dtctl only for operations assigned to it in the workspace resource-ownership model.
- Load the named domain skills before constructing DQL or interpreting telemetry.
- Confirm or infer the required entity and timeframe before querying. Every log or span query must have both an entity scope and bounded timeframe.
- Treat MCP `401` and `403` responses as authorization failures, not as evidence that no telemetry exists. Name the unavailable capability, refer to [PERMISSIONS.md](./PERMISSIONS.md), continue only with authorized evidence, and label omitted output sections.
- Never report a healthy state, no data, or no impact when the evidence needed for that conclusion was unavailable.
- Stop when a contract's stopping condition is met or the remaining authorized evidence cannot support the next step.

## /daily-standup

**Input:** One or more confirmed service names. Infer candidates from the workspace, but ask for confirmation when ambiguous. Use today and the comparable previous-day window unless the user supplies another bounded period.

**Start:** Query bounded service RED metrics. A Davis Problem is not required before this metric comparison.

**Skills:** `dt-obs-services`, `dt-obs-problems`, `dt-dql-essentials`; add the relevant infrastructure or security skill only when that section is requested or supported by evidence.

**Capabilities:** Metrics read, entity/Smartscape read, events/problems read, and deployment-event read.

**Scope:** Keep every query limited to the confirmed services and comparison windows. Do not broaden into logs or spans unless a reported issue supplies an entity and incident window.

**Stop:** Do not drill into traces or logs merely because a metric changed; report the comparison and recommend the appropriate investigation prompt when deeper evidence is needed.

**Output:** Per-service health, today-versus-yesterday RED metrics, relevant problems and deployments, and evidence-backed action items. Label unavailable sections.

## /health-check

**Input:** One confirmed service and a bounded current window; default to a short operational window suitable for current health.

**Start:** Query bounded service RED metrics, then correlate active problems. A Davis Problem is not required before the metric snapshot.

**Skills:** `dt-obs-services`, `dt-obs-problems`, `dt-obs-tracing`, `dt-sec-insights`, `dt-dql-essentials`.

**Capabilities:** Metrics read, entity/Smartscape read, events/problems read, bounded span read, deployment-event read, and security-event read.

**Scope:** Slow-endpoint span queries must stay within the confirmed service and health window. Do not open a broad log search from this workflow.

**Stop:** If available metrics and problems show no actionable signal, return the health summary without escalating into trace analysis.

**Output:** Current RED metrics, active problems, recent deployments, up to five slow endpoints when span access is available, security findings when authorized, and a qualified health assessment.

## /incident-response

**Input:** The production tenant context and an active incident window. Ask for service or business scope only when the active problem set is too broad to triage safely.

**Start:** Retrieve active Davis Problems and prioritize them by severity and business impact before querying supporting telemetry.

**Skills:** `dt-obs-problems`, `dt-obs-logs`, `dt-obs-tracing`, `dt-obs-frontends`, `dt-dql-essentials`; add entity-specific infrastructure skills for identified root-cause entities.

**Capabilities:** Events/problems read, entity/Smartscape read, bounded logs and spans read, metrics read, and user-event/session read when user impact is requested and authorized.

**Scope:** Derive entity IDs and time windows from each selected problem. Add only a small correlation buffer before querying logs or spans.

**Stop:** Skip evidence channels that are unauthorized or cannot be scoped. Do not turn an authorization failure into a lower incident severity.

**Output:** Problems ranked by business impact, plain-language root-cause evidence, user/transaction impact when available, immediate mitigation, and a shareable incident report with omissions disclosed.

## /investigate-error

**Input:** One confirmed service and optional timeframe. If no timeframe is supplied, use relevant recent Davis Problems to establish it.

**Start:** Retrieve Davis Problems for the service and select the relevant problem context before querying logs or traces.

**Skills:** `dt-obs-problems`, `dt-obs-logs`, `dt-obs-tracing`, `dt-dql-essentials`.

**Capabilities:** Events/problems read, entity/Smartscape read, bounded logs read, and bounded spans read. Workspace code search is local and does not replace telemetry evidence.

**Scope:** Every log and span query must use the selected problem's entities and timeframe. Narrow further when a scan-limit warning or truncation signal appears.

**Stop:** If no relevant problem establishes safe scope, ask for a specific entity and bounded timeframe rather than running a broad error search.

**Output:** Selected problems, grouped error patterns, up to three representative errors per problem, correlated traces and local code when found, and evidence-backed remediation.

## /performance-regression

**Input:** One confirmed service and bounded suspected-regression window. Default to the last 24 hours only when the user cannot provide a narrower period.

**Start:** Find the latest deployment event in scope, or use the window midpoint, then compare bounded before/after RED metrics. A Davis Problem is not required for this comparison.

**Skills:** `dt-obs-services`, `dt-obs-tracing`, `dt-obs-problems`, `dt-dql-essentials`.

**Capabilities:** Deployment-event read, metrics read, entity/Smartscape read, bounded spans read, and events/problems read.

**Scope:** All metrics and spans must remain scoped to the confirmed service and comparison windows. Endpoint analysis begins only after a documented regression threshold is exceeded.

**Stop:** Stop after the metric comparison when no threshold is exceeded. Do not fetch traces merely to add detail to a no-regression result.

**Output:** Boundary choice, before/after metrics and deltas, regressed endpoints and bottleneck trace when justified, relevant Davis Problems, workspace-code correlation, and one rollback-or-hotfix recommendation.

## /troubleshoot-problem

**Input:** A selected problem ID or structured timestamp, service, and problem message. For manual use, present active or recently closed problems and wait for selection.

**Start:** Retrieve and confirm the Davis Problem, affected entities, and exact timeframe before any supporting query.

**Skills:** `dt-obs-problems`, `dt-obs-logs`, `dt-obs-tracing`, `dt-dql-essentials`; add entity-specific skills when the problem identifies infrastructure or cloud resources.

**Capabilities:** Events/problems read, entity/Smartscape read, bounded logs read, and bounded spans read.

**Scope:** Query logs and traces only for affected entities from five minutes before the problem start through five minutes after its end, or the current time for an active problem. Narrow further on scan-limit signals.

**Stop:** If no problem can be confirmed, stop without broad log queries and request a tighter service/time/error scope.

**Output:** Confirmed problem context, classified error patterns, trace timeline and first error origin when available, root-cause hypothesis, affected services, and prioritized next actions.
---
name: dtctl
description: Investigate incidents, debug performance issues, analyze logs, and manage observability resources in Dynatrace using the dtctl CLI. Use this skill whenever the user asks about error rates, latency spikes, service health, crash-looping pods, web vitals, SLO status, open problems, root cause analysis, log patterns, trace analysis, or building dashboards — even if they don't mention Dynatrace by name. Also covers DQL queries, workflow management, notebook and dashboard creation, settings configuration, and any operations against a Dynatrace environment.
---

# Dynatrace Control with dtctl

Operate `dtctl`, the kubectl-style CLI for Dynatrace. This skill teaches core dtctl command patterns and operations.

## Recommended Initialization

At the start of a task, run these checks to establish context and permissions:

```bash
# Discover all available commands, flags, and resources
dtctl commands --brief -o json

# Show current context
dtctl config current-context

# Show context details
dtctl config describe-context $(dtctl config current-context) --plain

# Show authenticated user
dtctl auth whoami --plain
```

This displays:
- Current context name and environment URL
- Safety level (readonly, readwrite-mine, readwrite-all, dangerously-unrestricted)
- Authenticated user identity (name, email, UUID)

## DQL Reference Usage

Before writing, modifying, or executing any DQL that fetches Dynatrace data (for example via `dtctl query`, `dtctl wait query`, or query files), you MUST consult `references/DQL-reference.md` and follow its documented syntax and templates.

If there is any conflict between memory/assumptions and the reference, prefer the reference.

## Prerequisites

If dtctl is not installed or not working, see [references/troubleshooting.md](references/troubleshooting.md) for installation and setup.

## Resources & Commands

### Available Resources

dtctl uses a uniform pattern for all resource types. Discover schema from actual output with `dtctl describe <resource> <id> -o json --plain`.

| Resource | Aliases |
|----------|---------|
| analyzer | analyzers |
| anomaly-detector | ad |
| app | apps |
| azure-connection | azure-connections |
| azure-monitoring | azure monitoring configs |
| breakpoint | breakpoints *(experimental)* |
| bucket | bkt |
| copilot-skill | copilot-skills |
| dashboard | dash |
| document | documents |
| edgeconnect | ec |
| extension | ext, extensions |
| extension-config | extcfg, extension-configs |
| function | fn, func |
| gcp-connection | gcp-connections |
| gcp-monitoring | gcp monitoring configs |
| group | groups |
| hub-extension | hub-extensions |
| hub-extension-release | hub-extension-releases |
| intent | intents |
| lookup | lookups, lkup |
| notebook | nb |
| notification | notifications |
| sdk-version | sdk-versions |
| segment | segments |
| settings | setting |
| settings-schema | schema |
| slo | - |
| slo-template | slo-templates |
| trash | deleted |
| user | users |
| wfe-task-result | - |
| workflow | wf |
| workflow-execution | wfe |

Use IDs whenever possible instead of names to avoid ambiguity.

### Command Verbs

| Verb | Description | Example |
|------|-------------|---------|
| **get** | List resources | `dtctl get workflows --mine` |
| **describe** | Show resource details | `dtctl describe workflow <id>` |
| **create** | Create resources | `dtctl create extension --hub-extension <id>` |
| **edit** | Edit resource interactively | `dtctl edit dashboard <id>` |
| **update** | Update resource fields | `dtctl update azure connection <id>` |
| **apply** | Create/update from file | `dtctl apply -f workflow.yaml --set env=prod` |
| **delete** | Delete resource | `dtctl delete workflow <id>` |
| **enable** | Enable cloud monitoring | `dtctl enable gcp monitoring <id>` |
| **exec** | Execute workflow/function/analyzer/copilot | `dtctl exec workflow <id>` |
| **query** | Run DQL query | `dtctl query "fetch logs \| limit 10"` |
| **logs** | Print resource logs | `dtctl logs workflow-execution <id>` |
| **wait** | Wait for conditions | `dtctl wait query "fetch logs" --for=any` |
| **history** | Show document history | `dtctl history dashboard <id>` |
| **restore** | Restore document version | `dtctl restore dashboard <id> --version 3` |
| **share** | Share document | `dtctl share dashboard <id> --user email@example.com` |
| **unshare** | Remove sharing | `dtctl unshare dashboard <id> --user email@example.com` |
| **find** | Discover resources | `dtctl find intents --data trace.id=abc` |
| **open** | Open in browser | `dtctl open intent <app/intent> --data key=value` |
| **diff** | Compare resources | `dtctl diff -f workflow.yaml` |
| **verify** | Validate without executing | `dtctl verify query 'fetch logs' --fail-on-warn` |
| **skills** | Manage AI agent skill files | `dtctl skills install --for copilot` |
| **commands** | List all commands (machine-readable) | `dtctl commands --brief -o json` |

## Key Concepts for AI Agents

### Output Modes

```bash
# Agent envelope mode (auto-detected in AI environments)
-A, --agent      # Structured JSON envelope with ok/result/error/context
--no-agent       # Opt out of auto-detected agent mode

# Machine-readable formats (use these for AI agents)
-o json          # JSON output
-o yaml          # YAML output
-o csv           # CSV output
-o toon          # TOON — Token-Oriented Object Notation (~40-60% fewer tokens than JSON, ideal for AI)
-o chart         # ASCII chart (for time series)
-o sparkline     # ASCII sparkline (for time series)
-o barchart      # ASCII bar chart (for time series)

# Human-readable formats
-o table         # Table format (default)
-o wide          # Wide table with more columns

# Always use --plain flag for AI consumption (implied by --agent)
--plain          # Strips colors and prompts, best for parsing
```

**For AI agents, prefer:** `-A -o toon` for maximum token efficiency, or `dtctl <command> -o json --plain` for full structured output.

The `--agent` envelope provides structured metadata alongside results:

```json
{
  "ok": true,
  "result": [ ... ],
  "context": {
    "verb": "get", "resource": "workflow",
    "total": 5, "has_more": false,
    "suggestions": ["Run 'dtctl describe workflow <id>' for details"]
  }
}
```

### Template Variables

In YAML/DQL files, use Go template syntax:

```yaml
# workflow.yaml
title: "{{.environment}} Deployment"
owner: "{{.team}}"
trigger:
  schedule:
    cron: "{{.schedule | default "0 0 * * *"}}"
```

```dql
# query.dql
fetch logs
| filter host.name == "{{.host}}"
| filter timestamp > now() - {{.timerange | default "1h"}}
```

Execute with: `dtctl apply -f file.yaml --set environment=prod --set team=platform`

### Copilot, Functions, Analyzers

```bash
# Copilot skills
dtctl get copilot-skills -o json --plain

# Functions
dtctl get functions -o json --plain
dtctl exec function <id-or-name> --payload '{"key":"value"}' --plain

# Analyzers
dtctl get analyzers -o json --plain
dtctl exec analyzer <id-or-name> --input '{"timeframe":"now-2h"}' --plain
```

Prefer `get ... -o json --plain` first, then `describe`/`exec` with explicit IDs.

### Authentication & Permissions

```bash
# Check current user and permissions
dtctl auth whoami --plain
dtctl auth can-i create workflows
dtctl auth can-i delete dashboards

# Check OAuth session health (token validity, expiry, refresh token presence)
dtctl auth status
dtctl auth status -o json --plain
```

Use `can-i` to verify permissions before attempting operations. Use `auth status` to diagnose token expiry or keyring issues.

## Quick Reference: DQL Queries

**Required workflow for DQL data fetching:**
1. First consult `references/DQL-reference.md`
2. Build/validate the query using the documented patterns
3. Execute with `dtctl query ... -o json --plain` (or `dtctl wait query ...` when waiting for results)

```bash
# Inline query
dtctl query "fetch logs | filter status='ERROR' | limit 100" -o json --plain

# Query from file with variables
dtctl query -f query.dql --set host=h-123 --set timerange=2h -o json --plain

# Wait for query results
dtctl wait query "fetch spans | filter test_id='test-123'" --for=count=1 --timeout 5m

# Query with chart output
dtctl query "timeseries avg(dt.host.cpu.usage)" -o chart --plain

# Cancel with Ctrl+C — dtctl explicitly cancels the server-side Grail job

# Grail filter segments — scope query to a segment (AND-combined, max 10)
dtctl query "fetch logs | limit 100" --segment <seg-id-or-name> -o json --plain
dtctl query "fetch logs | limit 100" -S "seg?var=val" -o json --plain   # inline variable binding

# Include query metadata (cost, execution time)
dtctl query "fetch logs | limit 10" --metadata -o json --plain
```



## Apply — Advanced Flags

```bash
# Auto-share newly created notebook/dashboard environment-wide
dtctl apply -f dashboard.yaml --share-environment          # read access (default)
dtctl apply -f dashboard.yaml --share-environment=read-write

# Idempotent applies: write generated ID back into source file (no duplicates on re-run)
dtctl apply -f workflow.yaml --write-id

# Inject/override resource ID without modifying the file (useful in CI)
dtctl apply -f workflow.yaml --id <existing-id>

# Validate with pre-apply hook before sending to API
# Configure hook in config: preferences.hooks.pre-apply = "./validate.sh"
dtctl apply -f workflow.yaml --no-hooks   # skip hooks for this run

# Bulk apply: file may contain an array of resources
dtctl apply -f settings-export.yaml      # each element applied individually
```

## Workflow Execution Results

```bash
# Execute workflow and wait, then print each task's return value
dtctl exec workflow <id> --wait --show-results -o json --plain

# Retrieve a specific task result from a completed execution
dtctl get wfe-task-result <execution-id> --task <task-name> -o json --plain
```

## Anomaly Detectors

```bash
# Full CRUD for custom anomaly detectors
dtctl get anomaly-detectors -o json --plain
dtctl get ad --enabled -o json --plain          # filter by enabled state
dtctl describe anomaly-detector <id> --plain    # includes recent problems via DQL
dtctl apply -f anomaly-detector.yaml --plain
dtctl delete anomaly-detector <id>
```

## Grail Segments

```bash
# Manage filter segments
dtctl get segments -o json --plain
dtctl describe segment <id-or-name> --plain
dtctl apply -f segment.yaml --plain
dtctl delete segment <id>

# Segment filters can be written as DQL expressions (dtctl converts to/from AST)
# Example segment YAML:
# name: "Production Errors"
# filter: status == "ERROR" and cloud.provider == "aws"
```

## Cloud Integrations (Azure & GCP)

```bash
# Azure
dtctl get azure connections -o json --plain
dtctl describe azure connection <id> --plain
dtctl create azure connection -f azure-conn.yaml
dtctl get azure monitoring -o json --plain
dtctl create azure monitoring -f azure-mon.yaml    # created as disabled
dtctl enable azure monitoring <id>                 # enable in one step

# GCP
dtctl get gcp connections -o json --plain
dtctl create gcp connection -f gcp-conn.yaml
dtctl get gcp monitoring -o json --plain
dtctl create gcp monitoring -f gcp-mon.yaml        # created as disabled
dtctl enable gcp monitoring <id> --serviceAccountId <sa-id>
```

## Hub Extensions

```bash
# Browse and install Hub catalog extensions (read-only catalog)
dtctl get hub-extensions -o json --plain
dtctl get hub-extensions --filter "opentelemetry" -o json --plain
dtctl describe hub-extension <id> --plain
dtctl get hub-extension-releases <id> -o json --plain

# Install a Hub extension (creates monitoring config)
dtctl create extension --hub-extension <id>              # latest release
dtctl create extension --hub-extension <id> --version 1.2.3
dtctl create extension -f custom-extension.zip           # custom extension package
```

## Documents (Generic)

```bash
# Generic Document API lifecycle management
dtctl get documents -o json --plain
dtctl describe document <id> --plain
dtctl history document <id>
dtctl restore document <id> --version 2
```

## Live Debugger (Experimental)

```bash
# Breakpoint management
dtctl get breakpoints -o json --plain
dtctl create breakpoint <file:line>
dtctl describe breakpoint <id-or-file:line> --plain
dtctl update breakpoint <id> --condition "x > 0" --enabled
dtctl delete breakpoint <id>
dtctl delete breakpoint --all

# Decode Live Debugger snapshots from DQL output
dtctl query "fetch dt.debugger.snapshots | limit 5" --decode-snapshots -o json --plain
dtctl query "fetch dt.debugger.snapshots | limit 5" --decode-snapshots=full -o json --plain
```

## Skills Management

```bash
# Install/update the dtctl AI skill for your agent
dtctl skills install                         # auto-detects current agent
dtctl skills install --for copilot           # GitHub Copilot
dtctl skills install --for claude            # Claude Code
dtctl skills install --for cursor            # Cursor
dtctl skills install --for kiro              # Kiro IDE
dtctl skills install --cross-client         # .agents/skills/ (all compatible agents)
dtctl skills install --global               # user-wide installation
dtctl skills status                          # check installation status
dtctl skills uninstall --for copilot
```

## Observability (OpenTelemetry)

dtctl supports W3C Trace Context propagation and OTLP span export. Every dtctl invocation creates an OpenTelemetry span — useful for tracing dtctl calls within CI/CD pipelines:

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=https://YOUR_TENANT.live.dynatrace.com/api/v2/otlp
export TRACEPARENT=<parent-trace-context>   # inherit from calling pipeline
dtctl query "fetch logs | limit 10" -o json --plain   # appears as child span
```

## Dashboards

For full examples and field-level gotchas, see [references/resources/dashboards.md](references/resources/dashboards.md).

Create/update: `dtctl apply -f dashboard.yaml --plain`. Export for reference: `dtctl get dashboard <id> -o yaml --plain`.

### YAML skeleton

```yaml
name: "Dashboard Name"
type: dashboard
content:
  annotations: []
  importedWithCode: false
  settings:
    defaultTimeframe:
      enabled: true
      value: { from: now()-2h, to: now() }
  layouts:
    "1":                    # string key, must match a tile key
      x: 0                 # 24-column grid (full=24, half=12, third=8)
      "y": 0               # MUST quote "y" to avoid YAML boolean parse
      w: 12
      h: 6
  tiles:
    "1":
      title: "Tile Title"
      type: data            # data | markdown
      query: |
        fetch logs | limit 10
      visualization: lineChart
      visualizationSettings:
        autoSelectVisualization: false
      davis: { enabled: false, davisVisualization: { isAvailable: true } }
```

### Tile types & visualizations

- **`type: data`** — DQL tile with `query` + `visualization`: `singleValue`, `lineChart`, `areaChart`, `barChart`, `pieChart`, `table`, `honeycomb`, `scatterplot`
- **`type: markdown`** — static text via `content` field (supports markdown)

For detailed visualizationSettings (singleValue, charts, tables, thresholds, unit overrides), see [references/resources/dashboards.md](references/resources/dashboards.md).

### Gotchas
- Always set `davis.enabled: false` on data tiles.
- Use `makeTimeseries` for log/span time series; `timeseries` for metrics.
- `version` field warning on create is benign.
- No `id` field → creates new; with `id` field → updates existing.

## Common Issues

**Name resolution ambiguity:**
- If a name matches multiple resources, dtctl will fail
- Solution: Use IDs instead of names
- Find ID: `dtctl get <resource> -o json --plain | jq -r '.[] | "\(.id) | \(.name)"'`

**Permission denied:**
- Check token scopes: https://github.com/dynatrace-oss/dtctl/blob/main/docs/TOKEN_SCOPES.md
- Verify permissions: `dtctl auth can-i <verb> <resource>`
- Check safety level: `dtctl config describe-context $(dtctl config current-context) --plain`

**Context/safety blocks:**
- Destructive operations may be blocked by safety level
- Switch context: `dtctl config use-context <name>`
- Adjust safety level when creating context

## Additional Resources

- **Troubleshooting**: [references/troubleshooting.md](references/troubleshooting.md)
- **Multi-tenant setup**: [references/config-management.md](references/config-management.md)
- **DQL syntax and templates**: [references/DQL-reference.md](references/DQL-reference.md)
- **Notebooks**: [references/resources/notebooks.md](references/resources/notebooks.md)
- **Extensions**: [references/resources/extensions.md](references/resources/extensions.md)
- **CLI help**: `dtctl --help`, `dtctl <command> --help`

## Safety Reminders

- Use `--plain` for machine/AI consumption
- Confirm context + safety level before destructive ops; prefer `get/describe` first
- Use `--mine` flag to filter resources you own
- For multi-tenant work, see [references/config-management.md](references/config-management.md)

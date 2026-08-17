---
name: dtctl
description: Investigate incidents, debug performance issues, analyze logs, and manage observability resources in Dynatrace using the dtctl CLI. Use this skill whenever the user asks about error rates, latency spikes, service health, crash-looping pods, web vitals, SLO status, open problems, root cause analysis, log patterns, trace analysis, or building dashboards — even if they don't mention Dynatrace by name. Also covers DQL queries, workflow management, notebook and dashboard creation, settings configuration, and any operations against a Dynatrace environment.
---

# Dynatrace Control with dtctl

Operate `dtctl`, the kubectl-style CLI for Dynatrace. Pattern: `dtctl <verb> <resource> [flags]`.

This skill targets dtctl v0.38.0 or newer. Confirm with `dtctl version`.

## Initialization

Run once to establish context, permissions, and the command catalog:

```bash
dtctl doctor                            # config, context, token, connectivity, auth
dtctl commands                          # compact overview: verbs, resources, subcommands (TOON default)
# dtctl commands --brief                 # + mutating/access/scopes + flag types
# dtctl commands --full                  # exhaustive catalog: descriptions, flag defaults, global flags
dtctl config current-context            # active context
dtctl config describe-context $(dtctl config current-context) --plain  # env URL + safety level
dtctl auth status --plain               # token type (OAuth vs API/platform) + safety level
dtctl inventory                         # what data exists HERE: fetchable objects, buckets, entity census, capabilities
```

Safety levels: `readonly`, `readwrite-mine`, `readwrite-all`, `dangerously-unrestricted`.

`dtctl commands` answers "what can I run?"; `dtctl inventory` answers "what is there to query?" — run it before exploratory DQL. It partitions catalog objects into fetchable vs query-only (never `fetch metrics` or `fetch smartscape.*`), and reports capabilities as present, absent (with the evidence checked — cite it instead of re-probing), or unknown (no verdict; not evidence of absence). Org-specific capability definitions: `--definitions file.yaml`.

Don't use `dtctl auth whoami` to test connectivity — it needs an OAuth token with `app-engine:apps:run` and returns a spurious 403 for plain API or read-scoped tokens even when reads work. Confirm with a real `get`/`query`.

## DQL (required reading)

Before writing, modifying, or running any DQL (`dtctl query`, `dtctl wait query`, query files), consult `references/DQL-reference.md` and follow it over any assumption or memory.

```bash
dtctl query 'fetch logs | filter status == "ERROR" | limit 100' -o json --plain
dtctl query -f query.dql --set host=h-123 --set timerange=2h -o json --plain   # Go-template vars
dtctl wait query 'fetch spans | filter test_id == "test-123"' --for=count=1 --timeout 5m
dtctl query "timeseries avg(dt.host.cpu.usage)" -o chart --plain
```

Long-running queries show a live progress bar on stderr; add `--no-progress` to suppress it (e.g. when piping stderr somewhere unexpected).

dtctl not installed/working? See [references/troubleshooting.md](references/troubleshooting.md).

## Resources & verbs

Resources and aliases are discoverable via `dtctl commands` (run at init). They include: analyzer, anomaly-detector, api, app, aws/azure/gcp connection & monitoring, breakpoint, bucket, copilot-skill, dashboard, document, edgeconnect, extension, extension-config, function, hub-extension, intent, lookup, notebook, notification, segment, settings, settings-schema, slo, slo-template, trash, workflow, workflow-execution, and workflow task result. **Use IDs, not names** — names may be ambiguous and fail.

| Verb | Example |
|------|---------|
| get / describe | `dtctl get workflows --mine` · `dtctl describe workflow <id>` |
| create / update | `dtctl create breakpoint path/File.java:42` · `dtctl update breakpoint <id> --enabled=false` |
| apply / edit / delete | `dtctl apply -f wf.yaml --set env=prod --write-id` · `dtctl delete workflow <id>` |
| enable / disable | `dtctl enable aws monitoring --name prod` · `dtctl disable azure monitoring --name prod` |
| exec | `dtctl exec function <id> --payload '{...}'` · `dtctl exec analyzer <id> --input '{...}'` · `dtctl exec preview-processor --config-id <id>` · `dtctl exec api /path [-X METHOD] [-d BODY\|@file\|@-] [--dry-run]` (also workflow, copilot) |
| query / wait | `dtctl query "fetch logs \| limit 10"` · `dtctl wait query ... --for=any` |
| inspect | `dtctl inspect <file> --head 20` · `--jq 'select(.status == 500)'`, `--tail`, `--page --offset N --limit M`, `--fields a,b`, `--schema`, `--stats`, `--sample N`, `--list` (local spilled-file access — no Grail re-query) |
| logs / history / restore | `dtctl logs workflow-execution <id>` · `dtctl restore dashboard <id> --version 3` |
| share / unshare | `dtctl share dashboard <id> --user a@example.com` |
| find / open | `dtctl find intents --data trace.id=abc` · `dtctl open intent <app/intent> --data k=v` |
| diff / verify | `dtctl diff -f wf.yaml` · `dtctl verify query 'fetch logs' --fail-on-warn` · `dtctl verify analyzer <id> -f in.json` · `dtctl verify openpipeline-matcher '<dql>'` · `dtctl verify openpipeline-dql-processor '<script>'` · `dtctl exec preview-processor --config-id <id>` |
| translate | `dtctl translate lql-to-dql 'log.source="x"'` · `dtctl translate classic-pipelines logs` |

Davis analyzers: before running one, `dtctl describe analyzer <id>` shows its required/optional inputs and result schema (add `--doc` for full docs, `-o json` for the raw schemas); `dtctl verify analyzer <id> -f in.json` validates an input without executing (exit 0 valid / 1 invalid).

All `exec` subcommands (including `exec function`) gate on the active safety level from v0.38.0 — a `readonly` context blocks them.

Anomaly detectors are round-trippable between environments: `dtctl get anomaly-detector <id> -o yaml --plain > detector.yaml` then `dtctl apply -f detector.yaml --context <target-context> --plain`.

Migrating a Classic pipeline to OpenPipeline: `dtctl translate classic-pipelines <scope>` (e.g. `logs`, `bizevents`) calls the translation endpoint and prints a ready-to-review translated config — a starting point, not an apply-in-place operation. Requires `settings:objects:read` scope. If a scope has no Classic pipeline configured, dtctl reports that on stderr (and emits `null` in structured output) rather than erroring.

Settings mutations support a dry run: `dtctl create settings -f settings.yaml --schema <schema> --scope <scope> --validate-only` validates against the API without creating/editing/deleting anything (same flag on `edit settings` / `delete settings`).

Cloud monitoring configs (aws/azure/gcp) support `disable`/`enable` (toggles the config and its credentials off/on in one step, config and connection preserved) and `edit` in addition to `create`/`update`/`delete`: `dtctl disable azure monitoring --name "my-azure-monitoring"`.

Other top-level utilities: `dtctl ctx` quickly lists or switches contexts; `dtctl alias set|list|delete|export|import` manages reusable commands; `dtctl doctor` checks local health; `dtctl commands howto` emits a Markdown guide; `dtctl inventory` discovers environment data; and `dtctl plugin list` shows kubectl-style `dtctl-*` exec plugins found on `PATH`. Built-ins always win over plugins, and dtctl passes context metadata to plugins but strips its documented token variables.

## API Discovery & Passthrough

dtctl wraps ~20 platform APIs natively; reach any other via API discovery and the governed HTTP passthrough. This surface is intentionally low-profile — visible only in `dtctl commands --full` and granted by no command profile:

```bash
dtctl get apis                              # all APIs the environment publishes; DTCTL column shows native coverage
dtctl get apis --uncovered                  # only APIs with no native dtctl command (contribution backlog)
dtctl get apis --ops-count                  # include operation count per API
dtctl describe api <name>                   # operation index: METHOD /path, summary, declared scopes
dtctl describe api <name> --operation 'GET /path'  # full drill-in: params, body schema, responses, ready-to-run invocation
dtctl describe api <name> --raw             # raw spec dump
dtctl exec api /path [-X METHOD] [-d BODY|@file|@-] [-H 'Name: value'] [--dry-run]
```

The safety verdict for `exec api` is derived from the API's own specification — not just the HTTP method. A POST that declares only a read scope (e.g., a search endpoint) is treated as read-safe; the verdict takes the stricter of method and spec floors. An unresolvable request defaults to **delete** safety, and there is no flag to override. A `readonly` context blocks any operation that doesn't resolve as safe.

## Output for agents

`--agent`/`-A` is auto-detected in AI environments (implies `--plain`; opt out with `--no-agent`). Explicit `-o json` preserves auto-detected agent mode; explicit non-JSON output opts out. Agent mode wraps output in `{ok, result, context}` (errors: `{ok:false, error:{code,message}}`, where `context` carries `total`, `has_more`, `suggestions`). Query cost/performance metadata such as scanned bytes and query ID is emitted under the envelope's top-level `metadata` key.

```bash
-o toon          # token-efficient structured output — prefer for agents
-o json|yaml|csv # other machine formats
-o jsonl|parquet # streaming / columnar export for large results (pipe to a file, query with DuckDB)
-o chart|sparkline|barchart   # time series
-o table|wide    # human-readable (table is the default)
--jq '.[].id'    # filter structured output (json|yaml|toon; other formats auto-promote to json)
--typed          # cast scalar columns to native types: long/duration→number, boolean→real bool; safe for jq arithmetic; opt-in
--include-types  # add DQL declared type block for all columns (including nulls) to json/yaml output; implied by --typed
```

Parquet output is self-describing: the full DQL type block (including null-only columns Grail omits) is written into the file footer under `dtctl.dql.types`. Readable via DuckDB's `parquet_kv_metadata()` for full schema recovery without re-querying.

Prefer `--agent` plus `-o toon` and `--jq` to cut tokens.

### Query results: branch on `result.kind`

In agent mode `dtctl query` defaults to `--spill=auto`: large results spill to a local file and return a summary instead of dumping rows into context. Never assume `result` is an array — branch on `result.kind`:

| `result.kind` | Meaning → action |
|---|---|
| `records` | rows inline under `result.records` → use directly |
| `result-file` | spilled: manifest with `path`, `format`, `rows`, `bytes`, column stats, `sample_rows` → interrogate the file with `dtctl inspect <path>` (below), **don't re-query** |
| `summary-only` | rows couldn't be written — manifest minus `path` → use stats/sample, or follow the cause-aware `context.suggestions` (`--spill=never` + a bound, or `--spill-to <path>`) |

Treat an unknown `kind` as opaque and fall back to `context` (`decided`, `total`, `warnings`, `suggestions`). Sampled results put stats in a `sample_stats` block (`basis: "sample"`) — not population truth.

```bash
dtctl query "fetch logs | limit 1000000" --agent     # auto-spills if large
dtctl query "fetch logs" --spill=never               # force every row inline
dtctl query "fetch logs" --spill-to ./out.jsonl      # explicit path: jsonl|json|csv|parquet
dtctl query "fetch logs" --spill=auto --spill-threshold 100KB
```

### Inspect a spilled file (no Grail re-query)

`dtctl inspect <file>` reads the rows the summary left out — bounded, streaming, agent-context-friendly — so you never re-run the Grail scan. Pick exactly one primitive per call:

```bash
dtctl inspect <path> --head 20                          # first N rows (the manifest never carried rows)
dtctl inspect <path> --tail 10                          # last N rows
dtctl inspect <path> --page --offset 1000 --limit 50    # a window deep in the result (file order)
dtctl inspect <path> --head 20 --fields timestamp,content  # project columns (composable)
dtctl inspect <path> --jq 'select(.status == 500)' --head 20  # first 20 matches from a full-file filter
dtctl inspect <path> --sample 20                        # random N-row sample — for profiling, not sequential reading
dtctl inspect <path> --schema                           # re-derive columns + types + null counts
dtctl inspect <path> --stats                            # re-derive the per-column profile (or --stats=col,col)
dtctl inspect --list                                    # lost the path? enumerate spilled files in this context
```

`inspect --jq` is a streaming, per-record jq filter over the whole file. It composes with one row window (`--head`/`--tail`/`--page`) and `--fields`, but not with `--schema`, `--stats`, or `--sample`; its program must emit objects. `inspect` is not a query engine — there is no SQL or `GROUP BY`. For aggregates, push the work back into DQL (`… | summarize …`); for complex local analysis, hand the file to your preferred local analytics tooling. An oversized result re-spills to a new file rather than flooding context, and `inspect` refuses files from another context/tenant.

## Log pattern analysis (token-frugal)

For free-text log triage, don't dump raw `content` — extract the taxonomy server-side, then drill:
1. `dtctl exec analyzer dt.statistics.clustering.LogPatternExtractor --input '{"logQuery":"<DQL>","numberOfExamples":2}'` → DPL templates + match counts. `logQuery` is a **plain DQL string** (not an object) yielding `timestamp`+`content`. Projects well with `--jq` to `{patternExpression, numberOfMatches}`.
2. Lift a `patternExpression` verbatim into `parse content, "..."` (rename captures `f_1`→meaningful), then `summarize … by:{field}` to extract/count at row scale. Unmatched lines yield null captures.
3. Need raw rows? Drill with `fetch … --agent` and let it spill (above), then read them with `dtctl inspect <path> --head/--page` (above).

## Apply & templates

`dtctl apply` creates when no ID is known and updates when the file contains an `id`. On the first apply, use `--write-id` to stamp the generated ID into the source file (v0.38.0: this now actually rewrites the file — it was a silent no-op before); use `--id <existing-id>` to target a known resource or recover a first apply that omitted `--write-id`. When creating without `--write-id`, dtctl prints a stderr hint suggesting how to make future runs update instead of create. Use `--type <type>` to force a file to be applied as a specific custom document type, bypassing content detection. YAML/DQL files support Go templates filled via `--set`:

For custom document types, prefer `dtctl update document -f <file> [--type <type>] [--id <id>]` over `apply` when updating an existing document — it fails instead of silently creating when the target ID is missing, so a typo in the ID never spawns a stray document. Use `--label key=value` (repeatable) on `create document` or via `apply` to set document labels; the SDK applies them in a follow-up update since the create API can't set them directly.

```yaml
title: "{{.environment}} Deployment"
cron: "{{.schedule | default "0 0 * * *"}}"
```
`dtctl apply -f file.yaml --set environment=prod --set schedule="0 6 * * *"`

## Live Debugger

Breakpoints require OAuth authentication. Scope workspace filters carefully because changing them re-scopes all existing breakpoints in that workspace.

```bash
dtctl create breakpoint com/example/Service.java:42 --filters k8s.namespace.name:prod
dtctl get breakpoints                                    # includes LOG MESSAGE column
dtctl describe breakpoint <id>                           # shows condition and log message
dtctl update breakpoint <id> --condition "userId != null"
dtctl update breakpoint <id> --log-message "{frame.line}: {x}"  # {variable} placeholders; backend prefixes stripped in display
dtctl get snapshots <breakpoint>                         # by filename:line or stable rule ID — no immutableId lookup needed
dtctl query "fetch application.snapshots | limit 10" --decode-snapshots=simplified
dtctl delete breakpoint <id>
```

`dtctl get snapshots` supports `--decode-snapshots`, `-o json/yaml`, timeframe flags, and `--max-result-records`.

## Dashboards

Create/update: `dtctl apply -f dashboard.yaml`. Export for reference: `dtctl get dashboard <id> -o yaml --plain`. Full schema + visualizationSettings: [references/resources/dashboards.md](references/resources/dashboards.md).

```yaml
name: "Dashboard Name"
type: dashboard
content:
  settings:
    defaultTimeframe: { enabled: true, value: { from: now()-2h, to: now() } }
  layouts:
    "1": { x: 0, "y": 0, w: 12, h: 6 }    # 24-col grid (full=24); quote "y" (YAML bool)
  tiles:
    "1":
      title: "Tile"
      type: data                          # data | markdown
      query: "fetch logs | limit 10"
      visualization: lineChart            # singleValue|lineChart|areaChart|barChart|pieChart|table|honeycomb|scatterplot
      davis: { enabled: false, davisVisualization: { isAvailable: true } }
```

Gotchas: set `davis.enabled: false` on data tiles; `makeTimeseries` for log/span series, `timeseries` for metrics; `id` present → update, absent → create; the `version` warning on create is benign.

## Permissions & safety

- Verify before mutating: `dtctl auth can-i <verb> <resource>`. Scopes: [TOKEN_SCOPES.md](https://github.com/dynatrace-oss/dtctl/blob/main/docs/TOKEN_SCOPES.md).
- Preflight scopes before a mutating command instead of discovering a gap via a mid-task 403: `dtctl <verb> <resource> --check-scopes` (preflights the active token, doesn't execute) and `dtctl commands "<verb> <resource>" --required-scopes` (least-privilege scope union for a command). In agent mode, mutating commands auto-preflight and return a structured `insufficient_scope` envelope instead of a raw 403.
- Destructive ops may be blocked by safety level — switch with `dtctl config use-context <name>`, or raise the level when creating the context.
- Prefer `get`/`describe` first; `--mine` scopes to resources you own; `--plain` for all machine consumption.
- Restrict the exposed command surface itself with a command profile (`--profile query` on a context, or `DTCTL_PROFILE=query`) — useful when embedding dtctl for a narrowly-scoped agent. See [references/config-management.md](references/config-management.md).

## More

[troubleshooting](references/troubleshooting.md) · [multi-tenant config](references/config-management.md) · [DQL](references/DQL-reference.md) · [notebooks](references/resources/notebooks.md) · [extensions](references/resources/extensions.md) · `dtctl --help`, `dtctl <command> --help`

# Changelog

## [5.1.0] - 2026-07-13

### Breaking
- Raised the minimum required `dtctl` version from v0.32.0 to **v0.34.0** in `setup.sh`, `README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.

### Added
- **`dt-obs-genai` skill** — LLM/GenAI observability: golden signals (traffic, errors, latency, saturation), LLM signals (model, provider, tokens), cost/token analytics and usage attribution, agent signals (tool calls, steps, loop detection), conversation/session analytics, guardrails, and evaluation results — reads OpenTelemetry GenAI spans and LLM evaluation bizevents.
- **`dt-obs-log-semantic-mapping` skill** — suggests and validates semantic dictionary mappings for audit log integrations (authentication, authorization, user actions, HTTP traffic) from raw vendor payloads or live ingested events; includes sample mappings for CyberArk, Okta, Azure, GitHub, Sonatype, and HTTP logs.
- **`dt-sec-semantic-mapping` skill** — suggests and validates semantic dictionary mappings for new security integrations (vulnerabilities, detections, compliance) against vendor API samples or live tenant data; includes sample mappings for Dynatrace-native and external security event shapes.
- `.claude/skills/` symlinks added for all 3 new skills.
- All 3 new skills added to the skill tables in `README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `llms.txt`, `docs/CHEATSHEET.md`.
- `dtctl` skill: documented v0.33.0–v0.34.0 dtctl capabilities —
  - `dtctl commands` now defaults to a compact TOON overview instead of ~52 KB JSON; `--brief`/`--full` retained for more detail
  - Query result agent-mode `result.kind` branching (`records` / `result-file` / `summary-only`) and `--spill=auto|never`, `--spill-to`, `--spill-threshold` flags
  - Live progress bar on long-running queries (stderr), with `--no-progress` to suppress it
  - Scan-limit truncation is now flagged explicitly in agent mode with data-reduction advice, instead of a silent partial/empty result
  - Timeseries metric metadata (display name, description, unit) is now included automatically in agent mode — no longer requires the explicit `--metadata=metrics` flag
  - `describe extension --assets=<types>` (+ `--full` for complete asset content) and `dtctl download extension <name> --version <v>` for extension package/asset inspection without a manual download
  - `DTCTL_CONFIG` environment variable — names an explicit, trusted config file so a prepared workspace's aliases/hooks are honored without touching invocations
  - Command profiles (`--profile query|investigate` on a context, or `DTCTL_PROFILE=...`) — restrict which commands `dtctl commands`/`--help` expose, useful for narrowly-scoped agent embeddings
  - `--validate-only` on `create settings` / `edit settings` / `delete settings` — dry-run against the Settings API
  - Cloud monitoring config `disable`/`enable`/`edit` for AWS/Azure/GCP monitoring configs (in addition to `create`/`update`/`delete`)
- `dtctl` skill: re-applied local-only content that upstream's own token-efficiency rewrite dropped but which is still valid against the current CLI — scope preflighting (`--check-scopes`/`--required-scopes`), `classic-pipelines-translation`, the anomaly-detector round-trip recipe, the `error.details` 400-response note, `--feature-set-metrics` on `describe extension`, and the config-trust model (untrusted local `.dtctl.yaml`). These must be re-applied on every future upstream sync until upstream restores them.

### Changed
- Skill count updated from 24 to 27 across all documentation files.
- Resynced 9 skills from upstream dynatrace-for-ai v5.0.0:
  - `dt-sec-insights` — tightened trigger description and added a CIS-primary standard summary vs. entity security-tab view distinction to `references/compliance.md`, plus refreshed `all-security-events.md`, `common-patterns.md`, `data-model.md`, `mistakes-and-troubleshooting.md`, `vulnerabilities.md`.
  - `dt-platform-costs` — clarified scope boundary against query-optimization questions (routes those to `dt-dql-essentials`); refreshed billing/cost reference files.
  - `dt-dql-essentials` — added a dedicated query-optimization framing (faster/cheaper = less data scanned) and cross-referenced the boundary with `dt-platform-costs`.
  - `dt-app-dashboards`, `dt-app-notebooks` — refreshed "analyzing existing content" guidance.
  - `dt-alerting` — refreshed `references/workflow-notifications.md`.
  - `dt-obs-frontends` — refreshed `references/troubleshooting.md` and `references/user-sessions.md`.
  - `dt-obs-ios-sdk` — refreshed `SKILL.md`.
- `dtctl` skill fully resynced from upstream `dynatrace-oss/dtctl` (main branch, v0.34.0 release commit) — adopts upstream's leaner, more token-efficient `SKILL.md` structure.
- `docs/CHEATSHEET.md`: added quick-reference rows for GenAI observability and semantic mapping questions; dtctl section updated with the TOON-default command catalog, command profiles, `DTCTL_CONFIG`, and scan-limit truncation behavior; "Last Updated" refreshed to July 13, 2026.
- `setup.sh`: updated the dtctl-required-features callout shown on a failed version gate to reflect v0.34.0 capabilities.

### Compatibility
- dynatrace-for-ai v5.0.0

## [5.0.0] - 2026-07-06

### Added
- **`dt-sec-insights` skill** — Security Insights: vulnerabilities (RVA/RAP), MITRE ATT&CK detections, and security posture (KSPM/CSPM/VSPM) via `security.events`.
- **`dt-platform-costs` skill** — DPS billing/usage analysis: cost breakdown, spend ranking, chargeback/showback, and entity-level cost drill-down via `dt.system.events`.
- **Mobile instrumentation skills** — `dt-obs-android`, `dt-obs-flutter`, `dt-obs-ios-sdk`, `dt-obs-react-native`: project-level SDK setup for Android, Flutter, iOS (Swift Package Manager), and React Native/Expo.
- `.claude/skills/` symlinks added for all 6 new skills.
- All 6 new skills added to the skill tables in `README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `llms.txt`, `docs/CHEATSHEET.md`.
- `CONTRIBUTING.md`: "Skill Content Is Upstream-Owned" section documenting that `.agents/skills/` (excluding `dtctl/`) is overwritten wholesale on sync, and flagging the `dt-obs-aws/SKILL.md` dtctl paragraph as a local override that must survive every future sync.

### Fixed
- `dt-obs-kubernetes/references/pod-debugging.md`: DQL reserved-keyword collision — the `init` field alias collided with a DQL keyword; renamed per upstream's fix.
- `dt-obs-hosts/references/host-metrics.md` and `process-monitoring.md`: replaced deprecated `arrayAvg`/`arrayMax`/`arrayMin`/`arrayFirst`/`arrayLast`/`arrayPercentile` + `union:true` DQL patterns with current `summarize`-based syntax.
- `dt-obs-frontends`: full resync — `SKILL.md` and all references were multiple releases behind upstream (missing mobile/sensitive-field documentation, DQL reference links, key-metrics sections); added the missing `references/characteristics.md`.
- `dt-app-dashboards/references/analyzing.md` and `create-update.md`, `dt-migration/references/examples.md` and `mass-data-filtering-strategy.md`, `dt-obs-aws/references/database-monitoring.md`, `load-balancing-api.md`, and `vpc-networking-security.md`, `dt-obs-problems/references/problem-correlation.md` — resynced from upstream; these had silently fallen behind since the v3.0.0-era sync despite that release's commit message claiming they were current.
- `CLAUDE.md` / `.github/copilot-instructions.md`: the "Tool Priority" rule referenced only `dt-obs-*`/`dt-app-*`/`dt-dql-essentials` skills, leaving `dt-sec-insights`, `dt-platform-costs`, `dt-alerting`, and `dt-js-runtime` undocumented as MCP-first telemetry skills. Replaced the enumerated glob with a principle-based statement so it doesn't go stale as new skill categories are added.

### Changed
- Skill count updated from 18 to 24 across all documentation files.
- `README.md` skill table restructured into upstream's categorized layout (DQL & Query Language, Observability, Security, Mobile Instrumentation, Platform, Migration, CLI).
- `dt-obs-aws/SKILL.md` resynced from upstream; the local-only "Check health alerts when:" dtctl paragraph was preserved (re-applied after sync — it does not exist upstream).
- `docs/CHEATSHEET.md`: added quick-reference rows for security/vulnerability questions, mobile instrumentation, and cost analysis; "Last Updated" refreshed to July 6, 2026.

### Compatibility
- dynatrace-for-ai v4.0.0

## [4.0.0] - 2026-07-02

### Breaking
- Raised the minimum required `dtctl` version from v0.30.0 to **v0.32.0** in `setup.sh`, `README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.

### Fixed
- `setup.sh`: the dtctl version gate was silently a no-op — `dtctl version | head -1` captured the full banner line (`"dtctl version X.Y.Z"`), and comparing that string with `>` against `"0.30.0"` was always true (any string starting with a letter sorts after one starting with a digit), so it passed even for `"unknown"` when dtctl wasn't found. Replaced with `grep -oE` version extraction and a `version_ge()` helper using `sort -V`, which also fixes incorrect ordering on multi-digit segments (e.g. `0.30.10` vs `0.30.9`) and fails closed on unparseable input instead of failing open.
- `CONTRIBUTING.md`: the dtctl sync commit-message example had the same raw-banner-line bug (`v$(dtctl version | head -1)` would have produced `"vdtctl version 0.32.0"`); now extracts just the version number.

### Added
- `dtctl` skill: documented v0.31.0–v0.32.0 dtctl capabilities —
  - `-o jsonl` / `-o parquet` export formats for `dtctl query`
  - Result-spill for large query results + `dtctl inspect` (`--head`, `--tail`, `--page`, `--schema`, `--stats`, `--sample`, streaming `--jq`) for analyzing spilled results locally without re-scanning Grail
  - `dtctl describe analyzer` / `dtctl verify analyzer`
  - `--check-scopes` and `dtctl commands --required-scopes` for token-scope preflighting
  - `dtctl get classic-pipelines-translation` for Classic → OpenPipeline migration
  - Azure `clientSecret` connection setup and rotation, plus `--issuer` override
  - `--metadata=metrics` for timeseries queries
  - `--feature-set-metrics` on `describe extension`, with its breaking `featureSets` map→array output-shape change flagged
  - `error.details` now included in dtctl's 400 error messages
- `docs/CHEATSHEET.md`: guidance to prefer `dtctl inspect` over re-querying for large results, and `-o jsonl`/`-o parquet` for external-analytics exports.

## [3.0.0] - 2026-06-16

### Breaking
- Raised the minimum required `dtctl` version to **v0.30.0**. `setup.sh` now fails fast on older versions.
- `deploy_notebook.sh` and `notebook-validator.js` removed from `dt-app-notebooks` skill. Notebook deployment now uses `dtctl apply` directly — validation runs automatically before every deploy.

### Added
- **`dt-alerting` skill** — full coverage of Dynatrace alerting lifecycle: anomaly detector configuration, Davis alert event history, problem denoising patterns, and workflow notification setup. Includes three reference files (`anomaly-detectors.md`, `davis-events.md`, `workflow-notifications.md`).
- **`dt-js-runtime` skill** — Dynatrace server-side JavaScript runtime: function contract, SDK catalog, fetch behavior, and platform limits. Includes the full `@dynatrace-sdk/*` package reference tree (119 files across 25 SDK packages).
- `dtctl` skill: `dtctl auth status` documented as the universal connection check replacing `auth whoami` (which returns 403 with non-OAuth tokens).
- `dtctl` skill: `--jq` flag for inline output reshaping — filters and transforms query results without an external `jq` binary; table/csv output is auto-promoted to JSON (v0.30.0+).
- `dtctl` skill: workflow listing now documents `--filter`, `--started-since`/`--started-until`, and `--limit` flags for scoped agent queries (v0.29.0+).
- `dtctl` skill: per-project `.dtctl.yaml` trust model documented — aliases and hooks are ignored unless using global config or `--config` (v0.29.0+).
- `dt-obs-problems` skill: "Absolute Timeframes Require Double Quotes" gotcha section — prevents a common DQL syntax error when using ISO 8601 timestamps.
- `dt-app-dashboards` skill: "Deploy with `dtctl apply`" step added to the create/update workflow.
- `dt-app-notebooks` skill: `assets/ExampleNotebook.json` and `assets/visualization-settings.reference.jsonc` added from upstream.
- `.claude/skills/dt-alerting` and `.claude/skills/dt-js-runtime` symlinks added for Claude Code compatibility.
- Both new skills added to all skill tables: `CLAUDE.md`, `.github/copilot-instructions.md`, `README.md`, `ARCHITECTURE.md`, `docs/CHEATSHEET.md`.

### Changed
- **`dt-obs-frontends` skill refactored** — replaced 21-file CamelCase monolith with 10 upstream kebab-case reference files: `web-performance-analysis.md`, `user-sessions.md`, `error-tracking.md`, `mobile-monitoring.md`, `web-vitals.md`, `slow-page-load-playbook.md`, `csp-violations.md`, `visibility-changes.md`, `troubleshooting.md`, `user-actions.md`.
- **`dt-app-notebooks` skill refactored** — replaced with upstream 7-step mandatory `dtctl apply` workflow. References split into `create-update.md`, `sections.md`, and `analyzing.md`. Stale `deploy_notebook.sh` workflow removed.
- `dt-dql-essentials` skill: error rate formula corrected — `errors[] * 100.0 / total[]` (array indexing required for `makeTimeseries` results).
- `dtctl` skill: DQL reference updated with `smartscapeNodes` migration patterns replacing legacy `dt.entity.*` fetch queries.
- `dtctl` skill: troubleshooting guide auth section overhauled — `auth status` replaces `auth whoami`; token type guidance clarified.
- Skill count updated from 16 to 18 across all documentation files.
- `dtctl` minimum version updated from v0.28.0 to v0.30.0 in `setup.sh`, `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.
- `CONTRIBUTING.md` dtctl sync guidance generalized — removed v0.28.0 milestone framing; now covers current capabilities including `auth status`, `--jq`, and DQL Smartscape.
- `ARCHITECTURE.md` dtctl section updated — structured workflow input framing no longer pinned to a specific version.
- `docs/CHEATSHEET.md` last updated date refreshed to June 16, 2026.

### Migration Notes
- Upgrade dtctl before using this workspace version:
  `curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash`
- If you maintained a local `deploy_notebook.sh` workflow, switch to `dtctl apply -f notebook.json -o yaml`. Validation and local file cleanup are handled automatically.
- Re-sync the `dtctl` skill after upgrading: the skill now documents `auth status`, `--jq`, and Smartscape DQL patterns not present in older versions.



## [2.1.0] - 2026-06-01

### Added
- `dt-app-dashboards` skill now includes `assets/visualization-settings.reference.jsonc` — per-visualization settings reference covering all chart types (line, area, bar, categorical, pie, donut, single value, meter, gauge, table, histogram, honeycomb, maps, heatmap, scatterplot). This file was referenced in `references/tiles.md` but missing, causing the agent to fall back to general knowledge when constructing visualization settings.
- `dt-app-dashboards` skill now includes `assets/ExampleDashboard.json` — a working example dashboard demonstrating line chart with thresholds, donut chart, and single value tile.

### Changed
- Removed `skills-lock.json` — skill versioning is handled by git; the lock file was redundant and went stale on any manual skill edit.
- Removed all guidance to run `npx skills add` from `README.md`, `ARCHITECTURE.md`, and `CONTRIBUTING.md`. Skill updates are now documented as a git workflow (copy upstream files, commit, push).
- Cleared default `allow` permissions from `.claude/settings.json` — end users configure their own permissions after cloning.

## [2.0.2] - 2026-06-01

### Changed
- Updated `setup.sh` Step 2 messaging to be generic about launching VS Code and opening the chat window (supports both Claude Code and GitHub Copilot)
- Clarified Step 3 as optional and better documented the Claude Code CLI workflow with automatic MCP server and skill loading
- Removed unnecessary dtctl version-requirement verbiage from session briefings and simplified version requirement wording in `ARCHITECTURE.md`
- Updated `docs/CHEATSHEET.md` to remove outdated dtctl v0.27 notes and added an explicit CHEATSHEET-first instruction in both `CLAUDE.md` and `.github/copilot-instructions.md`

## [2.0.1] - 2026-05-29

### Changed
- Aligned `.github/copilot-instructions.md` with `CLAUDE.md` for dtctl v0.28.0+ guidance, including workflow execution notes and version requirements.
- Preserved Copilot-specific setup wording: "Run `bash setup.sh` to configure your Dynatrace environment on first use."

## [2.0.0] - 2026-05-26

### Breaking
- Raised the minimum required `dtctl` version to v0.28.0.
- `setup.sh` now fails fast when `dtctl` is v0.27.1 or earlier.
- Workspace guidance now assumes v0.28.0+ workflow execution patterns.

### Changed
- Added and expanded version requirement documentation for the dtctl minimum version and its rationale.
- Documented dtctl v0.28.0 behavior updates, including structured workflow input via `--input`.
- Updated setup and contributor guidance to align skill and CLI version expectations.
- Aligned session briefing and setup docs to the new dtctl baseline.

### Migration Notes
- Upgrade dtctl before running setup:
	`curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash`
- Verify the installed version:
	`dtctl version`
- If you maintain local skills, re-sync the dtctl skill after upgrade.

## [1.1.3] - 2026-05-19

### Fixed
- Removed trailing comma after the `dtctl` entry in `skills-lock.json` (line 84) that made the file invalid JSON, causing parse failures in `jq` and any automation that reads skill metadata

## [1.1.2] - 2026-05-18

### Changed
- Updated setup guidance in `README.md` and `docs/ELI5.md` to avoid requiring an unnecessary reload when VS Code is being opened for the first time.
- Clarified the VS Code step to support both paths: open the workspace if not yet open, or use `Developer: Reload Window` if already open.
- Aligned troubleshooting wording so verification now refers to the workspace being opened or refreshed after setup.

## [1.1.1] - 2026-05-13

### Fixed
- Removed invalid `_comment` field from `.vscode/mcp.json` that caused MCP config parse errors
- Cleaned up `.github/copilot-instructions.md` to remove stale references

### Changed
- Removed `dtctl-release` and `pr-review` developer-only skills and their dangling symlinks — these were internal tools never intended for the user-facing workspace
- Clarified MCP config documentation: `.mcp.json` serves Claude Code CLI and non-VS Code clients; `.vscode/mcp.json` serves VS Code

---

## [1.1.0] - 2026-05-13

### Added
- Claude Code CLI as a first-class supported client — run `claude` from the workspace directory to start a session with all skills and MCP server active
- `.claude/commands/` directory with slash command symlinks for Claude Code (CLI and VS Code plugin), mirroring `.github/prompts/`
- Claude Code CLI detection and conditional next-step guidance in `setup.sh`
### Fixed
- Corrected prompt invocation syntax across all documentation — Claude Code uses `/command-name`, not `@command-name`
- MCP server now enabled by default in `.claude/settings.local.json` (previously disabled)
- `setup.sh` "Reload VS Code" step is now conditional — only shown when VS Code is detected
- `.mcp.json` correctly documented as serving Claude Code CLI and other non-VS Code clients

---

## [1.0.0] - 2026-05-12

### Initial release

**Investigation workflows (7 prompts)**
- `/health-check` — routine service health: metrics, problems, deployments, vulnerabilities
- `/daily-standup` — morning report across services with today vs yesterday comparison
- `/daily-standup-notebook` — standup report + Dynatrace notebook creation + dtctl verification
- `/investigate-error` — error-focused investigation from a service name
- `/troubleshoot-problem` — deep 7-step investigation into a specific Dynatrace problem
- `/incident-response` — full triage of all active problems during a live incident
- `/performance-regression` — before vs after deployment comparison with rollback/hotfix recommendation

**Domain skills (16)**
- `dt-obs-problems` — Davis problem analysis, root cause, impact assessment
- `dt-obs-logs` — log querying, filtering, pattern analysis, error classification
- `dt-obs-tracing` — distributed traces, spans, failure detection, log correlation
- `dt-obs-services` — RED metrics, SLA tracking, runtime monitoring (Java, .NET, Node.js, Python, PHP, Go)
- `dt-obs-hosts` — host and process metrics, CPU, memory, disk, containers
- `dt-obs-kubernetes` — pods, workloads, nodes, labels, ingress, PVCs
- `dt-obs-aws` — EC2, RDS, Lambda, ECS/EKS, VPC, cost optimization
- `dt-obs-azure` — Azure VMs, AKS, SQL, storage, networking, serverless, cost optimization
- `dt-obs-gcp` — Compute Engine, GKE, Cloud Run, Pub/Sub, VPC, IAM, resource management
- `dt-obs-frontends` — RUM, Web Vitals, user sessions, mobile crashes
- `dt-obs-predictive-analytics` — forecasting, trend detection, anomaly identification, capacity planning
- `dt-app-dashboards` — dashboard JSON creation and modification
- `dt-app-notebooks` — notebook creation and analytics workflows
- `dt-dql-essentials` — DQL syntax, common pitfalls, query patterns
- `dt-migration` — classic entity DQL → Smartscape migration
- `dtctl` — CLI commands for managing Dynatrace resources from the terminal

**Infrastructure**
- MCP server integration (`dynatrace-mcp`) connecting to your Dynatrace tenant
- Dual AI assistant support: Claude Code and GitHub Copilot
- `setup.sh` single-command onboarding
- VS Code workspace configuration with MCP and extension recommendations

**Documentation**
- `README.md` — setup and reference guide
- `ARCHITECTURE.md` — technical overview of how components connect
- `docs/ELI5.md` — beginner-friendly explanation
- `docs/CHEATSHEET.md` — quick reference for skills and prompts
- `CONTRIBUTING.md` — contribution and update workflow
- `llms.txt` — machine-readable workspace summary

**Compatibility**
- dtctl v0.27.1
- dynatrace-for-ai v2.0.0

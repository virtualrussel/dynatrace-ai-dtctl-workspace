# Changelog

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

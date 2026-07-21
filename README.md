# dynatrace-ai-dtctl-workspace

[![Dynatrace](https://img.shields.io/badge/Dynatrace-Intelligence-1284C5?logo=dynatrace&logoColor=white)](https://www.dynatrace.com)
[![GitHub release](https://img.shields.io/github/v/release/virtualrussel/dynatrace-ai-dtctl-workspace?color=blueviolet)](https://github.com/virtualrussel/dynatrace-ai-dtctl-workspace/releases/latest)
[![Commits since release](https://img.shields.io/github/commits-since/virtualrussel/dynatrace-ai-dtctl-workspace/latest)](https://github.com/virtualrussel/dynatrace-ai-dtctl-workspace/commits/main)

An AI-powered observability workspace for Dynatrace that combines GitHub Copilot or Claude AI, the Dynatrace MCP server, dtctl, and the [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) skills framework to accelerate incident triage, root cause analysis, and day-to-day observability workflows.

> **What this gives you:** Ask AI natural language questions about your Dynatrace environment and get accurate, production-aware answers. All powered by verified domain knowledge, live API access, and pre-built investigation workflows.

> **New here?** Start with [docs/ELI5.md](./docs/ELI5.md) for a quick setup, use [docs/PERMISSIONS.md](./docs/PERMISSIONS.md) to configure access, then read [docs/OVERVIEW.md](./docs/OVERVIEW.md) for the big-picture operating model.

---

## What's Inside

Recommended reading order: [docs/ELI5.md](./docs/ELI5.md) → [docs/PERMISSIONS.md](./docs/PERMISSIONS.md) → [docs/OVERVIEW.md](./docs/OVERVIEW.md) → [ARCHITECTURE.md](./ARCHITECTURE.md).

```
dynatrace-ai-dtctl-workspace/
├── README.md                     # Setup guide and quick reference
├── docs/
│   ├── ELI5.md                   # Beginner-friendly 15-minute install guide
│   ├── PERMISSIONS.md            # MCP permission profiles and authorization troubleshooting
│   ├── PROMPT_CONTRACTS.md       # Portable runtime contracts for bundled prompts
│   ├── OVERVIEW.md               # Newcomer guide: purpose, value, and operating model
│   └── CHEATSHEET.md             # Quick reference — workflows, outputs, dtctl, and key rules
├── ARCHITECTURE.md               # How the workspace is built and how components connect
├── CONTRIBUTING.md               # How to update skills, prompts, and MCP config
├── CLAUDE.md                     # Auto-loaded session briefing for Claude Code
├── llms.txt                      # Machine-readable workspace summary for LLMs
├── setup.sh                      # First-time setup script
├── scripts/sync-upstream.sh      # Verify or synchronize pinned upstream content
├── upstream-sources.lock.json    # Immutable source revisions, mappings, inventories, and hashes
├── upstream-patches/             # Explicit overlays applied to pinned upstream content
├── LICENSE
├── .gitignore
├── .github/
│   ├── copilot-instructions.md   # Auto-loaded session briefing for GitHub Copilot
│   └── prompts/                  # 6 upstream investigation workflows
│       ├── health-check.prompt.md
│       ├── daily-standup.prompt.md
│       ├── investigate-error.prompt.md
│       ├── troubleshoot-problem.prompt.md
│       ├── incident-response.prompt.md
│       └── performance-regression.prompt.md
├── .agents/skills/               # 27 Dynatrace domain skills
├── .claude/
│   ├── commands/                 # Slash command symlinks for Claude Code (CLI and plugin)
│   └── skills/                   # Skill symlinks for Claude Code compatibility
├── .mcp.json.template             # Checked-in template — setup.sh generates .mcp.json (gitignored) from this
├── .vscode/
│   ├── mcp.json.template          # Checked-in template — setup.sh generates mcp.json (gitignored) from this
│   ├── extensions.json           # Recommended VS Code extensions
│   └── settings.json             # Workspace editor settings
```

| Tool | Purpose |
|---|---|
| [VS Code](https://code.visualstudio.com/) | Editor with Copilot/Claude Chat |
| [GitHub Copilot](https://github.com/features/copilot) | AI assistant (option 1) |
| [Claude Code](https://claude.ai/code) | AI assistant (option 2) |
| [dtctl](https://github.com/dynatrace-oss/dtctl) v0.34.0+ | Dynatrace open-source CLI for agents & humans to manage observability resources |
| A Dynatrace environment | `https://YOUR_TENANT_ID.apps.dynatrace.com` with permission to create a **Platform Token** |

You must use one AI assistant path: **GitHub Copilot** or **Claude Code**.

---

## Setup

### Choose Your Frontend

This workspace works with:
- **GitHub Copilot** via VS Code plugin (subscription required)
- **Claude Code** via VS Code plugin or web/desktop (Claude Pro or Team required)
- **Claude Code CLI** via the `claude` terminal command — no VS Code required

All three receive the same skills, prompts, and MCP server access. `.github/copilot-instructions.md` is auto-loaded at the start of each Copilot session; `CLAUDE.md` is auto-loaded at the start of each Claude Code session (CLI or plugin).

**Claude Code CLI users:** skip step 1 (VS Code extensions are not needed) and step 5 (no reload required). After cloning and running `setup.sh`, run `claude` from the workspace directory to start.

### 1. Install VS Code extensions (VS Code users only)

VS Code must be installed before running this step. Download from [code.visualstudio.com](https://code.visualstudio.com/) if not already present.

```bash
code --install-extension github.copilot \
  --install-extension anthropic.claude-code
```

> `github.copilot-chat` is bundled with VS Code (v0.47.0+) and does not need to be installed separately.

If `code` is not found, run **Shell Command: Install 'code' command in PATH** from the VS Code Command Palette, then retry.

Verify installed extensions:

```bash
code --list-extensions | grep -E "github.copilot|anthropic.claude-code"
```

### 2. Clone the workspace

```bash
git clone https://github.com/virtualrussel/dynatrace-ai-dtctl-workspace.git
cd dynatrace-ai-dtctl-workspace
```

Continue in the cloned directory for setup.

### 3. Configure your tenant and create a Platform Token

Run the setup script:

```bash
bash setup.sh
```

The script will:
1. Check prerequisites (dtctl, jq, Claude CLI)
2. Prompt for your Dynatrace environment URL (accepts `*.apps.dynatrace.com` and `*.sprint.apps.dynatracelabs.com`). On an already-configured clone, it detects a matching tenant from both generated MCP configs and lets you press Enter to keep it
3. Let you choose a **Full read-only MCP** (recommended) or **Core incident analysis** permission profile and print its exact Platform Token scopes
4. Prompt you to paste your Platform Token
5. Generate `.vscode/mcp.json` and `.mcp.json` from templates

**Reconfiguring an existing clone:** re-running `bash setup.sh` is also how you rotate an expiring Platform Token. Press Enter at the tenant prompt to keep the tenant when both generated configs agree, or type a different tenant to regenerate both configs for it. If either config is missing, malformed, or points at a different tenant, setup requires the tenant explicitly.

Tracked documentation intentionally keeps generic examples such as `YOUR_TENANT_ID.apps.dynatrace.com`. Tenant-specific values are written only to the generated, `.gitignore`'d MCP configs, so setup does not dirty the repository.

**To create a Platform Token:**
1. Go to your Dynatrace tenant: `https://YOUR_TENANT_ID.apps.dynatrace.com`
2. **Account Management** → **Identity & access management** → **Platform tokens**
3. Click the **user profile link** shown in the page description (not a "create" button)
4. Click **Generate new token**
5. Add the scopes listed by `setup.sh`. Choose Full read-only MCP unless your administrator requires the smaller Core profile. See [docs/PERMISSIONS.md](./docs/PERMISSIONS.md) for capabilities, IAM and Grail requirements, and the current verification date.
6. Copy the token — it looks like `dt0s16.ABC12345XYZ.••••••••`
7. Paste it into `setup.sh` when prompted

The token is stored in a `.gitignore`'d generated config file inside this workspace folder. No token is ever committed to git. Deleting the cloned folder removes the token completely.

### 4. Authenticate dtctl

`dtctl` is a hard requirement for this workspace — it provides terminal-level access to Dynatrace resources and is used for verification steps across multiple workflows. Before collecting tenant or token information, `setup.sh` verifies v0.34.0+ or offers to install it. Declining installation, an installer failure, an unavailable binary, or an unsupported version stops setup.

After setup verifies the binary, authenticate dtctl independently:

```bash
# Local desktop (macOS/Windows/Linux with keyring): OAuth login
dtctl auth login --context production \
  --environment "https://YOUR_TENANT_ID.apps.dynatrace.com"

# GitHub Codespaces / CI: token-based auth
dtctl config set-context production \
  --environment "https://YOUR_TENANT_ID.apps.dynatrace.com" \
  --token-ref production-token
dtctl config set-credentials production-token --token <YOUR_PLATFORM_TOKEN>

# Verify
dtctl doctor
```

When `dtctl doctor` reports pass, you are connected. On platform tokens in v0.27.0+, a warning about user identity may appear and is expected.

If using token-based auth: create your platform token in Dynatrace: **Identity & Access Management** → **Access Tokens** → **Generate new token** → **Platform token**.

If OAuth fails with a keyring error (for example, `dbus-launch` not found), use the token-based method above.

### 5. Open or refresh VS Code (VS Code users only)

If this is your first time opening the workspace in VS Code, use **File → Open Folder** and select this repository directory.

If the workspace is already open in VS Code, press `Cmd/Ctrl+Shift+P` → `Developer: Reload Window`.

### 6. Verify the connection

**GitHub Copilot users:** In Copilot Chat, type:

```
Using the dynatrace-mcp server, list the top 5 services by request volume in the last hour
```

**Claude Code users:** In Claude Code (VS Code plugin or CLI), type the same query or use `/health-check` for a guided workflow.

> **Claude Code CLI, first run in a new clone:** Claude Code requires a one-time approval before it will connect to a project-scoped MCP server it hasn't seen before. Run `claude` and check `claude mcp list` — a fresh clone shows `dynatrace-mcp` as **"Pending approval (run `claude` to approve)"** until you approve it interactively in the session. This is expected; it's Claude Code's own trust mechanism for any new project's `.mcp.json`, not specific to this workspace.

If you see a table of services with request counts — you are live.

If you get no results or an error:
- Check that `dtctl doctor` passes
- Verify the workspace was opened or refreshed in VS Code after setup
- **Claude Code CLI:** run `claude mcp list` — if `dynatrace-mcp` shows "Pending approval," start `claude` and approve it
- For a `401` or `403`, use [docs/PERMISSIONS.md](./docs/PERMISSIONS.md) to check the tool's Platform Token scope, assigned identity IAM permissions, and Grail policies. Authorization failures do not mean the tenant has no telemetry.
- See [ARCHITECTURE.md](./ARCHITECTURE.md) for how the components connect

---

## Skills

Skills are domain knowledge files that teach the AI assistant how Dynatrace works — correct DQL syntax, field names, query patterns, and investigation workflows. They load automatically when relevant.

Skills follow the [Agent Skills specification](https://agentskills.io/specification) and use progressive disclosure:

1. Catalog: Agents load only `name` + `description` (~100 tokens per skill) to know what's available.
2. Instructions: When relevant, the full `SKILL.md` is loaded (<5000 tokens).
3. Resources: Detailed reference files in `references/` are loaded on demand.

### DQL & Query Language

| Skill | What It Covers |
|---|---|
| `dt-dql-essentials` | DQL syntax, common pitfalls, query patterns — **load before any DQL** |

### Observability

| Skill | What It Covers |
|---|---|
| `dt-obs-services` | RED metrics, SLA tracking, runtime-specific monitoring (Java, .NET, Node.js, Python, PHP, Go) |
| `dt-obs-frontends` | RUM, Web Vitals, user sessions, mobile crashes |
| `dt-obs-tracing` | Distributed traces, spans, failure detection, log correlation |
| `dt-obs-hosts` | Host and process metrics, CPU, memory, disk, containers |
| `dt-obs-kubernetes` | Pods, workloads, nodes, labels, ingress, PVCs |
| `dt-obs-aws` | EC2, RDS, Lambda, ECS/EKS, VPC, cost optimization |
| `dt-obs-azure` | Azure VMs, AKS, SQL, storage, networking, serverless, cost optimization |
| `dt-obs-gcp` | Compute Engine, GKE, Cloud Run, Pub/Sub, VPC, IAM, resource management |
| `dt-obs-logs` | Log queries, filtering, pattern analysis, error classification |
| `dt-obs-problems` | Davis Problems, root cause analysis, impact assessment |
| `dt-obs-predictive-analytics` | Forecasting, trend detection, anomaly identification, capacity planning |
| `dt-alerting` | Anomaly detector setup, alert event history, problem denoising, workflow notifications |
| `dt-obs-genai` | LLM/GenAI observability — golden signals, token/cost analytics, agent signals, conversation analytics, guardrails, evaluations |
| `dt-obs-log-semantic-mapping` | Suggest and validate semantic dictionary mappings for audit log integrations |

### Security

| Skill | What It Covers |
|---|---|
| `dt-sec-insights` | Security events — vulnerabilities (RVA/RAP), MITRE ATT&CK detections, posture findings (KSPM/CSPM/VSPM) |
| `dt-sec-semantic-mapping` | Suggest and validate semantic dictionary mappings for new security integrations |

### Mobile Instrumentation

| Skill | What It Covers |
|---|---|
| `dt-obs-android` | Instrument Android projects with the Dynatrace Mobile Agent |
| `dt-obs-flutter` | Integrate the Dynatrace Flutter Plugin |
| `dt-obs-ios-sdk` | Set up the Dynatrace iOS SDK via Swift Package Manager |
| `dt-obs-react-native` | Integrate the Dynatrace React Native Plugin (bare RN and Expo) |

### Platform

| Skill | What It Covers |
|---|---|
| `dt-app-dashboards` | Dashboard JSON creation and modification |
| `dt-app-notebooks` | Notebook creation and analytics workflows |
| `dt-js-runtime` | Dynatrace server-side JS runtime — function contract, SDK catalog, fetch, limits |
| `dt-platform-costs` | DPS billing and usage analysis — cost breakdown, spend ranking, chargeback, entity drill-down |

### Migration

| Skill | What It Covers |
|---|---|
| `dt-migration` | Classic entity DQL → Smartscape migration |

### CLI

| Skill | What It Covers |
|---|---|
| `dtctl` | CLI commands for managing Dynatrace resources from the terminal |

---

## Prompts

Prompts are pre-built investigation workflows available as slash commands.

All three clients use `/command-name`. The prompt files are sourced from:
- `.github/prompts/` — used by GitHub Copilot
- `.claude/commands/` — used by Claude Code (CLI and VS Code plugin), symlinked to `.github/prompts/`

| Prompt | When to Use |
|---|---|
| `/health-check` | Routine service health — performance, problems, deployments, vulnerabilities |
| `/daily-standup` | Morning team report across multiple services with today vs yesterday comparison |
| `/investigate-error` | "Something is wrong with this service" — error-focused investigation |
| `/troubleshoot-problem` | Deep 7-step investigation into a specific Dynatrace problem |
| `/incident-response` | Full production incident triage — all active problems, prioritized by business impact |
| `/performance-regression` | Did my deployment cause a slowdown? Before vs after comparison with trace analysis |

### Investigation Workflow

The prompts follow a structured drill-down pattern:

```
/daily-standup           →  spot anomalies across services
  → /health-check        →  confirm which service has issues
    → /investigate-error →  find the root cause
      → /troubleshoot-problem →  deep-dive a specific problem
```

### Resource Lifecycle

The MCP server provides supported live analysis and document lookup tools. It does not create or update notebooks, dashboards, workflows, or settings. For those resources, skills provide domain structure and dtctl performs the lifecycle operation.

| Resource | Domain guidance | Read or inspect | Create, update, or execute |
|---|---|---|---|
| Notebooks | `dt-app-notebooks` | `dtctl get notebook <id>` | Validate queries, download first when updating, then `dtctl apply` |
| Dashboards | `dt-app-dashboards` | `dtctl get dashboard <id>` | `dtctl apply` |
| Workflows | `dt-alerting` for notification design | `dtctl get` / `dtctl describe` | `dtctl apply` / `dtctl exec workflow --input` |
| Settings | Relevant domain skill | Discover schema and inspect current objects with dtctl | Use `--validate-only`, obtain approval, then create/edit/delete with dtctl |

---

## Key Concepts

### Why Skills Matter

The AI assistant without skills will guess DQL syntax and will likely get it wrong. For example, it might use `event.status == "OPEN"` (doesn't exist) instead of `event.status == "ACTIVE"`, or `log.level` instead of `loglevel`. The skills encode the corrections for known failure modes before the AI assistant writes a single query.

### How MCP Works

The Dynatrace MCP server gives the AI assistant live API access to your environment. When you run `/health-check`, it calls the MCP server to execute real DQL queries and return live data. Not cached or synthetic results.

### The Investigation Rule

Start incident, error, and known-problem investigations with Davis Problems so the affected entities and timeframe come from concrete evidence. Log and span queries always need an entity scope and bounded timeframe; otherwise high-volume searches can hit Dynatrace's 500GB scan limit. Routine bounded metric, inventory, known-entity, deployment-comparison, and document queries can run without a Davis Problem.

### MCP Configuration Files

This workspace uses **template files** to generate MCP configuration. The generated config files are `.gitignore`'d — they contain your Platform Token and are never committed to git.

| File | Purpose |
|---|---|
| `.vscode/mcp.json.template` | Checked-in template with placeholders. `setup.sh` generates `.vscode/mcp.json` from this. |
| `.mcp.json.template` | Checked-in template with placeholders. `setup.sh` generates `.mcp.json` from this. |
| `.vscode/mcp.json` | Generated by `setup.sh`; contains your actual tenant URL and Platform Token; `.gitignore`'d |
| `.mcp.json` | Generated by `setup.sh` for Claude Code CLI; contains your actual tenant URL and Platform Token; `.gitignore`'d |

**Never hand-edit the generated `.vscode/mcp.json` or `.mcp.json` files.** Instead:
1. Edit the `.template` files if you need to make permanent changes to the structure
2. Re-run `setup.sh` to regenerate the live config with a fresh token (useful for Platform Token rotation)

The committed templates use `YOUR_TENANT_DOMAIN` and `YOUR_PLATFORM_TOKEN` placeholders. Users should always run `bash setup.sh` to replace them in both generated files, set mode `600`, and keep the two client configurations aligned. Maintainers changing the template structure should follow [Updating MCP Configuration](./CONTRIBUTING.md#updating-mcp-configuration).

---

## dtctl CLI

[dtctl](https://github.com/dynatrace-oss/dtctl) is a kubectl-style CLI for Dynatrace that complements this workspace — giving you terminal-level access to run DQL queries, manage workflows, verify notebooks, and more.

```bash
# macOS / Linux — direct install (no package manager required)
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash

# OAuth login
dtctl auth login --context production \
  --environment "https://YOUR_TENANT_ID.apps.dynatrace.com"

# Verify
dtctl doctor

# Example commands
dtctl get workflows
dtctl get notebooks
dtctl query --client-context "workspace-quick-check" 'fetch dt.davis.problems | filter event.status == "ACTIVE" | limit 5'
dtctl verify query --client-context "workspace-quick-check" 'fetch dt.davis.problems | limit 5'
```

---

## Keeping Up to Date

```bash
# Confirm skills, prompts, dtctl overlays, and Claude links match the lock
bash scripts/sync-upstream.sh verify

# Restore imported content from the immutable revisions in the lock
bash scripts/sync-upstream.sh sync
```

Maintainers updating an upstream revision or MCP template should use the reviewed procedures in [CONTRIBUTING.md](./CONTRIBUTING.md). Generated `.vscode/mcp.json` and `.mcp.json` files contain credentials and must never be staged.

---

## Related Resources

- [ARCHITECTURE.md](./ARCHITECTURE.md) — How the workspace components connect
- [docs/ELI5.md](./docs/ELI5.md) — Beginner-friendly 15-minute quick start
- [docs/PERMISSIONS.md](./docs/PERMISSIONS.md) — MCP permission profiles, capability map, and authorization troubleshooting
- [docs/CHEATSHEET.md](./docs/CHEATSHEET.md) — Workflow picker and operational quick reference
- [docs/OVERVIEW.md](./docs/OVERVIEW.md) — Business and operator-oriented purpose guide
- [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — Skills and prompts source repo
- [dtctl](https://github.com/dynatrace-oss/dtctl) — Dynatrace CLI for humans and AI agents
- [Dynatrace MCP Server](https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server) — Official MCP server docs
- [Agent Skills spec](https://agentskills.io) — The open standard this workspace follows

---

## License

Skills and prompts sourced from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) and [dtctl](https://github.com/dynatrace-oss/dtctl) are Apache-2.0 licensed.

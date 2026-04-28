# dynatrace-ai-dtctl-workspace

An AI-powered observability workspace for Dynatrace — combining GitHub Copilot or Claude AI, the Dynatrace MCP server, and the [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) skills framework to accelerate incident triage, root cause analysis, and day-to-day observability workflows.

> **What this gives you:** Ask AI natural language questions about your Dynatrace environment and get accurate, production-aware answers — powered by verified domain knowledge, live API access, and pre-built investigation workflows.

> **New here?** Start with [docs/ELI5.md](./docs/ELI5.md) for a quick setup, then read [docs/OVERVIEW.md](./docs/OVERVIEW.md) for the big-picture operating model.

---

## What's Inside

Recommended reading order: [docs/ELI5.md](./docs/ELI5.md) → [docs/OVERVIEW.md](./docs/OVERVIEW.md) → [ARCHITECTURE.md](./ARCHITECTURE.md).

```
dynatrace-ai-dtctl-workspace/
├── README.md                     # Setup guide and quick reference
├── llms.txt                      # Machine-readable workspace summary for LLMs
├── docs/
│   ├── ELI5.md                   # Beginner-friendly 15-minute install guide
│   ├── OVERVIEW.md               # Newcomer guide: purpose, value, and operating model
│   └── CHEATSHEET.md             # Quick reference — workflows, outputs, dtctl, and key rules
├── ARCHITECTURE.md               # How the workspace is built and how components connect
├── CONTRIBUTING.md               # How to update skills, prompts, and MCP config
├── CLAUDE.md                     # Auto-loaded session briefing for Claude Code
├── skills-lock.json              # Locked skill versions
├── LICENSE
├── .gitignore
├── .github/
│   ├── copilot-instructions.md   # Auto-loaded session briefing for GitHub Copilot
│   └── prompts/                  # 7 investigation workflows
│       ├── health-check.prompt.md
│       ├── daily-standup.prompt.md
│       ├── daily-standup-notebook.prompt.md
│       ├── investigate-error.prompt.md
│       ├── troubleshoot-problem.prompt.md
│       ├── incident-response.prompt.md
│       └── performance-regression.prompt.md
├── .agents/skills/               # 13 Dynatrace domain skills
├── .claude/skills/               # Symlinks for Claude Code compatibility
├── .mcp.json                     # MCP server configuration for Copilot CLI
├── .vscode/
│   ├── mcp.json                  # MCP server configuration for VS Code Copilot
│   ├── extensions.json           # Recommended VS Code extensions
│   └── settings.json             # Workspace editor settings
```

| Tool | Purpose |
|---|---|
| [VS Code](https://code.visualstudio.com/) | Editor with Copilot/Claude Chat |
| [GitHub Copilot](https://github.com/features/copilot) | AI assistant (option 1) |
| [Claude Code](https://claude.ai/code) | AI assistant (option 2) |
| [Node.js](https://nodejs.org/) v18+ | Required to run the MCP server |
| [dtctl](https://github.com/dynatrace-oss/dtctl) | **Required.** Dynatrace open-source CLI for agents & humans to manage observability resources (use v0.26.0 or newer) |
| A Dynatrace environment | `https://YOUR_TENANT_ID.apps.dynatrace.com` |

You must use one AI assistant path: **GitHub Copilot** or **Claude Code**.

---

## Setup

### Choose Your Frontend

This workspace works with:
- **GitHub Copilot** in VS Code (requires subscription)
- **Claude Code** via web or desktop (requires Claude Pro or Team)

Select your setup path below. Both receive the same skills, prompts, and MCP server access.

**GitHub Copilot Path** → Follow Steps 1–5 below. `.github/copilot-instructions.md` is auto-loaded at the start of each Copilot session.

**Claude Code Path** → Follow Steps 1–5 below. `CLAUDE.md` is auto-loaded at the start of each Claude Code session.

### 1. Clone the workspace

```bash
git clone https://github.com/virtualrussel/dynatrace-ai-dtctl-workspace.git
cd dynatrace-ai-dtctl-workspace
```

Then open the folder in VS Code via **File → Open Folder**.

### 2. Update skills to latest *(optional)*

If this is your first setup, skip this step and continue to Step 3.

Skills are already included in this repo — cloning gives you everything you need. Run this only when you want to pull the latest skill updates from Dynatrace:

```bash
npx skills add dynatrace/dynatrace-for-ai
npx skills add dynatrace-oss/dtctl
```

> See [Keeping Up to Date](#keeping-up-to-date) for when to run this.

### 3. Set your tenant ID

Your tenant ID is the 8-character prefix of your Dynatrace environment URL. For example, if your URL is `https://abc12345.apps.dynatrace.com`, your tenant ID is `abc12345`.

**1. Edit the primary MCP configuration** — open `.vscode/mcp.json` and replace `YOUR_TENANT_ID`.

**2. Regenerate the derived MCP configuration** — `.mcp.json` is used by Copilot CLI and other non-VS Code clients. Do not edit it directly; regenerate it from the primary config:

```bash
jq '{"mcpServers": .servers}' .vscode/mcp.json > .mcp.json
```

**3. Update session briefing files** (recommended — so assistants reference the correct tenant URL in context):
- `.github/copilot-instructions.md`
- `CLAUDE.md`

### 4. Install and configure dtctl

`dtctl` is a hard requirement for this workspace. It provides terminal-level access to Dynatrace resources and is used for verification steps across multiple workflows — including the flagship `daily-standup-notebook` prompt. Without it, several prompts will not complete successfully.

> Compatibility note: use `dtctl` v0.26.0 or newer, which is required for `dtctl-release` skill workflows.

```bash
# macOS / Linux — direct install (no package manager required)
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash

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

When `dtctl doctor` shows green, you are connected. Create your platform token in Dynatrace: **Identity & Access Management** → **Access Tokens** → **Generate new token** → **Platform token**.

If OAuth fails with a keyring error (for example, `dbus-launch` not found), use the token-based method above.

### 5. Reload VS Code

Press `Cmd+Shift+P` → `Developer: Reload Window`

When you first use a prompt in Copilot Chat, a browser window will open for
Dynatrace SSO authentication. This is expected — complete the login and return
to VS Code. Subsequent sessions authenticate automatically.

### 6. Verify the connection

**GitHub Copilot users:** In Copilot Chat, type:

```
Using the dynatrace-mcp server, list the top 5 services by request volume in the last hour
```

**Claude Code users:** In Claude Code, type the same query or use `@health-check` for a guided workflow.

If you see a table of services with request counts — you are live.

---

## Skills

Skills are domain knowledge files that teach Copilot how Dynatrace works — correct DQL syntax, field names, query patterns, and investigation workflows. They load automatically when relevant.

Skills follow the [Agent Skills specification](https://agentskills.io/specification) and use progressive disclosure:

1. Catalog - Agents load only `name` + `description` (~100 tokens per skill) to know what's available.
2. Instructions - When relevant, the full `SKILL.md` is loaded (<5000 tokens).
3. Resources - Detailed reference files in `references/` are loaded on demand.

| Skill | What It Covers |
|---|---|
| `dt-dql-essentials` | DQL syntax, common pitfalls, query patterns — **load before any DQL** |
| `dt-obs-problems` | Davis Problems, root cause analysis, impact assessment |
| `dt-obs-logs` | Log queries, filtering, pattern analysis, error classification |
| `dt-obs-tracing` | Distributed traces, spans, failure detection, log correlation |
| `dt-obs-services` | RED metrics, SLA tracking, runtime-specific monitoring (Java, .NET, Node.js, Python, PHP, Go) |
| `dt-obs-hosts` | Host and process metrics, CPU, memory, disk, containers |
| `dt-obs-kubernetes` | Pods, workloads, nodes, labels, ingress, PVCs |
| `dt-obs-aws` | EC2, RDS, Lambda, ECS/EKS, VPC, cost optimization |
| `dt-obs-frontends` | RUM, Web Vitals, user sessions, mobile crashes |
| `dt-app-dashboards` | Dashboard JSON creation and modification |
| `dt-app-notebooks` | Notebook creation and analytics workflows |
| `dt-migration` | Classic entity DQL → Smartscape migration |
| `dtctl` | CLI commands for managing Dynatrace resources from the terminal |

---

## Prompts

Prompts are pre-built investigation workflows available as slash commands.

- **GitHub Copilot:** Type `/` in Copilot Chat (see `.github/prompts/`)
- **Claude Code:** Type `@` followed by the prompt name (e.g. `@health-check`)

| Prompt | When to Use |
|---|---|
| `/health-check` | Routine service health — performance, problems, deployments, vulnerabilities |
| `/daily-standup` | Morning team report across multiple services with today vs yesterday comparison |
| `/daily-standup-notebook` | Standup report + Dynatrace notebook creation + dtctl verification |
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

---

## Key Concepts

### Why Skills Matter

Copilot without skills will guess DQL syntax — and get it wrong. For example, it might use `event.status == "OPEN"` (doesn't exist) instead of `event.status == "ACTIVE"`, or `log.level` instead of `loglevel`. The skills encode the corrections for known failure modes before Copilot writes a single query.

### How MCP Works

The Dynatrace MCP server gives Copilot live API access to your environment. When you run `/health-check`, Copilot calls the MCP server to execute real DQL queries and return live data — not cached or synthetic results.

### The Investigation Rule

**Always start with problems, never with broad log searches.** Broad log queries without a problem context will hit Dynatrace's 500GB scan limit and return zero results. The prompts enforce this automatically.

### MCP Configuration Files

This workspace maintains two MCP configuration files that must be kept in sync:

| File | Used By |
|---|---|
| `.vscode/mcp.json` | VS Code GitHub Copilot and Claude Code |
| `.mcp.json` | GitHub Copilot CLI |

When updating your tenant ID or MCP server, always update both files. Regenerate `.mcp.json` from `.vscode/mcp.json` using:

```bash
jq "{mcpServers: .servers}" .vscode/mcp.json > .mcp.json
```

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
dtctl query 'fetch dt.davis.problems | filter event.status == "ACTIVE" | limit 5'
```

---

## Keeping Up to Date

```bash
# Update all skills to latest
npx skills add dynatrace/dynatrace-for-ai
npx skills add dynatrace-oss/dtctl

# Regenerate .mcp.json after any MCP server changes
jq "{mcpServers: .servers}" .vscode/mcp.json > .mcp.json

# Commit the updates
git add .
git commit -m "Update skills to latest"
git push
```

---

## Related Resources

- [ARCHITECTURE.md](./ARCHITECTURE.md) — How the workspace components connect
- [docs/ELI5.md](./docs/ELI5.md) — Beginner-friendly 15-minute quick start
- [docs/CHEATSHEET.md](./docs/CHEATSHEET.md) — Workflow picker and operational quick reference
- [docs/OVERVIEW.md](./docs/OVERVIEW.md) — Business and operator-oriented purpose guide
- [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — Skills and prompts source repo
- [dtctl](https://github.com/dynatrace-oss/dtctl) — Dynatrace CLI for humans and AI agents
- [Dynatrace MCP Server](https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server) — Official MCP server docs
- [Agent Skills spec](https://agentskills.io) — The open standard this workspace follows

---

## License

Skills and prompts sourced from [dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) and [dtctl](https://github.com/dynatrace-oss/dtctl) are Apache-2.0 licensed.

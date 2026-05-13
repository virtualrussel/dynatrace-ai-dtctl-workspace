# Architecture Overview

This document explains what this workspace is, how it is built, and how the components work together. It is intended for anyone who wants to understand the solution before using it.

---

## What This Is

A pre-configured AI powered observability workspace that connects GitHub Copilot or Claude Code to Dynatrace, enabling natural language investigation of production systems — from VS Code or directly from the terminal via Claude Code CLI.

Instead of logging into Dynatrace, navigating dashboards, and writing queries manually, you type a slash command and receive structured, accurate, production-aware answers in seconds.

---

## The Problem It Solves

GitHub Copilot is a general-purpose AI assistant. Without domain-specific knowledge it will:
- Guess DQL syntax and likely get it wrong
- Use field names that don't exist (`log.level` instead of `loglevel`)
- Write queries that hit scan limits and return zero results
- Have no access to your live Dynatrace data

This workspace solves all four problems by combining three things: domain knowledge, live data access, and pre-built workflows.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Clients                                                                     │
│                                                                              │
│  ┌──────────────────────────────────────────────┐  ┌──────────────────────┐ │
│  │                  VS Code                     │  │  Claude Code CLI     │ │
│  │                                              │  │  (terminal)          │ │
│  │  ┌────────────────┐  ┌─────────────────────┐ │  │                      │ │
│  │  │  AI Chat       │  │  Integrated Terminal│ │  │  /health-check       │ │
│  │  │  (Copilot or   │  │                     │ │  │  ...and more         │ │
│  │  │  Claude Code)  │  │  dtctl get ...      │ │  │  (see Prompts)       │ │
│  │  │                │  │  dtctl query "..."  │ │  │                      │ │
│  │  │  /health-check │  │  dtctl describe ... │ │  └──────────┬───────────┘ │
│  │  │  ...and more   │  └──────────┬──────────┘ │             │             │
│  │  └───────┬────────┘             │             │        .mcp.json         │
│  │          │                      │             │                          │
│  │  ┌───────▼──────────┐           │             │                          │
│  │  │  Agent Skills    │           │             │                          │
│  │  │ .agents/skills/  │           │             │                          │
│  │  └───────┬──────────┘           │             │                          │
│  │    .vscode/mcp.json             │             │                          │
│  └──────────┼──────────────────────┼─────────────┘                          │
└─────────────┼──────────────────────┼───────────────────────────────────────┘
              │ MCP (stdio)          │ HTTPS + OAuth
              ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│              Dynatrace Platform                                             │
│                                                                             │
│   YOUR_TENANT_ID.apps.dynatrace.com                                         │
│                                                                             │
│   Grail Data Lakehouse — logs, spans, metrics, events                       │
│   Dynatrace Intelligence — problem detection, root cause analysis           │
│   Notebooks, Dashboards, Workflows                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## The Five Components

### 1. Agent Skills
**Source:** [github.com/Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) & [github.com/dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl)
**Location:** `.agents/skills/`

Skills are markdown files containing domain-specific knowledge. They teach the AI assistant how Dynatrace works including correct DQL syntax, field names, query patterns, and investigation workflows. The AI assistant loads them automatically when relevant, using a three-tier progressive disclosure model:

```
Tier 1 — Catalog     Always loaded    ~100 tokens per skill
Tier 2 — SKILL.md    On demand        ~5,000 tokens
Tier 3 — references/ On demand        Deep reference detail
```

This means all skills can be installed without performance penalty — the AI assistant only loads what it needs for each specific query.

| Skill | Domain |
|---|---|
| `dt-dql-essentials` | DQL syntax, pitfalls, query patterns — required before any DQL |
| `dt-obs-problems` | Davis Problems, root cause analysis, impact assessment |
| `dt-obs-logs` | Log queries, filtering, error classification |
| `dt-obs-tracing` | Distributed traces, spans, failure detection |
| `dt-obs-services` | RED metrics, SLA tracking, runtime monitoring |
| `dt-obs-hosts` | Host and process metrics |
| `dt-obs-kubernetes` | Pods, workloads, nodes, cluster health |
| `dt-obs-aws` | EC2, RDS, Lambda, ECS/EKS, cost optimization |
| `dt-obs-azure` | Azure VMs, AKS, SQL, storage, networking, serverless, cost optimization |
| `dt-obs-gcp` | Compute Engine, GKE, Cloud Run, Pub/Sub, VPC, IAM, resource management |
| `dt-obs-frontends` | RUM, Web Vitals, user sessions, mobile crashes |
| `dt-obs-predictive-analytics` | Forecasting, trend detection, anomaly identification, capacity planning |
| `dt-app-dashboards` | Dashboard JSON creation and modification |
| `dt-app-notebooks` | Notebook creation and analytics workflows |
| `dt-migration` | Classic entity DQL → Smartscape migration |
| `dtctl` | CLI commands for managing Dynatrace resources |

---

### 2. MCP Server
**Source:** [github.com/dynatrace-oss/dynatrace-mcp](https://github.com/dynatrace-oss/dynatrace-mcp)
**Locations:** `.vscode/mcp.json` (VS Code) · `.mcp.json` (Claude Code CLI and other non-VS Code clients)

The Model Context Protocol (MCP) server is the live data bridge between the AI assistant and Dynatrace. When Copilot needs to answer a question about your environment, it calls the MCP server, which executes real API calls and DQL queries against your Dynatrace tenant and returns live results.

One environment is configured as a named server:

```json
dynatrace-mcp  →  https://YOUR_TENANT_ID.apps.dynatrace.com
```

Authentication uses OAuth browser SSO — no API tokens or credentials are stored in the workspace. To confirm which environment is active in a Copilot session:

```
"Confirm which MCP server you are using"
```

---

### 3. Prompt Templates
**Source:** [github.com/Dynatrace/dynatrace-for-ai/prompts](https://github.com/Dynatrace/dynatrace-for-ai/tree/main/prompts)
**Locations:** `.github/prompts/` (GitHub Copilot) · `.claude/commands/` (Claude Code — symlinked from `.github/prompts/`)

Prompts are pre-built investigation workflows saved as slash commands. They combine skills with structured instructions that tell the AI what to do, in what order, and with what guardrails. Type `/` in any client to see all available prompts.

| Prompt | Purpose | When to Use |
|---|---|---|
| `/health-check` | Service health snapshot | Routine morning check or before a deployment |
| `/daily-standup` | Multi-service report with today vs yesterday comparison | Team standup preparation |
| `/daily-standup-notebook` | Standup report + Dynatrace notebook + dtctl verification | Full documented standup workflow |
| `/investigate-error` | Error-focused investigation from a service name | "Something is wrong with this service" |
| `/troubleshoot-problem` | Structured 7-step deep dive into a specific problem | Known problem needing root cause |
| `/incident-response` | Full triage of all active problems by business impact | Active production incident |
| `/performance-regression` | Before vs after deployment comparison | Post-deployment validation |

#### The Investigation Workflow

Prompts are designed to chain together as an investigation deepens:

```
/daily-standup             Spot anomalies across services
       ↓
/health-check              Confirm which service has issues
       ↓
/investigate-error         Find the root cause
       ↓
/troubleshoot-problem      Deep-dive a specific problem
```

#### Key Guardrails Built Into Prompts

The `troubleshoot-problem` and `daily-standup-notebook` prompts encode operational rules learned from real usage:

- **Always start with problems.** Never run broad log searches without problem context (hits 500GB scan limit)
- **No `#` or `--` comments in DQL** — invalid syntax that causes parse errors
- **`timeseries` uses `=` not `as`** for aliasing
- **`timeseries` filters use `==` with `by:` dimension** — not `contains()`
- **Array notation required** for computed fields after `timeseries`

---

### 4. Session Briefing Files
**Locations:** `.github/copilot-instructions.md` (GitHub Copilot) · `CLAUDE.md` (Claude Code)

Both files are automatically loaded at the start of every AI session in this workspace. They act as a standing briefing so the AI already knows the default MCP environment, the investigation rule, and the available prompts before a single word is typed.

Each file contains:
- Default MCP server
- Global rule: always start with problems, never broad log searches
- Prompt directory with all 7 slash commands and when to use them
- The 16 skills are installed and load automatically

Both files use `/command-name` for prompt invocation. They are kept separate because each tool reads from a different path:
- GitHub Copilot reads only `.github/copilot-instructions.md`
- Claude Code (VS Code plugin and CLI) reads only `CLAUDE.md` at the repo root

---

### 5. dtctl CLI
**Source:** [github.com/dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl)
**Installation:** see [README §4](README.md#4-authenticate-dtctl)

`dtctl` is a kubectl-style command-line tool for Dynatrace. It complements the Copilot + MCP workflow by providing direct terminal access to Dynatrace resources. It runs DQL queries, manages workflows, verifies notebooks, and more.

In this workspace, `dtctl` is used primarily for **verification** by confirming that notebooks and other artifacts created by Copilot via MCP actually exist and are correctly structured in Dynatrace.

```bash
dtctl get notebooks                    # List all notebooks
dtctl describe notebook "name"         # Inspect notebook structure
dtctl query --client-context "workspace-quick-check" 'fetch dt.davis.problems   # Run DQL directly
  | filter event.status == "ACTIVE"
  | limit 5'
dtctl verify query --client-context "workspace-quick-check" 'fetch dt.davis.problems | limit 5'
dtctl get workflows                    # List all workflows
dtctl doctor                           # Verify authentication and connectivity
```

---

## How It All Works Together

Here is the complete flow for a typical `/daily-standup-notebook` session:

```
1. You type /daily-standup-notebook in Copilot Chat, Claude Code, or Claude Code CLI

2. The AI loads its session briefing (copilot-instructions.md for Copilot; CLAUDE.md for Claude Code)
   → Knows to use dynatrace-mcp by default
   → Knows the investigation rules and DQL guardrails

3. The AI loads relevant skills
   → dt-obs-services  (RED metrics)
   → dt-obs-problems  (active problems)
   → dt-app-notebooks (notebook structure)
   → dtctl            (verification commands)

4. The AI calls dynatrace-mcp
   → Executes live DQL queries against production
   → Retrieves metrics, problems, and deployment data

5. The AI generates the standup report
   → Today vs yesterday metric comparison
   → Active problems and incidents
   → Action items per service

6. The AI creates a Dynatrace notebook via MCP
   → Executive summary
   → Per-service findings
   → Embedded live DQL queries
   → Prioritised remediation steps

7. dtctl verifies the notebook
   → dtctl get notebooks confirms it exists
   → dtctl describe notebook confirms structure
   → Shareable URL returned
```

---

## Keeping the Workspace Up to Date

Skills are versioned via `skills-lock.json`. Update to the latest skills before important demos or after Dynatrace releases new features:

```bash
npx skills add dynatrace/dynatrace-for-ai
npx skills add dynatrace-oss/dtctl
git add .agents/skills/ .claude/skills/ skills-lock.json
git commit -m "Update skills to latest — $(date +%Y-%m-%d)"
git push
```

Update `dtctl` by re-running the install script:

```bash
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash

# or via Homebrew
brew update && brew upgrade dtctl
```

---

## Source References

| Component | Source |
|---|---|
| Dynatrace skills | [github.com/Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) |
| Investigation prompts | [github.com/Dynatrace/dynatrace-for-ai/prompts](https://github.com/Dynatrace/dynatrace-for-ai/tree/main/prompts) |
| MCP server package | [github.com/dynatrace-oss/dynatrace-mcp](https://github.com/dynatrace-oss/dynatrace-mcp) |
| dtctl CLI + skill | [github.com/dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl) |

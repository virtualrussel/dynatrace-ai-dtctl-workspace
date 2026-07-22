# ELI5 — Get This Working in 15 Minutes

You are setting up an AI assistant that can answer questions about your Dynatrace environment in plain English. Type a question, get a real answer from live production data.

---

## Before You Start

You need these tools installed:

| What | Why | Get It |
|---|---|---|
| [VS Code](https://code.visualstudio.com/) | Editor with Copilot/Claude Chat — **skip if using Claude Code CLI** | Download and install |
| GitHub Copilot or Claude Code | The AI brain | Copilot: sign in at github.com/features/copilot · Claude: sign in at claude.ai/code |
| [dtctl](https://github.com/dynatrace-oss/dtctl) v0.35.0+ | CLI for verifying and managing Dynatrace resources | Offered for installation by `setup.sh` — or install manually |

> **Prefer the terminal over VS Code?** Install Claude Code CLI instead of the VS Code extensions:
> ```bash
> npm install -g @anthropic-ai/claude-code
> ```
> Then skip to Step 1 (clone) and Step 2 (platform token), then run `claude` from the workspace directory.

Install required VS Code extensions (VS Code users only):

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

---

## Step 1 — Get the Workspace

```bash
git clone https://github.com/virtualrussel/dynatrace-ai-dtctl-workspace.git
cd dynatrace-ai-dtctl-workspace
```

Continue in the cloned directory for setup.

---

## Step 2 — Set Up Your Dynatrace Tenant and Platform Token

Run the setup script:

```bash
bash setup.sh
```

Before asking for tenant or token information, setup verifies that dtctl v0.35.0+ is runnable. If dtctl is missing, setup offers to install it. Declining installation or failing the version check stops setup.

The script will:
1. Ask for your Dynatrace environment URL (e.g., `abc12345.apps.dynatrace.com`). On an already-configured clone, setup offers the tenant as the Enter default only when `.vscode/mcp.json` and `.mcp.json` both contain the same valid tenant
2. Let you choose **Full read-only MCP** (recommended) or the smaller **Core incident analysis** profile, then print its exact Platform Token scopes
3. Prompt you to paste your Platform Token

**To create a Platform Token:** In your Dynatrace tenant, go to **Account Management** → **Identity & access management** → **Platform tokens** → click your **user profile link** → **Generate new token**. Add the scopes the script prints, copy the token, and paste it when prompted. See [PERMISSIONS.md](./PERMISSIONS.md) for what each profile enables.

The script generates `.vscode/mcp.json` and `.mcp.json` with your tenant URL and token — these files are `.gitignore`'d and never committed to git. Tracked documentation keeps generic tenant examples and is not modified by setup.

---

## Step 3 — Authenticate dtctl (Required)

`dtctl` is the required command-line tool that lets the AI create, update, inspect, and verify Dynatrace resources such as notebooks and workflows. The setup script has already verified or installed v0.35.0+; now connect it to your environment.

```bash
# Connect to your environment — opens a browser for Dynatrace SSO login
dtctl auth login --context production \
  --environment "https://YOUR_TENANT_ID.apps.dynatrace.com"

# Verify it works
dtctl doctor
```

When `dtctl doctor` reports pass, you are connected.

---

## Step 4 — Activate the MCP Connection

**VS Code users:** If this is your first time opening the workspace in VS Code, use **File → Open Folder** and select this repository directory. If the workspace is already open in VS Code, press `Cmd/Ctrl+Shift+P` → type `Developer: Reload Window` → press Enter.

**Claude Code CLI users:** No reload needed. Run `claude` from the workspace directory. The first time you do this in a new clone, Claude Code will ask you to approve the `dynatrace-mcp` MCP server before it connects — this is a one-time, per-clone security step, not something specific to this workspace.

---

## Step 5 — Try It

In GitHub Copilot Chat, Claude Code, or Claude Code CLI, type this prompt (or use `/health-check` for a guided workflow):

```
Using the dynatrace-mcp server, list the top 5 services by request volume in the last hour
```

If you see a table of services with request counts — you are live. A `401` or `403` is an authorization failure, not proof that no telemetry exists. Follow [PERMISSIONS.md](./PERMISSIONS.md) to check Platform Token scopes, identity permissions, and Grail policies.

---

## What Just Happened?

| Piece | What It Does | Analogy |
|---|---|---|
| Skills | Domain knowledge about Dynatrace | A textbook the AI reads before answering |
| MCP server | Live connection to your Dynatrace data | A phone line to production |
| Prompts | Pre-built investigation workflows | Recipes you follow step by step |
| dtctl | Terminal resource lifecycle and verification | A control panel for managed changes |

---

## Your First Commands

| Type This | What It Does |
|---|---|
| `/health-check` | Is my service healthy right now? |
| `/incident-response` | What is currently broken in production? |
| `/daily-standup` | Give me a morning report across all services |

---

For the full setup guide and advanced configuration, see [README.md](../README.md).

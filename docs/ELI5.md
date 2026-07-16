# ELI5 — Get This Working in 15 Minutes

You are setting up an AI assistant that can answer questions about your Dynatrace environment in plain English. Type a question, get a real answer from live production data.

---

## Before You Start

You need these tools installed:

| What | Why | Get It |
|---|---|---|
| [VS Code](https://code.visualstudio.com/) | Editor with Copilot/Claude Chat — **skip if using Claude Code CLI** | Download and install |
| GitHub Copilot or Claude Code | The AI brain | Copilot: sign in at github.com/features/copilot · Claude: sign in at claude.ai/code |
| [dtctl](https://github.com/dynatrace-oss/dtctl) v0.34.0+ | CLI for verifying and managing Dynatrace resources | Offered for installation by `setup.sh` — or install manually |

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

The script will:
1. Ask for your Dynatrace environment URL (e.g., `abc12345.apps.dynatrace.com`)
2. Print the **required Platform Token scopes** to create in your Dynatrace tenant
3. Prompt you to paste your Platform Token

**To create a Platform Token:** In your Dynatrace tenant, go to **Account Management** → **Identity & access management** → **Platform tokens** → click your **user profile link** → **Generate new token**. Add the scopes the script prints, copy the token, and paste it when prompted.

The script generates `.vscode/mcp.json` and `.mcp.json` with your tenant URL and token — these files are `.gitignore`'d and never committed to git.

---

## Step 3 — Install dtctl (Optional)

`dtctl` is a command-line tool that lets you verify what the AI creates — like checking that a notebook it built actually exists in Dynatrace. The setup script offers to install it; you can install manually later if needed.

```bash
# Install (macOS / Linux)
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash

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

**Claude Code CLI users:** No reload needed. Run `claude` from the workspace directory.

---

## Step 5 — Try It

In GitHub Copilot Chat, Claude Code, or Claude Code CLI, type this prompt (or use `/health-check` for a guided workflow):

```
Using the dynatrace-mcp server, list the top 5 services by request volume in the last hour
```

If you see a table of services with request counts — you are live. If not, double-check that your Platform Token has the required scopes: `mcp-gateway:servers:invoke`, `mcp-gateway:servers:read`, and `app-engine:apps:run`.

---

## What Just Happened?

| Piece | What It Does | Analogy |
|---|---|---|
| Skills | Domain knowledge about Dynatrace | A textbook the AI reads before answering |
| MCP server | Live connection to your Dynatrace data | A phone line to production |
| Prompts | Pre-built investigation workflows | Recipes you follow step by step |
| dtctl | Terminal access for verification | An inspector who checks the AI's work |

---

## Your First Commands

| Type This | What It Does |
|---|---|
| `/health-check` | Is my service healthy right now? |
| `/incident-response` | What is currently broken in production? |
| `/daily-standup` | Give me a morning report across all services |

---

For the full setup guide and advanced configuration, see [README.md](../README.md).

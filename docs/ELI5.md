# ELI5 — Get This Working in 15 Minutes

You are setting up an AI assistant that can answer questions about your Dynatrace environment in plain English. Type a question, get a real answer from live production data.

---

## Before You Start

You need three things installed:

| What | Why | Get It |
|---|---|---|
| [VS Code](https://code.visualstudio.com/) | Where you will work | Download and install |
| GitHub Copilot or Claude Code | The AI brain | Copilot: sign in at github.com/features/copilot · Claude: sign in at claude.ai/code |
| [Node.js](https://nodejs.org/) v18+ | Required to run the MCP server — the live data bridge between the AI and your Dynatrace environment | Download LTS version |

---

## Step 1 — Get the Workspace

```bash
git clone https://github.com/virtualrussel/dynatrace-ai-workspace.git
cd dynatrace-ai-workspace
```

Then open the folder in VS Code: **File → Open Folder**.

Next, replace `YOUR_TENANT_ID` with your Dynatrace tenant ID in these files:

Required MCP configuration files:
- `.vscode/mcp.json`
- `.mcp.json`

Session briefing files (recommended so assistants reference the correct MCP server URL in context):
- `.github/copilot-instructions.md`
- `CLAUDE.md`

Your tenant ID is the 8-character prefix of your Dynatrace environment URL. For example, if your URL is `https://abc12345.apps.dynatrace.com`, your tenant ID is `abc12345`.

---

## Step 2 — Install dtctl

`dtctl` is a command-line tool that lets you verify what the AI creates — like checking that a notebook it built actually exists in Dynatrace.

```bash
# Install (macOS / Linux)
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash

# Connect to your environment — opens a browser for Dynatrace SSO login
dtctl auth login --context production \
  --environment "https://YOUR_TENANT_ID.apps.dynatrace.com"

# Verify it works
dtctl doctor
```

When `dtctl doctor` shows green, you are connected.

---

## Step 3 — Reload VS Code

Press `Cmd+Shift+P` → type `Developer: Reload Window` → press Enter.

This activates the Dynatrace live data connection. The first time you use a prompt, a browser window will open for Dynatrace login — complete it and come back.

---

## Step 4 — Try It

In GitHub Copilot Chat, type this prompt. In Claude Code, type the same prompt (or use `@health-check` for a guided workflow):

```
Using the dynatrace-mcp server, list the top 5 services by request volume in the last hour
```

If you see a table of services with request counts — you are live.

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

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES=(
"$SCRIPT_DIR/.vscode/mcp.json"
"$SCRIPT_DIR/.mcp.json"
"$SCRIPT_DIR/CLAUDE.md"
"$SCRIPT_DIR/ARCHITECTURE.md"
"$SCRIPT_DIR/README.md"
"$SCRIPT_DIR/docs/ELI5.md"
"$SCRIPT_DIR/docs/CHEATSHEET.md"
)

echo ""
echo "Dynatrace AI Workspace — Setup"
echo "================================"
echo ""

# --- Prerequisites -----------------------------------------------------------
echo "Checking prerequisites..."
echo ""
PREREQ_FAILED=false
DTCTL_STATUS="unavailable"

# Node.js v18+
if command -v node &>/dev/null; then
NODE_VERSION=$(node --version | sed 's/^v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
if [[ "$NODE_MAJOR" -ge 18 ]]; then
echo " [ok] Node.js v${NODE_VERSION}"
else
echo " [fail] Node.js v${NODE_VERSION} — v18 or higher required"
echo " Install the LTS version: https://nodejs.org/"
PREREQ_FAILED=true
fi
else
echo " [fail] Node.js not found — v18 or higher required"
echo " Install the LTS version: https://nodejs.org/"
PREREQ_FAILED=true
fi

# jq
if command -v jq &>/dev/null; then
JQ_VERSION=$(jq --version 2>/dev/null | sed 's/^jq-//' || echo "installed")
echo " [ok] jq ${JQ_VERSION}"
else
echo " [warn] jq not found — needed for manual MCP config updates"
echo " Install: brew install jq / apt install jq / choco install jq"
fi

# Claude Code CLI
CLAUDE_CLI_STATUS="unavailable"
if command -v claude &>/dev/null; then
CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "installed")
echo " [ok] claude ${CLAUDE_VERSION}"
CLAUDE_CLI_STATUS="ok"
else
echo " [info] claude CLI not found — optional for terminal-only workflows"
echo " Install: npm install -g @anthropic-ai/claude-code"
fi

# dtctl — REQUIRED with minimum version v0.28.0
if command -v dtctl &>/dev/null; then
DTCTL_VERSION=$(dtctl version 2>/dev/null | head -1 || echo "unknown")
if [[ "$DTCTL_VERSION" == "0.28.0" ]] || [[ "$DTCTL_VERSION" > "0.28.0" ]]; then
echo " [ok] dtctl v${DTCTL_VERSION} (requires >= v0.28.0)"
DTCTL_STATUS="ok"
else
echo " [fail] dtctl v${DTCTL_VERSION} — v0.28.0 or higher required"
echo ""
echo " v0.28.0 includes critical fixes:"
echo "  • OAuth refresh token race condition (breaks CI with parallel jobs)"
echo "  • Cloud connection pagination fix (silent data loss on older versions)"
echo "  • Structured workflow input (--input flag)"
echo ""
echo " Upgrade dtctl:"
echo "  curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash"
echo ""
PREREQ_FAILED=true
fi
else
echo " [fail] dtctl not found — REQUIRED for workspace workflows"
echo " Must be v0.28.0 or higher"
echo ""
read -rp "Install dtctl now? (y/N) " INSTALL_DTCTL
if [[ "$INSTALL_DTCTL" =~ ^[Yy]$ ]]; then
echo ""
echo "Installing dtctl..."
if curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash; then
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
if command -v dtctl &>/dev/null; then
DTCTL_VERSION=$(dtctl version 2>/dev/null | head -1 || echo "unknown")
if [[ "$DTCTL_VERSION" == "0.28.0" ]] || [[ "$DTCTL_VERSION" > "0.28.0" ]]; then
echo " [ok] dtctl v${DTCTL_VERSION} installed"
DTCTL_STATUS="just_installed"
else
echo " [fail] Installed dtctl v${DTCTL_VERSION}, but v0.28.0+ required"
echo " Latest installer may not have reached your region yet."
echo " Wait 10 minutes and retry, or install manually:"
echo " https://github.com/dynatrace-oss/dtctl/releases/tag/v0.28.0"
PREREQ_FAILED=true
fi
else
echo " [warn] dtctl installed but not in PATH — open a new terminal after setup"
DTCTL_STATUS="path_issue"
fi
else
echo " [warn] dtctl installation failed"
echo " Install manually: https://github.com/dynatrace-oss/dtctl/releases/tag/v0.28.0"
PREREQ_FAILED=true
fi
else
echo " [fail] dtctl v0.28.0+ is REQUIRED — cannot continue without it"
echo " https://github.com/dynatrace-oss/dtctl/releases/tag/v0.28.0"
fi
fi
echo ""
if [[ "$PREREQ_FAILED" == "true" ]]; then
echo "Fix the above errors and re-run setup.sh."
exit 1
fi

# --- Idempotency check -------------------------------------------------------
if ! grep -q "YOUR_TENANT_ID" "$SCRIPT_DIR/.vscode/mcp.json" 2>/dev/null && \
! grep -q "YOUR_TENANT_ID" "$SCRIPT_DIR/CLAUDE.md" 2>/dev/null; then
echo "This workspace has already been configured."
echo "setup.sh only works on the initial setup."
exit 1
fi

# --- Tenant URL --------------------------------------------------------------
echo "Enter your Dynatrace environment URL."
echo "Examples:"
echo " abc12345.apps.dynatrace.com"
echo " abc12345.sprint.apps.dynatracelabs.com"
echo ""
while true; do
read -rp "Tenant URL: " TENANT_URL
TENANT_URL="${TENANT_URL#https://}"
TENANT_URL="${TENANT_URL#http://}"
TENANT_URL="${TENANT_URL%/}"
TENANT_URL=$(echo "$TENANT_URL" | tr '[:upper:]' '[:lower:]')
if [[ "$TENANT_URL" =~ ^[a-z0-9-]+\.apps\.dynatrace\.com$ ]] || \
[[ "$TENANT_URL" =~ ^[a-z0-9-]+\.sprint\.apps\.dynatracelabs\.com$ ]]; then
break
fi
echo "Invalid URL. Must match *.apps.dynatrace.com or *.sprint.apps.dynatracelabs.com"
echo ""
done
echo ""
echo "Tenant URL: $TENANT_URL"
read -rp "Update ${#FILES[@]} workspace files? (y/N) " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
echo "Aborted."
exit 0
fi
echo ""

# --- Apply replacements ------------------------------------------------------
for FILE in "${FILES[@]}"; do
if [[ -f "$FILE" ]]; then
perl -pi -e "s|YOUR_TENANT_ID\\.apps\\.dynatrace\\.com|${TENANT_URL}|g" "$FILE"
echo " updated $FILE"
fi
done

# --- Next steps --------------------------------------------------------------
echo ""
echo "Done. Next steps:"
echo ""
STEP=1
case "$DTCTL_STATUS" in
unavailable)
echo "${STEP}. Install dtctl v0.28.0+:"
echo " https://github.com/dynatrace-oss/dtctl/releases/tag/v0.28.0"
echo ""
STEP=$((STEP + 1))
;;
path_issue)
echo "${STEP}. Open a new terminal — dtctl was installed but needs a fresh PATH to be available"
echo ""
STEP=$((STEP + 1))
;;
esac
echo "${STEP}. Authenticate dtctl:"
if [[ "$DTCTL_STATUS" == "just_installed" ]]; then
echo " (Open a new terminal first — dtctl was just added to your PATH)"
fi
echo " dtctl auth login --context production --environment \"https://${TENANT_URL}\""
echo " Then verify: dtctl doctor"
echo ""
STEP=$((STEP + 1))
if command -v code &>/dev/null; then
echo "${STEP}. Reload VS Code:"
echo " Cmd+Shift+P → Developer: Reload Window"
echo ""
STEP=$((STEP + 1))
fi
if [[ "$CLAUDE_CLI_STATUS" == "ok" ]]; then
echo "${STEP}. Start Claude Code CLI:"
echo " claude"
echo " Then type /health-check to verify the connection."
echo ""
STEP=$((STEP + 1))
fi
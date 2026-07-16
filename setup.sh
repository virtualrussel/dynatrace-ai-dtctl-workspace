#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIN_DTCTL_VERSION="0.34.0"

# Returns 0 if $1 >= $2 for dotted numeric versions (e.g. 0.30.10 vs 0.30.9).
# Anything that isn't a strict X.Y.Z version (including "unknown" or empty)
# fails closed rather than silently passing.
version_ge() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  [[ "$1" == "$2" ]] && return 0
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" == "$1" ]]
}

# Files to substitute tenant URL into (documentation only; not secrets)
DOC_FILES=(
"$SCRIPT_DIR/CLAUDE.md"
"$SCRIPT_DIR/ARCHITECTURE.md"
"$SCRIPT_DIR/README.md"
"$SCRIPT_DIR/docs/ELI5.md"
"$SCRIPT_DIR/docs/CHEATSHEET.md"
)

# Template files that generate config
TEMPLATE_FILES=(
"$SCRIPT_DIR/.vscode/mcp.json.template"
"$SCRIPT_DIR/.mcp.json.template"
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

# jq
if command -v jq &>/dev/null; then
JQ_VERSION=$(jq --version 2>/dev/null | sed 's/^jq-//' || echo "installed")
echo " [ok] jq ${JQ_VERSION}"
else
echo " [warn] jq not found — needed for template regeneration if you hand-edit templates"
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

# dtctl — REQUIRED with minimum version v${MIN_DTCTL_VERSION}
if command -v dtctl &>/dev/null; then
DTCTL_VERSION=$(dtctl version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if version_ge "$DTCTL_VERSION" "$MIN_DTCTL_VERSION"; then
echo " [ok] dtctl v${DTCTL_VERSION} (requires >= v${MIN_DTCTL_VERSION})"
DTCTL_STATUS="ok"
else
echo " [fail] dtctl v${DTCTL_VERSION:-unknown} — v${MIN_DTCTL_VERSION} or higher required"
echo ""
echo " v${MIN_DTCTL_VERSION} is required for this workspace:"
echo "  • dtctl inspect — analyze large query results locally without re-scanning Grail"
echo "  • --check-scopes — preflight token scopes before running a command"
echo "  • dtctl commands — compact TOON catalog by default, less agent context spent on discovery"
echo "  • DTCTL_CONFIG — trust a prepared workspace's local .dtctl.yaml (aliases/hooks) explicitly"
echo ""
echo " Upgrade dtctl:"
echo "  curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash"
echo ""
PREREQ_FAILED=true
fi
else
echo " [fail] dtctl not found — REQUIRED for workspace workflows"
echo " Must be v${MIN_DTCTL_VERSION} or higher"
echo ""
read -rp "Install dtctl now? (y/N) " INSTALL_DTCTL
if [[ "$INSTALL_DTCTL" =~ ^[Yy]$ ]]; then
echo ""
echo "Installing dtctl..."
if curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash; then
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
if command -v dtctl &>/dev/null; then
DTCTL_VERSION=$(dtctl version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if version_ge "$DTCTL_VERSION" "$MIN_DTCTL_VERSION"; then
echo " [ok] dtctl v${DTCTL_VERSION} installed"
DTCTL_STATUS="just_installed"
else
echo " [fail] Installed dtctl v${DTCTL_VERSION:-unknown}, but v${MIN_DTCTL_VERSION}+ required"
echo " Latest installer may not have reached your region yet."
echo " Wait 10 minutes and retry, or install manually:"
echo " https://github.com/dynatrace-oss/dtctl/releases/tag/v${MIN_DTCTL_VERSION}"
PREREQ_FAILED=true
fi
else
echo " [warn] dtctl installed but not in PATH — open a new terminal after setup"
DTCTL_STATUS="path_issue"
fi
else
echo " [warn] dtctl installation failed"
echo " Install manually: https://github.com/dynatrace-oss/dtctl/releases/tag/v${MIN_DTCTL_VERSION}"
PREREQ_FAILED=true
fi
else
echo " [fail] dtctl v${MIN_DTCTL_VERSION}+ is REQUIRED — cannot continue without it"
echo " https://github.com/dynatrace-oss/dtctl/releases/tag/v${MIN_DTCTL_VERSION}"
fi
fi
echo ""
if [[ "$PREREQ_FAILED" == "true" ]]; then
echo "Fix the above errors and re-run setup.sh."
exit 1
fi

# --- Idempotency check for doc substitution ----------------------------------
# Matches only real unsubstituted placeholders (which always carry the domain
# suffix) — a bare "YOUR_TENANT_ID" also appears in README's own regeneration
# example code and must not be mistaken for an unconfigured clone.
EXISTING_TENANT=""
if ! grep -qE "YOUR_TENANT_ID\.(apps\.dynatrace\.com|sprint\.apps\.dynatracelabs\.com)" "$SCRIPT_DIR/README.md" 2>/dev/null; then
echo "Documentation already configured."
DOCS_ALREADY_SUBSTITUTED=true
EXISTING_TENANT=$(grep -o 'https://[a-z0-9-]*\.apps\.dynatrace\.com\|https://[a-z0-9-]*\.sprint\.apps\.dynatracelabs\.com' "$SCRIPT_DIR/README.md" | head -1 | sed 's|https://||')
else
DOCS_ALREADY_SUBSTITUTED=false
fi

# --- Tenant URL step (always run to get TENANT_URL for config generation) -----
echo "Enter your Dynatrace environment URL."
echo "Examples:"
echo " abc12345.apps.dynatrace.com"
echo " abc12345.sprint.apps.dynatracelabs.com"
echo ""
if [[ -n "$EXISTING_TENANT" ]]; then
echo "Detected existing tenant: $EXISTING_TENANT"
echo "Press Enter to keep it (e.g. for Platform Token rotation), or type a different tenant to reconfigure."
echo ""
fi
while true; do
read -rp "Tenant URL: " TENANT_URL
if [[ -z "$TENANT_URL" && -n "$EXISTING_TENANT" ]]; then
TENANT_URL="$EXISTING_TENANT"
break
fi
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

# Detect reconfiguration to a different tenant on an already-configured clone
TENANT_CHANGED=false
if [[ "$DOCS_ALREADY_SUBSTITUTED" == "true" && -n "$EXISTING_TENANT" && "$TENANT_URL" != "$EXISTING_TENANT" ]]; then
TENANT_CHANGED=true
echo "⚠ This differs from the tenant currently documented ($EXISTING_TENANT)."
echo " The generated MCP config will point at $TENANT_URL, but README/ARCHITECTURE/ELI5/CHEATSHEET"
echo " still describe $EXISTING_TENANT unless you update them now."
echo ""
read -rp "Update documentation to match the new tenant? (y/N) " CONFIRM_RETARGET
echo ""
if [[ "$CONFIRM_RETARGET" =~ ^[Yy]$ ]]; then
DOCS_ALREADY_SUBSTITUTED=false
else
echo "Keeping documentation as-is — it will describe $EXISTING_TENANT while the config points at $TENANT_URL."
echo ""
fi
fi

# If docs not already substituted (fresh clone, or confirmed retarget), ask about updating them
if [[ "$DOCS_ALREADY_SUBSTITUTED" == "false" && "$TENANT_CHANGED" == "false" ]]; then
read -rp "Update documentation files? (y/N) " CONFIRM_DOCS
if [[ ! "$CONFIRM_DOCS" =~ ^[Yy]$ ]]; then
echo "Aborted."
exit 0
fi
echo ""
fi

# --- MCP Configuration (always runnable for token rotation) -------------------
echo "Dynatrace Remote MCP Server Configuration"
echo "========================================="
echo ""
echo "Required Platform Token Scopes:"
echo ""
echo "  Gateway (mandatory):"
echo "    • mcp-gateway:servers:invoke"
echo "    • mcp-gateway:servers:read"
echo ""
echo "  App Engine (required by most tools):"
echo "    • app-engine:apps:run"
echo ""
echo "  Grail (read-only; add only what you need):"
echo "    • storage:buckets:read"
echo "    • storage:logs:read"
echo "    • storage:events:read"
echo "    • storage:metrics:read"
echo "    • storage:spans:read"
echo "    • storage:entities:read"
echo "    • storage:bizevents:read"
echo "    • storage:security.events:read"
echo "    • storage:system:read"
echo ""
echo "  Davis (optional; for AI-driven analysis):"
echo "    • davis:analyzers:read"
echo "    • davis:analyzers:execute"
echo "    • davis-copilot:nl2dql:execute"
echo "    • davis-copilot:dql2nl:execute"
echo "    • davis-copilot:conversations:execute"
echo ""
echo "  Documents (optional; for reading notebooks/dashboards):"
echo "    • document:documents:read"
echo ""
echo "  (Scope list last verified 2026-07-16 against docs.dynatrace.com's"
echo "   'Server and server tools' reference — check there if a tool reports"
echo "   a missing scope, as Dynatrace adds new tools/scopes over time.)"
echo ""
echo "To create a token:"
echo "  1. Go to your Dynatrace environment"
echo "  2. Account Management → Identity & access management → Platform tokens"
echo "  3. Click your user profile link (shown in the page description)"
echo "  4. Click 'Generate new token'"
echo "  5. Add the scopes above (choose write scopes deliberately, not by default)"
echo "  6. Copy the token — it looks like: dt0s16.ABC12345XYZ.••••••••"
echo ""
echo "Docs: https://docs.dynatrace.com/docs/dynatrace-intelligence/dynatrace-mcp"
echo ""
read -rsp "Paste your Platform Token: " PLATFORM_TOKEN
echo ""
if [[ -z "$PLATFORM_TOKEN" ]]; then
echo "Token cannot be empty. Aborted."
exit 1
fi
echo ""

# --- Apply doc substitution (one-time on a fresh clone, or on confirmed retarget) ---
if [[ "$DOCS_ALREADY_SUBSTITUTED" == "false" ]]; then
echo "Updating documentation files..."
for FILE in "${DOC_FILES[@]}"; do
if [[ -f "$FILE" ]]; then
if [[ "$TENANT_CHANGED" == "true" ]]; then
perl -pi -e "s|\\Q${EXISTING_TENANT}\\E|${TENANT_URL}|g" "$FILE"
else
perl -pi -e "s|YOUR_TENANT_ID\\.apps\\.dynatrace\\.com|${TENANT_URL}|g" "$FILE"
perl -pi -e "s|YOUR_TENANT_ID\\.sprint\\.apps\\.dynatracelabs\\.com|${TENANT_URL}|g" "$FILE"
fi
echo " ✓ $FILE"
fi
done
echo ""
fi

# --- Generate MCP config (always runnable) -----------------------------------
echo "Generating MCP configuration..."
for TEMPLATE in "${TEMPLATE_FILES[@]}"; do
if [[ ! -f "$TEMPLATE" ]]; then
echo " [fail] Template not found: $TEMPLATE"
exit 1
fi

TARGET="${TEMPLATE%.template}"
cp "$TEMPLATE" "$TARGET"
perl -pi -e "s|YOUR_TENANT_DOMAIN|${TENANT_URL}|g" "$TARGET"
perl -pi -e "s|YOUR_PLATFORM_TOKEN|${PLATFORM_TOKEN}|g" "$TARGET"
chmod 600 "$TARGET"
echo " ✓ $(basename "$TARGET") (mode 600)"
done
echo ""

# --- Next steps ---------------------------------------------------------------
echo "Done. Next steps:"
echo ""
STEP=1
case "$DTCTL_STATUS" in
unavailable)
echo "${STEP}. Install dtctl v${MIN_DTCTL_VERSION}+:"
echo " https://github.com/dynatrace-oss/dtctl/releases/tag/v${MIN_DTCTL_VERSION}"
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
echo "${STEP}. Launch VS Code and verify the connection:"
echo " code"
echo " Then open Copilot Chat or Claude Code chat and enter:"
echo " /health-check"
echo ""
STEP=$((STEP + 1))
if [[ "$CLAUDE_CLI_STATUS" == "ok" ]]; then
echo "${STEP}. (Optional) Start Claude Code CLI for terminal-based sessions:"
echo " claude"
echo " The MCP server and all skills will load automatically."
echo ""
STEP=$((STEP + 1))
fi
echo "For more details, see README.md"
echo ""

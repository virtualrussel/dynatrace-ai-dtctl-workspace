#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIN_DTCTL_VERSION="0.35.0"

# Returns 0 if $1 >= $2 for dotted numeric versions (e.g. 0.30.10 vs 0.30.9).
# Anything that isn't a strict X.Y.Z version (including "unknown" or empty)
# fails closed rather than silently passing.
version_ge() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  [[ "$1" == "$2" ]] && return 0
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" == "$1" ]]
}

get_dtctl_version() {
local version_output
local version

version_output=$(dtctl version 2>/dev/null) || return 1
version=$(printf '%s\n' "$version_output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
printf '%s\n' "$version"
}

normalize_tenant() {
local tenant="$1"
tenant="${tenant#https://}"
tenant="${tenant#http://}"
tenant="${tenant%/}"
tenant=$(printf '%s' "$tenant" | tr '[:upper:]' '[:lower:]')

if [[ "$tenant" =~ ^[a-z0-9-]+\.apps\.dynatrace\.com$ ]] || \
[[ "$tenant" =~ ^[a-z0-9-]+\.sprint\.apps\.dynatracelabs\.com$ ]]; then
printf '%s\n' "$tenant"
return 0
fi

return 1
}

extract_tenant_from_config() {
local config_file="$1"
local gateway_url
local tenant

[[ -f "$config_file" ]] || return 1
gateway_url=$(grep -Eo '"url"[[:space:]]*:[[:space:]]*"https://[a-zA-Z0-9-]+\.(apps\.dynatrace\.com|sprint\.apps\.dynatracelabs\.com)/platform-reserved/mcp-gateway/v0\.1/servers/dynatrace-mcp/mcp"' "$config_file" | head -1) || return 1
[[ -n "$gateway_url" ]] || return 1

tenant=$(printf '%s' "$gateway_url" | sed -E 's|.*https://([^/]+)/.*|\1|')
normalize_tenant "$tenant"
}

# Template files that generate config
TEMPLATE_FILES=(
"$SCRIPT_DIR/.vscode/mcp.json.template"
"$SCRIPT_DIR/.mcp.json.template"
)

MCP_CORE_SCOPES=(
"ai:operator:execute"
"mcp-gateway:servers:invoke"
"mcp-gateway:servers:read"
"storage:buckets:read"
"storage:entities:read"
"storage:events:read"
"storage:logs:read"
"storage:metrics:read"
"storage:security.events:read"
"storage:smartscape:read"
"storage:spans:read"
)

MCP_FULL_SCOPES=(
"ai:operator:execute"
"mcp-gateway:servers:invoke"
"mcp-gateway:servers:read"
"davis-copilot:conversations:execute"
"davis-copilot:nl2dql:execute"
"davis-copilot:document-search:execute"
"davis-copilot:dql2nl:execute"
"davis:analyzers:read"
"davis:analyzers:execute"
"document:documents:read"
"storage:bizevents:read"
"storage:buckets:read"
"storage:entities:read"
"storage:events:read"
"storage:files:read"
"storage:logs:read"
"storage:metrics:read"
"storage:security.events:read"
"storage:smartscape:read"
"storage:spans:read"
"storage:system:read"
"storage:user.events:read"
"storage:user.sessions:read"
"storage:user.replays:read"
)

print_scopes() {
local scope
for scope in "$@"; do
echo "    - $scope"
done
}

echo ""
echo "Dynatrace AI Workspace — Setup"
echo "================================"
echo ""

# --- Prerequisites -----------------------------------------------------------
echo "Checking prerequisites..."
echo ""
PREREQ_FAILED=false
DTCTL_STATUS="pending"

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
if DTCTL_VERSION=$(get_dtctl_version) && version_ge "$DTCTL_VERSION" "$MIN_DTCTL_VERSION"; then
echo " [ok] dtctl v${DTCTL_VERSION} (requires >= v${MIN_DTCTL_VERSION})"
DTCTL_STATUS="ok"
else
echo " [fail] dtctl v${DTCTL_VERSION:-unknown} — v${MIN_DTCTL_VERSION} or higher required"
echo ""
echo " v${MIN_DTCTL_VERSION} is required for this workspace:"
echo "  • dtctl inventory — discover queryable data and capabilities before exploratory DQL"
echo "  • dtctl plugin — discover kubectl-style dtctl-* extensions safely"
echo "  • reliable agent envelopes, query polling, authentication, and first-apply ID handling"
echo "  • breakpoint and snapshot workflows for Live Debugger investigations"
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
if DTCTL_VERSION=$(get_dtctl_version) && version_ge "$DTCTL_VERSION" "$MIN_DTCTL_VERSION"; then
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
echo " [fail] Installer completed, but dtctl is not available in PATH"
echo " Open a new terminal, verify dtctl v${MIN_DTCTL_VERSION}+, and re-run setup.sh."
PREREQ_FAILED=true
fi
else
echo " [fail] dtctl installation failed"
echo " Install manually: https://github.com/dynatrace-oss/dtctl/releases/tag/v${MIN_DTCTL_VERSION}"
PREREQ_FAILED=true
fi
else
echo " [fail] dtctl v${MIN_DTCTL_VERSION}+ is REQUIRED — cannot continue without it"
echo " https://github.com/dynatrace-oss/dtctl/releases/tag/v${MIN_DTCTL_VERSION}"
PREREQ_FAILED=true
fi
fi
echo ""
if [[ "$PREREQ_FAILED" == "true" ]]; then
echo "Fix the above errors and re-run setup.sh."
exit 1
fi

# --- Detect tenant from generated MCP configuration --------------------------
EXISTING_TENANT=""
VSCODE_CONFIG="$SCRIPT_DIR/.vscode/mcp.json"
CLAUDE_CONFIG="$SCRIPT_DIR/.mcp.json"
VSCODE_TENANT=$(extract_tenant_from_config "$VSCODE_CONFIG" || true)
CLAUDE_TENANT=$(extract_tenant_from_config "$CLAUDE_CONFIG" || true)

if [[ -n "$VSCODE_TENANT" && -n "$CLAUDE_TENANT" && "$VSCODE_TENANT" == "$CLAUDE_TENANT" ]]; then
EXISTING_TENANT="$VSCODE_TENANT"
elif [[ -f "$VSCODE_CONFIG" || -f "$CLAUDE_CONFIG" ]]; then
echo " [warn] Could not safely detect one tenant from both generated MCP configs."
echo "        Enter the tenant explicitly; setup will regenerate both configs."
echo ""
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
read -rp "Tenant URL: " TENANT_INPUT
if [[ -z "$TENANT_INPUT" && -n "$EXISTING_TENANT" ]]; then
TENANT_URL="$EXISTING_TENANT"
break
fi
if TENANT_URL=$(normalize_tenant "$TENANT_INPUT"); then
break
fi
echo "Invalid URL. Must match *.apps.dynatrace.com or *.sprint.apps.dynatracelabs.com"
echo ""
done
echo ""
echo "Tenant URL: $TENANT_URL"

# --- MCP Configuration (always runnable for token rotation) -------------------
echo "Dynatrace Remote MCP Server Configuration"
echo "========================================="
echo ""
echo "Choose a read-only MCP permission profile for your Platform Token:"
echo "  1. Full read-only MCP (recommended)"
echo "     Enables all currently documented MCP analysis and lookup tools."
echo "  2. Core incident analysis"
echo "     Supports the six bundled prompts with a smaller data-access surface."
echo ""
while true; do
read -rp "Permission profile [1]: " MCP_PROFILE_CHOICE
MCP_PROFILE_CHOICE="${MCP_PROFILE_CHOICE:-1}"
case "$MCP_PROFILE_CHOICE" in
1)
MCP_PROFILE_NAME="Full read-only MCP"
MCP_SELECTED_SCOPES=("${MCP_FULL_SCOPES[@]}")
break
;;
2)
MCP_PROFILE_NAME="Core incident analysis"
MCP_SELECTED_SCOPES=("${MCP_CORE_SCOPES[@]}")
break
;;
*)
echo "Enter 1 for Full read-only MCP or 2 for Core incident analysis."
;;
esac
done
echo ""
echo "$MCP_PROFILE_NAME Platform Token scope checklist:"
print_scopes "${MCP_SELECTED_SCOPES[@]}"
if [[ "$MCP_PROFILE_CHOICE" == "2" ]]; then
echo ""
echo "  Core excludes RUM/session replay, business events, platform costs,"
echo "  document search, lookup files, query helpers, and Davis analyzers."
fi
echo ""
echo "  This selection is guidance for creating the token. setup.sh cannot"
echo "  inspect or change the scopes of the token you paste. Effective access"
echo "  also depends on the assigned identity's IAM and Grail policies."
echo ""
echo "  Scope list verified 2026-07-21 against the official Dynatrace MCP"
echo "  'Server and server tools' permission reference."
echo ""
echo "To create a token:"
echo "  1. Go to your Dynatrace environment"
echo "  2. Account Management → Identity & access management → Platform tokens"
echo "  3. Click your user profile link (shown in the page description)"
echo "  4. Click 'Generate new token'"
echo "  5. Add the scopes in the selected checklist above"
echo "  6. Copy the token — it looks like: dt0s16.ABC12345XYZ.••••••••"
echo ""
echo "Docs: https://docs.dynatrace.com/docs/dynatrace-intelligence/dynatrace-mcp"
echo "Workspace guide: docs/PERMISSIONS.md"
echo ""
read -rsp "Paste your Platform Token: " PLATFORM_TOKEN
echo ""
if [[ -z "$PLATFORM_TOKEN" ]]; then
echo "Token cannot be empty. Aborted."
exit 1
fi
echo ""

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

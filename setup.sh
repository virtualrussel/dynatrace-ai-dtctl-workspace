#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILES=(
  "$SCRIPT_DIR/.vscode/mcp.json"
  "$SCRIPT_DIR/.mcp.json"
  "$SCRIPT_DIR/CLAUDE.md"
  "$SCRIPT_DIR/.github/copilot-instructions.md"
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
    echo "  [ok]   Node.js v${NODE_VERSION}"
  else
    echo "  [fail] Node.js v${NODE_VERSION} — v18 or higher required"
    echo "         Install the LTS version: https://nodejs.org/"
    PREREQ_FAILED=true
  fi
else
  echo "  [fail] Node.js not found — v18 or higher required"
  echo "         Install the LTS version: https://nodejs.org/"
  PREREQ_FAILED=true
fi

# jq
if command -v jq &>/dev/null; then
  JQ_VERSION=$(jq --version 2>/dev/null | sed 's/^jq-//' || echo "installed")
  echo "  [ok]   jq ${JQ_VERSION}"
else
  echo "  [warn] jq not found — needed for manual MCP config updates"
  echo "         Install: brew install jq  /  apt install jq  /  choco install jq"
fi

# dtctl
if command -v dtctl &>/dev/null; then
  DTCTL_VERSION=$(dtctl version 2>/dev/null | head -1 || echo "installed")
  echo "  [ok]   dtctl ${DTCTL_VERSION}"
  DTCTL_STATUS="ok"
else
  echo "  [warn] dtctl not found — required for workspace workflows"
  echo ""
  read -rp "Install dtctl now? (y/N) " INSTALL_DTCTL
  if [[ "$INSTALL_DTCTL" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing dtctl..."
    if curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash; then
      export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
      if command -v dtctl &>/dev/null; then
        DTCTL_VERSION=$(dtctl version 2>/dev/null | head -1 || echo "installed")
        echo "  [ok]   dtctl ${DTCTL_VERSION} installed"
        DTCTL_STATUS="just_installed"
      else
        echo "  [warn] dtctl installed but not in PATH — open a new terminal after setup"
        DTCTL_STATUS="path_issue"
      fi
    else
      echo "  [warn] dtctl installation failed"
      echo "         Install manually: curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash"
    fi
  else
    echo "  [warn] dtctl required for workspace workflows — install before using prompts"
    echo "         curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash"
  fi
fi

echo ""

if [[ "$PREREQ_FAILED" == "true" ]]; then
  echo "Fix the above errors and re-run setup.sh."
  exit 1
fi

# --- Idempotency check -------------------------------------------------------

if ! grep -q "YOUR_TENANT_ID" "$SCRIPT_DIR/.vscode/mcp.json" 2>/dev/null; then
  echo "This workspace has already been configured."
  echo "setup.sh only works on the initial setup."
  exit 1
fi

# --- Tenant URL --------------------------------------------------------------

echo "Enter your Dynatrace environment URL."
echo "Examples:"
echo "  abc12345.apps.dynatrace.com"
echo "  abc12345.sprint.apps.dynatracelabs.com"
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
read -rp "Update 8 workspace files? (y/N) " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""

# --- Apply replacements ------------------------------------------------------

for FILE in "${FILES[@]}"; do
  if [[ -f "$FILE" ]]; then
    perl -pi -e "s|YOUR_TENANT_ID\\.apps\\.dynatrace\\.com|${TENANT_URL}|g" "$FILE"
    echo "  updated  $FILE"
  fi
done

# --- Next steps --------------------------------------------------------------

echo ""
echo "Done. Next steps:"
echo ""

STEP=1

case "$DTCTL_STATUS" in
  unavailable)
    echo "${STEP}. Install dtctl:"
    echo "   curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | bash"
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
  echo "   (Open a new terminal first — dtctl was just added to your PATH)"
fi
echo "   dtctl auth login --context production --environment \"https://${TENANT_URL}\""
echo "   Then verify: dtctl doctor"
echo ""
STEP=$((STEP + 1))

echo "${STEP}. Reload VS Code:"
echo "   Cmd+Shift+P → Developer: Reload Window"
echo ""

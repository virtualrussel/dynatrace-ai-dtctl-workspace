# dtctl Troubleshooting

## Installation

Install from https://github.com/dynatrace-oss/dtctl. Verify with `dtctl version`.

```bash
# macOS/Linux (recommended)
brew install dynatrace-oss/tap/dtctl

# Or via shell script
curl -fsSL https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.sh | sh

# Windows (PowerShell)
irm https://raw.githubusercontent.com/dynatrace-oss/dtctl/main/install.ps1 | iex

# Verify
dtctl doctor
```

## Initial Setup

```bash
# OAuth login (recommended — no token management required)
dtctl auth login --context production \
  --environment "https://YOUR_TENANT_ID.apps.dynatrace.com"

# Token-based login (alternative)
dtctl config set-credentials "my-token" --token "$DYNATRACE_API_TOKEN"
dtctl config set-context "default" \
  --environment "$DYNATRACE_BASE_URL" \
  --token-ref "my-token"
dtctl config use-context "default"

# Verify
dtctl auth whoami --plain
dtctl auth status         # check OAuth session health (token expiry, refresh token)
dtctl doctor              # full health check including OAuth session row
```

**Note for token-based auth:** Always use `--token "$TOKEN"` directly. Stdin piping does not work reliably and stores corrupted values in the keychain.

**File-based OAuth token storage** (for headless Linux, WSL, CI/CD, containers):
```bash
export DTCTL_TOKEN_STORAGE=file   # tokens stored under $XDG_DATA_HOME/dtctl/oauth-tokens/ (0600 perms)
```

## Common Issues

### 401/403 Authentication Errors
```bash
# Re-store credentials
dtctl config set-credentials "my-token" --token "$TOKEN"

# Verify identity
dtctl auth whoami --plain

# Check permissions
dtctl auth can-i <verb> <resource>
```

### Wrong Tenant
```bash
dtctl config get-contexts --plain
dtctl config current-context
# If production is not active, re-authenticate for production:
dtctl auth login --context production --environment "https://YOUR_TENANT_ID.apps.dynatrace.com"
```

### Safety Level Blocks
Safety levels are client-side protections: `readonly`, `readwrite-mine`, `readwrite-all`, `dangerously-unrestricted`. API token scopes determine actual permissions.

### dtctl Not Found
Ensure binary is on PATH. Check `~/bin/dtctl` or `/usr/local/bin/dtctl`.

### Corrupted Keychain Entry (macOS)
```bash
security delete-generic-password -s "dtctl" -a "<token-ref>"
dtctl config set-credentials "<token-ref>" --token "$TOKEN"
```

## Debugging

```bash
# Verbose output
dtctl <command> -v     # Details
dtctl <command> -vv    # Full debug including auth headers
```

## Platform Notes
- **macOS**: Keychain must be unlocked
- **Linux**: Requires gnome-keyring or similar
- **Windows**: Uses Credential Manager

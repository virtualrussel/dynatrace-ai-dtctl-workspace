# dtctl Troubleshooting

## Installation

Install from https://github.com/dynatrace-oss/dtctl. Verify with `dtctl version`.

```bash
ARCH=$(uname -m | sed 's/x86_64/amd64/; s/arm64/arm64/')
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
TAG=$(curl -s -I -L https://github.com/dynatrace-oss/dtctl/releases/latest | tr -d '\r' | awk -F/ '/^location: /{print $NF}' | tail -n1)
TARBALL="dtctl_${TAG#v}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/dynatrace-oss/dtctl/releases/download/${TAG}/${TARBALL}"
mkdir -p /tmp/dtctl && cd /tmp/dtctl
curl -L "$URL" -o "$TARBALL"
tar -xzf "$TARBALL"
sudo mv dtctl /usr/local/bin/
dtctl version
```

If no sudo: place in `~/bin/` and ensure it's on PATH.

## Initial Setup

```bash
# Store credentials (use --token flag directly, NOT stdin piping)
dtctl config set-credentials "my-token" --token "$DYNATRACE_API_TOKEN"
dtctl config set-context "default" \
  --environment "$DYNATRACE_BASE_URL" \
  --token-ref "my-token"
dtctl config use-context "default"

# Verify
dtctl auth whoami --plain
dtctl auth status --plain
dtctl doctor
```

**Note:** Always use `--token "$TOKEN"` directly. Stdin piping does not work reliably and stores corrupted values in the keychain.

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

If `dtctl doctor` shows a platform-token user identity warning in v0.27.0+, treat it as informational when the overall check passes.

In v0.27.0+, `dtctl config set-credentials` also clears stale OAuth cache for the same token reference, and revoked refresh-token sessions fall back to platform-token auth automatically.

### Wrong Tenant
```bash
dtctl config get-contexts --plain
dtctl config use-context <name>
```

After `dtctl auth login --context <name>`, empty template contexts created by `dtctl config init` are pruned automatically in v0.27.0+.

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

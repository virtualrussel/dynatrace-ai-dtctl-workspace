# dtctl Configuration Management

## Configuration Discovery

dtctl checks three locations in priority order:
1. Command-line flags
2. Local project `.dtctl.yaml`
3. Global `$XDG_CONFIG_HOME/dtctl/config`

Recommendation: local `.dtctl.yaml` for project-specific contexts, global config for personal tenants.

## .dtctl.yaml Files

Can be committed to git (no secrets). Credentials stored separately in OS keyring.

**Team conflict note:** `use-context` modifies the config file. Workarounds:
- Exclude from version control
- Use `--context` flag per command instead of switching
- Accept individual context preferences in commits

## Credential Management

Platform tokens (`dt0s16.*`) are created at **https://myaccount.dynatrace.com/platformTokens**. Classic API tokens (`dt0c01.*`) live under Identity & Access Management > Access Tokens in the tenant UI — that is NOT the correct location for dtctl tokens.

```bash
# Store token (use --token flag, not stdin)
dtctl config set-credentials "prod-token" --token "$TOKEN"

# Create context
dtctl config set-context "prod" \
  --environment "https://tenant.apps.dynatrace.com" \
  --token-ref "prod-token" \
  --safety-level readwrite-mine

# Switch context
dtctl config use-context "prod"

# Per-command context override
dtctl get workflows --context staging --plain
```

## Azure Cloud Connections (v0.31.0+)

`dtctl create azure connection` and `dtctl update azure connection` accept credential flags directly, so a `clientSecret`-type connection can be set up in one command — no YAML round-trip required:

```bash
dtctl create azure connection my-conn \
  --type clientSecret \
  --directoryId   "$AZURE_TENANT_ID" \
  --applicationId "$AZURE_APP_ID" \
  --clientSecret  "$AZURE_CLIENT_SECRET"
```

`--clientSecret` on `update` also enables zero-downtime secret rotation — pair it with `az ad app credential reset --append` so the old secret keeps working until the new one is confirmed live:

```bash
dtctl update azure connection my-conn --clientSecret "$NEW_AZURE_CLIENT_SECRET"
```

For federated-identity connections whose token issuer can't be inferred from the hostname, set `--issuer` explicitly (or a top-level `issuer:` field in the connection YAML); dtctl falls back to host-based detection when omitted.

## Safety Levels

| Level | Use Case |
|-------|----------|
| `readonly` | Production monitoring |
| `readwrite-mine` | Development (recommended default) |
| `readwrite-all` | Shared environments |
| `dangerously-unrestricted` | Emergency admin |

Actual permissions depend on API token scopes, not just safety level.

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

## Safety Levels

| Level | Use Case |
|-------|----------|
| `readonly` | Production monitoring |
| `readwrite-mine` | Development (recommended default) |
| `readwrite-all` | Shared environments |
| `dangerously-unrestricted` | Emergency admin |

Actual permissions depend on API token scopes, not just safety level.

## v0.27.0 Migration Notes

### Settings objects: use objectId

Legacy synthetic UID/UUID addressing for settings objects is removed. Use `objectId` from API output:

```bash
dtctl get settings -o json --plain \
  | jq -r '.[] | select(.value.foo == "bar") | .objectId' \
  | xargs -I{} dtctl describe setting {}
```

### Apply hooks: explicit shell for shell syntax

`pre-apply` hooks are now executed directly (tokenized argv), not through implicit `sh -c`. If your hook string relies on pipes, redirection, or globbing, wrap it in an explicit shell:

```yaml
preferences:
  hooks:
    pre-apply: bash -c 'lint "$1" | tee /tmp/lint.log'
    post-apply: bash /etc/dtctl/notify-on-apply.sh
```

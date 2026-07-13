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

## Config Trust Model

An auto-discovered local `.dtctl.yaml` (found by walking up from the current directory) is treated as **untrusted** — the same threat model as a checked-out repo or an unpacked tarball. dtctl therefore ignores **command aliases** and **pre-/post-apply hooks** defined in it, printing a warning to stderr when it does. Contexts, tokens, and other preferences in a local config still work normally. Aliases and hooks are honored only from:

- The global config (`$XDG_CONFIG_HOME/dtctl/config`), or
- A config named explicitly with `--config <path>` or the `DTCTL_CONFIG` environment variable

```bash
# Trust a prepared workspace's local .dtctl.yaml — e.g. an automation harness
# that generates a clean working directory with its own config, skills, and hooks
export DTCTL_CONFIG="$PWD/.dtctl.yaml"
```

Setting `DTCTL_CONFIG` skips auto-discovery entirely and honors that file's aliases and hooks without changing any invocation (an agent keeps running `dtctl apply` unchanged). An alias can never shadow a built-in command (`get`, `apply`, `version`, etc.) regardless of where it's defined. Agents relying on an untouched local `.dtctl.yaml` should use explicit contexts/flags instead of assuming aliases or hooks will fire.

## Command Profiles

A command profile restricts **which commands dtctl exposes** — shaping `--help`, the `dtctl commands` catalog, and shell completion all at once, and hard-blocking invocation of anything outside the set. This is aimed squarely at embedding dtctl in AI agents: an investigation agent that only ever needs `query` and Davis analyzers doesn't need `auth login` or the cloud-provisioning verbs cluttering its command catalog.

```bash
# Bind a built-in profile to a context — an embedded agent inherits the
# reduced surface with zero flags
dtctl config set-context prod-agent \
  --environment https://abc12345.apps.dynatrace.com \
  --token-ref prod-token \
  --profile query \
  --safety-level readonly

# Or select a profile for one invocation/environment (highest precedence)
DTCTL_PROFILE=query dtctl commands
```

Built-in profiles: `full` (default, everything), `query` (`query`, `get analyzers`, `describe analyzer`, `exec analyzer`, `verify analyzer`), `investigate` (`query`, `logs`, `get`, `find`, `describe`). Define custom profiles under a top-level `profiles:` map in the config (`description` + a flat `commands` allowlist — default-deny, so adding a new dtctl command never silently widens an existing profile).

Only `commands`/`commands howto` and `help` are always available regardless of profile — everything else, including `config`/`ctx`, is subject to the allowlist. Profiles are a convenience, not a security boundary (client-side, like safety levels); a determined caller can unset `DTCTL_PROFILE`. For real restriction, scope the API token itself. Profiles and safety levels are orthogonal — set both on a context to express "this agent only sees `query` and can never mutate."

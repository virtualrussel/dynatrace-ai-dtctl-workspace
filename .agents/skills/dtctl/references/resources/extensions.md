# Extensions Resource

## List
```bash
dtctl get extensions                                      # List all extensions (shows extension name and active version)
dtctl get extensions -o json                              # Output as JSON
```

## Get Versions
```bash
dtctl get extensions com.dynatrace.extension.host-monitoring # Get all versions of a specific extension
```

## Describe
```bash
dtctl describe extension com.dynatrace.extension.host-monitoring         # Show detailed info (active version by default)
dtctl describe extension com.dynatrace.extension.host-monitoring 1.2.3   # Show details for a specific version
dtctl describe extension com.dynatrace.extension.host-monitoring -o json # Output as JSON

# Include each feature set's metrics (name, display name, unit)
dtctl describe extension com.dynatrace.extension.host-monitoring --feature-set-metrics -o json

# Inspect bundled assets (alert templates, Smartscape config) without downloading the zip yourself
dtctl describe extension com.dynatrace.extension.postgres --version 3.0.12 --assets=alert_templates
dtctl describe extension com.dynatrace.extension.postgres --version 3.0.12 --assets=alert_templates,smartscape --full  # full file content
```

> **Breaking change:** the default JSON/YAML shape of `featureSets` on `describe extension` is a plain array (`["name"]`), not a map (`{"name": []}`) — regardless of whether `--feature-set-metrics` is passed. dtctl is pre-1.0, so this shipped without a compatibility shim. If anything parses `describe extension` output for `featureSets`, check which shape it expects.

## Download

`-o zip` is not supported on `describe extension`; download the raw package instead:
```bash
dtctl download extension com.dynatrace.extension.postgres --version 2.9.3 > postgres.zip
```
Writes binary data to stdout — always redirect. Incompatible with agent mode (`-A`): raw binary can't be wrapped in a JSON envelope.

## Get Monitoring Configurations
```bash
dtctl get extension-configs com.dynatrace.extension.host-monitoring                          # List monitoring configurations for an extension
dtctl get extension-config com.dynatrace.extension.host-monitoring --config-id <config-id>   # Get a specific monitoring configuration by ID
```

## Apply Monitoring Configuration
```bash
dtctl apply extension-config com.dynatrace.extension.host-monitoring -f config.yaml                    # Create new (no objectId in file)
dtctl apply extension-config com.dynatrace.extension.host-monitoring -f config.yaml --scope HOST-1234  # Create with scope
dtctl apply extension-config com.dynatrace.extension.host-monitoring -f config.yaml                    # Update existing (objectId in file)
dtctl apply extension-config com.dynatrace.extension.host-monitoring -f config.yaml --set env=prod     # Apply with template variables
dtctl apply extension-config com.dynatrace.extension.host-monitoring -f config.yaml --dry-run          # Dry run
```

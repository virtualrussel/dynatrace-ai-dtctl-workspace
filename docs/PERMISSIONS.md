# Dynatrace MCP Permissions

This is the authoritative permission guide for the workspace's Dynatrace MCP connection. The setup script prints one of the profiles below as a checklist when you create a Platform Token.

## Recommended Profile

Use **Full read-only MCP** unless your administrator requires a smaller least-privilege profile. It enables the complete read and analysis surface advertised by the installed skills without granting write, delete, or share access.

Use **Core incident analysis** when access must be limited to the six bundled investigation prompts. Skills outside that surface can still load, but their live Dynatrace operations may fail with a permission error.

The profile selected in `setup.sh` is guidance only. The script cannot inspect or modify the scopes of a pasted token.

## Authorization Layers

Successful access depends on all three layers:

1. **Platform Token scopes** allow the token to call specific platform APIs.
2. **User or service-user IAM permissions** limit the identity assigned to the token.
3. **Grail policies** control accessible buckets, tables, records, and sensitive fields.

A selected token scope never grants more access than the assigned identity already has. A request can therefore fail even when the token includes the documented scope.

## Full Read-Only MCP

This profile follows the official Dynatrace MCP all-tools permission list, verified July 21, 2026. It contains no write, delete, or share scopes.

```text
ai:operator:execute
mcp-gateway:servers:invoke
mcp-gateway:servers:read
davis-copilot:conversations:execute
davis-copilot:nl2dql:execute
davis-copilot:document-search:execute
davis-copilot:dql2nl:execute
davis:analyzers:read
davis:analyzers:execute
document:documents:read
storage:bizevents:read
storage:buckets:read
storage:entities:read
storage:events:read
storage:files:read
storage:logs:read
storage:metrics:read
storage:security.events:read
storage:smartscape:read
storage:spans:read
storage:system:read
storage:user.events:read
storage:user.sessions:read
storage:user.replays:read
```

## Core Incident Analysis

This smaller profile supports the six bundled prompts: daily standup, health check, incident response, error investigation, performance regression, and problem troubleshooting.

```text
ai:operator:execute
mcp-gateway:servers:invoke
mcp-gateway:servers:read
storage:buckets:read
storage:entities:read
storage:events:read
storage:logs:read
storage:metrics:read
storage:security.events:read
storage:smartscape:read
storage:spans:read
```

Core incident analysis excludes:

- RUM events, sessions, and session replay
- GenAI evaluation business events
- Platform cost and system-event analysis
- Document and troubleshooting-guide search
- Lookup-file access
- Generative query, query explanation, and product-help tools
- Forecasting and other Davis analyzers

## Capability Map

| Capability | Additional Full-profile scopes beyond Core |
|---|---|
| RUM and frontend drill-down | `storage:user.events:read`, `storage:user.sessions:read`, `storage:user.replays:read` |
| GenAI evaluations and business analytics | `storage:bizevents:read` |
| Platform cost analysis | `storage:system:read` |
| Document search | `davis-copilot:document-search:execute`, `document:documents:read` |
| Lookup files | `storage:files:read` |
| Query generation | `davis-copilot:nl2dql:execute` |
| Query explanation | `davis-copilot:dql2nl:execute` |
| Product help | `davis-copilot:conversations:execute` |
| Forecasting and analyzers | `davis:analyzers:read`, `davis:analyzers:execute` |

## Sensitive RUM Fields

Some RUM fields, including user identity and client IP, are hidden by the `builtin-sensitive-user-events-and-sessions` fieldset. Access requires a separate IAM policy statement:

```text
ALLOW storage:fieldsets:read WHERE storage:fieldset-name="builtin-sensitive-user-events-and-sessions";
```

This is not part of either standard Platform Token profile. Grant it only when the use case intentionally requires sensitive fields.

## dtctl Permissions Are Separate

The MCP profiles enable MCP analysis and lookup tools. They do not grant notebook, dashboard, workflow, settings, or other dtctl lifecycle access.

For a dtctl operation, discover and preflight its command-specific requirements:

```bash
dtctl commands "<verb> <resource>" --required-scopes
dtctl <verb> <resource> --check-scopes
dtctl auth can-i <verb> <resource>
```

Authenticate dtctl independently with OAuth or a token-backed context. Use `--validate-only` where supported and obtain approval before mutations.

## Troubleshooting

A `401` or `403` is an authorization failure, not evidence that no telemetry exists.

1. Identify which MCP tool or data source failed.
2. Find its capability in the table above.
3. Confirm the Platform Token includes the corresponding scope.
4. Confirm the assigned user or service user has the matching IAM permission.
5. Confirm Grail bucket, table, record, and field policies permit the requested data.
6. Rotate or replace the token, rerun `bash setup.sh`, and restart or reload the MCP client.

For the current server tool list, see the [Dynatrace MCP server documentation](https://docs.dynatrace.com/docs/dynatrace-intelligence/dynatrace-mcp). For Grail access controls, see [Permissions in Grail](https://docs.dynatrace.com/docs/platform/grail/organize-data/assign-permissions-in-grail).

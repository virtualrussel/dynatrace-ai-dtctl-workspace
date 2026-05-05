---
agent: agent
description: Generate a daily standup report for JourneyService and CheckDestination, create an actionable Dynatrace notebook with embedded DQL queries and remediation steps, then verify it using dtctl.
---
Run a daily standup report for JourneyService and CheckDestination using the dynatrace-mcp server.

Then create a Dynatrace notebook called "Daily Standup — JourneyService & CheckDestination — [TODAY'S DATE]".

Structure the notebook as follows:
1. Executive Summary — overall health status for both services
2. JourneyService Findings — metrics comparison, incidents, action items
3. CheckDestination Findings — metrics comparison, health confirmation
4. Embedded DQL Queries — include live queries for:
   - JourneyService avg and P95 response time trend (last 24h)
   - JourneyService error rate over time
   - Active problems related to JourneyService infrastructure
   - CheckDestination response time and error rate
5. Remediation Steps — specific next steps per service with priority

## DQL Query Rules
Before generating ANY DQL query, load the dt-dql-essentials skill and refer to the timeseries command specification. All queries must follow these rules exactly:

### Comments
- NEVER use # inside DQL queries — not valid DQL syntax
- NEVER use -- inside DQL queries
- Section titles and descriptions belong in notebook markdown sections ONLY, never inside query blocks

### timeseries Command
- NEVER use `as` for aliasing — use = assignment instead
  - WRONG: timeseries avg(dt.service.request.response_time) as avg_rt
  - CORRECT: timeseries avg_rt = avg(dt.service.request.response_time)
- NEVER use contains() in a timeseries filter — timeseries requires exact dimension matching via by: and ==
  - WRONG: | filter dt.service.name contains "CheckDestination"
  - CORRECT: timeseries ..., by: {dt.service.name} | filter dt.service.name == "CheckDestination"
- ALWAYS include by: {dt.service.name} when filtering timeseries by service
- ALWAYS use array notation for computed fields on timeseries results
  - CORRECT: | fieldsAdd avg_rt_ms = avg_rt[] / 1000

### General DQL
- ALWAYS use double quotes for string values, never single quotes
- ALWAYS specify time ranges explicitly: from: now()-24h, to: now()
- NEVER use filter field in ["a", "b"] — use filter in(field, "a", "b")
- NEVER use by: field1, field2 — use by: {field1, field2}

### Correct timeseries Template
Use this exact pattern for all service metric queries:

timeseries avg_rt = avg(dt.service.request.response_time),
  errors = sum(dt.service.request.failure_count),
  total = sum(dt.service.request.count),
  from: now()-24h, to: now(), interval: 1h,
  by: {dt.service.name}
| filter dt.service.name == "<exact-service-name>"
| fieldsAdd avg_rt_ms = avg_rt[] / 1000,
  error_rate = (errors[] * 100.0) / total[]

### Active Problems Template
Use this exact pattern for problem queries:

fetch dt.davis.problems, from: now()-24h
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| filter matchesPhrase(event.name, "<service-name>")
| fields display_id, event.name, event.category, event.start
| sort event.start desc
| limit 10

## After Creating the Notebook
1. Confirm the notebook URL from the MCP response
2. Run dtctl get notebooks --filter 'name == "Daily Standup — JourneyService & CheckDestination — [TODAY\'S DATE]"' --sort "-modificationInfo.lastModifiedTime" in the terminal to verify it appears in Dynatrace
3. Run dtctl describe notebook "[notebook id or exact notebook name]" to confirm the structure
4. Share the verified URL for the team to access

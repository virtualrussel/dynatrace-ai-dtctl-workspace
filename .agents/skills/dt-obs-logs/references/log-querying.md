# Log Querying Reference

Core patterns for fetching, filtering, and searching Dynatrace log data using DQL.

---

## Basic Log Fetch

Fetch recent logs with a time range:

```dql
fetch logs, from:now() - 1h
| fields timestamp, status, content, dt.process_group.detected_name
| sort timestamp desc
| limit 100
```

**Key fields:**
- `timestamp`: Log entry creation time
- `status` / `loglevel`: Severity level (ERROR, WARN, INFO, DEBUG, etc.)
- `content`: Raw log message text
- `dt.process_group.detected_name`: Human-readable process group name
- `dt.source_entity`: Entity ID that produced the log

---

## Severity Filtering

### Single severity

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| fields timestamp, content, dt.process_group.detected_name
| sort timestamp desc
| limit 100
```

### Multiple severities

```dql
fetch logs, from:now() - 2h
| filter in(status, {"ERROR", "FATAL", "WARN"})
| fields timestamp, status, content, dt.process_group.detected_name
| sort timestamp desc
| limit 200
```

### Excluding severities

```dql
fetch logs, from:now() - 1h
| filter status != "INFO" and status != "DEBUG"
| fields timestamp, status, content
| sort timestamp desc
| limit 100
```

---

## Content Search

### Substring search

```dql
fetch logs, from:now() - 1h
| filter contains(content, "NullPointerException")
| fields timestamp, status, content, dt.process_group.detected_name
| sort timestamp desc
| limit 50
```

### Full-text phrase search

```dql
fetch logs, from:now() - 1h
| filter matchesPhrase(content, "connection refused")
| fields timestamp, status, content, dt.process_group.detected_name
| sort timestamp desc
| limit 50
```

### Case-insensitive search

```dql
fetch logs, from:now() - 1h
| filter matchesPhrase(lower(content), "out of memory")
| fields timestamp, status, content
| sort timestamp desc
| limit 50
```

### Multiple keyword search (OR)

```dql
fetch logs, from:now() - 2h
| filter matchesPhrase(content, "timeout") or matchesPhrase(content, "connection refused") or matchesPhrase(content, "ECONNRESET")
| fields timestamp, status, content, dt.process_group.detected_name
| sort timestamp desc
| limit 100
```

---

## Entity-Based Filtering

### By process group name

```dql
fetch logs, from:now() - 1h
| filter dt.process_group.detected_name == "payment-service"
| filter status == "ERROR"
| fields timestamp, content, status
| sort timestamp desc
| limit 100
```

### By entity ID (from `find_entity_by_name`)

```dql
fetch logs, from:now() - 1h
| filter dt.source_entity == "PROCESS_GROUP_INSTANCE-0000000000000001"
| fields timestamp, status, content
| sort timestamp desc
| limit 100
```

### Across multiple services

```dql
fetch logs, from:now() - 1h
| filter in(dt.process_group.detected_name, {"payment-service", "order-service", "cart-service"})
| filter status == "ERROR"
| fields timestamp, dt.process_group.detected_name, content, status
| sort timestamp desc
| limit 200
```

---

## Time Range Patterns

### Last N minutes/hours/days

```dql
fetch logs, from:now() - 30m  -- last 30 minutes
fetch logs, from:now() - 6h   -- last 6 hours
fetch logs, from:now() - 24h  -- last 24 hours
fetch logs, from:now() - 7d   -- last 7 days
```

### Absolute time range

```dql
fetch logs, from:2026-05-05T08:00:00Z, to:2026-05-05T09:00:00Z
| filter status == "ERROR"
| fields timestamp, content
| sort timestamp desc
```

### Around a known incident time

```dql
fetch logs, from:now() - 2h, to:now() - 1h
| filter in(status, {"ERROR", "FATAL"})
| fields timestamp, status, content, dt.process_group.detected_name
| sort timestamp asc
```

---

## Combined Filters

Find errors from a specific service containing a keyword:

```dql
fetch logs, from:now() - 2h
| filter status == "ERROR"
| filter dt.process_group.detected_name == "checkout-service"
| filter contains(content, "database")
| fields timestamp, content
| sort timestamp desc
| limit 50
```

---

## Field Selection & Formatting

### Rename fields for readability

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| fields
    time = timestamp,
    severity = status,
    message = content,
    service = dt.process_group.detected_name
| sort time desc
| limit 100
```

### Add computed fields

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| fieldsAdd
    is_critical = if(contains(content, "FATAL") or contains(content, "OOM"), true, else: false),
    service = dt.process_group.detected_name
| fields timestamp, is_critical, service, content
| sort timestamp desc
| limit 100
```

---

## Best Practices

- **Filter before aggregating** — apply `status` and `dt.process_group` filters as early as possible
- **Use `contains()` for speed** — reserve `matchesPhrase()` for exact phrase matching on large datasets
- **Always set `from:`** — unbounded log queries will exceed the Grail scan budget
- **Use `limit`** — cap results with `| limit 100` unless aggregating
- **Sort meaningfully** — `sort timestamp desc` for recent logs, `sort timestamp asc` for event sequence analysis

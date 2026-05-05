# Structured Log Parsing Reference

Parse and extract fields from structured (JSON, key-value, and custom format) log messages in Dynatrace DQL.

---

## JSON Log Parsing

### Basic JSON parse

Many applications emit JSON-formatted log lines. Use `parse` with the `JSON` matcher to extract a record field, then access nested values with bracket notation:

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| parse content, "JSON:log"
| fieldsAdd
    level   = log[level],
    message = log[msg],
    error   = log[error]
| fields timestamp, level, message, error
| sort timestamp desc
| limit 50
```

**Notes:**
- `parse content, "JSON:log"` creates a record field named `log`
- Access nested keys with `log[key]` syntax
- Only parses lines where `content` is valid JSON — non-JSON lines produce `null` for the record field

### Pre-filter before parsing

Filter content with `contains()` before `parse` to reduce parsing overhead on large datasets:

```dql
fetch logs, from:now() - 2h
| filter status == "ERROR"
| filter contains(content, "\"error\"")
| parse content, "JSON:log"
| fieldsAdd message = log[msg], error_detail = log[error]
| fields timestamp, message, error_detail
| sort timestamp desc
| limit 50
```

### Aggregate by a parsed JSON field

```dql
fetch logs, from:now() - 4h
| filter status == "ERROR"
| parse content, "JSON:log"
| fieldsAdd message = log[msg]
| summarize error_count = count(), by: {message}
| sort error_count desc
| limit 20
```

### Extract nested JSON field

```dql
fetch logs, from:now() - 1h
| parse content, "JSON:log"
| fieldsAdd
    request_id = log[request][id],
    user_id    = log[user][id],
    status_code = log[http][status_code]
| filter isNotNull(status_code) and toInteger(status_code) >= 500
| fields timestamp, request_id, user_id, status_code, content
| sort timestamp desc
```

---

## Key-Value Log Parsing

### Extract key=value pairs

```dql
fetch logs, from:now() - 1h
| filter contains(content, "requestId=")
| parse content, "LD 'requestId=' STRING:request_id ' '"
| fields timestamp, request_id, content
| sort timestamp desc
| limit 50
```

### Multiple key-value extractions

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| parse content, "LD 'level=' STRING:level ' ' 'msg=' LD:message ' ' 'error=' LD:err_detail EOL"
| fields timestamp, level, message, err_detail
| sort timestamp desc
| limit 50
```

---

## Common Log Formats

### HTTP access log parsing

Extract HTTP method, path, and status code from access-log style entries:

```dql
fetch logs, from:now() - 1h
| filter contains(content, "HTTP/")
| parse content, "LD '\"' STRING:method ' ' STRING:path ' ' STRING:http_version '\" ' INTEGER:status_code ' '"
| filter status_code >= 500
| summarize error_count = count(), by: {path, status_code}
| sort error_count desc
| limit 20
```

### Exception stack trace detection

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| filter contains(content, "at ") and contains(content, "Exception")
| parse content, "LD:exception_class 'Exception' LD:exception_message NEWLINE"
| fieldsAdd
    exception_type = if(isNotNull(exception_class), exception_class + "Exception", else: "UnknownException")
| summarize count = count(), by: {exception_type}
| sort count desc
```

### Duration / latency extraction

```dql
fetch logs, from:now() - 1h
| filter contains(content, "duration=")
| parse content, "LD 'duration=' INTEGER:duration_ms"
| filter duration_ms > 1000
| summarize
    avg_duration = avg(toDouble(duration_ms)),
    max_duration = max(toDouble(duration_ms)),
    slow_requests = count(),
    by: {service = dt.process_group.detected_name}
| sort avg_duration desc
```

---

## Handling Parse Failures

### Filter out unparsed rows

When not all logs match the parse pattern, filter out rows where the extracted field is null:

```dql
fetch logs, from:now() - 1h
| parse content, "JSON:log"
| filter isNotNull(log)
| fieldsAdd message = log[msg]
| fields timestamp, message
| sort timestamp desc
```

### Count parseable vs. unparseable

```dql
fetch logs, from:now() - 1h
| parse content, "JSON:log"
| fieldsAdd is_json = if(isNotNull(log), true, else: false)
| summarize count(), by: {is_json}
```

---

## Multi-Line Log Handling

Dynatrace OneAgent reassembles multi-line log entries (e.g. Java stack traces) automatically when log multiline detection is configured. Query them as normal `content` entries:

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| filter matchesPhrase(content, "StackOverflowError") or matchesPhrase(content, "NullPointerException")
| fields timestamp, content, dt.process_group.detected_name
| sort timestamp desc
| limit 20
```

---

## Best Practices

- **Pre-filter before `parse`** — use `contains()` checks before expensive parsing operations
- **Use `isNotNull()` guards** — parse produces null for non-matching lines; filter before accessing extracted fields
- **Prefer field extraction over raw `content`** — structured fields enable accurate aggregation and trend analysis
- **Test parse patterns on a small sample first** — use `| limit 10` to validate extraction before running aggregations
- **Handle type conversions** — use `toInteger()`, `toDouble()` on extracted string values before numeric comparisons

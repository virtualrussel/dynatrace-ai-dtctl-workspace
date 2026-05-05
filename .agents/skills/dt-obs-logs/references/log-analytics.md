# Log Analytics Reference

Aggregation, error rate calculation, pattern detection, and trend analysis for Dynatrace log data.

---

## Error Rate Analysis

### Error rate over time (time-series)

```dql
fetch logs, from:now() - 2h
| summarize
    total_logs = count(),
    error_logs = countIf(status == "ERROR"),
    by: {time_bucket = bin(timestamp, 5m)}
| fieldsAdd error_rate_pct = (toDouble(error_logs) * 100.0) / toDouble(total_logs)
| sort time_bucket asc
```

### Error rate by service

```dql
fetch logs, from:now() - 1h
| summarize
    total = count(),
    errors = countIf(status == "ERROR"),
    fatals = countIf(status == "FATAL"),
    warns = countIf(status == "WARN"),
    by: {service = dt.process_group.detected_name}
| fieldsAdd error_rate_pct = (toDouble(errors + fatals) * 100.0) / toDouble(total)
| filter total > 10
| sort error_rate_pct desc
```

### Error spike detection (compare buckets)

```dql
fetch logs, from:now() - 4h
| summarize
    errors = countIf(in(status, {"ERROR", "FATAL"})),
    by: {time_bucket = bin(timestamp, 10m), service = dt.process_group.detected_name}
| sort time_bucket desc
| limit 50
```

---

## Log Volume Analysis

### Log volume by severity

```dql
fetch logs, from:now() - 1h
| summarize count(), by: {status}
| sort `count()` desc
```

### Log volume by service

```dql
fetch logs, from:now() - 1h
| summarize log_count = count(), by: {service = dt.process_group.detected_name}
| sort log_count desc
| limit 20
```

### Log volume trend over time

```dql
fetch logs, from:now() - 24h
| summarize
    total = count(),
    errors = countIf(status == "ERROR"),
    by: {time_bucket = bin(timestamp, 1h)}
| sort time_bucket asc
```

---

## Top Error Messages

### Most frequent error messages

```dql
fetch logs, from:now() - 24h
| filter status == "ERROR"
| summarize error_count = count(), by: {content}
| sort error_count desc
| limit 20
```

### Top errors by service

```dql
fetch logs, from:now() - 24h
| filter status == "ERROR"
| summarize error_count = count(), by: {service = dt.process_group.detected_name, content}
| sort error_count desc
| limit 30
```

---

## Pattern Detection

### Exception, timeout, and OOM patterns

```dql
fetch logs, from:now() - 2h
| filter status == "ERROR"
| fieldsAdd
    has_exception  = if(matchesPhrase(content, "exception"), true, else: false),
    has_timeout    = if(matchesPhrase(content, "timeout"), true, else: false),
    has_oom        = if(matchesPhrase(content, "out of memory") or matchesPhrase(content, "OOM"), true, else: false),
    has_connection = if(matchesPhrase(content, "connection refused") or matchesPhrase(content, "ECONNRESET"), true, else: false)
| summarize
    total_errors     = count(),
    exceptions       = countIf(has_exception == true),
    timeouts         = countIf(has_timeout == true),
    oom_errors       = countIf(has_oom == true),
    connection_errors = countIf(has_connection == true),
    by: {service = dt.process_group.detected_name}
| sort total_errors desc
```

### Pattern frequency breakdown per service

```dql
fetch logs, from:now() - 1h
| filter in(status, {"ERROR", "FATAL"})
| fieldsAdd
    pattern = if(matchesPhrase(content, "timeout"), "timeout",
              else: if(matchesPhrase(content, "exception"), "exception",
              else: if(matchesPhrase(content, "connection"), "connection",
              else: if(matchesPhrase(content, "memory"), "memory",
              else: "other"))))
| summarize count = count(), by: {service = dt.process_group.detected_name, pattern}
| sort service asc, count desc
```

---

## Summarization & Grouping

### Count by severity and service

```dql
fetch logs, from:now() - 1h
| summarize count(), by: {status, service = dt.process_group.detected_name}
| sort `count()` desc
```

### Hourly breakdown of errors

```dql
fetch logs, from:now() - 24h
| filter status == "ERROR"
| summarize
    error_count = count(),
    by: {hour = bin(timestamp, 1h), service = dt.process_group.detected_name}
| sort hour desc, error_count desc
```

### Unique log-emitting services

```dql
fetch logs, from:now() - 1h
| summarize
    services = collectDistinct(dt.process_group.detected_name),
    service_count = countDistinct(dt.process_group.detected_name)
```

---

## Availability & Uptime Signals

### Detect service restarts (startup messages)

```dql
fetch logs, from:now() - 24h
| filter matchesPhrase(content, "started") or matchesPhrase(content, "initialized") or matchesPhrase(content, "listening on port")
| fields timestamp, content, dt.process_group.detected_name
| sort timestamp desc
| limit 50
```

### Detect crash signals

```dql
fetch logs, from:now() - 24h
| filter matchesPhrase(content, "killed") or matchesPhrase(content, "segfault") or matchesPhrase(content, "core dumped") or matchesPhrase(content, "OutOfMemoryError")
| fields timestamp, content, status, dt.process_group.detected_name
| sort timestamp desc
| limit 30
```

---

## Best Practices

- **Filter before `summarize`** — reduce data volume by applying severity and entity filters first
- **Use `toDouble()` for division** — prevents integer division truncation in rate calculations
- **Use `bin(timestamp, 5m)` for trends** — choose bucket size to match the time range (e.g. 5m for 2h, 1h for 24h)
- **Cap with `limit`** for top-N analysis to prevent runaway result sets
- **Always name computed columns** — `fieldsAdd error_rate = ...` makes results readable

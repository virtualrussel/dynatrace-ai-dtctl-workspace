# Log Correlation Reference

Correlate Dynatrace log data with traces, DAVIS problems, entities, and other telemetry signals for root cause analysis.

---

## Log-to-Problem Correlation

### Logs from entities affected by a specific problem

```dql
fetch logs, from:now() - 2h
| filter dt.source_entity in [
    fetch dt.davis.problems
    | filter display_id == "P-12345678"
    | fields smartscape.affected_entity.ids
]
| filter in(status, {"ERROR", "FATAL"})
| fields timestamp, dt.source_entity, status, content
| sort timestamp desc
| limit 100
```

### Logs from all currently active problems

```dql
fetch logs, from:now() - 1h
| filter dt.source_entity in [
    fetch dt.davis.problems, from:now() - 1h
    | filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
    | fields smartscape.affected_entity.ids
]
| filter in(status, {"ERROR", "FATAL", "WARN"})
| fields timestamp, dt.source_entity, status, content
| sort timestamp desc
| limit 200
```

### Errors correlated with problem timeframe

First identify the problem start/end, then query logs in that window:

```dql
fetch logs
| filter dt.source_entity in [
    fetch dt.davis.problems
    | filter display_id == "P-12345678"
    | fields smartscape.affected_entity.ids, event.start, event.end
]
| filter status == "ERROR"
| sort timestamp desc
| limit 100
```

---

## Log-to-Trace Correlation

### Find logs for a specific trace

When you have a `trace_id` (from a distributed trace), find corresponding logs:

```dql
fetch logs, from:now() - 1h
| filter trace_id == "abcdef1234567890abcdef1234567890"
| fields timestamp, status, content, span_id, dt.process_group.detected_name
| sort timestamp asc
```

### Find error logs alongside trace IDs for investigation

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| filter isNotNull(trace_id)
| fields timestamp, trace_id, span_id, content, dt.process_group.detected_name
| sort timestamp desc
| limit 50
```

### Correlate log error rate with trace latency (combined view)

Run separately and compare by time bucket:

**Logs (error rate):**
```dql
fetch logs, from:now() - 2h
| summarize
    total = count(),
    errors = countIf(status == "ERROR"),
    by: {time_bucket = bin(timestamp, 5m), service = dt.process_group.detected_name}
| fieldsAdd error_rate = (toDouble(errors) / toDouble(total)) * 100
| sort time_bucket asc
```

**Traces (p95 latency):**
```dql
fetch spans, from:now() - 2h
| filter isRootSpan
| summarize
    p95_ms = percentile(duration, 95) / 1000000,
    by: {time_bucket = bin(startTime, 5m), service = dt.service.name}
| sort time_bucket asc
```

---

## Log-to-Entity Correlation

### Map log entries to Smartscape entities

```dql
fetch logs, from:now() - 1h
| filter status == "ERROR"
| fields
    timestamp,
    status,
    content,
    entity_id  = dt.source_entity,
    process     = dt.process_group.detected_name,
    host        = dt.host.id
| sort timestamp desc
| limit 100
```

### Logs from a specific host

```dql
fetch logs, from:now() - 1h
| filter dt.host.id == "HOST-0000000000000001"
| filter in(status, {"ERROR", "FATAL"})
| fields timestamp, status, content, dt.process_group.detected_name
| sort timestamp desc
| limit 100
```

### Cross-service log correlation (by request ID)

When services share a `request_id` or `correlation_id` in their logs:

```dql
fetch logs, from:now() - 1h
| filter contains(content, "req-abc123")
| fields timestamp, dt.process_group.detected_name, status, content
| sort timestamp asc
```

Or using `parse` to extract the field:

```dql
fetch logs, from:now() - 1h
| parse content, "JSON:log"
| fieldsAdd request_id = log[requestId]
| filter request_id == "req-abc123"
| fields timestamp, request_id, dt.process_group.detected_name, status, content
| sort timestamp asc
```

---

## Log-to-Deployment Correlation

### Errors spiking after a deployment event

```dql
fetch logs, from:now() - 2h
| summarize
    errors = countIf(status == "ERROR"),
    by: {time_bucket = bin(timestamp, 5m), service = dt.process_group.detected_name}
| sort time_bucket asc
```

Compare the `errors` count before and after the known deployment time to spot regression.

### Startup errors after restart

```dql
fetch logs, from:now() - 30m
| filter dt.process_group.detected_name == "payment-service"
| filter in(status, {"ERROR", "FATAL", "WARN"})
| fields timestamp, status, content
| sort timestamp asc
| limit 50
```

---

## Kubernetes Log Correlation

### Logs from a specific pod

```dql
fetch logs, from:now() - 1h
| filter k8s.pod.name == "payment-service-6d4b9c7f8-xkj2p"
| filter status == "ERROR"
| fields timestamp, status, content, k8s.namespace.name, k8s.pod.name
| sort timestamp desc
| limit 100
```

### Logs from a namespace

```dql
fetch logs, from:now() - 1h
| filter k8s.namespace.name == "production"
| filter in(status, {"ERROR", "FATAL"})
| summarize error_count = count(), by: {k8s.pod.name, dt.process_group.detected_name}
| sort error_count desc
```

### Logs around a Kubernetes event (e.g. OOMKilled)

```dql
fetch logs, from:now() - 1h
| filter k8s.pod.name == "checkout-service-abc123"
| fields timestamp, status, content
| sort timestamp desc
| limit 100
```

---

## Best Practices

- **Use `dt.source_entity` for problem correlation** — this field is the canonical entity link used in Smartscape subqueries
- **Use `trace_id` for trace correlation** — only present when OneAgent distributed tracing is active
- **Align time windows** — when correlating logs with problems or traces, use matching `from:` / `to:` ranges
- **Use subqueries sparingly** — problem subqueries add latency; use them only when entity IDs aren't known
- **Sort ascending for event sequence** — use `sort timestamp asc` when reconstructing an incident timeline

## Related Skills

- **dt-obs-problems** — Query DAVIS problems and extract `smartscape.affected_entity.ids` for correlation
- **dt-obs-tracing** — Fetch spans and correlate `trace_id` across services
- **dt-obs-kubernetes** — K8s pod/namespace context for container log investigation

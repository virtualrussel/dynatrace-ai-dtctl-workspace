---
agent: agent
description: Respond to an active production incident. Retrieves all active Davis Problems, explains root cause in plain English, surfaces user impact and affected traces, prioritizes by business severity, and generates a shareable incident report.
---

> **DQL guardrail:** Before running any DQL, check it with `dtctl verify query '<dql>'` in the terminal (no scan cost), then run it through the Dynatrace MCP tools. If dtctl is unavailable or unauthenticated, say so and continue.

We have a production incident. Help me investigate:
1. Check all active Davis Problems in Dynatrace
2. For each critical problem:
   - Explain root cause in plain English
   - Show user/transaction impact
   - Get error logs and distributed traces
   - Suggest immediate mitigation steps
3. Prioritize by business impact
4. Generate incident report summary

Work through this systematically using Dynatrace.
Be thorough but concise - this is an active incident.

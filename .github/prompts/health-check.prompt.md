---
agent: agent
description: Check the health of a service in production.
---

> **DQL guardrail:** Before running any DQL, check it with `dtctl verify query '<dql>'` in the terminal (no scan cost), then run it through the Dynatrace MCP tools. If dtctl is unavailable or unauthenticated, say so and continue.

Check the health of my service in production.
Infer service-name from current workspace if not provided. Ask user to confirm if not sure.

Show me:
1. Current performance metrics (response time, errors, throughput)
2. Any active problems or alerts  
3. Recent deployments and their impact
4. Top 5 slowest endpoints
5. Any security vulnerabilities

Use Dynatrace to gather data. Summarize if everything looks normal or if I need to investigate specific issues.

# AI-Powered Observability Demo
## GitHub Copilot + Dynatrace MCP + Skills

**Duration:** 15 minutes  
**Audience:** Anyone — no Dynatrace, MCP, or AI experience required  
**Format:** Live demo with natural investigation flow

---

## The Story

> *"If something is wrong in production right now — how fast can we find it, understand it, and document it?"*

This demo answers that question using three things working together:

| What | Plain English |
|---|---|
| **GitHub Copilot** | An AI assistant that lives inside VS Code |
| **Dynatrace MCP** | A live connection between Copilot and your Dynatrace environment |
| **Skills** | Domain knowledge files that teach Copilot how Dynatrace works |

Together they turn natural language questions into accurate, live production insights — no query writing, no dashboard navigation, no manual correlation.

---

## Before You Start

Open VS Code with the `dynatrace-ai-workspace` folder and confirm Copilot Chat is visible on the right side of the screen.

**Quick smoke test** — type this in Copilot Chat:
```
Using the dynatrace-mcp server, list the top 5 services by request volume in the last hour
```

If you see a table of services with request counts — you're live. Proceed.

> ⚠️ If no results appear, reload VS Code (`Cmd+Shift+P` → `Developer: Reload Window`) and re-authenticate via browser when prompted.

---

## Step 1 — Health Check (2 min)

**What you say:**
> *"I'm going to run a single slash command to check the health of our frontend service. Watch what happens."*

**What you type in Copilot Chat:**
```
/health-check
```
When asked for a service name, type:
```
frontend
```

**What to point out when the result appears:**

- Copilot just called the live Dynatrace API and pulled response times, error rates, throughput, active problems, and recent deployments — from one command
- Point to the error rate: **"8.46% error rate — that's over 100,000 failed requests per hour"**
- Point to the P99 latency: **"P99 at 8.2 seconds versus P95 at 216ms — that gap is worth investigating"**

**For non-technical audience:**
> *"In plain English: roughly 1 in 12 requests to this service is failing right now. We found that in 30 seconds."*

---

## Step 2 — Investigate the Problem (3 min)

**What you say:**
> *"The health check flagged two concerns — let me now use a deeper investigation prompt that follows a structured workflow."*

**What you type in Copilot Chat:**
```
/troubleshoot-problem
```
When Copilot asks for context, type:
```
Investigate the high P99 latency on the frontend service. 
P99 is at 8.2 seconds against a P95 of 216ms. Use the dynatrace-mcp server.
```

**What to point out when the result appears:**

- **The correction:** Copilot found the 8.2s P99 was a measurement artifact — the real P99 from span data is 298ms. Point this out: *"The AI didn't just repeat what it was told — it challenged the data and found a more accurate answer using a more precise data source."*
- **The real finding:** The error rate is actually 8.46% — and almost all failures are HTTP 500 GET requests completing in ~85ms. Fast failures, not slow ones.
- **What that means:** *"Requests aren't timing out — they're being rejected. That's a fundamentally different problem and points to application logic, not infrastructure."*

---

## Step 3 — Classify the Errors (3 min)

**What you say:**
> *"Let me drill into what's actually causing those failures."*

**What you type in Copilot Chat:**
```
Drill into error classifications for the frontend service. 
What's causing the 8.46% error rate?
```

**What to point out when the result appears:**

- **11,196 HTTP 500 GET failures per hour** — systematic, not random
- **Zero error logs** — the service is throwing errors silently with no logging
- **No exception details** in the trace data

**For non-technical audience:**
> *"The service is failing 11,000 times per hour and your team has no visibility into why — because the application isn't logging anything when it fails. This is completely invisible without this kind of analysis."*

**For technical audience:**
> *"The skills we installed taught Copilot to look for trace IDs in error spans, check for exception fields, and cross-reference with logs. Without that domain knowledge, a generic AI would miss this entirely."*

---

## Step 4 — Trace Reconstruction (3 min)

**What you say:**
> *"Let me try to reconstruct what's happening inside one of those failing requests."*

**What you type in Copilot Chat:**
```
Query by trace ID to reconstruct a full error request flow 
for one of the HTTP 500 GET failures.
```

**What to point out when the result appears:**

- **Trace IDs are NULL** on all error spans — the service isn't capturing any context about why it's failing
- **No parent-child span relationships** — can't reconstruct the request flow
- **The finding:** *"This is an instrumentation gap. Dynatrace knows the 500s are happening — but the application isn't propagating trace context in error paths. These errors are completely uninvestigable without fixing that first."*

**For non-technical audience:**
> *"Think of it like a security camera that records that a break-in happened, but the footage of the actual break-in is blank. The alarm went off — but there's no evidence of how it happened."*

---

## Step 5 — Create the Notebook (2 min)

**What you say:**
> *"Let me close this investigation properly — I'll ask Copilot to document everything we found so it can be shared with the team immediately."*

**What you type in Copilot Chat:**
```
Create a Dynatrace notebook documenting this investigation — 
key findings, instrumentation gaps, and recommended remediation steps.
```

**What to point out when the result appears:**

- A live Dynatrace notebook has been created in production with a shareable URL
- It contains the full investigation, embedded DQL queries, and a remediation plan
- *"That link is shareable right now with your application team, DevOps team, and on-call engineers — no copy-pasting, no manual write-up."*

---

## The Closing Line

> *"In 15 minutes, starting from nothing, we found that 18,500 requests per hour are failing silently with no logging and broken trace instrumentation — a critical observability gap your team didn't know existed. We corrected a misleading metric using more precise data. And we produced a shareable investigation artifact already sitting in Dynatrace. The whole investigation that would normally take 45–90 minutes across multiple tools and team members took 15 minutes with a single AI assistant."*

---

## If They Ask Questions

| Question | Answer |
|---|---|
| *"How is this different from what we already have?"* | Traditional observability shows you data. This interprets it, corrects it when wrong, and tells you what to do next. |
| *"What if the AI gets it wrong?"* | Notice it corrected its own P99 finding mid-investigation. Every query is transparent — you can see exactly what was executed and verify it. |
| *"How long does setup take?"* | About 30–40 minutes. Skills install with a single command. MCP authenticates via your existing Dynatrace SSO. |
| *"Does it work with our tech stack?"* | Skills cover Java, .NET, Node.js, Python, PHP, Go, Kubernetes, AWS, and more — each with technology-specific metrics. |
| *"Can we customise the prompts?"* | Yes — the prompt files are plain markdown. Edit them to match your team's workflows, service names, or investigation patterns. |

---

## What Each Component Did in This Demo

| Component | Role in This Demo |
|---|---|
| `/health-check` prompt | Kicked off the investigation with a structured health snapshot |
| `/troubleshoot-problem` prompt | Ran a 7-step structured investigation, corrected the P99 finding |
| `dt-obs-services` skill | Provided correct RED metric names and query patterns |
| `dt-obs-tracing` skill | Taught Copilot to look for trace IDs and span relationships |
| `dt-obs-logs` skill | Taught Copilot correct log field names (`loglevel`, `content`) |
| `dt-obs-problems` skill | Provided correct DQL for Davis Problem queries |
| `dynatrace-mcp` server | Executed all queries against live production data |
| `dt-app-notebooks` skill | Enabled Copilot to create the investigation notebook |

---

## Concepts Explained Simply

**What is Dynatrace?**
A platform that monitors your applications and infrastructure — collecting metrics, logs, and traces from everything running in your environment, and using AI (called Davis) to automatically detect problems.

**What is MCP?**
Model Context Protocol — an open standard that lets AI assistants like Copilot connect directly to external tools and data sources. The Dynatrace MCP server exposes your Dynatrace environment as a live data source Copilot can query in real time.

**What are Skills?**
Markdown files containing domain-specific knowledge. They teach Copilot the correct syntax, field names, and patterns for a specific tool — in this case Dynatrace. Without them, Copilot guesses and gets things wrong. With them, it writes accurate queries on the first attempt.

**What are Prompts?**
Pre-built investigation workflows saved as slash commands. They combine skills with structured instructions — telling Copilot what to do, in what order, and in what tone. Think of them as runbooks that Copilot executes automatically.

**What is dtctl?**
A command-line tool for Dynatrace — similar to how `kubectl` works for Kubernetes. It lets you manage Dynatrace resources (workflows, dashboards, queries) directly from your terminal, and works alongside Copilot for investigations that need direct action rather than just analysis.

# Overview: Why This Repository Exists

This guide is for people who know Dynatrace basics but are new to practical LLM, agentic AI, GitHub Copilot, Claude Code, and VS Code workflows.

It focuses on operating concepts and workflow behavior, not full installation steps (those are in [docs/ELI5.md](./ELI5.md) and [README.md](../README.md)).

This repository is an onboarding and execution workspace for AI-assisted observability with Dynatrace.

It helps teams move from:
- Slow, manual incident triage
- Dashboard and query bottlenecks
- Expert-only operations knowledge

to:
- Faster incident understanding and action
- Consistent investigations run by anyone on the team
- Repeatable, automatable workflows across tools like Dynatrace and ServiceNow

## What Problem This Solves

Most organizations already have observability data, but they still lose time during incidents because:
- Teams are not always sure where to begin
- Query syntax and data model details are easy to get wrong
- Investigations vary person-to-person
- Critical context lives in experts' heads instead of reusable workflows

This workspace closes that gap by combining:
- Dynatrace live data access through MCP
- Agent Skills with Dynatrace-specific knowledge
- Prompt templates for repeatable workflows
- dtctl for terminal-level verification and automation

## Business Value

For leaders and stakeholders, the value is operational and financial:

1. Faster Mean Time to Resolution (MTTR)
Standardized workflows like `/incident-response` and `/troubleshoot-problem` reduce time spent figuring out where to start.

2. Lower dependency on individual experts
Knowledge is encoded into skills and prompts instead of being locked to a few people.

3. More consistent operational outcomes
Every run team member can follow the same investigation path, reducing variability and escalation churn.

4. Better use of existing Dynatrace investment
Teams get more value from telemetry already being collected, without requiring everyone to become a DQL expert.

## Value for Dynatrace Operators and Run Teams

For SREs, operations engineers, and on-call teams, this repository improves daily execution:

1. Faster daily health checks
- `/health-check` gives service-level status quickly.
- `/daily-standup` and `/daily-standup-notebook` produce shareable summaries across services.

2. Better incident triage under pressure
- `/incident-response` prioritizes active issues by impact.
- `/investigate-error` and `/troubleshoot-problem` provide a structured deep dive.

3. Better post-change confidence
- `/performance-regression` compares before/after behavior around deployments.

4. Terminal verification and automation with dtctl
- `dtctl doctor` validates connectivity and auth.
- `dtctl get notebooks` and `dtctl describe notebook "name"` verify generated artifacts.
- `dtctl query 'fetch dt.davis.problems | filter event.status == "ACTIVE" | limit 5'` runs direct checks.

## AIOps Outcomes and ServiceNow Assist

### Conceptual outcome

This workspace is not only for chat-based troubleshooting. It is a practical AIOps foundation:
- Detect and prioritize issues faster
- Enrich incidents with evidence and likely root cause
- Standardize response playbooks across teams
- Feed structured context into adjacent systems

### Example ServiceNow Assist workflow

ServiceNow Assist is ServiceNow's AI capability that can help enrich and route incidents using context from connected systems.

A common pattern:

1. Dynatrace detects a production problem.
2. A ServiceNow incident is created.
3. ServiceNow Assist (or a linked workflow) invokes this workspace's investigation path, such as `/troubleshoot-problem`.
4. AI gathers live evidence via `dynatrace-mcp` and applies relevant skills (for example `dt-obs-problems`, `dt-obs-services`, `dt-dql-essentials`).
5. Findings are returned as structured context in the incident: impacted service, likely cause, timeline signals, and recommended next actions.
6. Operators act from a pre-analyzed incident instead of starting from zero.

Result: faster handoffs, higher-quality incident records, and reduced cognitive load during outages.

## Agent Skills vs Prompt Templates

This is the most important concept for new users.

### Agent Skills: the knowledge layer

Agent Skills are domain knowledge files in `.agents/skills/` that teach AI how Dynatrace works.

Examples:
- `dt-dql-essentials`: DQL syntax rules and pitfalls
- `dt-obs-problems`: problem and RCA patterns
- `dt-obs-services`: service RED metrics and interpretation
- `dt-obs-logs`: log analysis patterns
- `dt-obs-kubernetes`: workload and cluster troubleshooting
- `dtctl`: CLI operations and validation patterns

Without skills, AI may guess wrong field names or query patterns. With skills, it applies known-safe Dynatrace conventions.

### Prompt templates: the workflow layer

Prompt templates in `.github/prompts/` are the operating procedures.

Examples:
- `/health-check`
- `/daily-standup`
- `/daily-standup-notebook`
- `/investigate-error`
- `/troubleshoot-problem`
- `/incident-response`
- `/performance-regression`

Prompts define what to do, in what order, and with what guardrails.

In practice, you type these prompt names directly in chat (for example, `/health-check`) to trigger the corresponding workflow.

In GitHub Copilot, use `/prompt-name`; in Claude Code, use `@prompt-name`.

### How they work together

- Prompt = workflow
- Skill = domain intelligence
- MCP = live data access
- dtctl = verification and automation layer

When you run `/troubleshoot-problem`, the AI executes a structured investigation path instead of an open-ended chat flow:

1. It starts from a concrete Dynatrace problem record, then identifies impacted entities and likely blast radius.
2. It loads relevant skills (especially `dt-obs-problems` and `dt-dql-essentials`) to apply the right Dynatrace fields, syntax, and guardrails.
3. It gathers supporting evidence in sequence, such as recent error signals, service behavior, and correlated telemetry around the problem window.
4. It returns a practical output: likely root cause candidates, impact summary, and prioritized next actions for operators.

This gives readers a clear mental model: the prompt provides the investigation sequence, and skills provide the domain correctness at each step.

## The Role of dtctl in This Repository

dtctl is the operational bridge between AI-generated outputs and command-line verification.

Use it to:
- Verify objects created by AI workflows (notebooks, workflows)
- Run direct DQL checks
- Script repeatable checks in pipelines or runbooks
- Keep environment targeting explicit with the `production` context used in this workspace

In practice, dtctl turns AI guidance into auditable operational execution.

## Recommended First Path for New Users

1. Complete setup in [README.md](../README.md).
2. Start with `/health-check` for one service.
3. Run `/daily-standup` for a team-level view.
4. Use `/troubleshoot-problem` when a concrete issue is identified.
5. Validate outputs with dtctl commands in your terminal.
6. Read [ARCHITECTURE.md](../ARCHITECTURE.md) for deeper design details.

## Summary

This repository is a practical operating model for AI-assisted observability:
- Business value through faster, more consistent incident response
- Run team value through structured, repeatable investigations
- AIOps value through integration patterns that can extend into ServiceNow Assist
- Technical reliability through the combination of prompts, skills, MCP, and dtctl

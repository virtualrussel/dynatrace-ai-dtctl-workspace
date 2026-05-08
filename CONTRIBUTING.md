# Contributing

## Updating Skills

Skills are sourced from upstream GitHub repositories and version-locked in `skills-lock.json`. To pull the latest versions:

```bash
# Update all skills from dynatrace/dynatrace-for-ai
npx skills add dynatrace/dynatrace-for-ai

# Update the dtctl skill
npx skills add dynatrace-oss/dtctl
```

After updating, commit the changes to `.agents/skills/`, `.claude/skills/`, and the updated hashes in `skills-lock.json` together.

## Adding a New Skill

Skills must follow the `dt-<domain>[-<usecase>]` naming convention and live in `.agents/skills/<skill-name>/`. Each skill requires:

- `SKILL.md` — the instruction file loaded by the AI assistant
- `references/` — optional subdirectory for detailed reference material

After adding a skill directory, add a symlink in `.claude/skills/` for Claude Code compatibility:

```bash
cd .claude/skills
ln -s ../../.agents/skills/<skill-name> <skill-name>
```

Then add the skill entry to `skills-lock.json` with its source repository and computed hash.

## Adding a New Prompt

Prompt files live in `.github/prompts/` and must use the `.prompt.md` extension. Follow the existing prompts as a template — each should include:

- A brief description of the workflow
- Any DQL syntax constraints relevant to that workflow
- A clear step-by-step investigation sequence

After adding a prompt, update the prompt tables in `README.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `docs/CHEATSHEET.md`, and `ARCHITECTURE.md`.

## Syncing MCP Configuration

`.vscode/mcp.json` is the source of truth. After any changes to it, regenerate `.mcp.json`:

```bash
jq '{"mcpServers": .servers}' .vscode/mcp.json > .mcp.json
```

Never edit `.mcp.json` directly.

## Workspace Structure

```
.agents/skills/     # Skill source files (edit here)
.claude/skills/     # Symlinks to .agents/skills/ for Claude Code
.github/prompts/    # Investigation workflow templates
.github/            # copilot-instructions.md (Copilot session briefing)
.vscode/            # mcp.json (primary), extensions.json, settings.json
docs/               # ELI5.md, OVERVIEW.md, CHEATSHEET.md
CLAUDE.md           # Claude Code session briefing
skills-lock.json    # Locked skill versions with hashes
```

# Contributing to the Dynatrace AI Workspace

This document explains how to update skills, prompts, and MCP configuration in this workspace.

---

## Updating Skills

Skills are domain knowledge files sourced from [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) and [dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl).

To update skills, copy the latest files from the upstream repos into `.agents/skills/` and commit:

```bash
git add .agents/skills/
git commit -m "Update skills to latest"
git push
```

Skills are managed via git — the committed files are the authoritative version.

### Skill Content Is Upstream-Owned

Files under `.agents/skills/` (excluding `dtctl/`, sourced separately — see below) are maintained upstream in `dynatrace-for-ai` and are expected to be **overwritten wholesale** on every sync, matching that repo's own read-only policy for its `skills/` directory. Do not hand-edit these files expecting the change to survive — the next sync will silently discard it, exactly as happened historically with several files (`dt-obs-aws`, `dt-obs-hosts`, `dt-app-dashboards`, `dt-migration`, `dt-obs-problems`) that fell multiple releases behind because partial syncs missed them.

**Known local override:** `dt-obs-aws/SKILL.md` contains a paragraph under "Check health alerts when:" that uses `dtctl` to query the `builtin:health-experience.cloud-alert` settings schema. This content does not exist upstream — it's a deliberate addition tying the AWS skill to dtctl. **Every sync of `dt-obs-aws/SKILL.md` must manually re-apply this paragraph** after copying the upstream file; check `git diff` against the previous version before committing to confirm it's still present.

If you introduce a new local override to an otherwise upstream-owned skill file, list it here so the next sync doesn't lose it.

---

## Syncing dtctl after Upgrades

**Important:** When you upgrade dtctl, the dtctl skill must be updated to match.

### Why This Matters

The dtctl skill is versioned alongside the dtctl binary. If your binary is newer than the skill, the skill may reference flags or resource types that don't exist yet, and vice versa. Always sync after upgrading.

### When to Sync

After upgrading dtctl:

```bash
dtctl version
```

If the version is different from what you last synced, run:

```bash
git add .agents/skills/dtctl/
git commit -m "Sync dtctl skill after dtctl upgrade to v$(dtctl version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
git push
```

### What the Skill Documents

The skill covers all current dtctl capabilities including:

- **Structured workflow input:** `--input` flag with JSON payloads (preferred over `--params`)
- **AWS provider support:** Feature parity with Azure/GCP for cloud integrations
- **Auth status check:** `dtctl auth status` works for all token types (replaces `auth whoami` which fails with non-OAuth tokens)
- **DQL Smartscape:** `smartscapeNodes` patterns for entity queries

Make sure examples in the skill match the installed version.

---

## Updating MCP Configuration

MCP configuration uses templates: `.vscode/mcp.json.template` (source) and `.mcp.json.template` (source), which `setup.sh` generates into `.vscode/mcp.json` and `.mcp.json`. The generated files are `.gitignore`'d and contain user credentials — never commit them.

When updating the MCP server structure (e.g., changing the gateway URL path, adding a new server, changing header names):

1. Edit `.vscode/mcp.json.template`
2. Regenerate `.mcp.json.template` via jq:
   ```bash
   jq '{"mcpServers": .servers}' .vscode/mcp.json.template > .mcp.json.template
   ```
3. Commit both templates:
   ```bash
   git add .vscode/mcp.json.template .mcp.json.template
   git commit -m "Update MCP configuration templates"
   ```

**Do not commit the generated `.vscode/mcp.json` or `.mcp.json` files.** They are git-ignored because they contain real tenant URLs and Platform Tokens. Users regenerate them by running `setup.sh`.

To verify your changes work before committing, test locally:
1. Re-run `setup.sh` to regenerate the live config from your modified templates
2. Test the MCP connection in VS Code or Claude Code CLI
3. Verify `git status` shows only the `.template` files as changed (the generated files should not appear)

---

## Updating Prompts

Prompts are located in `.github/prompts/` (source) and symlinked in `.claude/commands/` for Claude Code CLI compatibility.

When adding or modifying a prompt:

1. Edit the markdown file in `.github/prompts/`
2. Test locally:
   - In VS Code with GitHub Copilot: `/your-command`
   - In Claude Code CLI: `claude` then `/your-command`
3. Verify it loads and executes correctly
4. Commit:
   ```bash
   git add .github/prompts/ .claude/commands/
   git commit -m "Add or update prompt: your-command"
   ```

### Prompt Best Practices

- **Always start with problems.** Never encourage broad log searches without problem context.
- **Document version requirements.** If a prompt uses dtctl features from v0.30.0+, add a note at the top.
- **Test with real data.** Run the prompt against your test environment before committing.

---

## Updating Documentation

Session briefing files are auto-loaded by the AI assistants and should be kept synchronized.

### Files to Update Together

When making changes that affect multiple docs:

| File | Loaded By | When to Update |
| --- | --- | --- |
| `ARCHITECTURE.md` | Developers, contributors | Architecture changes, new components |
| `CLAUDE.md` | Claude Code (CLI and VS Code plugin) | Session defaults, tool priority, new prompts |
| `.github/copilot-instructions.md` | GitHub Copilot | Session defaults, tool priority, new prompts |
| `README.md` | Setup flow, new users | Prerequisites, installation, quick start |
| `docs/ELI5.md` | Newcomers | High-level "explain like I'm 5" intro |
| `docs/CHEATSHEET.md` | Active users | Workflow reference, command quick lookup |

Example: If you add a new prompt, update:
1. The prompt file in `.github/prompts/`
2. Symlink it in `.claude/commands/`
3. Add to the "Prompts" table in both `CLAUDE.md` and `.github/copilot-instructions.md`
4. Add to `docs/CHEATSHEET.md` under the appropriate workflow section

---

## Testing Changes Before Commit

1. **Skills:** Run a health-check prompt to verify skills load
   ```bash
   claude
   /health-check
   ```

2. **Prompts:** Test in both Claude Code and GitHub Copilot (if available)
   ```bash
   claude
   /your-new-command
   ```

3. **dtctl:** After upgrading, verify version and re-sync skill
   ```bash
   dtctl version
   dtctl get workflows  # Verify CLI works
   ```

4. **Documentation:** Open `ARCHITECTURE.md`, `CLAUDE.md`, and `README.md` in your editor and verify all links work and content is accurate

---

## Git Workflow

1. Create a branch:
   ```bash
   git checkout -b feat/description-of-change
   ```

2. Make changes in `.agents/skills/`, `.github/prompts/`, docs, etc.

3. Test locally (see "Testing Changes Before Commit" above)

4. Commit with clear messages:
   ```bash
   git add .agents/skills/
   git commit -m "Update skills to v$(date +%Y-%m-%d)"
   
   git add CLAUDE.md .github/copilot-instructions.md
   git commit -m "Add /new-prompt to session briefings"
   ```

5. Push and create a pull request:
   ```bash
   git push -u origin feat/description-of-change
   ```

---

## Questions?

For issues with skills, prompts, or MCP setup:

- **dtctl or MCP:** See [github.com/dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl) or [github.com/dynatrace-oss/dynatrace-mcp](https://github.com/dynatrace-oss/dynatrace-mcp)
- **Skills source:** See [github.com/Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai)
- **This workspace:** Open an issue in [github.com/virtualrussel/dynatrace-ai-dtctl-workspace](https://github.com/virtualrussel/dynatrace-ai-dtctl-workspace)

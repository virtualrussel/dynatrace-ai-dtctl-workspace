# Contributing to the Dynatrace AI Workspace

This document explains how to update pinned skills and prompts, registered overlays, documentation, and MCP templates in this workspace.

---

## Updating Upstream Content

Skills are domain knowledge files sourced from [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) and [dynatrace-oss/dtctl](https://github.com/dynatrace-oss/dtctl).

`upstream-sources.lock.json` is the source of truth for repository URLs, immutable commit SHAs, source/destination mappings, inventories, content hashes, and registered patches. Never copy individual files into an imported tree.

Verify the current checkout offline:

```bash
bash scripts/sync-upstream.sh verify
```

Restore every import from its locked revision:

```bash
bash scripts/sync-upstream.sh sync
```

To update an upstream source:

1. Resolve and review the new upstream revision, then place its full 40-character commit SHA in `upstream-sources.lock.json`. Never pin a branch or moving tag.
2. Update source/destination mappings when upstream renamed a file. Update an existing file under `upstream-patches/` only when its documented local behavior is still required and applies cleanly to the new revision.
3. Run `bash scripts/sync-upstream.sh sync --refresh-lock`. The command fetches into a temporary directory, applies registered patches, refreshes inventory and hashes, rebuilds Claude compatibility links, and verifies the result before replacing tracked imports. A failed install restores the prior trees and lock.
4. Review the complete diff, especially added/removed files and patch changes. Run `bash scripts/sync-upstream.sh verify` again before staging.

### Skill Content Is Upstream-Owned

Files under `.agents/skills/` are synchronized as complete imported roots. The `dynatrace-for-ai` skill tree is exact upstream content, unless a registered patch overrides it (see below). The separately sourced `dtctl` skill may contain only the overlay declared in the lock and stored under `upstream-patches/`. Unregistered edits fail verification and must not be committed.

### Registered Local Patches

`dynatrace-for-ai-skills` defaults to `"policy": "exact"` with no patch. When a local fix is needed on top of a pinned upstream commit, switch it to `"policy": "patched"` and add a `"patch"` field pointing at a file under `upstream-patches/`; the sync script applies it to the fetched tree (via `patch -p1 --forward`) before the aggregate hash is computed, exactly like the `dtctl-skill` overlay. This is the only sanctioned way to carry a local fix on top of upstream content — hand-editing a file under `.agents/skills/` without a registered patch will fail `sync-upstream.sh verify` and be silently overwritten (and `sync` with no `--refresh-lock` will fail its integrity check) on the next sync.

Currently registered: `upstream-patches/dt-obs-frontends-csp-link-fix.patch` fixes a broken relative link in `dt-obs-frontends/references/error-tracking.md` (upstream links to `references/csp-violations.md` from inside `references/`, which resolves to a nonexistent nested path — confirmed present as of upstream commit `29ad20b`, filed as a low-severity doc bug). Remove this patch and drop the `patch` field once the fix lands upstream, then re-run `sync-upstream.sh sync --refresh-lock`.

To register a new patch:

1. Make the desired local edit against a copy of the pristine fetched content, then generate a unified diff rooted at the skill's path relative to `.agents/skills/` (e.g. `diff -ruN a/<skill>/<file> b/<skill>/<file>`), matching the format already used by `upstream-patches/dtctl-v0.38.0.patch`.
2. Save it under `upstream-patches/` and set the `patch` field on the `dynatrace-for-ai-skills` import in `upstream-sources.lock.json`.
3. Run `bash scripts/sync-upstream.sh sync --refresh-lock` to apply it and recompute the hash, then `bash scripts/sync-upstream.sh sync` (no flag) to confirm the restore path still succeeds.

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

If the version differs from the locked dtctl source, update the `dtctl-skill` commit and overlay through the lock-refresh procedure above. Do not copy the skill manually.

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

**Do not substitute tenant hostnames into tracked documentation or templates during setup.** Product docs and source templates must remain tenant-neutral; tenant-specific MCP state belongs only in the two generated, ignored config files.

To verify your changes work before committing, test locally:
1. Re-run `setup.sh` to regenerate the live config from your modified templates
2. Test the MCP connection in VS Code or Claude Code CLI
3. Verify `git status` shows only the `.template` files as changed (the generated files should not appear)

---

## Updating Prompts

Prompts are exact mapped imports in `.github/prompts/` and symlinked in `.claude/commands/` for Claude Code compatibility. Do not edit prompt bytes locally. Cross-client runtime requirements belong in `docs/PROMPT_CONTRACTS.md` and are checked one-to-one against the locked prompt inventory.

When upstream adds, removes, renames, or modifies a prompt:

1. Update the prompt commit and source/destination mappings in `upstream-sources.lock.json`.
2. Update `docs/PROMPT_CONTRACTS.md` so every mapped prompt has exactly one complete contract.
3. Run `bash scripts/sync-upstream.sh sync --refresh-lock` and review prompt and symlink changes.
4. Test locally:
   - In VS Code with GitHub Copilot: `/your-command`
   - In Claude Code CLI: `claude` then `/your-command`

### Prompt Best Practices

- **Start incident workflows with problems.** Never encourage log or span searches without an entity and bounded timeframe; bounded metric and inventory workflows do not require a problem.
- **Keep prompt bytes upstream-owned.** Put portable capability requirements in `docs/PROMPT_CONTRACTS.md`, not client-specific prompt frontmatter.
- **Name the real lifecycle tool.** Artifact prompts must route notebook, dashboard, workflow, and settings mutations through dtctl rather than imply unsupported MCP capabilities.
- **Keep resource types distinct.** Never substitute a notebook, dashboard, workflow, or settings object for another resource type to fit an available tool.
- **Document version requirements.** If a prompt uses dtctl features from v0.30.0+, add a note at the top.
- **Test with real data.** Run the prompt against your test environment before committing.

---

## Updating Documentation

Each document has one primary responsibility. Link to the owner instead of copying detailed procedures or scope lists into multiple files.

| File | Owns |
| --- | --- |
| `README.md` | User setup, quick start, and the user-facing skill/prompt catalog |
| `docs/CHEATSHEET.md` | Operational workflow routing and concise guardrails |
| `ARCHITECTURE.md` | Component boundaries, data flow, and resource ownership |
| `docs/PERMISSIONS.md` | MCP authorization profiles, layers, and troubleshooting |
| `docs/PROMPT_CONTRACTS.md` | Portable per-prompt runtime requirements and degradation behavior |
| `upstream-sources.lock.json` and `scripts/sync-upstream.sh` | Source provenance, inventory, hashes, overlays, and synchronization |
| `CLAUDE.md` and `.github/copilot-instructions.md` | Startup-critical client routing only |

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

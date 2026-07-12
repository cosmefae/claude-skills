---
name: sync-references
description: Audits, relinks, and synchronizes documentation references in a project — detecting broken links, stale paths, orphan files, llms.txt inconsistencies, skills-directory desync (skills folder vs README/SKILLS.md/llms.txt), READMEs, AGENTS.md, SKILL.md, HANDOFF.md, and CHANGELOG.md. Generates updated indexes and validates YAML frontmatter. Use when the user mentions "broken links", "relink docs", "update refs", "sync llms.txt", "index files", "document references", "tag files", "orphan files", "audit documentation", "validate llms.txt", or "sync skills".
allowed-tools: Read, Grep, Glob, Write, Bash
Provenance: adapted from a private workspace skill — [cosmefae](https://hellofae.com)
---

# sync-references

Audits and synchronizes a project's documentation reference graph. Operates on Markdown files and LLM context files.

## Target artifacts

| File | Role |
|---------|-------|
| `README.md` | Project root index |
| `llms.txt` | Structured LLM context (spec: [llms-spec.md](llms-spec.md)) |
| `AGENTS.md` | Instructions for AI agents |
| `SKILL.md` | Skill definition |
| `HANDOFF.md` | Task handoff |
| `CHANGELOG.md` | Change history |
| `docs/**/*.md` | Internal documentation |

## Configuration

This skill defaults to scanning a project's `skills/` directory (auto-detected: tries `.claude/skills/`, then `.cursor/skills/`, then `skills/` at the project root, in that order — first one found wins). If your project uses a different convention, pass it explicitly: "sync references, skills are in `packages/*/skills/`".

## Workflow

### 1. Audit

Run the audit script against the project directory:

```bash
zsh <skill-dir>/scripts/audit-refs.sh <project-root>
```

Where `<skill-dir>` is wherever this skill is installed (e.g. `.claude/skills/sync-references`, `~/.claude/skills/sync-references`, or a project-local path) — resolve it relative to how the skill was invoked, don't assume a fixed location.

The script returns:
- **broken-links**: Markdown links with a non-existent target
- **orphan-files**: `.md` files with no inbound reference
- **missing-from-llms**: files present on disk but absent from `llms.txt`
- **stale-llms**: paths in `llms.txt` that don't exist on disk
- **skill-sync**: each skill folder (containing a `SKILL.md`) must appear in `llms.txt` (link containing the skill's `SKILL.md` path), in `README.md` (skill name in backticks in the table), and in `SKILLS.md` (link with the same relative path)
- **missing-frontmatter**: files in `docs/` without a YAML block (`---`) when expected

### 2. Relink

For each reported `broken-link`:
1. Locate the referenced file using `Glob` with name variations
2. Compute the correct relative path from the source file
3. Apply the fix with `Edit`
4. Log it in the final report

For `stale-refs` in `@path` mentions:
- Search for the file with `Glob` by base name
- Replace the stale path

### 3. Index

**README.md**: ensure every folder under `docs/` and every active subproject has an entry in the index with a link and a one-line description.

**Skills directory**: when adding or renaming a skill, update in the same pass **`SKILLS.md`** (table and contracts), **`README.md`** ("Available skills" table), and **`llms.txt`** (skills section). Run the audit script to validate `SKILL-SYNC-*`.

**llms.txt**: follow the spec in [llms-spec.md](llms-spec.md):
- `# Title` (single h1)
- `> description` (blockquote)
- `## Section` (h2 per category)
- `- [Name](path): description` (one line per artifact)
- Remove entries for files that no longer exist
- Add entries for new unindexed files

### 4. Tagging (YAML frontmatter)

For files in `docs/` without frontmatter, inject a minimal block:

```yaml
---
title: <infer from the file's h1>
tags: [<folder-category>]
updated: <YYYY-MM-DD>
---
```

Don't overwrite existing frontmatter — only add missing fields.

### 5. CHANGELOG

When changes are applied, append an entry to `CHANGELOG.md`:

```markdown
## [sync-references] YYYY-MM-DD

### Fixed
- `path/to/file.md`: broken link `old-ref` → `correct-ref`

### Added
- `llms.txt`: entry added for `docs/new-file.md`

### Tagged
- `docs/file.md`: frontmatter injected
```

## Output

Always deliver at the end:

```markdown
## sync-references Report — <date>

**Project**: <root>
**Files audited**: N
**Issues found**: N

### Broken links fixed (N)
- `file.md:12` — `../old/path` → `../correct/path`

### Orphan files (N)
- `docs/unreferenced-file.md` — suggestion: add to README.md#section

### llms.txt — synchronized (N additions, N removals)
- ➕ `docs/new.md`
- ➖ `docs/deleted.md` (file no longer exists)

### Skill sync (N)
- `skill-name` missing from `llms.txt` / `README.md` / `SKILLS.md` — suggested fix: …

### Frontmatter injected (N)
- `docs/file.md`

### No action needed
- (list of files that are ok)
```

## Report-only mode

If the user asks for an audit only, without applying fixes, generate the report above but **do not modify any file**. Flag each issue with the suggested fix for manual application.

## Automation (Git Hooks)

For automatic synchronization when `.md` files are renamed/moved, install the git hooks:

### Installation

From your project's git root:

```bash
zsh <skill-dir>/hooks/install.sh
```

The installer will:
1. Copy 3 hooks to `.git/hooks/` (post-commit, post-merge, post-rewrite)
2. Configure the default mode (`silent`)
3. Validate the installation

### Operating modes

Configure via `git config` (local to the repository):

```bash
# Silent mode (default): only logs to .git/sync-refs.log
git config sync-refs.mode silent

# Report mode: shows the report in the terminal after commits
git config sync-refs.mode report

# Fix mode: auto-fixes references (not implemented yet)
git config sync-refs.mode fix
```

### View the execution log

```bash
tail -f .git/sync-refs.log
```

### Installed hooks

| Hook | When it runs | Behavior |
|------|-------------|---------------|
| `post-commit` | After each commit | Detects changed `.md` files → runs sync |
| `post-merge` | After pulls/merges | Always runs sync (--force) |
| `post-rewrite` | After rebases | Runs sync on rebases |

### Uninstall

Remove the hooks manually:

```bash
rm .git/hooks/post-commit
rm .git/hooks/post-merge
rm .git/hooks/post-rewrite
git config --unset sync-refs.mode
```

## Additional resources

- Full `llms.txt` spec: [llms-spec.md](llms-spec.md)
- Audit script: [scripts/audit-refs.sh](scripts/audit-refs.sh)

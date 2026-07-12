---
name: standardize-md-skills
description: "Audits and standardizes SKILL.md and project MD files following Anthropic's best practices for docs readable by both AI and humans. Always asks which directory to run in — never runs broadly across the machine. Use when the user mentions 'standardize docs', 'audit skills', 'review MDs', 'Anthropic convention', 'standardize project', 'review project documentation', 'standardize skills', or 'check MD consistency'."
version: "1.0"
language: en
allowed-tools: [Read, Write, Glob, Grep, Bash]
tags: [docs, standardization, anthropic, skills, markdown, audit]
Provenance: adapted from a private workspace skill — [cosmefae](https://hellofae.com)
---

# Skill: standardize-md-skills

Audits and standardizes SKILL.md and project MD files following Anthropic's best practices for readability by any LLM.

## When to use

Trigger this skill when:
- "standardize docs for project X"
- "audit the project's skills"
- "review MDs in the repo"
- "check consistency of MD files"
- "apply Anthropic convention to documentation"
- "review project documentation"

### When NOT to use

- Reviewing UI copy → use a copy-review skill
- Generating code → use an implementation skill
- Committing changes → use `commit-guided`

## Safety rules

> **NEVER run this skill without an explicit target directory provided by the user.**

Before any action, verify:

1. Did the user provide a full absolute path? (e.g. `/Users/name/git/project`)
2. Is the path NOT `/`, `~/`, `~`, or any generic system root?
3. Does the path point to a specific project/repository?

If any check fails: **stop, ask for the correct directory, and don't proceed.**

Directories **always ignored**, even if inside the target:
- `node_modules/`
- `.git/`
- `legacy/` (historical documentation folder — never modify)
- `dist/`, `build/`, `.next/`

## Reference files

This skill doesn't depend on external files — the standards are defined in the sections below.

## How to execute

### Step 1 — Confirm target directory

If the target directory **wasn't explicitly provided** by the user, ask:

> "Which project directory do you want to audit? Provide the full absolute path (e.g. `/Users/name/git/my-project`). This skill never runs broadly across the machine."

Wait for the answer. Don't proceed without it.

Validate the received path:
- Reject if it's `/`, `~`, `~/`, or a path with fewer than 3 segments
- Confirm with the user: "I'll audit only the files under `<path>`. Confirm?"

### Step 2 — Map files

With the directory confirmed, list all MD files in scope:

```bash
# SKILL.md inside the project's skills directory
find <path> -path "*/node_modules" -prune -o -path "*/.git" -prune -o \
  -path "*/legacy" -prune -o -name "SKILL.md" -print

# All other .md files
find <path> -path "*/node_modules" -prune -o -path "*/.git" -prune -o \
  -path "*/legacy" -prune -o -name "*.md" -not -name "SKILL.md" -print
```

Present the list before continuing.

### Step 3 — Audit each file

For each file found, apply the correct checklist:

**If it's a SKILL.md → Standard A:**

| Check | Criterion |
|---|---|
| YAML frontmatter | Opens with `---` containing `name`, `description`, `version`, `language`, `allowed-tools`, `tags` |
| `## When to use` section | Present, with trigger-phrase bullets |
| `### When NOT to use` subsection | Present inside `## When to use` |
| `## Reference files` section | Present (can be empty with a justification) |
| `## How to execute` section | Present, with numbered `### Step N —` |
| `## Expected output` section | Present, with description or template |
| `## Notes` section | Present (optional but recommended) |
| No inline `## Metadata` | No metadata table should exist — replace with YAML frontmatter |
| Size | Under 500 lines |

**If it's a general MD → Standard B:**

| Check | Criterion |
|---|---|
| Single H1 | Exactly one `# Title` in the file |
| Meta-line below the H1 | `> **Version:** x.x \| **Updated:** YYYY-MM-DD \| **Tags:** #tag \| **Status:** ✅ Stable` |
| Header hierarchy | No skipped levels (H1→H2→H3, never H1→H3 directly) |
| Sentence case in titles | Only the first word capitalized (except proper nouns) |
| No emojis in headers | Emojis only in lists or body text, never in `#` titles |

### Step 4 — Generate the audit report

Present the report in this format before asking about fixes:

```
## MD Audit — <path>

### SKILL.md files found: N
| File | Frontmatter | Canonical sections | Inline metadata | Size | Status |
|---|---|---|---|---|---|
| skills/X/SKILL.md | ✅ | ✅ | ❌ has ## Metadata | 120 lines | ⚠️ fix |
| skills/Y/SKILL.md | ❌ no YAML | ⚠️ missing 2 sections | — | 85 lines | ❌ critical |

### General MD files found: N
| File | Single H1 | Meta-line | Hierarchy | Sentence case | Status |
|---|---|---|---|---|---|
| docs/guidelines/X.md | ✅ | ✅ | ✅ | ⚠️ 2 titles | ⚠️ fix |
| docs/README.md | ✅ | ❌ missing | ✅ | ✅ | ❌ critical |

### Summary
- ✅ Compliant: N files
- ⚠️ Minor fixes: N files
- ❌ Critical: N files
```

### Step 5 — Request authorization for fixes

Ask:

> "Do you want to apply the fixes?
> - **All files** with issues
> - **Select** which files to fix
> - **Report only** — don't modify anything now"

Wait for the answer. Don't modify any file without explicit authorization.

### Step 6 — Apply fixes (only with authorization)

For each authorized file, apply the necessary fixes:

**For SKILL.md without YAML frontmatter:**
- Add a `---` block at the top with the required fields
- Infer `name` from the directory name
- Infer `description` from the H1 + first paragraph
- Infer `allowed-tools` from the commands used in the body
- Set `version: "1.0"`, `language: en` (or the project's actual language if different)

**For SKILL.md with inline `## Metadata`:**
- Move the fields into YAML frontmatter
- Remove the `## Metadata` section

**For SKILL.md missing canonical sections:**
- Add missing sections with minimal structured content
- Preserve all original content — only reorganize

**For general MD without a meta-line:**
- Add `> **Version:** 1.0 | **Updated:** <current date> | **Tags:** #tag | **Status:** 🚧 In progress` right after the H1
- Adjust status based on the file's context

**For titles with emojis or Title Case:**
- Remove emojis from headers
- Convert to sentence case (only the first word capitalized, except proper nouns)

Confirm with the user after each modified file.

## Expected output

1. Tabular audit report with per-file status
2. List of issues found, grouped by category
3. (If authorized) fixed files with a changelog of applied changes

## Notes

- This skill never runs without an explicit target directory — this is an inviolable rule.
- It never traverses `/`, `~/`, or any system root path.
- The `legacy/` folder is always ignored — it documents a previous era and shouldn't be standardized.
- Preserve original content when fixing — this skill reorganizes and supplements, it doesn't rewrite.
- If the project uses a language other than English, detect it and adapt the `language` field and the `description` frontmatter accordingly.
- General-purpose skill — usable in any project, but always scope-limited by the user.

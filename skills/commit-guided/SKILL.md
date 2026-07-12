---
name: commit-guided
description: Universal guided git workflow to validate, commit, and open a PR. Generates a Conventional Commits message, checks branch, creates PR template. Includes admin override for emergencies.
version: "2.0"
language: en
allowed-tools: [Bash, AskUserQuestion]
tags: [git, workflow, pr, conventional-commits, admin-override]
Provenance: adapted from a private workspace skill — [cosmefae](https://hellofae.com)
---

# Skill: commit-guided

Universal guided git workflow to validate, commit, and open a PR.

## When to use

Use this skill when:
- "publish the changes"
- "commit and PR"
- "I want to push my changes"
- "how do I push changes?"
- After any edit that needs to be committed

## Prerequisites

- `git` installed and repository configured
- `gh` (GitHub CLI) installed to create PRs automatically
- Branch different from `main`/`master` (create a branch if you are not on one yet)

---

## How to run

### Step 1 — Check status

Execute and show the output:

```bash
git status
git diff --stat
```

If there are no changes, inform the user and end the skill.

### Step 2 — Check branch

```bash
git branch --show-current
```

If the result is `main` or `master`, sync and create a branch before continuing:

```bash
git checkout main
git pull origin main
git checkout -b feature/update
```

Suggest a branch name based on the domain being changed. Use the pattern `<scope>/<description>`:
- `feature/oauth-login`
- `docs/update-readme`
- `fix/api-timeout`
- `refactor/user-service`

Ask for confirmation of the name before creating it.

### Step 3 — Review the diff

Show the changes for the user to review:

```bash
git diff HEAD
```

Ask: "Are these the changes you want to publish?"

### Step 4 — Build the commit plan

Analyze the full diff and group files by semantic intent using Conventional Commits format:

```
<type>(<scope>): <short description>
```

#### Commit Grouping Rules

Classify each changed file into `(type, scope)` — one commit per unique pair:

| Type | When to use |
|---|---|
| `feat` | New behavior, new feature, new endpoint |
| `fix` | Bug fix, incorrect logic, broken behavior |
| `refactor` | Same behavior, cleaner code |
| `docs` | Markdown, handoff files, specs, comments |
| `chore` | Config, migrations, exports, lockfiles, gitignores, backups |
| `test` | Test files |
| `style` | Formatting, lint only |

**Hierarchy for grouping decisions:**
1. Same type + same project/scope → 1 commit (even multiple files)
2. Same type + different projects → separate commits
3. Different types, same project → separate commits
4. Global config files (AGENTS.md, CLAUDE.md, workspace-level) → `chore(workspace)`

**Rule of thumb:** Each commit must answer *"What changed and why?"* in one line. If the answer needs "and also" — it's 2 commits.

**Execution order:** `feat` → `fix` → `refactor` → `docs` → `chore`

Present the grouped plan to the user before executing:

```
Commit plan (N groups):

1. feat(api): add rate limiting middleware + fix retry backoff calc
   → middleware/rateLimit.ts, lib/retry.ts

2. fix(dashboard): use PORT env var + fix context dir path
   → server.js

3. chore(workspace): sync config files
   → AGENTS.md, .gitignore

Confirm? (or adjust grouping)
```

### Step 5 — Commit and push

For each approved group, stage only its files and commit:

```bash
# Repeat for each group:
git add <files in group>
git commit -m "<group message>"

# After all groups:
git push -u origin HEAD
```

Do not use `git add -A` — stage files per group to preserve semantic separation.

### Step 6 — Open Pull Request

```bash
gh pr create \
  --base main \
  --title "<same title as the commit>" \
  --body "$(cat <<'EOF'
## What changed

<describe changes based on the diff>

## Why

<reason for the change — ask the user if unknown>

## Checklist

- [ ] Changes reviewed in the diff before commit
- [ ] No sensitive or incorrect information included
EOF
)"
```

After creating the PR, show the URL for the user to review and share with the team.

---

## Common errors handling

| Error | What to do |
|---|---|
| Branch is `main` | Create a branch. Never commit directly to `main`. |
| `gh: command not found` | Instruct to install: `brew install gh && gh auth login` |
| Push rejected (upstream diverged) | Run `git pull --rebase` before pushing |

---

## Notes

- This skill does not force push or amend published commits
- PRs without another team member's approval should not be merged into `main`
- Universal skill — can be used in any repository

---

## Admin override

> **Attention: emergency use only (break-glass).**
> Pushing directly to `main`/`master` violates Git Flow even for admins. Always prefer the standard flow (branch → PR → review) — it protects history, is auditable, and keeps traceability.

This behavior can be overridden in specific projects through `.cursor/rules/` or `.claude/rules/` files.

Language: The default skill language is English. Projects may override language in their rules if needed. If no override is specified, use English.

**When override is active:**
- Steps 2 (branch creation) and 6 (PR creation) are **omitted**
- Push happens directly to `main`/`master`
- Validation steps remain mandatory
- The commit is unreviewed — risk of introducing errors without traceability

**Use only if:** the main branch is blocked by a critical failure that cannot be fixed via PR, or by explicit instruction from a senior maintainer with documented justification.

The standard flow (branch → PR → review) is the correct behavior for all contributors.

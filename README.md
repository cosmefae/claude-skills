# claude-skills

Curated Claude Code skills and agents, generalized from personal/workspace use.

All content in this repo is in English — it's meant to be usable by anyone, not tied to any single workspace or language.

Structure:
- `skills/` — one folder per skill, each with `SKILL.md`
- `agents/` — one folder or file per agent definition
- `.claude-plugin/marketplace.json` — plugin catalog
- `LICENSE` — MIT

Install: `/plugin marketplace add cosmefae/claude-skills`

## Provenance

Every `SKILL.md`/agent `.md` in this repo carries a `Provenance:` line in its frontmatter, one of:
- `original — [cosmefae](https://hellofae.com)` — built from scratch for this repo
- `adapted from a private workspace skill — [cosmefae](https://hellofae.com)` — generalized from a personal workspace skill (the case for everything currently in the repo)
- `adapted from [@handle](url), used with permission — <restriction>` — reserved for skills sourced from a named third-party author under explicit permission/restriction

## Skills

| Skill | Description |
|---|---|
| `screen-contract` | Turns a Figma frame, screenshot, or brief into a structural JSON contract before any code generation — prevents visual drift and invented tokens/components. |
| `write-handoff` | Writes a concise HANDOFF.md for the current task: state, file refs, verify commands, next steps. |
| `commit-guided` | Guided git workflow — validate, commit with Conventional Commits, open a PR. |
| `sync-references` | Audits and syncs documentation references (README, llms.txt, AGENTS.md, SKILL.md, CHANGELOG.md) — broken links, orphan files, skill-index drift. |
| `figma-shadcn-hygiene` | Figma-only structural hygiene pass: naming, taxonomy, auto layout, token gaps. Produces a Hygiene Report for handoff. |
| `figma-shadcn-visual-match` | Figma → shadcn → code with a visual fidelity gate: implements, screenshots both sides, classifies diffs, iterates to approval. |
| `career-boost` | Resume/LinkedIn diagnosis and rewrite for ATS and recruiters, with fit scoring against a target job. |
| `crisis-investing` | Builds and scores investment strategies for global crisis scenarios (wars, pandemics, recessions, tail-risk events). |
| `standardize-md-skills` | Audits and standardizes SKILL.md/project MD files against Anthropic conventions — always scoped to an explicit target directory. |
| `ai-daily-brief` | Generates a daily brief of top AI-world news, deduped across a curated, user-editable source list. |

## Agents

| Agent | Description |
|---|---|
| `security-auditor` | Read-only security audit of a Claude Code environment — secrets, permissions, config hygiene. |

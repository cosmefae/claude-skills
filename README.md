# claude-skills

I never accepted that designers don't build. These are skills and agents I actually use, in Claude Code, Codex, and whatever agent surface I'm on that day.

I'm Cosme Faé, a design engineer and agent architect ([hellofae.com](https://hellofae.com)). Most of my work now is agentic experience design: systems that decide, explain, and act on their own, and still need to feel trustworthy to the people depending on them. This repo holds the toolkit: a Figma-to-code pipeline, git discipline, doc hygiene, a couple of finance and career skills. Nothing here is theoretical. Everything shipped because I hit the same friction twice and got tired of solving it by hand.

All content is in English. It's meant to be usable by anyone, not tied to any single workspace or language.

Structure:
- `skills/`: one folder per skill, each with `SKILL.md`
- `agents/`: one folder or file per agent definition
- `.claude-plugin/marketplace.json`: plugin catalog
- `LICENSE`: MIT

## Install

Whole marketplace, inside Claude Code:
```
/plugin marketplace add cosmefae/claude-skills
```

One skill or agent at a time, with the [Vercel Labs `skills` CLI](https://github.com/vercel-labs/skills) (works in Claude Code, Codex, Cursor, and anywhere else the Agent Skills spec is supported):
```
npx skills add cosmefae/claude-skills/skills/<skill-name>
npx skills add cosmefae/claude-skills/agents/<agent-name>
```
Example: `npx skills add cosmefae/claude-skills/skills/screen-contract`

Or with GitHub CLI's native `gh skill` (v2.90.0+), which lets you pin a commit hash for reproducibility:
```
gh skill install cosmefae/claude-skills/skills/<skill-name>
```

Each skill/agent link in the tables below points straight to its folder, so you can grab the exact path for either command.

## Provenance

Every `SKILL.md`/agent `.md` in this repo carries a `Provenance:` line in its frontmatter, one of:
- `original: [cosmefae](https://hellofae.com)`: built from scratch for this repo
- `adapted from a private workspace skill: [cosmefae](https://hellofae.com)`: generalized from a personal workspace skill (the case for everything currently in the repo)
- `adapted from [@handle](url), used with permission: <restriction>`: reserved for skills sourced from a named third-party author under explicit permission/restriction

## Skills

| Skill | Description |
|---|---|
| [`screen-contract`](skills/screen-contract) | Turns a Figma frame, screenshot, or brief into a structural JSON contract before any code generation. Prevents visual drift and invented tokens/components. |
| [`write-handoff`](skills/write-handoff) | Writes a concise HANDOFF.md for the current task: state, file refs, verify commands, next steps. |
| [`commit-guided`](skills/commit-guided) | Guided git workflow. Validate, commit with Conventional Commits, open a PR. |
| [`sync-references`](skills/sync-references) | Audits and syncs documentation references (README, llms.txt, AGENTS.md, SKILL.md, CHANGELOG.md). Broken links, orphan files, skill-index drift. |
| [`figma-shadcn-hygiene`](skills/figma-shadcn-hygiene) | Figma-only structural hygiene pass: naming, taxonomy, auto layout, token gaps. Produces a Hygiene Report for handoff. |
| [`figma-shadcn-visual-match`](skills/figma-shadcn-visual-match) | Figma → shadcn → code with a visual fidelity gate: implements, screenshots both sides, classifies diffs, iterates to approval. |
| [`career-boost`](skills/career-boost) | Resume/LinkedIn diagnosis and rewrite for ATS and recruiters, with fit scoring against a target job. |
| [`crisis-investing`](skills/crisis-investing) | Builds and scores investment strategies for global crisis scenarios (wars, pandemics, recessions, tail-risk events). |
| [`standardize-md-skills`](skills/standardize-md-skills) | Audits and standardizes SKILL.md/project MD files against Anthropic conventions. Always scoped to an explicit target directory. |
| [`ai-daily-brief`](skills/ai-daily-brief) | Generates a daily brief of top AI-world news, deduped across a curated, user-editable source list. |

## Agents

| Agent | Description |
|---|---|
| [`security-auditor`](agents/security-auditor.md) | Read-only security audit of a Claude Code environment: secrets, permissions, config hygiene. |

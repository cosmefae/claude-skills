# claude-skills

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![Skills](https://img.shields.io/badge/skills-11-brightgreen.svg)

Agent Skills for Claude Code, built by a design engineer who actually ships with them.

I never accepted that designers don't build. These are skills and agents I use myself, in Claude Code, Codex, and whatever agent surface I'm on that day.

I'm Cosme Faé, a design engineer and agent architect ([hellofae.com](https://hellofae.com)). Most of my work now is agentic experience design: systems that decide, explain, and act on their own, and still need to feel trustworthy to the people depending on them. This repo holds the toolkit: a Figma-to-code pipeline, git discipline, doc hygiene, a couple of finance and career skills. Nothing here is theoretical. Everything shipped because I hit the same friction twice and got tired of solving it by hand.

All content is in English. It's meant to be usable by anyone, not tied to any single workspace or language.

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

Each skill link in the table below points straight to its folder, so you can grab the exact path for either command.

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
| [`security-auditor`](skills/security-auditor) | Read-only security audit of a Claude Code environment: secrets, permissions, config hygiene. |

`agents/` exists in the structure but has no published agents yet — skills are the current focus.

## Why this over writing your own

| | From scratch | Generic prompt libraries | This repo |
|---|---|---|---|
| Battle-tested | No — new, untested | Rarely — written for demos | Yes — every skill shipped from a real workspace friction point |
| Figma-to-code pipeline | Build it yourself | Not included | Included, with a visual fidelity gate |
| Git/PR discipline | Ad hoc | Not included | Included (`commit-guided`) |
| Provenance transparency | N/A | Usually unclear | Every skill tags its origin in frontmatter |

## Structure

- `skills/`: one folder per skill, each with `SKILL.md`
- `agents/`: one folder or file per agent definition
- `.claude-plugin/marketplace.json`: plugin catalog
- `llms.txt`: machine-readable index of this repo, for LLMs/agents
- `LICENSE`: MIT

## Provenance

Every `SKILL.md`/agent `.md` in this repo carries a `Provenance:` line in its frontmatter. The value is always quoted, since it contains its own colon:
- `Provenance: "original: [cosmefae](https://hellofae.com)"`: built from scratch for this repo
- `Provenance: "adapted from a private workspace skill: [cosmefae](https://hellofae.com)"`: generalized from a personal workspace skill (the case for everything currently in the repo)
- `Provenance: "adapted from [@handle](url), used with permission: <restriction>"`: reserved for skills sourced from a named third-party author under explicit permission/restriction

## Contributing

Found a rough edge, or built a skill that fits the same bar (real friction, actually used, provenance tagged)? See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)

---

If this saved you the trouble of writing one of these yourself, a star helps others find it.

[![Star History Chart](https://api.star-history.com/svg?repos=cosmefae/claude-skills&type=Date)](https://star-history.com/#cosmefae/claude-skills&Date)

# llms.txt — Reference Spec

> Based on the spec at [llmstxt.org](https://llmstxt.org). A structured LLM context file — analogous to `robots.txt` but for language models.

## Required structure

```markdown
# Project Name

> One-to-three-line description of the project so the model understands the context.

## Main Section

- [Artifact Name](relative/path/or/url): Concise one-line description.
- [Other Artifact](path/file.md): What this file contains and when it's relevant.

## Secondary Section

- [File](docs/file.md): Description.

## Optional

- [Optional File](docs/optional.md): Included only when relevant.
```

## Validation rules

| Rule | Valid | Invalid |
|-------|--------|---------|
| A single top-level `# H1` | `# My Project` | two `# H1`s |
| Description via `>` immediately after H1 | `> Project context` | loose paragraph |
| Sections are `## H2` | `## Docs` | `### Subsection` as a root section |
| Links are `- [Name](path): desc` | `- [File](docs/a.md): desc` | `- docs/a.md` |
| Link description on the same line | `- [A](b.md): What it is` | description on a separate line |
| Resolvable relative paths | `docs/file.md` | `../other-repo/file.md` |
| `## Optional` section for secondary items | `## Optional\n- [...]` | mixing optional with mandatory |

## Recommended section categories

Use semantic sections to make it easier for the model to read:

- `## Essential context` — documents the model MUST always read
- `## Code-generation specs` — contracts, APIs, schemas
- `## Active subprojects` — sub-modules with their own README
- `## Skills and automation` — skills, AGENTS.md, workflows
- `## Tokens` — design tokens, constants, config variables
- `## Optional` — history, legacy, supporting files

## What NOT to include in llms.txt

- `CHANGELOG.md` — too long, wastes context unnecessarily
- `CONTRIBUTING.md` — instructions for humans, not models
- `legacy/` — unless explicitly referenced as historical reading
- Binary files, images, token JSONs (unless critical)
- Temporary or build files

## Validation checklist (for sync-references)

- [ ] Exactly one `# H1` exists
- [ ] A `>` exists right after the H1
- [ ] All sections are `## H2`
- [ ] All links follow the `- [Name](path): description` pattern
- [ ] All paths exist on disk
- [ ] No listed file has been deleted
- [ ] New relevant files have been added
- [ ] An `## Optional` section exists for secondary items

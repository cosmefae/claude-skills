---
name: write-handoff
description: Writes a HANDOFF.md for the current task. Documents state, relevant files with @path and line ranges, verification commands, and next steps. Use when you need to hand off task context concisely.
allowed-tools: Read, Grep, Glob, Write, AskUserQuestion
Provenance: adapted from a private workspace skill: [cosmefae](https://hellofae.com)
---

You write HANDOFF.md for the current task.

Rules:
- Keep it short.
- Reference files with @path and line ranges when possible.
- Include "Commands to verify".
- Include "Next steps".

$ARGUMENTS

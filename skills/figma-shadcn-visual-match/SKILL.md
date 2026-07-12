---
name: figma-shadcn-visual-match
description: Runs the Figma → shadcn → code pipeline with a visual fidelity gate. Consumes the Hygiene Report, implements components, generates screenshots (Figma and local), classifies diffs (blocker/major/minor), and iterates until approval.
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, mcp__figma__*, mcp__*shadcn*, mcp__*design*, mcp__*component*, mcp__*code*, mcp__playwright__*
Provenance: adapted from a private workspace skill — [cosmefae](https://hellofae.com)
---

# Figma + shadcn/ui Visual Match

**Arguments:** `$ARGUMENTS` (optional: `--constraint "fixed-sidebar-color" --target "high-fidelity"`)

## Goal

Turn an already-hygienic Figma node into a shadcn/ui-based implementation with high visual fidelity and explicit screenshot-based validation.

## Mandatory precondition

This skill only starts if it receives a complete **Hygiene Report**, **confirmed by the user**, with:
- `rootNode`
- `semanticRegions`
- `primitiveMapping`
- `tokensAndVariables`
- `knownExceptions`

If any item is missing, hand back to `figma-shadcn-hygiene` with objective feedback.

## `[GAP]` protocol

Never invent a component, token, or path that doesn't actually exist. If the Hygiene Report has an unresolved `[GAP]`, or a value shows up with no corresponding semantic token, or an asset doesn't come from Figma — declare `[GAP]` in the Visual Match Report instead of assuming. Don't use a placeholder when Figma provides the real asset.

## Scope and boundaries

### This skill does
- Code implementation based on shadcn/ui.
- Layout/typography/spacing/opacity adjustments for visual match.
- Screenshot capture and comparison (local vs Figma).
- Classification of divergences (`blocker`, `major`, `minor`).

### This skill does NOT do
- Primary structural renaming in Figma.
- Redefinition of base taxonomy/hierarchy.

## Mandatory workflow

### Phase 1 — Handoff ingestion
- Read and validate the Hygiene Report.
- Register constraints (e.g. "fixed sidebar color") as fixed requirements.

### Phase 2 — shadcn implementation

**Before coding, detect whether the screen has already been implemented.** If code already exists for this frame:
- **DO NOT regenerate from scratch** — that erases manual adjustments made to the code after the first generation.
- Diff the updated frame against the existing code; apply **surgical edits** only where the design changed.
- Preserve everything that didn't change in Figma (logic, tracking, code adjustments with no design origin).
- If the code doesn't exist yet, implement it from scratch normally.

Then:
- If the project has a `components.json`, consult it first (framework, aliases, already-installed components, base library) instead of assuming structure — this is what the official shadcn Skill exposes when available.
- Compose the UI with the appropriate shadcn primitives.
- Preserve project patterns and correct aliases.
- Avoid local components duplicating primitives that already exist.
- If the project doesn't yet have a defined folder structure, recommend (don't impose):
  `components/ui` (raw shadcn/CLI) → `primitives` (wrapper with business logic/tracking/state)
  → `blocks` (full compositions). This is an organizational suggestion, not an execution precondition.

### Phase 3 — Dual screenshot capture
- Capture the Figma reference (target node).
- Capture the locally rendered screen in the equivalent state.
- Ensure comparable dimensions and context.

### Phase 3.5 — Accessibility checks (mandatory)
Before the visual diff, validate against objective criteria:
- **Touch targets:** interactive elements (button, link, input) with a minimum height of 44px
- **Contrast:** minimum 4.5:1 for normal text
- **Labels:** input with a visible label; `aria-label` on icon-only buttons; descriptive `alt` on images
- **Icons:** never a Unicode emoji as a UI icon — always a native SVG/asset from Figma
- **`prefers-reduced-motion`** on any animation

Failure on any of these = classify as `major` in the diff (not `minor`).

### Phase 4 — Qualitative diff with severity
Classify differences:
- `blocker`: structural break, overflow, missing critical element, misplaced section.
- `major`: perceptible spacing/alignment/typography/opacity deviation from the spec; also classify as `major` when the code uses a raw utility class (e.g. `bg-blue-500`, `text-red-800`) instead of the semantic token already present in the design system (e.g. `bg-brand-primary`, `text-destructive`) — the most common failure point of AI-generated code.
- `minor`: fine icon/font rendering differences with no structural impact.

### Phase 5 — Adjustment loop
- Iterate on the code until `blocker` and `major` are both zero.
- Document remaining `minor` items with justification.

### Phase 6 — Delivery
Emit the complete **Visual Match Report**.

## Acceptance criteria

The task can only be closed when:
1. `blocker = 0`
2. `major = 0`
3. Local + Figma screenshots attached/referenced
4. Declared constraints met (e.g. fixed sidebar color)

## Mandatory output

```markdown
VISUAL MATCH REPORT

Frame:
- fileKey: ...
- nodeId: ...

Constraint set:
- ...

Screenshots:
- figma: <path-or-link>
- local: <path-or-link>

Diff summary:
- blocker: <n>
- major: <n>
- minor: <n>

Checklist:
- [ ] structure (header/nav/footer)
- [ ] no overflow
- [ ] critical elements present
- [ ] spacing/alignment
- [ ] typography/opacity
- [ ] constraints applied
- [ ] a11y: 44px touch targets / 4.5:1 contrast / labels / no emoji-icons
- [ ] semantic tokens (no raw utility class where a token exists)

Residual differences (minor only):
- ...

Final status: PASS | FAIL
```

## Feedback loop rule

If a structural problem originating in Figma comes up (naming/taxonomy/auto layout), don't patch it locally without registering it.
Return to `figma-shadcn-hygiene` with:
- observed problem
- visual evidence
- objective structural fix suggestion

## Mental command

"I'll use the hygienic handoff as a contract, implement with shadcn primitives, and only finish when the visual diff is free of blockers/majors."

---
name: figma-shadcn-hygiene
description: Analyzes and cleans up the selected Figma frame to make it semantic, consistent, predictable, and ready for structural handoff. This skill is Figma-only — it standardizes naming, taxonomy, auto layout, and token gaps. It does not generate code or decide final visual match.
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion, mcp__figma__*, mcp__*shadcn*, mcp__*design*, mcp__*component*, mcp__*code*
Provenance: adapted from a private workspace skill — [cosmefae](https://hellofae.com)
---

# Figma + shadcn/ui Hygiene

**Arguments:** `$ARGUMENTS` (optional: `--focus "ComponentName,OtherComponent"` to focus on specific patterns)

---

You are a hygiene specialist who transforms Figma frames into semantic, predictable structures ready for handoff.

## Idempotency (mandatory — read before anything else)

This skill **only acts on gaps**. It never redoes what's already compliant. An already-hygienic frame should come out of a run practically untouched.

Before any mutation (renaming, creating a variable, adjusting layout), **diagnose first**:
- Does the layer already have a semantic name (`Page/...`, `Button/...`)? → **don't rename**.
- Does the value already reference a variable/token? → **don't recreate** the token.
- Is auto layout already normalized? → **don't touch it**.

Only operate where the diagnosis flags a real problem. This avoids the anti-pattern of "re-renaming differently on every run" (which breaks Code Connect) and of recreating tokens that already exist.

The final report must separate **`already compliant`** (untouched) from **`fixed`** (what changed in this pass). If the frame was already 100% hygienic, the correct output is "no changes needed" + the updated Handoff Contract — not a replay of the entire process.

## Scope and boundaries (mandatory)

### This skill does
- Figma-side operations: structural reading, renaming, taxonomy, auto layout, variables/tokens, and gaps.
- Structural handoff preparation for a later implementation stage.
- Conceptual mapping to primitives (without a final visual-fidelity commitment).

### This skill does NOT do
- Frontend code generation.
- Final visual validation via screenshots of rendered code.
- Final visual match approval, Figma → code.

If the task requires implementation or final visual QA, explicitly hand off to the `figma-shadcn-visual-match` skill.

## Your role

Given a frame selected in Figma, run **7 hygiene phases**:

### Phase 1 — Structural reading
Follow the official Figma MCP Server sequence (more efficient than reading everything at once):
1. `get_design_context` on the selected root node — structured representation of the exact node
2. If the response is too large, `get_metadata` first (high-level view), then fetch only the needed node
3. `get_screenshot` as a visual reference before proceeding

From this:
- List the main hierarchy
- Detect semantic regions (header, sidebar, content, forms, dialogs, etc.)
- Find recurring primitives
- Map composite patterns

Layer names aren't just organization — they're a direct semantic signal to the MCP's LLM (the model uses the layer name to infer intent). This is why Phase 2 (renaming) matters.

### Phase 2 — Naming hygiene
Rename **only layers with generic names** (not ones already semantic):
- ❌ `Frame 1`, `Group 12`, `Rectangle 4` → rename
- ✅ `Page/Dashboard`, `FilterBar/Base`, `StatCard/Active` → **already compliant, don't touch**

### Phase 3 — Taxonomy
Classify each part:
- `primitive` — reusable base
- `pattern` — recurring combination
- `block` — product-specific block
- `template` — final page composition

### Phase 4 — Match with shadcn/ui
Map each pattern to the closest shadcn primitive:
- Button → `Button`
- Input → `Input`
- Selector → `Select`
- Modal → `Dialog`
- Table → `Table`
- etc.

**If available:** use shadcn/ui tools (MCP) to validate primitives and consult official component documentation.

**Code Connect:** if the project has Code Connect configured (Figma node → real repo component already mapped), use it as the primary source of truth instead of approximate name-based mapping. When it exists, register the id in the Handoff Contract (`primitiveMapping[].codeConnectId`).

**Figma Slots:** when inspecting the structure, prefer instances with slot/instance-swap over "detached" components (detaching breaks the link to the design system and eliminates reuse). If you find a detach, flag it in `openStructuralIssues`.

**Golden rule:** map to the closest primitive, don't force-rename proprietary components that already have an established identity.
Goal of this phase: structural and semantic compatibility, not final visual conformity.

### Phase 5 — Variables and design tokens
Inspect and propose **only where missing** (raw value with no variable). Where a variable/token is already applied, don't recreate or duplicate it. Propose:
- color variables
- spacing variables
- radius variables
- typography styles
- semantic roles

### Phase 6 — Auto layout and structure
Normalize:
- direction
- spacing
- padding
- alignment
- excessive nesting
- constraints

### Phase 7 — Output

Always deliver:

1. **Diagnosis** — what was wrong
2. **Structural map** — root, sections, patterns, primitives
3. **Rename plan** — old name → new name
4. **shadcn/ui mapping** — Figma layer → primitive
5. **Gaps** — what needs to become a token or component
6. **Next step** — clear recommendation

## `[GAP]` protocol (mandatory)

Never invent a token, component, or mapping that doesn't actually exist. If a Figma pattern has no corresponding shadcn primitive, or a value has no semantic token, or Code Connect isn't configured — register an explicit **`[GAP]`** instead of assuming. An honest `[GAP]` is worth more than an invented mapping that breaks during implementation.

## Priorities

1. Semantics > Appearance
2. Consistency > Flexibility
3. Reuse > Specificity
4. Structural handoff > implementation decisions
5. Product identity > template conformity
6. Honest `[GAP]` > invented inference

## Mandatory naming convention

```
Page/<name>
Section/<name>
Layout/<name>
Panel/<name>
Shell/<name>

Button/<variant>
Input/<type>
Textarea/Field
Select/Field
Checkbox/Field
Radio/Field
Switch/Field
Tabs/List
Dialog/Content
Card/Base
Badge/<variant>
Avatar/Base

FilterBar/Base
SearchBar/Base
FormSection/<name>
EmptyState/<name>
StatCard/<name>
DataTable/<name>
SettingsGroup/<name>
ActionRow/<name>

Title
Description
Label
Helper
Value
Icon
Image
Actions
Content
Header
Body
Footer
```

## Quick heuristics

- Generic names = rename without hesitation
- Patterns repeated 2x+ = component candidates
- Ambiguous structure = ask for clarification
- Deep nesting = group by intent
- No variables = add to the gaps list

## Mandatory output

Always deliver in this format:

```
DIAGNOSIS
[what was wrong and what was cleaned up]

ALREADY COMPLIANT (untouched)
- [layers/tokens that were already OK — confirm, don't redo]

FIXED (changed in this pass)
- [what actually changed; if empty: "no changes needed"]

STRUCTURAL MAP
Root: Page/...
Sections:
  - Section/...
  - Section/...
Patterns:
  - FilterBar/Base
  - DataTable/...
Primitives:
  - Button/...
  - Input/...

RENAME PLAN
Frame 1 → Page/Records
Group 4 → FilterBar/Base
Frame 33 → DataTable/Records
Group 10 → StatCard/ActiveRecords

SHADCN/UI MAPPING
FilterBar/Base → Input + Select + Button
DataTable/Records → Table
StatCard → Card + Badge

DESIGN SYSTEM GAPS
- Spacing without variables
- Inconsistent radius
- Undefined button states
- [others...]

NEXT STEP
Convert FilterBar and StatCard into reusable patterns; then map semantic tokens and move to codegen.
```

## Handoff Contract (mandatory for the next skill)

At the end, the output must explicitly include these fields:

```yaml
rootNode: "<root node-id>"
semanticRegions:
  - name: "<region>"
    nodeId: "<node-id>"
primitiveMapping:
  - figmaPattern: "<name>"
    shadcnPrimitive: "<primitive>"
    codeConnectId: "<optional, if Code Connect is configured>"
tokensAndVariables:
  colors: ["..."]
  spacing: ["..."]
  radius: ["..."]
  typography: ["..."]
knownExceptions:
  - "<non-Figma constraint, e.g. fixed color on a specific region>"
openStructuralIssues:
  - "<issue>"
```

Without this contract, consider the hygiene pass incomplete.

**Confirmation gate:** present the Handoff Contract to the user and **wait for explicit confirmation** before forwarding to `figma-shadcn-visual-match`. Don't proceed to implementation with an unconfirmed contract — this is the point where the user corrects a wrong mapping or resolves a `[GAP]` before it becomes code.

## Full workflow (Figma-only)

1. **Read the hierarchy** — understand the current structure
2. **Detect semantic regions** — identify pages, sections, patterns, primitives
3. **Clean up naming** — rename everything semantically (Phase 2)
4. **Classify taxonomy** — primitive, pattern, block, template (Phase 3)
5. **Map to primitives** — connect each layer to the closest primitive (Phase 4)
6. **List gaps** — identify what still needs design tokens or components (Phase 5)
7. **Prepare structural handoff** — emit the contract for `figma-shadcn-visual-match` (Phase 6-7)

## Mental command

"I'll clean up this frame to make it semantically readable and structurally predictable in Figma, preparing a complete handoff for the separate visual-match and implementation stage."

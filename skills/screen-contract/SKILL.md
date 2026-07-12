---
name: screen-contract
description: "Transforms any design input (Figma frame, screenshot, or text brief) into a structural JSON contract before any code generation. Use when asked to 'generate the contract', 'build the screen contract', or before implementing a screen from a design."
version: "1.0"
allowed-tools: [Read, mcp__*]
tags: [design-system, contract, pre-generation, consistency, figma]
Provenance: "adapted from a private workspace skill: [cosmefae](https://hellofae.com)"
---

# Skill: screen-contract

Converts any design input (Figma, screenshot, or brief) into a structural JSON contract that constrains and guides code generation, preventing visual drift and invented tokens or components outside the project's design system.

> **Core rule:** Never generate UI directly from an image or description without first producing a structural contract. The contract is a human checkpoint. The model presents it, the user confirms it, then generation proceeds.

This skill is **standalone**: it generates the contract and stops there. It does not assume or invoke other skills. If your workflow has a brainstorm step before and a code-generation step after, wire this skill in manually; there is no implicit coupling.

## When to use

- "generate the screen contract for this frame"
- "build the contract before implementing"
- "I want to see the contract before the code"
- Before implementing any screen from Figma/screenshot/brief

### When NOT to use

- Validating already-generated code: use a quality-gate skill from your project
- Reviewing standalone copy: use a copy-review skill from your project
- Committing changes

## Per-project configuration

This skill is design-system agnostic. Before first use in a project, create a `.screen-contract.config.json` file at the repo root (or provide the paths when asked):

```json
{
  "design_system_doc": "docs/design-system.md",
  "component_mapping_doc": "docs/specs/figma-mapping.md",
  "copy_rules_doc": "docs/copy-rules.md",
  "tokens_source": "tokens/design-tokens.json",
  "design_system_name": "Name of the project's DS",
  "language": "en"
}
```

If `.screen-contract.config.json` doesn't exist, **ask the user** where the design system reference files live before proceeding. Never assume paths or conventions from another project.

## Reference files (defined by the config above)

- `design_system_doc`: semantic tokens, components, spacing, typography
- `component_mapping_doc`: component catalog and Code Connect paths
- `copy_rules_doc`: copy rules for validating extracted text
- `tokens_source`: actual token values (reference, do not edit)

---

## How to execute

**Follow the steps in order. Do not skip steps.**

### Step 0: Load project configuration

Read `.screen-contract.config.json` at the project root. If it doesn't exist, ask the user for the equivalent paths before continuing. Every step below references the files defined here.

### Step 1: Identify the input type

Determine the origin of the received input:

| Type | Signal | Action in Step 2 |
|---|---|---|
| **Figma URL** | URL with `node-id` or active selection in Figma Desktop | Use MCP `get_design_context` + `get_screenshot` |
| **Screenshot** | Image pasted by the user | Analyze regions visually |
| **Text brief** | Text description of the screen/component | Infer regions from the description |

If the type is ambiguous, ask the user before proceeding.

---

### Step 2: Extract regions, hierarchy, and real visual tokens

Split the screen into semantic regions. The goal is a structural description, not pixel-perfect.

**For Figma input, call BOTH tools in parallel:**

```
get_design_context(fileKey, nodeId)   → node hierarchy, reference code, screenshot
get_variable_defs(fileKey, nodeId)    → actual variable values (hex, font-family, spacing)
```

`get_variable_defs` returns a `{variable_name: value}` map, for example:
```json
{
  "black": "#1a1a1a",
  "primary/default": "#3B82F6",
  "shadow/03": "0px 4px 16px rgba(0,0,0,0.08)",
  "font/family/sans": "Inter"
}
```
These values feed the `visual_tokens.extracted` field in the contract. **Never assume values; always use what `get_variable_defs` returns.**

Use the hierarchy from `get_design_context` to identify top-level regions (child frames, main groups). Prefer semantic names (`header`, `card-area`, `cta-area`) over literal Figma layer names.

**For screenshot or brief:**

Describe regions top to bottom following the visual structure:
- Top: navigation, header, breadcrumb
- Middle: main content (cards, lists, forms)
- Bottom: CTAs, fixed bar, footer

**Expected intermediate output:**

```
Regions identified:
1. header: navigation with back button and title
2. card-area: summary card with main data
3. info-area: alert or context message
4. cta-area: primary button fixed at the bottom

Tokens extracted (get_variable_defs):
- font-family: Inter
- --primary: #3B82F6
- --black: #1a1a1a
- --shadow-03: 0px 4px 16px rgba(0,0,0,0.08)
```

---

### Step 2b: Analyze target file (when provided)

If a target file was specified (e.g. existing HTML playground, React component):

1. **Read the file** with the `Read` tool
2. **Extract all CSS custom properties** defined in `:root` or global selectors
3. **Compare** each property against the `get_variable_defs` values
4. **Produce the list of discrepancies** → `visual_delta` field in the contract

**Comparison rules:**

| Situation | Action |
|---|---|
| CSS value differs from Figma value | Register in `visual_delta` with `action: "fix"` |
| CSS property doesn't exist in the file, but Figma defines it | Register in `visual_delta` with `action: "add"` |
| Font-family differs from Figma | Register in `visual_delta` with `action: "import + update var"` |
| CSS value matches Figma | Do not register (no delta) |

**If no target file is provided:** skip this step and leave `visual_delta: []` in the contract.

---

### Step 2c: Extract component anatomy

From the reference code returned by `get_design_context`, document the internal structure of the main components, not just the type, but the real visual hierarchy.

**Rule:** describe what you see in the code/node structure, not what you imagine. Use this format:

```
[component-name]: [outer-layer { inner-layer-1 + inner-layer-2 }] + [other-layer]
```

**Example (generic, adapt to your screen):**
```
summary-card: colored-header { date-badge + status-chip + title + subtitle } / white-body { grid-2x2[field1·field2·field3·field4] + extra-chip + [btn-primary + btn-ghost] }
```

Register in `component_anatomy` in the contract. If the component is simple (no relevant hierarchy), omit it from the anatomy.

---

### Step 3: Map design system components

For each region, identify the corresponding component in the project's design system.

Read `component_mapping_doc` (defined in the config) to consult the official component catalog.

**If the input is Figma, check Code Connect:**

```
get_code_connect_map(fileKey, nodeId)
```

For each component:
- If Code Connect returns a path → register it in `code_connect`
- If it doesn't → register `null` and note that it should be implemented per `component_mapping_doc`

**Rule:** If an existing component covers the use case, never create an ad-hoc one. Register it as the existing component with the closest variant.

---

### Step 4: Bind tokens

For each region and component, list the design system tokens that will be used.

Consult `design_system_doc` and `tokens_source` (defined in the config) for correct naming.

**Mandatory categories:**

| Category | Prefer | Avoid |
|---|---|---|
| Colors | semantic tokens (`--primary`, `--success`, `--error`) | raw palette tokens (`--blue-500`, `--red-80`) |
| Spacing | scale tokens (`--size-16`, `--space-md`) | loose `px` values |
| Typography | named styles (`Heading/md`, `Body/lg`) | literal px sizes |
| Radius | radius tokens (`--card-radius`) | loose px values |
| Shadows | shadow tokens (`--shadow-xs`, `--shadow-lg`) | custom `box-shadow` |

**Rule:** Any visual value without a corresponding design system token must appear in `uncertainties`, not in `tokens_used`.

---

### Step 5: Extract content and states

**Text:** Extract visible text (labels, CTAs, messages). **Emoji as an icon substitute is forbidden** in the `copy` or `content.texts` fields.

**Typography:** For each text region, register the Figma style, weight, size, and recommended HTML element in `typography_map`.

**Icons:** For each visible icon, register the Figma node and `asset_policy: svg-from-mcp` in `icons[]`.

**States:** Identify the states the screen/component needs to support. Minimum default: `default`. Add when applicable: `loading`, `empty`, `error`, `success`.

**Interactions:** Note explicit behaviors (scroll, expansion, modal, navigation).

---

### Step 6: Register uncertainties

Explicitly list any detected ambiguity. **Never guess; register it in `uncertainties`.**

Examples of valid uncertainties:
- "Header icon: use the Figma asset via MCP or the DS icon library?"
- "Card error state: no spec found in the frame, assume DS default?"
- "Spacing between card and CTA: no value identified in the node, use the DS default?"

---

### Step 7: Assemble and present the contract

Generate the JSON contract object and a readable summary. **Wait for user confirmation before proceeding to code generation.**

---

## Screen Contract template

```json
{
  "screen_name": "Screen or component name",
  "purpose": "What the user does/sees on this screen and the business goal",
  "source": {
    "type": "figma|screenshot|brief",
    "ref": "Figma URL, frame name, or origin description"
  },
  "layout": {
    "type": "stacked|grid|sidebar|overlay",
    "breakpoint_base": "375px",
    "regions": ["header", "card-area", "cta-area"]
  },
  "visual_tokens": {
    "source": "get_variable_defs",
    "extracted": {
      "font-family": "Inter",
      "--primary": "#3B82F6",
      "--black": "#1a1a1a",
      "--shadow-03": "0px 4px 16px rgba(0,0,0,0.08)"
    }
  },
  "visual_delta": [
    {
      "target": "font-family",
      "current": "system-ui",
      "figma": "Inter",
      "action": "import via Google Fonts + update var"
    },
    {
      "target": "--gray-10",
      "current": "#f5f5f5",
      "figma": "#1a1a1a",
      "action": "fix variable value"
    }
  ],
  "component_anatomy": {
    "summary-card": "colored-header { date-badge + status-chip + title + subtitle } / white-body { grid-2x2[field1·field2·field3·field4] + extra-chip + [btn-primary + btn-ghost] }"
  },
  "components": [
    {
      "region": "header",
      "type": "page_header",
      "variant": "with_back",
      "role": "screen navigation and title",
      "code_connect": "@/components/ui/PageHeader"
    },
    {
      "region": "card-area",
      "type": "card",
      "variant": "default",
      "role": "main content summary",
      "code_connect": null
    },
    {
      "region": "cta-area",
      "type": "button",
      "variant": "primary",
      "role": "primary action, sticky at the bottom",
      "code_connect": "@/components/ui/Button"
    }
  ],
  "tokens_used": {
    "colors": ["--primary", "--success"],
    "spacing": ["--size-16", "--size-24"],
    "typography": ["Heading/md", "Body/lg", "Body/sm"],
    "radius": ["--card-radius"],
    "shadows": ["--shadow-xs"]
  },
  "typography_map": [
    {
      "region": "card-title",
      "figma_style": "Mob/Subtitle/sm",
      "weight": 400,
      "size": "20px",
      "line_height": 1.2,
      "element": "p",
      "class": "text-subtitle-sm"
    }
  ],
  "icons": [
    {
      "region": "search",
      "figma_node": "icon / search",
      "asset_policy": "svg-from-mcp",
      "local_path": "assets/{slug}/icon-search.svg"
    }
  ],
  "content": {
    "texts": [
      {"region": "header", "value": "Screen title", "copy_ok": true},
      {"region": "cta-area", "value": "Confirm", "copy_ok": true}
    ],
    "states": ["default", "loading", "error"],
    "interactions": ["vertical scroll", "CTA button navigates to next screen"]
  },
  "constraints": [
    "Apply all visual_delta fixes before adding any new state or component",
    "No colors outside the design system's semantic tokens",
    "No custom shadows; use only the defined shadow tokens",
    "Reuse existing components before creating new ones",
    "Minimum touch target 44px on all interactive elements",
    "Copy follows the project's copy_rules_doc",
    "Icons only as SVG/Figma MCP assets; never emoji",
    "Explicit font-weight on typography classes"
  ],
  "uncertainties": [
    "Header icon: Figma asset via MCP or DS icon library?"
  ]
}
```

---

## Output format for the user

Present the contract in two blocks:

### Block 1: Readable summary

```markdown
## Screen Contract: [screen_name]

**Purpose:** [purpose]
**Source:** [source.type]: [source.ref]
**Layout:** [layout.type], base [breakpoint_base]

### Regions and components
| Region | Component | Variant | Code Connect |
|---|---|---|---|
| header | page_header | with_back | ✅ @/components/ui/PageHeader |
| card-area | card | default | ⏳ unmapped |
| cta-area | button | primary | ✅ @/components/ui/Button |

### Component anatomy (Figma)
- **summary-card:** colored-header { date-badge + status-chip + title + subtitle } / white-body { grid-2x2 + extra-chip + 2 buttons }

### Visual tokens extracted (Figma)
- **font-family:** Inter
- **--primary:** #3B82F6
- **--black:** #1a1a1a
- **--shadow-03:** 0px 4px 16px rgba(0,0,0,0.08)

### Mandatory visual fixes (visual_delta)
| Property | Current in file | Figma value | Action |
|---|---|---|---|
| font-family | system-ui | Inter | import + update var |
| --gray-10 | #f5f5f5 | #1a1a1a | fix value |

> If visual_delta is empty, the file is already aligned with Figma tokens.

### Bound tokens
- **Colors:** --primary, --success
- **Spacing:** --size-16, --size-24
- **Typography:** Heading/md, Body/lg
- **Radius:** --card-radius

### Required states
default · loading · error

### ⚠️ Uncertainties to resolve
1. Header icon: Figma asset via MCP or DS icon library?

---
**Waiting for confirmation to proceed with code generation.**
Reply "ok" to confirm, or adjust the contract before proceeding.
```

### Block 2: Contract JSON

The full JSON per the template above, for use by code generation.

---

## Operating rules

### Generation priority (critical rule)

> **The generator must apply all `visual_delta` fixes before adding new states or components. `visual_delta` is blocking.**

Mandatory order:
1. Fix every `visual_delta` item (CSS tokens, font-family, shadow values)
2. Apply `component_anatomy` to redesigned structures
3. Implement new functional states and components

If `visual_delta` is empty, proceed directly to the functional items.

### What this skill NEVER does
- Generate code: that's the responsibility of whoever consumes the contract, after confirmation
- Invent tokens that don't exist in `design_system_doc` or `tokens_source`
- Create new components when an existing one covers the case
- Skip the human checkpoint: always wait for confirmation before signaling the contract is ready
- Assume token values without consulting `get_variable_defs` when a Figma URL is available
- Assume config paths from another project: always read `.screen-contract.config.json` or ask

### What to do when the input is ambiguous
- Register it in `uncertainties` instead of assuming
- Present options when there are 2 valid paths
- Ask the user only what's strictly necessary to unblock the contract

---

## Notes

- The screen contract is the source of truth for code generation. Whoever generates the code should reference the JSON contract, not the Figma frame directly, when making component and token decisions.
- If the user changes the contract after confirmation, ask whether to regenerate the JSON before proceeding.
- If your project has its own brainstorm/generation/quality-gate skills, chain them manually: brainstorm → **screen-contract** → code generation → quality gate. This skill does not invoke any of them automatically.

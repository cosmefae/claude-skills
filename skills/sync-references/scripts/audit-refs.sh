#!/usr/bin/env zsh
# audit-refs.sh — Audits a project's documentation references
# Usage: zsh <skill-dir>/scripts/audit-refs.sh [project-root]
# Deps: zsh, grep, find, realpath (macOS default)

setopt nullglob

ROOT="${1:-$(pwd)}"
ROOT="$(realpath "$ROOT")"

RED='\033[0;31m'; YEL='\033[0;33m'; GRN='\033[0;32m'; BLU='\033[0;34m'; RST='\033[0m'
broken=0; orphan=0; missing_llms=0; stale=0; no_frontmatter=0; skill_sync=0; ok=0

echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  sync-references audit — $(date '+%Y-%m-%d %H:%M')"
echo "  Root: $ROOT"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Collect .md files (excluding dot-dirs and legacy) ──────────────────────
ALL_MD=()
while IFS= read -r -d '' f; do ALL_MD+=("$f"); done < <(
  find "$ROOT" -name "*.md" \
    ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/legacy/*" \
    ! -path "*/.claude/*" ! -path "*/.cursor/*" ! -path "*/.codex/*" \
    ! -path "*/.gemini/*" -print0 | sort -z
)

echo ""; echo "${BLU}[1/6] Files found: ${#ALL_MD[@]}${RST}"

# ── 2. Broken links — extract every local link target with grep ──────────────
echo ""; echo "${BLU}[2/6] Checking broken links...${RST}"

for md in "${ALL_MD[@]}"; do
  dir="$(dirname "$md")"
  rel_md="${md#"$ROOT/"}"

  # Extract "path" from every [text](path) that isn't http/mailto/#
  targets=$(grep -oE '\[[^]]*\]\([^)]+\)' "$md" 2>/dev/null \
    | grep -oE '\([^)]+\)' \
    | tr -d '()' \
    | sed 's/#.*//' \
    | grep -v '^$' \
    | grep -v '^https\?://' \
    | grep -v '^mailto:' \
    | grep -v '^#' \
    | awk -F'?' '{print $1}' \
    || true)

  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    resolved="$(realpath -m "$dir/$target" 2>/dev/null || true)"
    [[ -z "$resolved" ]] && continue
    if [[ -e "$resolved" ]]; then
      ((ok++)) || true
    else
      printf "  ${RED}✗ BROKEN${RST}  %s → %s\n" "$rel_md" "$target"
      ((broken++)) || true
    fi
  done <<< "$targets"
done

[[ $broken -eq 0 ]] && echo "  ${GRN}✓ No broken links${RST}"

# ── 3. Orphan files ─────────────────────────────────────────────────────────
echo ""; echo "${BLU}[3/6] Checking orphan files...${RST}"

# Concatenate every .md into a single buffer for efficient search
TMP_ALL=$(mktemp)
cat "${ALL_MD[@]}" > "$TMP_ALL" 2>/dev/null

for md in "${ALL_MD[@]}"; do
  bname="$(basename "$md")"
  case "$bname" in README.md|llms.txt|CHANGELOG.md|CONTRIBUTING.md|AGENTS.md|SKILLS.md) continue ;; esac
  [[ "$bname" =~ ^HANDOFF ]] && continue

  # Search the file's name in the overall buffer (not counting the file itself)
  total_hits=$(grep -c "$bname" "$TMP_ALL" 2>/dev/null || true)
  own_hits=$(grep -c "$bname" "$md" 2>/dev/null || true)
  total_hits=$(( ${total_hits:-0} + 0 ))
  own_hits=$(( ${own_hits:-0} + 0 ))
  external_hits=$(( total_hits - own_hits ))

  if [[ $external_hits -le 0 ]]; then
    rel_md="${md#"$ROOT/"}"
    printf "  ${YEL}⚠ ORPHAN${RST}  %s\n" "$rel_md"
    ((orphan++)) || true
  fi
done

rm -f "$TMP_ALL"
[[ $orphan -eq 0 ]] && echo "  ${GRN}✓ No orphan files${RST}"

# ── 4. llms.txt ────────────────────────────────────────────────────────────
echo ""; echo "${BLU}[4/6] Checking llms.txt...${RST}"

LLMS="$ROOT/llms.txt"
if [[ -f "$LLMS" ]]; then

  # Files present on disk but absent from llms.txt
  for md in "${ALL_MD[@]}"; do
    bname="$(basename "$md")"
    rel_md="${md#"$ROOT/"}"
    case "$bname" in CHANGELOG.md|CONTRIBUTING.md) continue ;; esac
    [[ "$bname" =~ ^HANDOFF ]] && continue

    if ! grep -qF "$rel_md" "$LLMS" && ! grep -qF "$bname" "$LLMS"; then
      printf "  ${YEL}⚠ MISSING-LLMS${RST}  %s\n" "$rel_md"
      ((missing_llms++)) || true
    fi
  done

  # llms.txt entries pointing to paths that don't exist on disk
  stale_targets=()
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    [[ "$target" =~ ^https?:// ]] && continue
    resolved="$(realpath -m "$ROOT/$target" 2>/dev/null || true)"
    [[ -z "$resolved" ]] && continue
    if ! [[ -e "$resolved" ]]; then
      stale_targets+=("$target")
    fi
  done < <(grep -oE '\([^)]+\)' "$LLMS" | tr -d '()')

  for t in "${stale_targets[@]}"; do
    printf "  ${RED}✗ STALE-LLMS${RST}  llms.txt → %s (doesn't exist)\n" "$t"
    ((stale++)) || true
  done

  [[ $missing_llms -eq 0 && $stale -eq 0 ]] && echo "  ${GRN}✓ llms.txt synchronized${RST}"
else
  echo "  ${YEL}⚠ llms.txt not found in $ROOT${RST}"
fi

# ── 5. Skills directory vs README / SKILLS.md / llms.txt ────────────────────
echo ""; echo "${BLU}[5/6] Checking skills sync...${RST}"

# Auto-detect skills directory convention: .claude/skills, then .cursor/skills, then skills/
SKILLS_DIR=""
for candidate in "$ROOT/.claude/skills" "$ROOT/.cursor/skills" "$ROOT/skills"; do
  if [[ -d "$candidate" ]]; then
    SKILLS_DIR="$candidate"
    break
  fi
done

README_F="$ROOT/README.md"
SKILLS_MD="$ROOT/SKILLS.md"

if [[ -z "$SKILLS_DIR" ]]; then
  echo "  ${GRN}✓ No skills directory found — skipping${RST}"
else
  skill_paths=()
  while IFS= read -r -d '' d; do
    [[ -f "$d/SKILL.md" ]] && skill_paths+=("$d")
  done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

  if [[ ${#skill_paths[@]} -eq 0 ]]; then
    echo "  ${GRN}✓ No skills in $SKILLS_DIR — skipping${RST}"
  else
    if [[ ! -f "$README_F" ]]; then
      printf "  ${YEL}⚠ SKILL-SYNC-README${RST}  README.md not found — could not validate \\\`skill\\\` names in the table\n"
      ((skill_sync++)) || true
    fi
    if [[ ! -f "$SKILLS_MD" ]]; then
      printf "  ${YEL}⚠ SKILL-SYNC-SKILLS${RST}  SKILLS.md not found — could not validate skill SKILL.md links\n"
      ((skill_sync++)) || true
    fi

    SKILLS_DIR_REL="${SKILLS_DIR#"$ROOT/"}"

    for sdir in "${skill_paths[@]}"; do
      id="$(basename "$sdir")"
      rel_skill="${SKILLS_DIR_REL}/${id}/SKILL.md"

      if [[ ! -f "$LLMS" ]] || ! grep -qF "$rel_skill" "$LLMS"; then
        printf "  ${YEL}⚠ SKILL-SYNC-LLMS${RST}    %s missing from llms.txt (add a link to %s)\n" "$id" "$rel_skill"
        ((skill_sync++)) || true
      fi

      if [[ -f "$README_F" ]] && ! grep -qF "\`${id}\`" "$README_F"; then
        printf "  ${YEL}⚠ SKILL-SYNC-README${RST}  %s missing from README.md (use \\\`%s\\\` in the skills table)\n" "$id" "$id"
        ((skill_sync++)) || true
      fi

      if [[ -f "$SKILLS_MD" ]] && ! grep -qF "$rel_skill" "$SKILLS_MD"; then
        printf "  ${YEL}⚠ SKILL-SYNC-SKILLS${RST}  %s missing from SKILLS.md (table must link %s)\n" "$id" "$rel_skill"
        ((skill_sync++)) || true
      fi
    done

    [[ $skill_sync -eq 0 ]] && echo "  ${GRN}✓ All skills indexed in README, SKILLS.md, and llms.txt${RST}"
  fi
fi

# ── 6. YAML frontmatter in docs/ ─────────────────────────────────────────────
echo ""; echo "${BLU}[6/6] Checking frontmatter in docs/...${RST}"

DOCS_DIR="$ROOT/docs"
if [[ -d "$DOCS_DIR" ]]; then
  while IFS= read -r -d '' md; do
    if ! head -1 "$md" | grep -q "^---"; then
      rel_md="${md#"$ROOT/"}"
      printf "  ${YEL}⚠ NO-FRONTMATTER${RST}  %s\n" "$rel_md"
      ((no_frontmatter++)) || true
    fi
  done < <(find "$DOCS_DIR" -name "*.md" ! -path "*/legacy/*" -print0)
  [[ $no_frontmatter -eq 0 ]] && echo "  ${GRN}✓ All files in docs/ have frontmatter${RST}"
else
  echo "  (no docs/ folder — skipping)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
total=$((broken + orphan + missing_llms + stale + no_frontmatter + skill_sync))
echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  Broken links      : %d\n" $broken
printf "  Orphan files      : %d\n" $orphan
printf "  Missing from llms : %d\n" $missing_llms
printf "  Stale in llms.txt : %d\n" $stale
printf "  Skill sync        : %d\n" $skill_sync
printf "  No frontmatter    : %d\n" $no_frontmatter
printf "  Links OK          : %d\n" $ok
echo ""
if [[ $total -eq 0 ]]; then
  echo "  ${GRN}✅ Clean documentation — no issues found${RST}"
else
  echo "  ${RED}⚠  $total issues found — review above${RST}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo ""

exit $total

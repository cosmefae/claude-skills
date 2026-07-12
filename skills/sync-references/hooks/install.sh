#!/usr/bin/env zsh
# install.sh: Installs git hooks for automatic sync-references
# Usage: zsh <skill-dir>/hooks/install.sh

setopt nullglob

# ── Configuration ────────────────────────────────────────────────────────────
SCRIPT_DIR="${0:A:h}"
SKILL_ROOT="${SCRIPT_DIR:h}"

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[0;33m'; BLU='\033[0;34m'; RST='\033[0m'

# ── Verify we're in a git repo ────────────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "${RED}❌ Error: not inside a git repository${RST}" >&2
  echo "   Run this script from the root of your git project." >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo ""
echo "${BLU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo "${BLU}  sync-references: Git Hooks Installation${RST}"
echo "${BLU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo ""
echo "📁 Repository: $REPO_ROOT"
echo "📂 Skill: $SKILL_ROOT"
echo ""

# ── Check for existing hooks ──────────────────────────────────────────────────
HOOKS_TO_INSTALL=(post-commit post-merge post-rewrite)
EXISTING_HOOKS=()

for hook in "${HOOKS_TO_INSTALL[@]}"; do
  if [[ -f "$HOOKS_DIR/$hook" ]]; then
    EXISTING_HOOKS+=("$hook")
  fi
done

if [[ ${#EXISTING_HOOKS[@]} -gt 0 ]]; then
  echo "${YEL}⚠ Existing hooks found:${RST}"
  for h in "${EXISTING_HOOKS[@]}"; do
    echo "   - $h"
  done
  echo ""
  echo -n "Overwrite? [y/N] "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "${RED}✗ Installation cancelled${RST}"
    exit 0
  fi
  echo ""
fi

# ── Copy hooks ──────────────────────────────────────────────────────────────
echo "${BLU}[1/4] Copying hooks...${RST}"
for hook in "${HOOKS_TO_INSTALL[@]}"; do
  src="$SCRIPT_DIR/$hook"
  dst="$HOOKS_DIR/$hook"

  if [[ ! -f "$src" ]]; then
    echo "   ${RED}✗ $hook not found in $SCRIPT_DIR${RST}" >&2
    exit 1
  fi

  cp "$src" "$dst"
  chmod +x "$dst"
  echo "   ${GRN}✓ $hook${RST}"
done

# ── Store the skill install path so the hooks can find it ────────────────────
echo ""
echo "${BLU}[2/4] Recording skill path...${RST}"
git config --local sync-refs.skill-root "$SKILL_ROOT"
echo "   ${GRN}✓ sync-refs.skill-root = $SKILL_ROOT${RST}"

# ── Configure default mode (silent) ──────────────────────────────────────────
echo ""
echo "${BLU}[3/4] Configuring mode...${RST}"

CURRENT_MODE=$(git config --local --get sync-refs.mode 2>/dev/null || echo "")

if [[ -z "$CURRENT_MODE" ]]; then
  git config --local sync-refs.mode silent
  echo "   ${GRN}✓ Mode: silent (default)${RST}"
else
  echo "   ${GRN}✓ Mode already configured: $CURRENT_MODE${RST}"
fi

# ── Validate installation ─────────────────────────────────────────────────────
echo ""
echo "${BLU}[4/4] Validating installation...${RST}"

ALL_OK=1
for hook in "${HOOKS_TO_INSTALL[@]}"; do
  dst="$HOOKS_DIR/$hook"
  if [[ -x "$dst" ]]; then
    echo "   ${GRN}✓ $hook executable${RST}"
  else
    echo "   ${RED}✗ $hook not executable${RST}"
    ALL_OK=0
  fi
done

# Check auto-sync.sh exists
AUTO_SYNC="$SKILL_ROOT/scripts/auto-sync.sh"
if [[ -x "$AUTO_SYNC" ]]; then
  echo "   ${GRN}✓ auto-sync.sh found${RST}"
else
  echo "   ${RED}✗ auto-sync.sh not found or not executable${RST}"
  ALL_OK=0
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""

if [[ $ALL_OK -eq 1 ]]; then
  echo "${GRN}✅ Installation complete!${RST}"
  echo ""
  echo "🎯 Hooks installed:"
  echo "   - post-commit   (detects renamed/moved .md files)"
  echo "   - post-merge    (syncs after pulls/merges)"
  echo "   - post-rewrite  (syncs after rebases)"
  echo ""
  echo "⚙️  Current config:"
  echo "   Mode: $(git config --get sync-refs.mode)"
  echo ""
  echo "📝 Change mode:"
  echo "   ${BLU}git config sync-refs.mode silent${RST}   # just logs to .git/sync-refs.log"
  echo "   ${BLU}git config sync-refs.mode report${RST}   # shows the report in the terminal"
  echo "   ${BLU}git config sync-refs.mode fix${RST}      # auto-fixes (not implemented yet)"
  echo ""
  echo "📋 View log:"
  echo "   ${BLU}tail -f .git/sync-refs.log${RST}"
  echo ""
else
  echo "${RED}❌ Installation failed: check errors above${RST}"
  exit 1
fi

echo "${BLU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo ""

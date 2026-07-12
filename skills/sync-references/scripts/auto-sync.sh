#!/usr/bin/env zsh
# auto-sync.sh — Detects .md changes and syncs references automatically
# Usage: zsh auto-sync.sh [--force]
# Deps: zsh, git, audit-refs.sh

setopt nullglob

# ── Configuration ────────────────────────────────────────────────────────────
SCRIPT_DIR="${0:A:h}"
AUDIT_SCRIPT="$SCRIPT_DIR/audit-refs.sh"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOG_FILE="$ROOT/.git/sync-refs.log"

# Operating mode (via git config or default to silent)
MODE=$(git config --get sync-refs.mode 2>/dev/null || echo "silent")
FORCE=0

# ── Parse args ────────────────────────────────────────────────────────────────
[[ "$1" == "--force" ]] && FORCE=1

# ── Verify audit-refs.sh exists ────────────────────────────────────────────────
if [[ ! -x "$AUDIT_SCRIPT" ]]; then
  echo "❌ Error: audit-refs.sh not found in $SCRIPT_DIR" >&2
  exit 1
fi

# ── Log function ────────────────────────────────────────────────────────────────
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# ── Detect .md changes ──────────────────────────────────────────────────────────
detect_md_changes() {
  # Check for .md files in the last commit or staged
  local changed_files

  # Try the diff from the last commit
  changed_files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep '\.md$' || true)

  # If there's no previous commit (fresh repo), check staged
  if [[ -z "$changed_files" ]]; then
    changed_files=$(git diff --cached --name-only | grep '\.md$' || true)
  fi

  # If still empty, check the working tree
  if [[ -z "$changed_files" ]]; then
    changed_files=$(git diff --name-only | grep '\.md$' || true)
  fi

  echo "$changed_files"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  # Detect changes
  local md_changes
  md_changes=$(detect_md_changes)

  # If no changes and not forced, skip
  if [[ -z "$md_changes" && $FORCE -eq 0 ]]; then
    log "No .md changes detected — skipping sync"
    [[ "$MODE" == "report" ]] && echo "✓ No .md changes — sync-references skipped"
    exit 0
  fi

  log "Detected .md changes:"
  echo "$md_changes" | while read -r f; do log "  - $f"; done

  # Run the audit
  log "Running audit-refs.sh..."
  local audit_output audit_exit
  audit_output=$("$AUDIT_SCRIPT" "$ROOT" 2>&1)
  audit_exit=$?

  log "Audit exit code: $audit_exit"

  # Handle based on mode
  case "$MODE" in
    silent)
      # Just log
      log "Mode: silent — logging only"
      echo "$audit_output" >> "$LOG_FILE"
      [[ $audit_exit -ne 0 ]] && log "⚠ $audit_exit issues found (not auto-fixing in silent mode)"
      ;;

    report)
      # Show in the terminal
      log "Mode: report — displaying output"
      echo "$audit_output"
      [[ $audit_exit -ne 0 ]] && echo "\n⚠ $audit_exit issues found. Run /sync-references to fix manually."
      ;;

    fix)
      # Auto-fix (placeholder — implement fix logic)
      log "Mode: fix — attempting auto-fix"
      echo "$audit_output"

      if [[ $audit_exit -ne 0 ]]; then
        echo "\n⚠ Auto-fix mode not implemented yet."
        echo "📝 Issues found: $audit_exit"
        echo "Run the '/sync-references' command to fix manually."
        log "Auto-fix not implemented — user intervention required"
      else
        echo "✅ No issues found — references already synchronized"
        log "No issues found"
      fi
      ;;

    *)
      log "Unknown mode: $MODE (defaulting to silent)"
      echo "$audit_output" >> "$LOG_FILE"
      ;;
  esac

  exit $audit_exit
}

main "$@"

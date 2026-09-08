#!/usr/bin/env bash
# actions.sh — the deletions themselves. Every path through here honours DRY_RUN.

_do_rm() {
  local p="$1"
  if [ "${DRY_RUN:-0}" = 1 ]; then logline "DRY rm -rf $p"; return 0; fi
  rm -rf -- "$p" 2>/dev/null || return 1
  logline "rm -rf $p"
}

run_item() {
  # IMPORTANT: these have to be separate statements. `local i="$1" act="${I_ACTION[$i]}"`
  # expands ${I_ACTION[$i]} using the GLOBAL $i (bash expands all arguments
  # before assigning any of them) — that runs the wrong item.
  local i act extra p rc
  i="$1"; act="${I_ACTION[$i]}"; extra="${I_EXTRA[$i]}"; rc=0

  case "$act" in
    rm)
      while IFS= read -r p; do
        [ -n "$p" ] || continue; [ -e "$p" ] || continue
        _do_rm "$p" || rc=1
      done <<< "${I_PATHS[$i]}"
      ;;

    rmchild)
      while IFS= read -r p; do
        [ -n "$p" ] || continue; [ -d "$p" ] || continue
        if [ "${DRY_RUN:-0}" = 1 ]; then logline "DRY clear $p/*"; continue; fi
        find "$p" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || rc=1
        logline "clear $p/*"
      done <<< "${I_PATHS[$i]}"
      ;;

    findrm)
      local depth="${extra%%|*}" pat="${extra#*|}"
      while IFS= read -r p; do
        [ -n "$p" ] || continue; [ -d "$p" ] || continue
        if [ "${DRY_RUN:-0}" = 1 ]; then
          find "$p" -maxdepth "$depth" -name "$pat" -print 2>/dev/null \
            | while IFS= read -r m; do logline "DRY rm -rf $m"; done
          continue
        fi
        find "$p" -maxdepth "$depth" -name "$pat" -exec rm -rf -- {} + 2>/dev/null || rc=1
        logline "findrm $p -maxdepth $depth -name $pat"
      done <<< "${I_PATHS[$i]}"
      ;;

    agerm)
      local days="${extra%%|*}" pat="${extra#*|}"
      while IFS= read -r p; do
        [ -n "$p" ] || continue; [ -d "$p" ] || continue
        if [ "${DRY_RUN:-0}" = 1 ]; then
          find "$p" -mindepth 1 -name "$pat" -mtime "+$days" -prune -print 2>/dev/null \
            | while IFS= read -r m; do logline "DRY delete $m"; done
          continue
        fi
        # -prune so find does not descend into what it just removed; rm -rf
        # rather than -delete because -delete only removes EMPTY directories
        # (that was a real bug once: old /tmp/claude-* dirs never went away).
        find "$p" -mindepth 1 -name "$pat" -mtime "+$days" -prune \
             -exec rm -rf -- {} + 2>/dev/null || rc=1
        logline "agerm $p -name $pat -mtime +$days"
      done <<< "${I_PATHS[$i]}"
      ;;

    cmd)
      if [ "${DRY_RUN:-0}" = 1 ]; then logline "DRY cmd: $extra"; return 0; fi
      logline "cmd: $extra"
      eval "$extra" >/dev/null 2>&1 || rc=1
      ;;

    note) return 0 ;;
    *) return 1 ;;
  esac
  return $rc
}

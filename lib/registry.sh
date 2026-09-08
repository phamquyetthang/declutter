#!/usr/bin/env bash
# registry.sh — the store of cleanup items. Parallel arrays, because bash 3.2
# has no associative arrays.

I_LEVEL=(); I_GROUP=(); I_DESC=(); I_ACTION=(); I_EXTRA=(); I_PATHS=()

# Every group a module may register into. Used to reject typos in --only/--skip
# instead of silently matching nothing.
KNOWN_GROUPS="ai-cli ai-ide ai-ml ai-model pkg-node pkg-python pkg-rust pkg-go pkg-java docker browser os xcode"

# add LEVEL GROUP ACTION EXTRA "description" [path...]
#
#   LEVEL : green | yellow | red
#   ACTION: rm      delete the paths
#           rmchild delete what is inside the path, keep the directory
#           findrm  EXTRA="maxdepth|pattern"
#           agerm   EXTRA="days|pattern"  (only entries older than N days)
#           cmd     EXTRA is a shell command; paths are only used to measure
#           note    report only, never deletes anything
#
# An item whose paths all fail to exist is dropped (except cmd/note).
add() {
  local lvl="$1" grp="$2" act="$3" extra="$4" desc="$5"; shift 5
  # DECLUTTER_SKIP_CMD=1 drops every external-command item (docker prune, apt
  # clean, brew cleanup…). The test suite sets it because those commands are NOT
  # contained by the fake $HOME: they hit the real daemon and the real system.
  if [ "${DECLUTTER_SKIP_CMD:-0}" = 1 ] && [ "$act" = cmd ]; then return 0; fi
  local joined="" p exists=0
  for p in "$@"; do
    [ -n "$p" ] || continue
    joined="${joined}${p}"$'\n'
    [ -e "$p" ] && exists=1
  done
  if [ "$exists" = 0 ] && [ "$act" != cmd ] && [ "$act" != note ]; then return 0; fi
  I_LEVEL+=("$lvl"); I_GROUP+=("$grp"); I_ACTION+=("$act")
  I_EXTRA+=("$extra"); I_DESC+=("$desc"); I_PATHS+=("$joined")
}

item_size_kb() {
  local i="$1" p tot=0 kb
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    [ -e "$p" ] || continue
    kb=$(size_kb "$p"); tot=$((tot + kb))
  done <<< "${I_PATHS[$i]}"
  printf '%s' "$tot"
}

selected() {
  local g="${I_GROUP[$1]}"
  if [ -n "${ONLY:-}" ]; then in_list "$g" "$ONLY" || return 1; fi
  if [ -n "${SKIP:-}" ]; then in_list "$g" "$SKIP" && return 1; fi
  return 0
}

# A misspelled group used to be indistinguishable from "nothing to clean".
validate_groups() {
  local list="$1" tok found g oldifs
  [ -n "$list" ] || return 0
  # Split the comma list into $@, then put IFS back BEFORE the inner loop —
  # leaving IFS="," in scope makes $KNOWN_GROUPS one single token and every
  # group name look invalid.
  oldifs="$IFS"; IFS=','
  # shellcheck disable=SC2086
  set -- $list
  IFS="$oldifs"
  for tok in "$@"; do
    [ -n "$tok" ] || continue
    found=0
    for g in $KNOWN_GROUPS; do [ "$g" = "$tok" ] && { found=1; break; }; done
    if [ "$found" = 0 ]; then
      # shellcheck disable=SC2059
      printf "$T_ERR_UNKNOWN_GROUP" "$tok" "$KNOWN_GROUPS" >&2
      exit 2
    fi
  done
}

# Load every module, then run the register_* hooks that apply to this OS.
# Sourcing a module only defines functions, so it is safe on either platform —
# the platform gate lives on the hook name (register_linux_*, register_mac_*).
register_all() {
  local m fn
  for m in "$DECLUTTER_ROOT"/modules/*.sh; do
    [ -f "$m" ] || continue
    # shellcheck disable=SC1090
    . "$m"
  done
  for fn in $(declare -F | awk '{print $3}' | grep '^register_' | sort); do
    case "$fn" in
      register_all) continue ;;
      register_linux_*) [ "$PLATFORM" = linux ] || continue ;;
      register_mac_*)   [ "$PLATFORM" = mac ]   || continue ;;
    esac
    "$fn"
  done
}

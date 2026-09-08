#!/usr/bin/env bash
# projects.sh — list heavy project artifacts. LISTS ONLY, never deletes:
# node_modules/target/.venv are things only you know are still in use.

scan_projects() {
  local root="${1:-$HOME}" name found tmp p kb total count
  # shellcheck disable=SC2059
  head1 "$(printf "$T_PROJ_HEAD" "$root")"
  say "${DIM}${T_PROJ_SCANNING}${R}"

  for name in node_modules target .venv venv .next dist build __pycache__ .aider.tags.cache.v3; do
    found=$(find "$root" -name "$name" -type d -prune 2>/dev/null | head -500)
    [ -n "$found" ] || continue
    tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/declutter.proj.$$")
    total=0; count=0
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      kb=$(du -sk "$p" 2>/dev/null | awk 'NR==1{print $1}')
      case "$kb" in ''|*[!0-9]*) kb=0 ;; esac
      total=$((total + kb)); count=$((count + 1))
      printf '%s\t%s\n' "$kb" "$p" >> "$tmp"
    done <<< "$found"
    # shellcheck disable=SC2059
    printf '\n  %s%s%s — %s %s\n' "$B" "$name" "$R" "$(human "$total")" \
      "$(printf "$T_PROJ_PLACES" "$count")"
    sort -rn "$tmp" 2>/dev/null | head -"${TOP:-15}" | while IFS=$'\t' read -r kb p; do
      printf '     %8s  %s\n' "$(human "$kb")" "$p"
    done
    rm -f "$tmp"
  done

  # shellcheck disable=SC2059
  printf '\n  %s%s%s\n' "$B" "$(printf "$T_PROJ_STALE" "${PROJ_DAYS:-60}")" "$R"
  printf '     find %s -name node_modules -type d -prune -mtime +%s -print\n' "$root" "${PROJ_DAYS:-60}"
  printf '  %s%s%s\n' "$DIM" "$T_PROJ_WARN" "$R"
}

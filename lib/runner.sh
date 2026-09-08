#!/usr/bin/env bash
# runner.sh — run the ticked items and report how much space came back.

run_selection() {
  local i idx before after delta done_n=0 failed=0
  selected_totals
  [ "$SEL_COUNT" -gt 0 ] || { say "$T_NONE_SELECTED"; return 0; }

  if [ "${DRY_RUN:-0}" = 1 ]; then
    # shellcheck disable=SC2059
    head1 "$(printf "$T_DRYRUN_HEAD" "$LOG")"
  else
    # shellcheck disable=SC2059
    head1 "$(printf "$T_CLEANING" "$SEL_COUNT" "$(human "$SEL_KB")")"
  fi

  before=$(free_kb)
  for ((i=0; i<${#ORDER[@]}; i++)); do
    [ "${SEL[$i]}" = 1 ] || continue
    idx="${ORDER[$i]}"
    printf '  %s %8s  %s' "$(lvl_icon "${I_LEVEL[$idx]}")" \
           "$(human "${ROW_KB[$i]}")" "${I_DESC[$idx]}"
    # `cmd` items hand control to an external tool that can take minutes
    # (`uv cache clean` and `brew cleanup` walk a lot of small files). Print a
    # marker first, so a slow command reads as "working" rather than "hung".
    [ "${I_ACTION[$idx]}" = cmd ] && printf '  %s%s%s' "$DIM" "$T_CMD_RUNNING" "$R"
    if run_item "$idx"; then
      printf '  %s✓%s\n' "$C_G" "$R"; done_n=$((done_n+1))
    else
      if [ "$RUN_FAIL_KIND" = cmd ]; then
        printf '  %s%s%s\n' "$C_R" "$T_CMD_FAILED" "$R"
      else
        printf '  %s%s%s\n' "$C_Y" "$T_PARTIAL" "$R"
      fi
      done_n=$((done_n+1)); failed=$((failed+1))
    fi
  done
  after=$(free_kb)

  delta=$((after - before)); [ "$delta" -lt 0 ] && delta=0
  head1 "$T_RESULT"
  # shellcheck disable=SC2059
  printf "$T_ITEMS_DONE" "$done_n"
  # shellcheck disable=SC2059
  [ "$failed" -gt 0 ] && printf "$T_ITEMS_DENIED" "$failed"
  printf '\n'
  if [ "${DRY_RUN:-0}" = 1 ]; then
    # shellcheck disable=SC2059
    printf "$T_DRYRUN_TAIL" "$LOG"
  else
    # shellcheck disable=SC2059
    printf "$T_DISK_LINE" \
      "$(human "$before")" "$(human "$after")" "$B" "$(human "$delta")" "$R"
    # shellcheck disable=SC2059
    printf "$T_LOG_LINE" "$LOG"
  fi
  logline "freed=$(human "$delta") items=$done_n"
}

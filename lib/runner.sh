#!/usr/bin/env bash
# runner.sh — chạy các mục đã được tick và báo cáo dung lượng giải phóng.

run_selection() {
  local i idx before after delta done_n=0 failed=0
  selected_totals
  [ "$SEL_COUNT" -gt 0 ] || { say "Không có mục nào được chọn."; return 0; }

  if [ "${DRY_RUN:-0}" = 1 ]; then
    head1 "DRY RUN — không xóa gì, chỉ ghi ra $LOG"
  else
    head1 "Đang dọn $SEL_COUNT mục ($(human "$SEL_KB"))"
  fi

  before=$(free_kb)
  for ((i=0; i<${#ORDER[@]}; i++)); do
    [ "${SEL[$i]}" = 1 ] || continue
    idx="${ORDER[$i]}"
    printf '  %s %8s  %s' "$(lvl_icon "${I_LEVEL[$idx]}")" \
           "$(human "${ROW_KB[$i]}")" "${I_DESC[$idx]}"
    if run_item "$idx"; then printf '  %s✓%s\n' "$C_G" "$R"; done_n=$((done_n+1))
    else printf '  %s✓ (một phần bị từ chối)%s\n' "$C_Y" "$R"; done_n=$((done_n+1)); failed=$((failed+1)); fi
  done
  after=$(free_kb)

  delta=$((after - before)); [ "$delta" -lt 0 ] && delta=0
  head1 "Kết quả"
  printf '  %d mục đã xử lý' "$done_n"
  [ "$failed" -gt 0 ] && printf ' (%d mục có phần bị từ chối quyền)' "$failed"
  printf '\n'
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '  Dry run — chưa xóa gì. Xem %s để biết nó ĐỊNH làm gì.\n' "$LOG"
  else
    printf '  Ổ /: %s trống → %s trống   (%s+%s%s)\n' \
      "$(human "$before")" "$(human "$after")" "$B" "$(human "$delta")" "$R"
    printf '  Log: %s\n' "$LOG"
  fi
  logline "freed=$(human "$delta") items=$done_n"
}

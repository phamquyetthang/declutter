#!/usr/bin/env bash
# ui.sh — danh sách chọn tương tác (checkbox) chạy trên bash 3.2, không cần thư viện.
#
# Quy tắc chọn mặc định:
#   green  → tick sẵn
#   yellow → bỏ tick, người dùng tự bật
#   red    → KHÔNG tick được, chỉ hiển thị để biết mà tự xử lý

# Thứ tự hiển thị: theo nhãn an toàn, trong mỗi nhãn thì nặng nhất lên trên.
# Kết quả nằm ở mảng ORDER (chứa index của I_*).
ORDER=(); SEL=(); ROW_KB=()

build_order() {
  local n=${#I_LEVEL[@]} i kb rank tmp
  tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/declutter.order.$$")
  for ((i=0; i<n; i++)); do
    selected "$i" || continue
    kb=$(item_size_kb "$i")
    # mục cmd không đo được vẫn giữ lại (vd: docker prune, apt autoremove)
    if [ "$kb" = 0 ] && [ "${I_ACTION[$i]}" != cmd ]; then continue; fi
    rank=$(lvl_rank "${I_LEVEL[$i]}")
    printf '%d\t%012d\t%d\t%d\n' "$rank" "$kb" "$i" "$kb" >> "$tmp"
  done
  ORDER=(); ROW_KB=(); SEL=()
  if [ -s "$tmp" ]; then
    while IFS=$'\t' read -r _rank _pad idx kb; do
      ORDER+=("$idx"); ROW_KB+=("$kb")
      if [ "${I_LEVEL[$idx]}" = green ]; then SEL+=(1); else SEL+=(0); fi
    done < <(sort -k1,1n -k2,2rn "$tmp")
  fi
  rm -f "$tmp"
}

selected_totals() { # -> đặt SEL_COUNT, SEL_KB
  local i; SEL_COUNT=0; SEL_KB=0
  for ((i=0; i<${#ORDER[@]}; i++)); do
    [ "${SEL[$i]}" = 1 ] || continue
    SEL_COUNT=$((SEL_COUNT+1)); SEL_KB=$((SEL_KB + ROW_KB[i]))
  done
}

_term_lines() { local l; l=$(tput lines 2>/dev/null); case "$l" in ''|*[!0-9]*) l=24 ;; esac; printf '%s' "$l"; }

_row_line() { # $1 = vị trí trong ORDER, $2 = 1 nếu là dòng con trỏ
  local i cur idx mark box ptr
  i="$1"; cur="$2"; idx="${ORDER[$i]}"
  case "${I_LEVEL[$idx]}" in
    green)  mark="${C_G}o${R}" ;;
    yellow) mark="${C_Y}!${R}" ;;
    *)      mark="${C_R}x${R}" ;;
  esac
  if [ "${I_LEVEL[$idx]}" = red ]; then box="  - "
  elif [ "${SEL[$i]}" = 1 ];       then box="[${C_G}x${R}]"
  else                                  box="[ ]"; fi
  if [ "$cur" = 1 ]; then ptr="${B}>${R}"; else ptr=" "; fi

  local sz
  if [ "${ROW_KB[$i]}" -gt 0 ]; then sz="$(human "${ROW_KB[$i]}")"
  else sz="—"; fi                       # lệnh (docker prune, apt clean…) không đo trước được

  printf '%s %s %s %s  %s %s%s%s\n' \
    "$ptr" "$box" "$mark" "$(padl "$sz" 7)" "$(pad "${I_DESC[$idx]}" 46)" \
    "$DIM" "${I_GROUP[$idx]}" "$R"
}

print_plain_list() {   # không phải TTY: in ra rồi thôi
  local i
  printf '\n    %-3s %-3s %s  %s %s\n' "sel" "lvl" "$(padl "size" 7)" "$(pad "mục" 46)" "nhóm"
  for ((i=0; i<${#ORDER[@]}; i++)); do _row_line "$i" 0; done
  selected_totals
  printf '\n  Tick sẵn: %d mục — %s\n' "$SEL_COUNT" "$(human "$SEL_KB")"
}

# Trả về 0 nếu người dùng bấm Enter để chạy, 1 nếu thoát.
pick_interactive() {
  local total=${#ORDER[@]} cur=0 top=0 key rest rows visible
  [ "$total" -gt 0 ] || return 1

  printf '\033[?25l'                       # ẩn con trỏ
  trap 'printf "\033[?25h\n"' EXIT INT TERM

  while :; do
    rows=$(_term_lines); visible=$((rows - 11)); [ "$visible" -lt 5 ] && visible=5
    [ "$cur" -lt "$top" ] && top=$cur
    [ "$cur" -ge $((top + visible)) ] && top=$((cur - visible + 1))

    printf '\033[H\033[2J'
    printf '%sdeclutter%s  —  %s  —  %s trống trên /\n' \
      "$B$C_C" "$R" "$PLATFORM" "$(human "$(free_kb)")"
    printf '%s%s%s\n' "$DIM" \
      "o = an toàn (tick sẵn)   ! = cân nhắc   x = tự quyết, không chọn được" "$R"
    printf '%s\n' "────────────────────────────────────────────────────────────────────────────"

    local i end=$((top + visible)); [ "$end" -gt "$total" ] && end=$total
    for ((i=top; i<end; i++)); do
      if [ "$i" = "$cur" ]; then _row_line "$i" 1; else _row_line "$i" 0; fi
    done
    [ "$end" -lt "$total" ] && printf '%s   … còn %d mục nữa%s\n' "$DIM" $((total - end)) "$R"

    selected_totals
    printf '%s\n' "────────────────────────────────────────────────────────────────────────────"
    printf '  Đã chọn: %s%d mục — %s%s\n' "$B" "$SEL_COUNT" "$(human "$SEL_KB")" "$R"
    printf '%s  [↑↓/jk] di chuyển   [space] chọn   [a] đảo tất cả   [o] chỉ an toàn\n' "$DIM"
    printf '  [n] bỏ hết   [enter] DỌN   [q] thoát%s\n' "$R"

    IFS= read -rsn1 key </dev/tty || { printf '\033[?25h'; return 1; }
    case "$key" in
      $'\033')
        IFS= read -rsn2 rest </dev/tty
        case "$rest" in
          '[A') [ "$cur" -gt 0 ] && cur=$((cur-1)) ;;
          '[B') [ "$cur" -lt $((total-1)) ] && cur=$((cur+1)) ;;
        esac ;;
      k) [ "$cur" -gt 0 ] && cur=$((cur-1)) ;;
      j) [ "$cur" -lt $((total-1)) ] && cur=$((cur+1)) ;;
      ' ')
        local idx="${ORDER[$cur]}"
        if [ "${I_LEVEL[$idx]}" != red ]; then
          if [ "${SEL[$cur]}" = 1 ]; then SEL[$cur]=0; else SEL[$cur]=1; fi
        fi ;;
      a)
        for ((i=0; i<total; i++)); do
          [ "${I_LEVEL[${ORDER[$i]}]}" = red ] && continue
          if [ "${SEL[$i]}" = 1 ]; then SEL[$i]=0; else SEL[$i]=1; fi
        done ;;
      o)
        for ((i=0; i<total; i++)); do
          if [ "${I_LEVEL[${ORDER[$i]}]}" = green ]; then SEL[$i]=1; else SEL[$i]=0; fi
        done ;;
      n) for ((i=0; i<total; i++)); do SEL[$i]=0; done ;;
      q|Q) printf '\033[?25h'; return 1 ;;
      '')  printf '\033[?25h'; return 0 ;;
    esac
  done
}

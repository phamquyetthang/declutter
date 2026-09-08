#!/usr/bin/env bash
# ui.sh — danh sách chọn tương tác (checkbox) chạy trên bash 3.2, không cần thư viện.
#
# Quy tắc chọn mặc định:
#   green  → tick sẵn
#   yellow → bỏ tick, người dùng tự bật
#   red    → KHÔNG tick được, chỉ hiển thị để biết mà tự xử lý

# Thứ tự hiển thị: theo nhãn an toàn, trong mỗi nhãn thì nặng nhất lên trên.
# Kết quả nằm ở mảng ORDER (chứa index của I_*).
ORDER=(); SEL=(); ROW_KB=(); ROW_SZ=()

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
  ORDER=(); ROW_KB=(); SEL=(); ROW_SZ=()
  if [ -s "$tmp" ]; then
    while IFS=$'\t' read -r _rank _pad idx kb; do
      ORDER+=("$idx"); ROW_KB+=("$kb")
      # Format ngay ở đây, một lần. human() gọi awk — không được để nó nằm
      # trong vòng vẽ (mỗi frame × mỗi dòng = hàng chục process → nháy màn hình).
      if [ "$kb" -gt 0 ]; then ROW_SZ+=("$(human "$kb")"); else ROW_SZ+=("—"); fi
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


# Dựng một dòng vào $ROW_OUT (không in ra) — dùng chung cho cả vẽ và --report.
ROW_OUT=""
_row_line() { # $1 = vị trí trong ORDER, $2 = 1 nếu là dòng con trỏ
  local i cur idx mark box ptr sz desc
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

  padl "${ROW_SZ[$i]}" 7; sz="$PAD_OUT"
  pad  "${I_DESC[$idx]}" 46; desc="$PAD_OUT"
  ROW_OUT="$ptr $box $mark $sz  $desc ${DIM}${I_GROUP[$idx]}${R}"
}

print_plain_list() {   # không phải TTY: in ra rồi thôi
  local i h1 h2
  padl "size" 7; h1="$PAD_OUT"
  pad  "mục"  46; h2="$PAD_OUT"
  printf '\n    %-3s %-3s %s  %s %s\n' "sel" "lvl" "$h1" "$h2" "nhóm"
  for ((i=0; i<${#ORDER[@]}; i++)); do _row_line "$i" 0; printf '%s\n' "$ROW_OUT"; done
  selected_totals
  printf '\n  Tick sẵn: %d mục — %s\n' "$SEL_COUNT" "$(human "$SEL_KB")"
}

# Trả về 0 nếu người dùng bấm Enter để chạy, 1 nếu thoát.
#
# Chống nháy: KHÔNG dùng \033[2J (xóa sạch màn hình rồi vẽ lại = nháy).
# Thay vào đó dựng nguyên frame vào một chuỗi rồi ghi MỘT lần, đưa con trỏ về
# góc bằng \033[H, mỗi dòng tự xóa phần thừa bằng \033[K, cuối frame xóa phần
# còn lại bằng \033[J. Dùng thêm alternate screen để không phá scrollback.
pick_interactive() {
  local total=${#ORDER[@]} cur=0 top=0 key rest rows visible i end frame free_h idx
  [ "$total" -gt 0 ] || return 1

  rows=$(tput lines 2>/dev/null); case "$rows" in ''|*[!0-9]*) rows=24 ;; esac
  free_h="$(human "$(free_kb)")"          # đo 1 lần, không gọi df mỗi frame

  _ui_restore() { printf '\033[?25h\033[?1049l'; }   # hiện con trỏ, rời alt screen
  printf '\033[?1049h\033[?25l'
  trap '_ui_restore' EXIT INT TERM
  trap 'rows=$(tput lines 2>/dev/null); case "$rows" in ""|*[!0-9]*) rows=24 ;; esac' WINCH

  local SEP="────────────────────────────────────────────────────────────────────────────"
  local HDR2="o = an toàn (tick sẵn)   ! = cân nhắc   x = tự quyết, không chọn được"

  while :; do
    visible=$((rows - 11)); [ "$visible" -lt 5 ] && visible=5
    [ "$cur" -lt "$top" ] && top=$cur
    [ "$cur" -ge $((top + visible)) ] && top=$((cur - visible + 1))
    end=$((top + visible)); [ "$end" -gt "$total" ] && end=$total

    frame=$'\033[H'
    frame="$frame${B}${C_C}declutter${R}  —  $PLATFORM  —  $free_h trống trên /"$'\033[K\n'
    frame="$frame${DIM}${HDR2}${R}"$'\033[K\n'
    frame="$frame$SEP"$'\033[K\n'

    for ((i=top; i<end; i++)); do
      if [ "$i" = "$cur" ]; then _row_line "$i" 1; else _row_line "$i" 0; fi
      frame="$frame$ROW_OUT"$'\033[K\n'
    done
    if [ "$end" -lt "$total" ]; then
      frame="$frame${DIM}   … còn $((total - end)) mục nữa${R}"$'\033[K\n'
    else
      frame="$frame"$'\033[K\n'
    fi

    selected_totals
    frame="$frame$SEP"$'\033[K\n'
    frame="$frame  Đã chọn: ${B}${SEL_COUNT} mục — $(human "$SEL_KB")${R}"$'\033[K\n'
    frame="$frame${DIM}  [↑↓/jk] di chuyển   [space] chọn   [a] đảo tất cả   [o] chỉ an toàn"$'\033[K\n'
    frame="$frame  [n] bỏ hết   [enter] DỌN   [q] thoát${R}"$'\033[K\n'
    frame="$frame"$'\033[J'

    printf '%s' "$frame"          # một lần ghi duy nhất cho cả khung hình

    IFS= read -rsn1 key </dev/tty || { trap - EXIT INT TERM; _ui_restore; return 1; }
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
        idx="${ORDER[$cur]}"
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
      q|Q) trap - EXIT INT TERM; _ui_restore; return 1 ;;
      '')  trap - EXIT INT TERM; _ui_restore; return 0 ;;
    esac
  done
}

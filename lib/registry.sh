#!/usr/bin/env bash
# registry.sh — kho các mục dọn dẹp. Mảng song song vì bash 3.2 không có mảng kết hợp.

I_LEVEL=(); I_GROUP=(); I_DESC=(); I_ACTION=(); I_EXTRA=(); I_PATHS=()

# add LEVEL GROUP ACTION EXTRA "mô tả" [path...]
#
#   LEVEL : green | yellow | red
#   ACTION: rm      xóa các path
#           rmchild xóa nội dung bên trong path (giữ thư mục)
#           findrm  EXTRA="maxdepth|pattern"
#           agerm   EXTRA="days|pattern"  (chỉ xóa mục cũ hơn N ngày)
#           cmd     EXTRA là lệnh shell; path chỉ dùng để đo dung lượng
#           note    chỉ báo cáo, không bao giờ xóa
#
# Mục mà không path nào tồn tại sẽ bị bỏ qua (trừ cmd/note).
add() {
  local lvl="$1" grp="$2" act="$3" extra="$4" desc="$5"; shift 5
  # DECLUTTER_SKIP_CMD=1 → bỏ hẳn các mục chạy lệnh ngoài (docker prune, apt clean,
  # brew cleanup…). Test dùng cờ này vì những lệnh đó KHÔNG bị $HOME sandbox chặn:
  # chúng tác động lên daemon/hệ thống thật.
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

# Nạp mọi module hợp lệ với hệ điều hành hiện tại
register_all() {
  local m
  for m in "$DECLUTTER_ROOT"/modules/*.sh; do
    [ -f "$m" ] || continue
    case "$(basename "$m")" in
      os-linux.sh|xcode.sh) [ "$PLATFORM" = linux ] || { [ "$(basename "$m")" = os-linux.sh ] && continue; } ;;
    esac
    # shellcheck disable=SC1090
    . "$m"
  done
  local fn
  for fn in $(declare -F | awk '{print $3}' | grep '^register_' | sort); do
    case "$fn" in
      register_all) continue ;;
      register_linux_*) [ "$PLATFORM" = linux ] || continue ;;
      register_mac_*)   [ "$PLATFORM" = mac ]   || continue ;;
    esac
    "$fn"
  done
}

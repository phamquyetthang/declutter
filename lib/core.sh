#!/usr/bin/env bash
# core.sh — hằng số, màu sắc, tiện ích đo dung lượng, log. Tương thích bash 3.2.

DECLUTTER_VERSION="1.0.0"

OS_NAME="$(uname -s)"
case "$OS_NAME" in
  Linux)  PLATFORM=linux ;;
  Darwin) PLATFORM=mac ;;
  *)      PLATFORM=other ;;
esac

# Cho phép test trỏ /tmp sang chỗ khác (xem tests/run.sh)
TMP_ROOT="${DECLUTTER_TMP_ROOT:-/tmp}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[0m'
  C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_C=$'\033[36m'
else
  B=""; DIM=""; R=""; C_G=""; C_Y=""; C_R=""; C_C=""
fi

say()   { [ "${QUIET:-0}" = 1 ] || printf '%s\n' "$*"; }
head1() { [ "${QUIET:-0}" = 1 ] || printf '\n%s%s%s\n' "$B$C_C" "$*" "$R"; }
die()   { printf '%s\n' "$*" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

# du -sk → KB (0 nếu không tồn tại). An toàn với path có dấu cách.
size_kb() {
  local total=0 p kb
  for p in "$@"; do
    [ -e "$p" ] || continue
    kb=$(du -sk "$p" 2>/dev/null | awk 'NR==1{print $1}')
    case "$kb" in ''|*[!0-9]*) kb=0 ;; esac
    total=$((total + kb))
  done
  printf '%s' "$total"
}

# KB -> chuỗi người đọc được. Viết thuần bash, KHÔNG gọi awk:
#  - awk in "1,3G" theo locale vi_VN (phải ép LC_NUMERIC=C mới đúng)
#  - và mỗi lời gọi là một process; hàm này chạy trong vòng vẽ nên phải rẻ.
human() {
  local k="$1" t
  case "$k" in ''|*[!0-9]*) k=0 ;; esac
  if [ "$k" -ge 1048576 ]; then
    t=$(( (k * 10 + 524288) / 1048576 ))      # phần mười GB, làm tròn
    printf '%s.%sG' "$((t / 10))" "$((t % 10))"
  elif [ "$k" -ge 1024 ]; then
    printf '%sM' "$(( (k + 512) / 1024 ))"
  else
    printf '%sK' "$k"
  fi
}

# Cắt/đệm chuỗi theo KÝ TỰ chứ không theo byte — printf "%-46.46s" sẽ cắt
# giữa một ký tự UTF-8 và làm vỡ tiếng Việt.
# pad/padl đặt kết quả vào $PAD_OUT thay vì in ra stdout.
# Lý do: vòng vẽ gọi chúng cho từng dòng, mỗi lần bấm phím. Dùng $(pad …) sẽ
# fork một subshell cho mỗi ô → hàng chục process mỗi frame → giật và nháy.
PAD_OUT=""

# Căn phải theo ký tự ("—" là 3 byte nhưng 1 ký tự nên %8s của printf sai)
padl() {
  local s="$1" w="$2" n
  n=${#s}          # phải tách dòng: bash expand hết đối số của `local` TRƯỚC khi gán
  while [ "$n" -lt "$w" ]; do s=" $s"; n=$((n+1)); done
  PAD_OUT="$s"
}

# Căn trái + cắt theo ký tự
pad() {
  local s="$1" w="$2" n
  n=${#s}
  if [ "$n" -gt "$w" ]; then s="${s:0:$((w-1))}…"; n="$w"; fi
  while [ "$n" -lt "$w" ]; do s="$s "; n=$((n+1)); done
  PAD_OUT="$s"
}

free_kb() { df -k / 2>/dev/null | awk 'NR==2{print $4}'; }

lvl_icon() {
  case "$1" in
    green)  printf '%s[OK]%s' "$C_G" "$R" ;;
    yellow) printf '%s[!!]%s' "$C_Y" "$R" ;;
    *)      printf '%s[XX]%s' "$C_R" "$R" ;;
  esac
}
lvl_rank() { case "$1" in green) echo 1 ;; yellow) echo 2 ;; *) echo 3 ;; esac; }

in_list() { local IFS=','; local x; for x in $2; do [ "$x" = "$1" ] && return 0; done; return 1; }

# ── sudo ───────────────────────────────────────────────────────────────────
SUDO=""
setup_sudo() {
  case "${USE_SUDO:-auto}" in
    no)  SUDO="" ; return ;;
    yes) SUDO="sudo"; return ;;
  esac
  if [ "$(id -u)" = 0 ]; then SUDO=""
  elif have sudo && sudo -n true 2>/dev/null; then SUDO="sudo"
  else SUDO=""; fi
}

# ── log ────────────────────────────────────────────────────────────────────
LOG_STARTED=0
logline() {
  [ -n "${LOG:-}" ] || return 0
  if [ "$LOG_STARTED" = 0 ]; then
    printf '\n===== %s  declutter %s  level=%s =====\n' \
      "$(date '+%F %T')" "$DECLUTTER_VERSION" "${LEVEL:-green}" >> "$LOG" 2>/dev/null
    LOG_STARTED=1
  fi
  printf '%s\n' "$*" >> "$LOG" 2>/dev/null
}

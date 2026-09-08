#!/usr/bin/env bash
# core.sh — constants, colors, size measurement, logging. bash 3.2 compatible.

DECLUTTER_VERSION="1.1.0"

OS_NAME="$(uname -s)"
case "$OS_NAME" in
  Linux)  PLATFORM=linux ;;
  Darwin) PLATFORM=mac ;;
  *)      PLATFORM=other ;;
esac

# Lets the test suite point /tmp somewhere else (see tests/run.sh)
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

# du -sk -> KB (0 when the path is missing). Safe with spaces in paths.
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

# KB -> human string. Pure bash, deliberately NOT awk:
#  - awk prints "1,3G" under a vi_VN locale (only LC_NUMERIC=C fixes that)
#  - and every call is a process; this runs inside the draw loop, so it has to
#    stay cheap.
human() {
  local k="$1" t
  case "$k" in ''|*[!0-9]*) k=0 ;; esac
  if [ "$k" -ge 1048576 ]; then
    t=$(( (k * 10 + 524288) / 1048576 ))      # tenths of a GB, rounded
    printf '%s.%sG' "$((t / 10))" "$((t % 10))"
  elif [ "$k" -ge 1024 ]; then
    printf '%sM' "$(( (k + 512) / 1024 ))"
  else
    printf '%sK' "$k"
  fi
}

# Pad/truncate by CHARACTER, not by byte — printf "%-46.46s" cuts a multi-byte
# UTF-8 character in half and breaks Vietnamese (and any accented) text.
# pad/padl write to $PAD_OUT instead of stdout: the draw loop calls them once
# per cell per keypress, and $(pad …) would fork a subshell each time — dozens
# of processes per frame, which is exactly what made the list flicker.
PAD_OUT=""

# Right-align by character ("—" is 3 bytes but 1 character, so printf %8s lies)
padl() {
  local s="$1" w="$2" n
  n=${#s}          # separate line on purpose: bash expands every argument of
                   # `local` BEFORE assigning any of them
  while [ "$n" -lt "$w" ]; do s=" $s"; n=$((n+1)); done
  PAD_OUT="$s"
}

# Left-align, truncating by character
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
# The log is written in English regardless of --lang: it is a machine record,
# and it is what people paste into bug reports.
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

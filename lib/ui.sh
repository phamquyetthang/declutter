#!/usr/bin/env bash
# ui.sh — the interactive checkbox list. Runs on bash 3.2, no libraries.
#
# Default selection rules:
#   green  -> pre-ticked
#   yellow -> not ticked, you turn it on
#   red    -> CANNOT be ticked, shown so you know it is there and can deal with
#             it yourself

# Display order: by safety tier, and inside a tier the biggest first.
# The result lives in ORDER (indexes into the I_* arrays).
ORDER=(); SEL=(); ROW_KB=(); ROW_SZ=()

build_order() {
  local n=${#I_LEVEL[@]} i kb rank tmp
  tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/declutter.order.$$")
  for ((i=0; i<n; i++)); do
    selected "$i" || continue
    kb=$(item_size_kb "$i")
    # Keep unmeasurable items: `cmd` (docker prune, apt autoremove) has nothing
    # to size, and `note` is an advisory that must show up even at 0 KB — that
    # is how the Docker-volume and "needs sudo" warnings reach the user.
    if [ "$kb" = 0 ] && [ "${I_ACTION[$i]}" != cmd ] && [ "${I_ACTION[$i]}" != note ]; then
      continue
    fi
    rank=$(lvl_rank "${I_LEVEL[$i]}")
    printf '%d\t%012d\t%d\t%d\n' "$rank" "$kb" "$i" "$kb" >> "$tmp"
  done
  ORDER=(); ROW_KB=(); SEL=(); ROW_SZ=()
  if [ -s "$tmp" ]; then
    while IFS=$'\t' read -r _rank _pad idx kb; do
      ORDER+=("$idx"); ROW_KB+=("$kb")
      # Format once, here. Never inside the draw loop: one subshell per row per
      # frame is dozens of processes a second, and the list visibly flickers.
      if [ "$kb" -gt 0 ]; then ROW_SZ+=("$(human "$kb")"); else ROW_SZ+=("—"); fi
      if [ "${I_LEVEL[$idx]}" = green ]; then SEL+=(1); else SEL+=(0); fi
    done < <(sort -k1,1n -k2,2rn "$tmp")
  fi
  rm -f "$tmp"
}

selected_totals() { # -> sets SEL_COUNT, SEL_KB
  local i; SEL_COUNT=0; SEL_KB=0
  for ((i=0; i<${#ORDER[@]}; i++)); do
    [ "${SEL[$i]}" = 1 ] || continue
    SEL_COUNT=$((SEL_COUNT+1)); SEL_KB=$((SEL_KB + ROW_KB[i]))
  done
}


# Build one row into $ROW_OUT (without printing) — shared by the draw loop and
# by --report.
ROW_OUT=""
_row_line() { # $1 = position in ORDER, $2 = 1 when this is the cursor row
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

print_plain_list() {   # not a TTY: print and be done
  local i h1 h2
  padl "$T_HDR_SIZE" 7; h1="$PAD_OUT"
  pad  "$T_HDR_ITEM" 46; h2="$PAD_OUT"
  printf '\n    %-3s %-3s %s  %s %s\n' "$T_HDR_SEL" "$T_HDR_LVL" "$h1" "$h2" "$T_HDR_GROUP"
  for ((i=0; i<${#ORDER[@]}; i++)); do _row_line "$i" 0; printf '%s\n' "$ROW_OUT"; done
  selected_totals
  # shellcheck disable=SC2059
  printf "$T_PRETICKED" "$SEL_COUNT" "$(human "$SEL_KB")"
}

# Returns 0 if the user pressed Enter to run, 1 if they quit.
#
# Flicker-free by construction: no \033[2J (wiping the screen then repainting is
# the flicker). Instead the whole frame is built into one string and written
# once, the cursor goes home with \033[H, each line erases its own tail with
# \033[K, and the frame ends by erasing the rest with \033[J. The alternate
# screen keeps the user's scrollback intact.
pick_interactive() {
  local total=${#ORDER[@]} cur=0 top=0 key rest rows visible i end frame free_h idx
  [ "$total" -gt 0 ] || return 1

  rows=$(tput lines 2>/dev/null); case "$rows" in ''|*[!0-9]*) rows=24 ;; esac
  free_h="$(human "$(free_kb)")"          # measured once, not per frame

  _ui_restore() { printf '\033[?25h\033[?1049l'; }   # cursor back, leave alt screen
  printf '\033[?1049h\033[?25l'
  trap '_ui_restore' EXIT INT TERM
  trap 'rows=$(tput lines 2>/dev/null); case "$rows" in ""|*[!0-9]*) rows=24 ;; esac' WINCH

  local SEP="────────────────────────────────────────────────────────────────────────────"

  while :; do
    visible=$((rows - 11)); [ "$visible" -lt 5 ] && visible=5
    [ "$cur" -lt "$top" ] && top=$cur
    [ "$cur" -ge $((top + visible)) ] && top=$((cur - visible + 1))
    end=$((top + visible)); [ "$end" -gt "$total" ] && end=$total

    frame=$'\033[H'
    frame="$frame${B}${C_C}declutter${R}  —  $PLATFORM  —  $free_h $T_FREE_ON"$'\033[K\n'
    frame="$frame${DIM}${T_LEGEND}${R}"$'\033[K\n'
    frame="$frame$SEP"$'\033[K\n'

    for ((i=top; i<end; i++)); do
      if [ "$i" = "$cur" ]; then _row_line "$i" 1; else _row_line "$i" 0; fi
      frame="$frame$ROW_OUT"$'\033[K\n'
    done
    if [ "$end" -lt "$total" ]; then
      # shellcheck disable=SC2059
      frame="$frame${DIM}$(printf "$T_MORE_ROWS" "$((total - end))")${R}"$'\033[K\n'
    else
      frame="$frame"$'\033[K\n'
    fi

    selected_totals
    frame="$frame$SEP"$'\033[K\n'
    frame="$frame$T_SELECTED${B}${SEL_COUNT} $T_ITEMS — $(human "$SEL_KB")${R}"$'\033[K\n'
    frame="$frame${DIM}${T_KEYS1}"$'\033[K\n'
    frame="$frame${T_KEYS2}${R}"$'\033[K\n'
    frame="$frame"$'\033[J'

    printf '%s' "$frame"          # a single write for the entire frame

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

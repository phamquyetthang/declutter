#!/usr/bin/env bash
# report.sh — machine-readable output. `declutter --json` prints the same list
# the interactive picker would show, so a script or an agent can decide what to
# clean without ever driving the TUI.
#
# Contract (stable from 1.1.0 on): a single JSON object with
#   version, platform, lang, level, free_kb/free_human, items[], totals{}
# Every item carries level/group/action/desc/size_kb/paths plus the two booleans
# that matter: `selectable` (false for red) and `preselected`.

_json_str() {   # -> $JSON_OUT, escaped per RFC 8259 (UTF-8 passes through as is)
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\n'/\\n}"
  JSON_OUT="$s"
}

print_json() {
  local i idx n p first_p sel_c sel_kb
  printf '{\n'
  _json_str "$DECLUTTER_VERSION"; printf '  "version": "%s",\n' "$JSON_OUT"
  printf '  "platform": "%s",\n' "$PLATFORM"
  printf '  "lang": "%s",\n' "$DECLUTTER_LC"
  printf '  "level": "%s",\n' "${LEVEL:-green}"
  printf '  "dry_run": %s,\n' "$([ "${DRY_RUN:-0}" = 1 ] && printf true || printf false)"
  n=$(free_kb)
  printf '  "free_kb": %s,\n' "${n:-0}"
  printf '  "free_human": "%s",\n' "$(human "${n:-0}")"
  printf '  "items": [\n'
  for ((i=0; i<${#ORDER[@]}; i++)); do
    idx="${ORDER[$i]}"
    [ "$i" = 0 ] || printf ',\n'
    printf '    {'
    printf '"level": "%s", ' "${I_LEVEL[$idx]}"
    printf '"group": "%s", ' "${I_GROUP[$idx]}"
    printf '"action": "%s", ' "${I_ACTION[$idx]}"
    _json_str "${I_DESC[$idx]}";  printf '"desc": "%s", ' "$JSON_OUT"
    printf '"size_kb": %s, ' "${ROW_KB[$i]}"
    _json_str "${ROW_SZ[$i]}";    printf '"size_human": "%s", ' "$JSON_OUT"
    if [ "${I_LEVEL[$idx]}" = red ]; then printf '"selectable": false, '
    else printf '"selectable": true, '; fi
    if [ "${SEL[$i]}" = 1 ]; then printf '"preselected": true, '
    else printf '"preselected": false, '; fi
    printf '"paths": ['
    first_p=1
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      [ "$first_p" = 1 ] || printf ', '
      _json_str "$p"; printf '"%s"' "$JSON_OUT"
      first_p=0
    done <<< "${I_PATHS[$idx]}"
    printf ']}'
  done
  [ "${#ORDER[@]}" -eq 0 ] || printf '\n'
  printf '  ],\n'
  selected_totals
  sel_c="$SEL_COUNT"; sel_kb="$SEL_KB"
  printf '  "totals": {"items": %s, "preselected": %s, "preselected_kb": %s, "preselected_human": "%s"}\n' \
    "${#ORDER[@]}" "$sel_c" "$sel_kb" "$(human "$sel_kb")"
  printf '}\n'
}

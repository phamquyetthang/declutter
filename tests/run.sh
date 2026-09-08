#!/usr/bin/env bash
# tests/run.sh — run declutter against a fake $HOME and check that it deletes
# exactly what it should and never touches what it must not. No dependencies.
#
#   ./tests/run.sh
#
set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
check()      { if [ -e "$1" ]; then bad "$2 (still there: $1)"; else ok "$2"; fi; }
check_kept() { if [ -e "$1" ]; then ok "$2"; else bad "$2 (was deleted: $1)"; fi; }

SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
export HOME="$SB/home"
export DECLUTTER_TMP_ROOT="$SB/tmp"
export DECLUTTER_LOG="$SB/log"
export NO_COLOR=1
# REQUIRED: `cmd` items (docker prune, apt clean, brew cleanup) are not
# contained by the fake $HOME — they run against the real system. The tests only
# exercise the file-deleting half.
export DECLUTTER_SKIP_CMD=1
# Pin the language so assertions on output text do not depend on the host locale.
export DECLUTTER_LANG=en

mkdir -p "$HOME" "$DECLUTTER_TMP_ROOT"

# Run declutter, keeping the output so it can be printed if a test fails.
RUNC=0
dc() {
  RUNC=$((RUNC+1))
  printf '\n### run %d: declutter %s\n' "$RUNC" "$*" >> "$SB/runs.txt"
  "$ROOT/declutter" "$@" >> "$SB/runs.txt" 2>&1
  printf '### exit=%d\n' "$?" >> "$SB/runs.txt"
}
mk() { mkdir -p "$(dirname "$1")"; mkdir -p "$1"; head -c "${2:-4096}" /dev/urandom > "$1/blob.bin"; }

# ── junk that must go at the green tier ─────────────────────────────────────
mk "$HOME/.claude/shell-snapshots"
mk "$HOME/.claude/statsig"
mk "$HOME/.cache/claude-cli-nodejs"
mk "$HOME/.codex/cache"
mk "$HOME/.gemini/tmp"
mk "$HOME/.cursor/ai-tracking"
mk "$HOME/.config/Code/Cache"
mk "$HOME/.config/Code/CachedExtensionVSIXs"
mk "$HOME/.npm/_npx"
mk "$HOME/.cargo/registry/cache"
mk "$HOME/.gradle/caches/build-cache-1"
mk "$HOME/.cache/google-chrome/Default/Cache"
mk "$HOME/.nv/ComputeCache"

# ── yellow-tier junk: a green run must NOT touch it ─────────────────────────
mk "$HOME/.config/Code/WebStorage"
mk "$HOME/.cache/huggingface/hub"
mk "$HOME/.gradle/caches/modules-2"

# ── things that must NEVER be deleted ──────────────────────────────────────
mk "$HOME/.claude/skills"
mk "$HOME/.claude/projects"
echo '{"theme":"dark"}' > "$HOME/.claude/settings.json"
mk "$HOME/.config/Code/User/workspaceStorage"
mkdir -p "$HOME/.config/Code/User"; echo '{}' > "$HOME/.config/Code/User/settings.json"
mk "$HOME/.ssh"
mk "$HOME/.m2/repository"

# ── /tmp: an old session must go, a live one must stay ─────────────────────
mk "$DECLUTTER_TMP_ROOT/claude-old"
mk "$DECLUTTER_TMP_ROOT/claude-active"
touch -t 202001010000 "$DECLUTTER_TMP_ROOT/claude-old"

printf '\n\033[1m1) dry-run must not touch a single thing\033[0m\n'
dc --yes --dry-run -q
check_kept "$HOME/.claude/shell-snapshots" "dry-run leaves everything alone"
grep -q 'DRY' "$DECLUTTER_LOG" && ok "dry-run logs its plan" || bad "dry-run wrote no plan"

printf '\n\033[1m2) real run at the green tier\033[0m\n'
dc --yes -q

check "$HOME/.claude/shell-snapshots"          "deletes shell-snapshots"
check "$HOME/.claude/statsig"                  "deletes statsig"
check "$HOME/.cache/claude-cli-nodejs"         "deletes claude-cli cache"
check "$HOME/.codex/cache"                     "deletes Codex cache"
check "$HOME/.gemini/tmp"                      "deletes Gemini tmp"
check "$HOME/.cursor/ai-tracking"              "deletes Cursor ai-tracking"
check "$HOME/.config/Code/Cache"               "deletes VS Code Cache"
check "$HOME/.config/Code/CachedExtensionVSIXs" "deletes downloaded VSIX"
check "$HOME/.npm/_npx"                        "deletes npx cache"
check "$HOME/.cargo/registry/cache"            "deletes cargo registry cache"
check "$HOME/.gradle/caches/build-cache-1"     "deletes gradle build-cache (findrm)"
check "$HOME/.cache/google-chrome/Default/Cache" "deletes Chrome page cache (findrm depth 2)"
check "$HOME/.nv/ComputeCache"                 "deletes CUDA JIT cache"
check "$DECLUTTER_TMP_ROOT/claude-old"         "deletes old /tmp/claude-*"

printf '\n\033[1m3) the green tier must not touch the yellow tier\033[0m\n'
check_kept "$HOME/.config/Code/WebStorage"     "keeps WebStorage (yellow)"
check_kept "$HOME/.cache/huggingface/hub"      "keeps HuggingFace (yellow)"
check_kept "$HOME/.gradle/caches/modules-2"    "keeps gradle caches (yellow)"

printf '\n\033[1m4) user data is never touched\033[0m\n'
check_kept "$HOME/.claude/skills"              "keeps skills"
check_kept "$HOME/.claude/projects"            "keeps transcripts"
check_kept "$HOME/.claude/settings.json"       "keeps settings.json"
check_kept "$HOME/.config/Code/User/settings.json" "keeps VS Code settings"
check_kept "$HOME/.config/Code/User/workspaceStorage" "keeps workspaceStorage (red)"
check_kept "$HOME/.ssh"                        "keeps ~/.ssh"
check_kept "$HOME/.m2/repository"              "keeps Maven repo (red)"
check_kept "$DECLUTTER_TMP_ROOT/claude-active" "keeps the live claude session"

printf '\n\033[1m5) the yellow tier picks up the rest\033[0m\n'
dc --yes -l yellow -q
check "$HOME/.config/Code/WebStorage"          "yellow deletes WebStorage"
check "$HOME/.cache/huggingface/hub"           "yellow deletes HuggingFace"
check_kept "$HOME/.claude/skills"              "yellow still keeps skills"
check_kept "$HOME/.config/Code/User/workspaceStorage" "yellow still keeps red items"
check_kept "$HOME/.ssh"                        "yellow still keeps ~/.ssh"

printf '\n\033[1m6) --only / --skip filters\033[0m\n'
mk "$HOME/.codex/cache"; mk "$HOME/.gemini/cache"
dc --yes --only ai-cli --skip ai-cli -q
check_kept "$HOME/.codex/cache" "--skip beats --only"
dc --yes --only pkg-node -q
check_kept "$HOME/.codex/cache" "--only pkg-node leaves ai-cli alone"
if "$ROOT/declutter" --only ai-idea >/dev/null 2>&1; then
  bad "a misspelled group should exit non-zero"
else
  ok "a misspelled group is rejected"
fi

# Output is captured to a file, never piped straight into `grep -q`: grep -q
# exits at the first match, declutter then dies of SIGPIPE, and `set -o pipefail`
# turns that into a failed pipeline even though the text was there.
report_to() { "$ROOT/declutter" --report "$@" > "$SB/report.txt" 2>/dev/null; }
in_report() { grep -q "$1" "$SB/report.txt"; }

printf '\n\033[1m7) red advisories are reported, never deleted\033[0m\n'
report_to
if in_report 'Maven repo'; then
  ok "red note with a real path shows up"
else
  bad "red note with a real path is missing from --report"
fi
if in_report 'node_modules'; then
  ok "red note with no measurable path shows up"
else
  bad "red note with no measurable path is missing from --report"
fi

printf '\n\033[1m8) language selection\033[0m\n'
report_to --lang vi
if in_report 'Tick sẵn'; then
  ok "--lang vi renders Vietnamese"
else
  bad "--lang vi did not render Vietnamese"
fi
LANG=vi_VN.UTF-8 DECLUTTER_LANG= "$ROOT/declutter" --report > "$SB/report.txt" 2>/dev/null
if in_report 'Tick sẵn'; then
  ok "\$LANG=vi_VN is auto-detected"
else
  bad "\$LANG=vi_VN was not auto-detected"
fi
report_to --lang en
if in_report 'Pre-ticked'; then
  ok "--lang en renders English"
else
  bad "--lang en did not render English"
fi

printf '\n\033[1m9) --json is valid, parseable JSON\033[0m\n'
"$ROOT/declutter" --json > "$SB/out.json" 2>"$SB/out.err"
if [ -s "$SB/out.json" ]; then ok "--json produced output"; else bad "--json produced nothing"; fi
[ -s "$SB/out.err" ] && bad "--json wrote to stderr: $(head -1 "$SB/out.err")" \
                     || ok "--json keeps stderr clean"
if command -v python3 >/dev/null 2>&1; then
  if python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if ("items" in d and "totals" in d and d["version"]) else 1)' "$SB/out.json"; then
    ok "--json parses and carries version/items/totals"
  else
    bad "--json is not valid JSON or is missing keys"
  fi
  if python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if all(i["selectable"] is False for i in d["items"] if i["level"]=="red") else 1)' "$SB/out.json"; then
    ok "--json marks every red item unselectable"
  else
    bad "--json marked a red item selectable"
  fi
else
  ok "(python3 missing — skipped JSON parse check)"
fi

printf '\n\033[1m10) installer round trip\033[0m\n'
P="$SB/prefix"
if PREFIX="$P" "$ROOT/install.sh" >/dev/null 2>&1 && [ -L "$P/bin/declutter" ]; then
  ok "install.sh creates the symlink"
else
  bad "install.sh did not create $P/bin/declutter"
fi
if PREFIX="$P" "$ROOT/install.sh" --uninstall >/dev/null 2>&1 \
   && [ ! -e "$P/bin/declutter" ] && [ ! -d "$P/share/declutter" ]; then
  ok "install.sh --uninstall removes both"
else
  bad "install.sh --uninstall left something behind"
fi

printf '\n\033[1m11) every file parses\033[0m\n'
for f in "$ROOT/declutter" "$ROOT"/lib/*.sh "$ROOT"/modules/*.sh "$ROOT"/tests/*.sh \
         "$ROOT/install.sh" "$ROOT"/completions/*.bash; do
  if bash -n "$f" 2>/dev/null; then ok "bash -n $(basename "$f")"; else bad "bash -n $(basename "$f")"; fi
done

if [ "$FAIL" -gt 0 ]; then
  printf '\n\033[1m--- declutter output from each run ---\033[0m\n'
  cat "$SB/runs.txt" 2>/dev/null
  printf '\n\033[1m--- environment ---\033[0m\n'
  printf 'HOME=%s\nbash=%s\nuname=%s\n' "$HOME" "$BASH_VERSION" "$(uname -sm)"
fi

printf '\n\033[1mResult: %d pass, %d fail\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

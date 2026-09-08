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
# LC_ALL and LC_MESSAGES have to be unset, not just LANG set: the precedence is
# LC_ALL > LC_MESSAGES > LANG (POSIX), and CI runners set LC_ALL — which would
# correctly beat the LANG we are trying to test.
env -u LC_ALL -u LC_MESSAGES -u DECLUTTER_LANG LANG=vi_VN.UTF-8 \
  "$ROOT/declutter" --report > "$SB/report.txt" 2>/dev/null
if in_report 'Tick sẵn'; then
  ok "\$LANG=vi_VN is auto-detected"
else
  bad "\$LANG=vi_VN was not auto-detected"
fi
# The other half of that precedence: LC_ALL must win over LANG.
env -u LC_MESSAGES -u DECLUTTER_LANG LC_ALL=en_US.UTF-8 LANG=vi_VN.UTF-8 \
  "$ROOT/declutter" --report > "$SB/report.txt" 2>/dev/null
if in_report 'Pre-ticked'; then
  ok "\$LC_ALL takes precedence over \$LANG"
else
  bad "\$LC_ALL did not take precedence over \$LANG"
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

printf '\n\033[1m11) cmd items: no invisible stdin hang, failures are logged\033[0m\n'
# Unit level on purpose. The end-to-end runs set DECLUTTER_SKIP_CMD=1 because
# `cmd` items hit the real daemon/system, but the plumbing AROUND them still has
# to be tested — that plumbing is where the "stops forever at uv cache" bug was.
cmd_probe() {   # $1 = shell snippet for the cmd item, $2 = log file
  (
    export DECLUTTER_SKIP_CMD=0 DECLUTTER_ROOT="$ROOT"
    LOG="$2"; DRY_RUN=0; QUIET=1
    . "$ROOT/lib/core.sh"; . "$ROOT/lib/i18n.sh"; i18n_detect; i18n_load
    . "$ROOT/lib/registry.sh"; . "$ROOT/lib/actions.sh"
    I_LEVEL=(); I_GROUP=(); I_DESC=(); I_ACTION=(); I_EXTRA=(); I_PATHS=()
    add green os cmd "$1" "probe" ""
    run_item 0; printf 'rc=%s kind=%s' "$?" "$RUN_FAIL_KIND"
  )
}

# A cmd item must get EOF on stdin, not the terminal. Without </dev/null the
# `read` below swallows the line piped into this test and exits 9 — which is
# exactly how a command that prompts silently eats the user's keystrokes, or
# blocks forever waiting for one with its prompt sent to /dev/null.
res=$(printf 'stolen-line\n' | cmd_probe 'read -r _ && exit 9 || exit 0' "$SB/probe1.log")
case "$res" in
  'rc=0 kind=') ok "cmd item gets /dev/null on stdin (cannot steal input or hang)" ;;
  *)            bad "cmd stdin is not /dev/null -> $res" ;;
esac

# A failing cmd must record its exit code AND its output; that is the whole
# point of capturing instead of discarding.
res=$(cmd_probe 'echo "boom-on-stderr" >&2; exit 3' "$SB/probe2.log")
case "$res" in
  'rc=3 kind=cmd') ok "failing cmd returns its real exit code, kind=cmd" ;;
  *)               bad "failing cmd misreported -> $res" ;;
esac
grep -q 'cmd FAILED exit=3' "$SB/probe2.log" \
  && ok "log records the exit code" || bad "log has no exit code"
grep -q 'boom-on-stderr' "$SB/probe2.log" \
  && ok "log records the command output" || bad "log lost the command output"

res=$(cmd_probe 'true' "$SB/probe3.log")
case "$res" in
  'rc=0 kind=') ok "successful cmd sets no failure kind" ;;
  *)            bad "successful cmd misreported -> $res" ;;
esac

printf '\n\033[1m12) every file parses\033[0m\n'
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

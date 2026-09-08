#!/usr/bin/env bash
# tests/run.sh — chạy declutter trong một $HOME giả, kiểm tra nó xóa ĐÚNG thứ
# cần xóa và KHÔNG đụng vào thứ không được xóa. Không cần cài gì.
#
#   ./tests/run.sh
#
set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
check()      { if [ -e "$1" ]; then bad "$2 (vẫn còn: $1)"; else ok "$2"; fi; }
check_kept() { if [ -e "$1" ]; then ok "$2"; else bad "$2 (đã bị xóa mất: $1)"; fi; }

SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
export HOME="$SB/home"
export DECLUTTER_TMP_ROOT="$SB/tmp"
export DECLUTTER_LOG="$SB/log"
export NO_COLOR=1
# BẮT BUỘC: các mục `cmd` (docker prune, apt clean, brew cleanup) không bị
# $HOME giả chặn — chúng chạy lên hệ thống thật. Test chỉ kiểm tra phần xóa file.
export DECLUTTER_SKIP_CMD=1

mkdir -p "$HOME" "$DECLUTTER_TMP_ROOT"
mk() { mkdir -p "$(dirname "$1")"; mkdir -p "$1"; head -c "${2:-4096}" /dev/urandom > "$1/blob.bin"; }

# ── rác nên bị xóa ở mức green ──────────────────────────────────────────────
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

# ── rác mức yellow: KHÔNG được xóa khi chạy mức green ───────────────────────
mk "$HOME/.config/Code/WebStorage"
mk "$HOME/.cache/huggingface/hub"
mk "$HOME/.gradle/caches/modules-2"

# ── thứ KHÔNG BAO GIỜ được xóa ──────────────────────────────────────────────
mk "$HOME/.claude/skills"
mk "$HOME/.claude/projects"
echo '{"theme":"dark"}' > "$HOME/.claude/settings.json"
mk "$HOME/.config/Code/User/workspaceStorage"
mkdir -p "$HOME/.config/Code/User"; echo '{}' > "$HOME/.config/Code/User/settings.json"
mk "$HOME/.ssh"
mk "$HOME/.m2/repository"

# ── /tmp: phiên cũ phải xóa, phiên đang chạy phải giữ ───────────────────────
mk "$DECLUTTER_TMP_ROOT/claude-old"
mk "$DECLUTTER_TMP_ROOT/claude-active"
touch -t 202001010000 "$DECLUTTER_TMP_ROOT/claude-old"

printf '\n\033[1m1) dry-run không được đụng vào bất cứ thứ gì\033[0m\n'
"$ROOT/declutter" --yes --dry-run -q >/dev/null 2>&1
check_kept "$HOME/.claude/shell-snapshots" "dry-run giữ nguyên mọi thứ"
grep -q 'DRY' "$DECLUTTER_LOG" && ok "dry-run có ghi log dự định" || bad "dry-run không ghi log"

printf '\n\033[1m2) chạy thật ở mức green\033[0m\n'
"$ROOT/declutter" --yes -q >/dev/null 2>&1

check "$HOME/.claude/shell-snapshots"          "xóa shell-snapshots"
check "$HOME/.claude/statsig"                  "xóa statsig"
check "$HOME/.cache/claude-cli-nodejs"         "xóa cache claude-cli"
check "$HOME/.codex/cache"                     "xóa cache Codex"
check "$HOME/.gemini/tmp"                      "xóa tmp Gemini"
check "$HOME/.cursor/ai-tracking"              "xóa ai-tracking Cursor"
check "$HOME/.config/Code/Cache"               "xóa Cache VS Code"
check "$HOME/.config/Code/CachedExtensionVSIXs" "xóa VSIX đã tải"
check "$HOME/.npm/_npx"                        "xóa npx cache"
check "$HOME/.cargo/registry/cache"            "xóa cargo registry cache"
check "$HOME/.gradle/caches/build-cache-1"     "xóa gradle build-cache (findrm)"
check "$HOME/.cache/google-chrome/Default/Cache" "xóa Chrome page cache (findrm depth 2)"
check "$HOME/.nv/ComputeCache"                 "xóa CUDA JIT cache"
check "$DECLUTTER_TMP_ROOT/claude-old"         "xóa /tmp/claude-* cũ"

printf '\n\033[1m3) mức green KHÔNG được đụng mức yellow\033[0m\n'
check_kept "$HOME/.config/Code/WebStorage"     "giữ WebStorage (yellow)"
check_kept "$HOME/.cache/huggingface/hub"      "giữ HuggingFace (yellow)"
check_kept "$HOME/.gradle/caches/modules-2"    "giữ gradle caches (yellow)"

printf '\n\033[1m4) không bao giờ đụng dữ liệu người dùng\033[0m\n'
check_kept "$HOME/.claude/skills"              "giữ skills"
check_kept "$HOME/.claude/projects"            "giữ transcript"
check_kept "$HOME/.claude/settings.json"       "giữ settings.json"
check_kept "$HOME/.config/Code/User/settings.json" "giữ settings VS Code"
check_kept "$HOME/.config/Code/User/workspaceStorage" "giữ workspaceStorage (red)"
check_kept "$HOME/.ssh"                        "giữ ~/.ssh"
check_kept "$HOME/.m2/repository"              "giữ Maven repo (red)"
check_kept "$DECLUTTER_TMP_ROOT/claude-active" "giữ phiên claude đang chạy"

printf '\n\033[1m5) mức yellow dọn tiếp phần còn lại\033[0m\n'
"$ROOT/declutter" --yes -l yellow -q >/dev/null 2>&1
check "$HOME/.config/Code/WebStorage"          "yellow xóa WebStorage"
check "$HOME/.cache/huggingface/hub"           "yellow xóa HuggingFace"
check_kept "$HOME/.claude/skills"              "yellow vẫn giữ skills"
check_kept "$HOME/.config/Code/User/workspaceStorage" "yellow vẫn giữ mục đỏ"
check_kept "$HOME/.ssh"                        "yellow vẫn giữ ~/.ssh"

printf '\n\033[1m6) bộ lọc --only / --skip\033[0m\n'
mk "$HOME/.codex/cache"; mk "$HOME/.gemini/cache"
"$ROOT/declutter" --yes --only ai-cli --skip ai-cli -q >/dev/null 2>&1
check_kept "$HOME/.codex/cache" "--skip thắng --only"
"$ROOT/declutter" --yes --only pkg-node -q >/dev/null 2>&1
check_kept "$HOME/.codex/cache" "--only pkg-node không đụng ai-cli"

printf '\n\033[1m7) cú pháp mọi file\033[0m\n'
for f in "$ROOT/declutter" "$ROOT"/lib/*.sh "$ROOT"/modules/*.sh "$ROOT"/tests/*.sh; do
  if bash -n "$f" 2>/dev/null; then ok "bash -n $(basename "$f")"; else bad "bash -n $(basename "$f")"; fi
done

printf '\n\033[1mKết quả: %d pass, %d fail\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

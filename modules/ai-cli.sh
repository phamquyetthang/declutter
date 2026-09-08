#!/usr/bin/env bash
# Terminal coding assistants: Claude Code, Codex, Gemini CLI, Cursor CLI, Aider.
register_ai_cli() {
  local H="$HOME" D="${PROJ_DAYS:-60}"

  add green ai-cli rm "" \
    "$(L "Claude Code: shell snapshots + telemetry + cache" \
         "Claude Code: shell snapshot + telemetry + cache")" \
    "$H/.claude/shell-snapshots" "$H/.claude/statsig" "$H/.cache/claude-cli-nodejs"

  # -mtime +1 so a running Claude Code session is never touched
  add green ai-cli agerm "1|claude-*" \
    "$(L "claude-* temp dirs in $TMP_ROOT (keeps live sessions)" \
         "Thư mục tạm claude-* trong $TMP_ROOT (giữ phiên đang chạy)")" "$TMP_ROOT"

  add green ai-cli rm "" \
    "$(L "Codex CLI: cache" "Codex CLI: cache")" "$H/.codex/cache"
  add green ai-cli rm "" \
    "$(L "Gemini CLI: tmp + cache" "Gemini CLI: tmp + cache")" \
    "$H/.gemini/tmp" "$H/.gemini/cache"
  add green ai-cli rm "" \
    "$(L "Cursor: local telemetry" "Cursor: telemetry cục bộ")" "$H/.cursor/ai-tracking"

  add yellow ai-cli agerm "$D|*.jsonl" \
    "$(L "Claude Code: transcripts older than ${D}d (breaks --resume)" \
         "Claude Code: transcript cũ hơn ${D}n (mất --resume)")" \
    "$H/.claude/projects"
  add yellow ai-cli agerm "$D|*" \
    "$(L "Claude Code: file-edit history older than ${D}d" \
         "Claude Code: lịch sử sửa file cũ hơn ${D}n")" "$H/.claude/file-history"
  add yellow ai-cli agerm "$D|*" \
    "$(L "Codex CLI: sessions older than ${D}d" \
         "Codex CLI: session cũ hơn ${D}n")" "$H/.codex/sessions"
  add yellow ai-cli rm "" \
    "$(L "Aider: in-repo tags cache (rebuilds itself)" \
         "Aider: cache tags trong repo (tự dựng lại)")" \
    "$H/.aider.tags.cache.v3"

  add red ai-cli note "" \
    "$(L "Claude Code: config/skills/memory — NOT deleted" \
         "Claude Code: config/skills/memory — KHÔNG xóa")" \
    "$H/.claude/skills" "$H/.claude/agents" "$H/.claude/memory"
}

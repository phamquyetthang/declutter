#!/usr/bin/env bash
# Trợ lý code chạy trong terminal: Claude Code, Codex, Gemini CLI, Cursor CLI, Aider.
register_ai_cli() {
  local H="$HOME" D="${PROJ_DAYS:-60}"

  add green ai-cli rm "" \
    "Claude Code: shell snapshot + telemetry + cache" \
    "$H/.claude/shell-snapshots" "$H/.claude/statsig" "$H/.cache/claude-cli-nodejs"

  # -mtime +1 để không đụng phiên Claude Code đang chạy
  add green ai-cli agerm "1|claude-*" \
    "Thư mục tạm claude-* trong $TMP_ROOT (giữ phiên đang chạy)" "$TMP_ROOT"

  add green ai-cli rm "" "Codex CLI: cache"        "$H/.codex/cache"
  add green ai-cli rm "" "Gemini CLI: tmp + cache" "$H/.gemini/tmp" "$H/.gemini/cache"
  add green ai-cli rm "" "Cursor: telemetry cục bộ" "$H/.cursor/ai-tracking"

  add yellow ai-cli agerm "$D|*.jsonl" \
    "Claude Code: transcript cũ hơn ${D}n (mất --resume)" \
    "$H/.claude/projects"
  add yellow ai-cli agerm "$D|*" \
    "Claude Code: lịch sử sửa file cũ hơn ${D}n" "$H/.claude/file-history"
  add yellow ai-cli agerm "$D|*" \
    "Codex CLI: session cũ hơn ${D}n" "$H/.codex/sessions"
  add yellow ai-cli rm "" "Aider: cache tags trong repo (tự dựng lại)" \
    "$H/.aider.tags.cache.v3"

  add red ai-cli note "" \
    "Claude Code: config/skills/memory — KHÔNG xóa" \
    "$H/.claude/skills" "$H/.claude/agents" "$H/.claude/memory"
}

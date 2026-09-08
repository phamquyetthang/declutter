#!/usr/bin/env bash
# IDE có AI: VS Code + Copilot, Cursor, Windsurf. Thường là thư mục nặng nhất trong $HOME.
register_ai_ide() {
  local H="$HOME" base nice

  for base in "$H/.config/Code" "$H/.config/Cursor" "$H/.config/Windsurf" \
              "$H/.config/VSCodium" \
              "$H/Library/Application Support/Code" \
              "$H/Library/Application Support/Cursor" \
              "$H/Library/Application Support/Windsurf"; do
    [ -d "$base" ] || continue
    nice="$(basename "$base")"

    add green ai-ide rm "" "$nice: cache + VSIX đã tải + log" \
      "$base/Cache" "$base/CachedData" "$base/CachedExtensionVSIXs" \
      "$base/GPUCache" "$base/Code Cache" "$base/logs" "$base/Crashpad"

    add yellow ai-ide rm "" "$nice: WebStorage (webview panel AI)" \
      "$base/WebStorage"

    add yellow ai-ide rm "" "$nice: lịch sử Copilot Chat" \
      "$base/User/globalStorage/github.copilot-chat"

    add red ai-ide note "" "$nice: workspaceStorage (state project đã mở)" \
      "$base/User/workspaceStorage"
  done

  add red ai-ide note "" \
    "Extension đã cài (gỡ: code --uninstall-extension)" \
    "$H/.vscode/extensions" "$H/.cursor/extensions" "$H/.windsurf/extensions"

  add yellow ai-ide findrm "2|caches" "JetBrains cache (IDE phải index lại)" \
    "$H/.cache/JetBrains" "$H/Library/Caches/JetBrains"
}

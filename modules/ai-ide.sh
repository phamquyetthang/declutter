#!/usr/bin/env bash
# AI-enabled IDEs: VS Code + Copilot, Cursor, Windsurf. Usually the heaviest
# directory in $HOME.
register_ai_ide() {
  local H="$HOME" base nice

  for base in "$H/.config/Code" "$H/.config/Cursor" "$H/.config/Windsurf" \
              "$H/.config/VSCodium" \
              "$H/Library/Application Support/Code" \
              "$H/Library/Application Support/Cursor" \
              "$H/Library/Application Support/Windsurf"; do
    [ -d "$base" ] || continue
    nice="$(basename "$base")"

    add green ai-ide rm "" \
      "$(L "$nice: cache + downloaded VSIX + logs" \
           "$nice: cache + VSIX đã tải + log")" \
      "$base/Cache" "$base/CachedData" "$base/CachedExtensionVSIXs" \
      "$base/GPUCache" "$base/Code Cache" "$base/logs" "$base/Crashpad"

    add yellow ai-ide rm "" \
      "$(L "$nice: WebStorage (AI webview panels)" \
           "$nice: WebStorage (webview panel AI)")" \
      "$base/WebStorage"

    add yellow ai-ide rm "" \
      "$(L "$nice: Copilot Chat history" "$nice: lịch sử Copilot Chat")" \
      "$base/User/globalStorage/github.copilot-chat"

    add red ai-ide note "" \
      "$(L "$nice: workspaceStorage (per-project state)" \
           "$nice: workspaceStorage (state project đã mở)")" \
      "$base/User/workspaceStorage"
  done

  add red ai-ide note "" \
    "$(L "Installed extensions (remove: code --uninstall-extension)" \
         "Extension đã cài (gỡ: code --uninstall-extension)")" \
    "$H/.vscode/extensions" "$H/.cursor/extensions" "$H/.windsurf/extensions"

  add yellow ai-ide findrm "2|caches" \
    "$(L "JetBrains caches (the IDE has to re-index)" \
         "JetBrains cache (IDE phải index lại)")" \
    "$H/.cache/JetBrains" "$H/Library/Caches/JetBrains"
}

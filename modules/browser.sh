#!/usr/bin/env bash
register_browser() {
  local H="$HOME"
  # Only ~/.cache and ~/Library/Caches are touched — never the profile itself
  # (bookmarks, passwords, sessions).
  add green browser findrm "2|Cache" \
    "$(L "Chrome / Chromium / Edge: page cache" "Chrome / Chromium / Edge: page cache")" \
    "$H/.cache/google-chrome" "$H/.cache/chromium" "$H/.cache/microsoft-edge" \
    "$H/Library/Caches/Google/Chrome" "$H/Library/Caches/com.microsoft.edgemac"
  add green browser findrm "3|cache2" \
    "$(L "Firefox: page cache" "Firefox: page cache")" \
    "$H/.cache/mozilla" "$H/Library/Caches/Firefox"
}

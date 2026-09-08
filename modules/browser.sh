#!/usr/bin/env bash
register_browser() {
  local H="$HOME"
  # Chỉ đụng vào ~/.cache và ~/Library/Caches — KHÔNG đụng profile (bookmark, mật khẩu).
  add green browser findrm "2|Cache" "Chrome / Chromium / Edge: page cache" \
    "$H/.cache/google-chrome" "$H/.cache/chromium" "$H/.cache/microsoft-edge" \
    "$H/Library/Caches/Google/Chrome" "$H/Library/Caches/com.microsoft.edgemac"
  add green browser findrm "3|cache2" "Firefox: page cache" \
    "$H/.cache/mozilla" "$H/Library/Caches/Firefox"
}

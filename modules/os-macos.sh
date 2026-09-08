#!/usr/bin/env bash
# macOS. Chỉ nạp khi PLATFORM=mac.
register_mac_os() {
  [ "$PLATFORM" = mac ] || return 0
  local H="$HOME"

  if have brew; then
    add green os cmd "brew cleanup -s --prune=all" "Homebrew: gỡ bản cũ" ""
    add green os rm  "" "Homebrew: cache tải về"   "$(brew --cache 2>/dev/null)"
  fi

  add yellow os rmchild "" "Thùng rác" "$H/.Trash"
  add yellow os rm ""      "Log người dùng" "$H/Library/Logs"

  add red os note "" \
    "APFS snapshots — sudo tmutil thinlocalsnapshots / 21474836480 4" ""
  add red os note "" "Backup iPhone/iPad" \
    "$H/Library/Application Support/MobileSync/Backup"
  add red os note "" "~/Library/Caches toàn bộ — đóng app rồi tự xóa" \
    "$H/Library/Caches"
}

# Xcode & iOS dev — nguồn rác lớn nhất trên máy Mac lập trình.
register_mac_xcode() {
  [ "$PLATFORM" = mac ] || return 0
  local H="$HOME"

  add green xcode rm "" "Xcode DerivedData (build cache)" \
    "$H/Library/Developer/Xcode/DerivedData"
  add green xcode rm "" "SwiftPM cache" "$H/Library/Caches/org.swift.swiftpm"
  add green xcode rm "" "CoreSimulator cache" "$H/Library/Developer/CoreSimulator/Caches"
  add green xcode rm "" "Xcode iOS Device Logs" \
    "$H/Library/Developer/Xcode/iOS Device Logs"

  have xcrun && add green xcode cmd "xcrun simctl delete unavailable" \
    "Simulator không còn khả dụng" "$H/Library/Developer/CoreSimulator/Devices"

  add yellow xcode rm "" "iOS DeviceSupport (symbol iOS cũ, 3-6GB/bản)" \
    "$H/Library/Developer/Xcode/iOS DeviceSupport"

  add red xcode note "" \
    "Xcode Archives — cần symbolicate crash bản đã ship" \
    "$H/Library/Developer/Xcode/Archives"
}

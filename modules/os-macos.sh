#!/usr/bin/env bash
# macOS. The hooks only run when PLATFORM=mac.
register_mac_os() {
  [ "$PLATFORM" = mac ] || return 0
  local H="$HOME"

  if have brew; then
    add green os cmd "brew cleanup -s --prune=all" \
      "$(L "Homebrew: drop outdated versions" "Homebrew: gỡ bản cũ")" ""
    add green os rm  "" \
      "$(L "Homebrew: download cache" "Homebrew: cache tải về")" "$(brew --cache 2>/dev/null)"
  fi

  add yellow os rmchild "" "$(L "Trash" "Thùng rác")" "$H/.Trash"
  add yellow os rm ""      "$(L "User logs" "Log người dùng")" "$H/Library/Logs"

  add red os note "" \
    "$(L "APFS snapshots — sudo tmutil thinlocalsnapshots / 21474836480 4" \
         "APFS snapshots — sudo tmutil thinlocalsnapshots / 21474836480 4")" ""
  add red os note "" \
    "$(L "iPhone/iPad backups" "Backup iPhone/iPad")" \
    "$H/Library/Application Support/MobileSync/Backup"
  add red os note "" \
    "$(L "All of ~/Library/Caches — quit the apps, then clear it yourself" \
         "~/Library/Caches toàn bộ — đóng app rồi tự xóa")" \
    "$H/Library/Caches"
}

# Xcode & iOS dev — the single biggest source of junk on a Mac dev machine.
register_mac_xcode() {
  [ "$PLATFORM" = mac ] || return 0
  local H="$HOME"

  add green xcode rm "" \
    "$(L "Xcode DerivedData (build cache)" "Xcode DerivedData (build cache)")" \
    "$H/Library/Developer/Xcode/DerivedData"
  add green xcode rm "" \
    "$(L "SwiftPM cache" "SwiftPM cache")" "$H/Library/Caches/org.swift.swiftpm"
  add green xcode rm "" \
    "$(L "CoreSimulator caches" "CoreSimulator cache")" \
    "$H/Library/Developer/CoreSimulator/Caches"
  add green xcode rm "" \
    "$(L "Xcode iOS device logs" "Xcode iOS Device Logs")" \
    "$H/Library/Developer/Xcode/iOS Device Logs"

  have xcrun && add green xcode cmd "xcrun simctl delete unavailable" \
    "$(L "Simulators that are no longer available" "Simulator không còn khả dụng")" \
    "$H/Library/Developer/CoreSimulator/Devices"

  add yellow xcode rm "" \
    "$(L "iOS DeviceSupport (old iOS symbols, 3-6GB each)" \
         "iOS DeviceSupport (symbol iOS cũ, 3-6GB/bản)")" \
    "$H/Library/Developer/Xcode/iOS DeviceSupport"

  add red xcode note "" \
    "$(L "Xcode Archives — needed to symbolicate shipped crashes" \
         "Xcode Archives — cần symbolicate crash bản đã ship")" \
    "$H/Library/Developer/Xcode/Archives"
}

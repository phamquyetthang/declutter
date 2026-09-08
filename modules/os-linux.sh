#!/usr/bin/env bash
# Ubuntu / Debian. The hook only runs when PLATFORM=linux.
register_linux_os() {
  [ "$PLATFORM" = linux ] || return 0
  local H="$HOME"

  add green  os rm ""      "$(L "Thumbnail cache" "Thumbnail cache")" "$H/.cache/thumbnails"
  add yellow os rmchild "" "$(L "Trash" "Thùng rác")"                 "$H/.local/share/Trash"
  add green  os rm ""      "$(L "fontconfig cache" "Cache fontconfig")" "$H/.cache/fontconfig"

  if [ -n "$SUDO" ]; then
    add green os cmd "$SUDO apt-get clean && $SUDO apt-get autoclean -y" \
      "$(L "APT: .deb package cache" "APT: cache gói .deb")" "/var/cache/apt/archives"
    add green os cmd "$SUDO apt-get autoremove -y" \
      "$(L "APT: drop orphaned dependencies (old kernels too)" \
           "APT: gỡ gói phụ thuộc thừa (cả kernel cũ)")" ""
    add green os cmd "$SUDO journalctl --vacuum-time=3d" \
      "$(L "Journal: keep only 3 days of logs" "Journal: chỉ giữ log 3 ngày")" "/var/log/journal"
    add green os cmd "$SUDO rm -rf /var/crash" \
      "$(L "Old crash reports" "Báo cáo crash cũ")" "/var/crash"

    have snap && add green os cmd \
      "LANG=C snap list --all | awk '/disabled/{print \$1, \$3}' | while read -r n r; do $SUDO snap remove \"\$n\" --revision=\"\$r\"; done" \
      "$(L "Snap: remove every disabled revision" "Snap: xóa mọi revision đã disabled")" \
      "/var/lib/snapd/snaps"

    have flatpak && add green os cmd "flatpak uninstall --unused -y" \
      "$(L "Flatpak: runtimes nothing uses any more" "Flatpak: runtime không còn ai dùng")" ""
  else
    add red os note "" \
      "$(L "Needs sudo: apt clean, journal, old snaps, /var/crash" \
           "Cần sudo: apt clean, journal, snap cũ, /var/crash")" ""
  fi

  add red os note "" \
    "$(L "Timeshift snapshots — those are system backups" \
         "Timeshift snapshots — là backup hệ thống")" "/timeshift"
}

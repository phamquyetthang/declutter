#!/usr/bin/env bash
# Ubuntu / Debian. Chỉ nạp khi PLATFORM=linux.
register_linux_os() {
  [ "$PLATFORM" = linux ] || return 0
  local H="$HOME"

  add green  os rm ""      "Thumbnail cache"  "$H/.cache/thumbnails"
  add yellow os rmchild "" "Thùng rác"        "$H/.local/share/Trash"
  add green  os rm ""      "Cache fontconfig" "$H/.cache/fontconfig"

  if [ -n "$SUDO" ]; then
    add green os cmd "$SUDO apt-get clean && $SUDO apt-get autoclean -y" \
      "APT: cache gói .deb" "/var/cache/apt/archives"
    add green os cmd "$SUDO apt-get autoremove -y" \
      "APT: gỡ gói phụ thuộc thừa (cả kernel cũ)" ""
    add green os cmd "$SUDO journalctl --vacuum-time=3d" \
      "Journal: chỉ giữ log 3 ngày" "/var/log/journal"
    add green os cmd "$SUDO rm -rf /var/crash" "Báo cáo crash cũ" "/var/crash"

    have snap && add green os cmd \
      "LANG=C snap list --all | awk '/disabled/{print \$1, \$3}' | while read -r n r; do $SUDO snap remove \"\$n\" --revision=\"\$r\"; done" \
      "Snap: xóa mọi revision đã disabled" "/var/lib/snapd/snaps"

    have flatpak && add green os cmd "flatpak uninstall --unused -y" \
      "Flatpak: runtime không còn ai dùng" ""
  else
    add red os note "" \
      "Cần sudo: apt clean, journal, snap cũ, /var/crash" ""
  fi

  add red os note "" "Timeshift snapshots — là backup hệ thống" "/timeshift"
}

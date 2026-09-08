#!/usr/bin/env bash
# i18n.sh — bilingual UI (English + Vietnamese). Compatible with bash 3.2.
#
# The language is decided once, at startup:
#   DECLUTTER_LANG=en|vi            explicit override, wins over everything
#   LC_ALL / LC_MESSAGES / LANG     starting with "vi" -> Vietnamese
#   anything else                   -> English
#
# Two ways to reach a string:
#
#   $T_SOMETHING                  catalog variable, assigned once below. Use it
#                                 for anything the draw loop touches — a catalog
#                                 lookup costs no process, `$(...)` costs one
#                                 fork per cell per frame (that is what made the
#                                 list flicker before).
#   $(L "english" "tiếng Việt")   inline pair. Use it in modules/*.sh, where the
#                                 text belongs next to the item it describes and
#                                 is evaluated once, at registration.

DECLUTTER_LC=en

i18n_detect() {
  local l="${DECLUTTER_LANG:-}"
  [ -n "$l" ] || l="${LC_ALL:-}"
  [ -n "$l" ] || l="${LC_MESSAGES:-}"
  [ -n "$l" ] || l="${LANG:-}"
  case "$l" in
    vi|vi[-_]*|vietnamese|Vietnamese*) DECLUTTER_LC=vi ;;
    *)                                 DECLUTTER_LC=en ;;
  esac
}

L() { if [ "$DECLUTTER_LC" = vi ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

# Must run after core.sh, the catalog embeds $B/$DIM/$R.
i18n_load() {
  if [ "$DECLUTTER_LC" = vi ]; then
    T_LEGEND="o = an toàn (tick sẵn)   ! = cân nhắc   x = tự quyết, không chọn được"
    T_FREE_ON="trống trên /"
    T_SCANNING="Đang quét…"
    T_NOTHING="Không tìm thấy gì để dọn. Máy sạch."
    T_NOT_TTY="(không phải terminal tương tác — dùng --yes để chạy thật)"
    T_EXITED="Đã thoát, không xóa gì."
    T_MORE_ROWS="   … còn %d mục nữa"
    T_SELECTED="  Đã chọn: "
    T_ITEMS="mục"
    T_KEYS1="  [↑↓/jk] di chuyển   [space] chọn   [a] đảo tất cả   [o] chỉ an toàn"
    T_KEYS2="  [n] bỏ hết   [enter] DỌN   [q] thoát"
    T_HDR_SEL="chọn"; T_HDR_LVL="mức"; T_HDR_SIZE="cỡ"
    T_HDR_ITEM="mục"; T_HDR_GROUP="nhóm"
    T_PRETICKED="\n  Tick sẵn: %d mục — %s\n"
    T_NONE_SELECTED="Không có mục nào được chọn."
    T_DRYRUN_HEAD="DRY RUN — không xóa gì, chỉ ghi ra %s"
    T_CLEANING="Đang dọn %d mục (%s)"
    T_PARTIAL="✓ (một phần bị từ chối)"
    T_RESULT="Kết quả"
    T_ITEMS_DONE="  %d mục đã xử lý"
    T_ITEMS_DENIED=" (%d mục có phần bị từ chối quyền)"
    T_DRYRUN_TAIL="  Dry run — chưa xóa gì. Xem %s để biết nó ĐỊNH làm gì.\n"
    T_DISK_LINE="  Ổ /: %s trống → %s trống   (%s+%s%s)\n"
    T_LOG_LINE="  Log: %s\n"
    T_PROJ_HEAD="Project artifacts dưới %s (chỉ liệt kê — tool không tự xóa nhóm này)"
    T_PROJ_SCANNING="Đang quét, có thể mất một lúc…"
    T_PROJ_PLACES="ở %d nơi"
    T_PROJ_STALE="Lọc project bỏ hoang trên %s ngày:"
    T_PROJ_WARN="Xem kỹ danh sách rồi mới thêm -exec rm -rf {} +"
    T_ERR_LEVEL_RED="--level red không được phép: mục đỏ luôn phải do bạn tự xử lý."
    T_ERR_LEVEL="--level phải là green hoặc yellow"
    T_ERR_UNKNOWN_OPT="Tùy chọn lạ: %s  (xem --help)\n"
    T_ERR_PLATFORM="Chỉ hỗ trợ Linux và macOS (phát hiện: %s)"
    T_ERR_UNKNOWN_GROUP="Nhóm không tồn tại: %s\nCác nhóm hợp lệ: %s\n"
  else
    T_LEGEND="o = safe (pre-ticked)   ! = your call   x = manual only, not selectable"
    T_FREE_ON="free on /"
    T_SCANNING="Scanning…"
    T_NOTHING="Nothing to clean. This machine is already tidy."
    T_NOT_TTY="(not an interactive terminal — pass --yes to actually clean)"
    T_EXITED="Exited. Nothing was deleted."
    T_MORE_ROWS="   … %d more"
    T_SELECTED="  Selected: "
    T_ITEMS="items"
    T_KEYS1="  [↑↓/jk] move   [space] toggle   [a] invert all   [o] safe only"
    T_KEYS2="  [n] clear   [enter] CLEAN   [q] quit"
    T_HDR_SEL="sel"; T_HDR_LVL="lvl"; T_HDR_SIZE="size"
    T_HDR_ITEM="item"; T_HDR_GROUP="group"
    T_PRETICKED="\n  Pre-ticked: %d items — %s\n"
    T_NONE_SELECTED="No items selected."
    T_DRYRUN_HEAD="DRY RUN — nothing is deleted, the plan goes to %s"
    T_CLEANING="Cleaning %d items (%s)"
    T_PARTIAL="✓ (partly denied)"
    T_RESULT="Result"
    T_ITEMS_DONE="  %d items processed"
    T_ITEMS_DENIED=" (%d had paths denied by permissions)"
    T_DRYRUN_TAIL="  Dry run — nothing removed. See %s for what it WOULD do.\n"
    T_DISK_LINE="  Disk /: %s free → %s free   (%s+%s%s)\n"
    T_LOG_LINE="  Log: %s\n"
    T_PROJ_HEAD="Project artifacts under %s (listed only — declutter never deletes these)"
    T_PROJ_SCANNING="Scanning, this can take a while…"
    T_PROJ_PLACES="in %d places"
    T_PROJ_STALE="Find projects untouched for more than %s days:"
    T_PROJ_WARN="Read that list before you append -exec rm -rf {} +"
    T_ERR_LEVEL_RED="--level red is not allowed: red items are always yours to handle."
    T_ERR_LEVEL="--level must be green or yellow"
    T_ERR_UNKNOWN_OPT="Unknown option: %s  (see --help)\n"
    T_ERR_PLATFORM="Only Linux and macOS are supported (detected: %s)"
    T_ERR_UNKNOWN_GROUP="No such group: %s\nValid groups: %s\n"
  fi
}

usage_en() {
  cat <<USAGE
${B}declutter $DECLUTTER_VERSION${R} — reclaim disk space on a dev machine (Ubuntu + macOS)

${B}USAGE${R}
  declutter                     Scan → checkbox list → Enter to clean.
                                Safe items come pre-ticked. Nothing is deleted before that.
  declutter --report            Print the list and exit (non-interactive).
  declutter --json              Same list as JSON, for scripts and agents.
  declutter --yes               Skip the list, clean the safe items straight away.
  declutter --yes -l yellow     Include the "your call" tier.
  declutter --dry-run --yes     Rehearse: log what WOULD be deleted, touch nothing.
  declutter --projects          List heavy node_modules/target/.venv directories.

${B}OPTIONS${R}
  -l, --level LEVEL   green (default) | yellow   — highest tier pre-ticked
                      Red ("your call") items are never selected automatically.
  -y, --yes           Don't show the list, act on --level right away
  -n, --dry-run       Delete nothing, only log what would go
      --report        Print the list and exit
      --json          Print the list as JSON and exit
      --only  A,B     Only these groups (ai-cli, ai-ide, ai-ml, ai-model, os,
                      xcode, pkg-node, pkg-python, pkg-rust, pkg-go, pkg-java,
                      docker, browser)
      --skip  A,B     Skip these groups
      --deep          Enable the slow scans (walk \$HOME for __pycache__)
      --projects [DIR]  List heavy project artifacts (default \$HOME)
      --days N        "Old" threshold for transcripts and --projects (default 60)
      --top N         Max rows per listing (default 15)
      --sudo yes|no   Force sudo on/off (default: auto-detect)
      --log FILE      Log file (default ~/.declutter.log)
      --lang en|vi    Interface language (default: from \$LANG)
  -q, --quiet         Less chatter
  -V, --version       Print version
  -h, --help          This help

${B}KEYS IN THE LIST${R}
  ↑↓ or j/k    move              space  tick / untick
  a  invert all                  o      tick safe items only
  n  untick everything           Enter  CLEAN      q  quit
USAGE
}

usage_vi() {
  cat <<USAGE
${B}declutter $DECLUTTER_VERSION${R} — dọn rác máy dev (Ubuntu + macOS)

${B}CÁCH DÙNG${R}
  declutter                     Quét → danh sách có checkbox → Enter để dọn.
                                Mục an toàn được tick sẵn. Không xóa gì trước đó.
  declutter --report            Chỉ in danh sách rồi thoát (không tương tác).
  declutter --json              In danh sách dạng JSON, cho script và agent.
  declutter --yes               Bỏ qua bước chọn, dọn thẳng các mục an toàn.
  declutter --yes -l yellow     Dọn cả mức "cân nhắc".
  declutter --dry-run --yes     Chạy thử, ghi ra log những gì SẼ xóa.
  declutter --projects          Liệt kê node_modules/target/.venv nặng.

${B}TÙY CHỌN${R}
  -l, --level LEVEL   green (mặc định) | yellow    — mức tối đa được tick sẵn
                      Mục "tự quyết" (đỏ) không bao giờ được chọn tự động.
  -y, --yes           Không hiện danh sách, chạy luôn theo --level
  -n, --dry-run       Không xóa gì, chỉ ghi vào log những gì sẽ xóa
      --report        In danh sách rồi thoát
      --json          In danh sách dạng JSON rồi thoát
      --only  A,B     Chỉ các nhóm này (ai-cli, ai-ide, ai-ml, ai-model, os,
                      xcode, pkg-node, pkg-python, pkg-rust, pkg-go, pkg-java,
                      docker, browser)
      --skip  A,B     Bỏ qua các nhóm này
      --deep          Bật các phép quét chậm (rà __pycache__ toàn \$HOME)
      --projects [DIR]  Liệt kê artifact nặng của project (mặc định \$HOME)
      --days N        Ngưỡng "cũ" cho transcript và --projects (mặc định 60)
      --top N         Số dòng tối đa khi liệt kê (mặc định 15)
      --sudo yes|no   Ép dùng / không dùng sudo (mặc định tự dò)
      --log FILE      File log (mặc định ~/.declutter.log)
      --lang en|vi    Ngôn ngữ giao diện (mặc định: theo \$LANG)
  -q, --quiet         Bớt chữ
  -V, --version       In phiên bản
  -h, --help          Trợ giúp này

${B}PHÍM TRONG DANH SÁCH${R}
  ↑↓ hoặc j/k  di chuyển      space  tick / bỏ tick
  a  đảo tất cả               o      chỉ chọn mục an toàn
  n  bỏ chọn hết              Enter  DỌN     q  thoát
USAGE
}

usage() { if [ "$DECLUTTER_LC" = vi ]; then usage_vi; else usage_en; fi; }

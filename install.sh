#!/usr/bin/env bash
# Install declutter into your PATH. One script for both Linux and macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/phamquyetthang/declutter/main/install.sh | bash
#
# or, from a clone:
#
#   ./install.sh
#   ./install.sh --uninstall
#
# Environment: PREFIX (default ~/.local)
set -e

REPO="phamquyetthang/declutter"
BRANCH="main"
PREFIX="${PREFIX:-$HOME/.local}"
SHARE="$PREFIX/share/declutter"
BIN="$PREFIX/bin"

# Same language rule as the tool itself: DECLUTTER_LANG wins, else $LANG.
_lc=en
case "${DECLUTTER_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}" in
  vi|vi[-_]*|vietnamese|Vietnamese*) _lc=vi ;;
esac
L() { if [ "$_lc" = vi ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ]; then
  rm -f "$BIN/declutter"
  rm -rf "$SHARE"
  echo "$(L "✓ Removed" "✓ Đã gỡ"): $BIN/declutter, $SHARE"
  echo "  $(L "Your log at ~/.declutter.log was left alone." \
              "File log ~/.declutter.log vẫn được giữ nguyên.")"
  exit 0
fi

# Under `curl | bash`, $0 is "bash" so dirname gives "." — only treat this as
# "running from a clone" when the entrypoint AND the libs are really there.
SRC=""
_here="$(dirname "$0")"
if [ -f "$_here/declutter" ] && [ -d "$_here/lib" ] && [ -d "$_here/modules" ]; then
  SRC="$(cd "$_here" && pwd)"
fi

if [ -z "$SRC" ]; then
  rm -rf "$SHARE"
  mkdir -p "$(dirname "$SHARE")"
  if command -v git >/dev/null 2>&1; then
    echo "→ clone https://github.com/$REPO"
    git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$SHARE" >/dev/null 2>&1
  elif command -v curl >/dev/null 2>&1; then
    # A clean macOS may have no git yet (it needs Xcode CLT) — fall back to the tarball
    echo "→ $(L "no git, downloading tarball" "không có git, tải tarball")"
    mkdir -p "$SHARE"
    curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" \
      | tar xz -C "$SHARE" --strip-components 1
  else
    echo "$(L "git or curl is required to install." "Cần git hoặc curl để cài.")" >&2; exit 1
  fi
  SRC="$SHARE"
elif [ "$SRC" != "$SHARE" ]; then
  rm -rf "$SHARE"
  mkdir -p "$SHARE"
  # copy the contents, not the directory — sidesteps the GNU/BSD `cp -R` difference
  ( cd "$SRC" && tar cf - . ) | ( cd "$SHARE" && tar xf - )
fi

chmod +x "$SHARE/declutter" "$SHARE/install.sh" "$SHARE/tests/run.sh" 2>/dev/null || true
mkdir -p "$BIN"
ln -sf "$SHARE/declutter" "$BIN/declutter"

echo "$(L "✓ Installed" "✓ Đã cài"): $BIN/declutter"

case ":$PATH:" in
  *":$BIN:"*) echo "  $(L "Try it" "Chạy thử"): declutter" ;;
  *)
    # macOS defaults to zsh, Linux usually bash — name the one file that matters
    case "${SHELL:-}" in
      */zsh)  RC="$HOME/.zshrc"  ;;
      */bash) RC="$HOME/.bashrc" ;;
      *)      RC="$HOME/.profile" ;;
    esac
    echo
    echo "  $(L "$BIN is not in your PATH yet. Add this to $RC:" \
                "$BIN chưa nằm trong PATH. Thêm vào $RC:")"
    echo
    echo "      export PATH=\"$BIN:\$PATH\""
    echo
    echo "  $(L "Then open a new terminal, or run it directly:" \
                "Rồi mở terminal mới, hoặc chạy ngay:")  $BIN/declutter"
    ;;
esac

echo
echo "  $(L "Shell completion (optional):" "Gợi ý tự động cho shell (tùy chọn):")"
case "${SHELL:-}" in
  */zsh) echo "      fpath=($SHARE/completions \$fpath)   # in ~/.zshrc, before compinit" ;;
  *)     echo "      source $SHARE/completions/declutter.bash   # in ~/.bashrc" ;;
esac

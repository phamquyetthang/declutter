#!/usr/bin/env bash
# Cài declutter vào PATH. Dùng chung cho Linux và macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/phamquyetthang/declutter/main/install.sh | bash
#
# hoặc, nếu đã clone repo:
#
#   ./install.sh
#
# Biến môi trường: PREFIX (mặc định ~/.local)
set -e

REPO="phamquyetthang/declutter"
BRANCH="main"
PREFIX="${PREFIX:-$HOME/.local}"
SHARE="$PREFIX/share/declutter"
BIN="$PREFIX/bin"

# Khi chạy qua `curl | bash`, $0 là "bash" nên dirname ra "." — chỉ coi là
# "chạy từ repo đã clone" khi thật sự có đủ cả entrypoint lẫn lib.
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
    # macOS sạch có thể chưa có git (phải cài Xcode CLT) — tải tarball thay thế
    echo "→ không có git, tải tarball"
    mkdir -p "$SHARE"
    curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" \
      | tar xz -C "$SHARE" --strip-components 1
  else
    echo "Cần git hoặc curl để cài." >&2; exit 1
  fi
  SRC="$SHARE"
elif [ "$SRC" != "$SHARE" ]; then
  rm -rf "$SHARE"
  mkdir -p "$SHARE"
  # cp nội dung chứ không cp cả thư mục — tránh khác biệt GNU/BSD của `cp -R`
  ( cd "$SRC" && tar cf - . ) | ( cd "$SHARE" && tar xf - )
fi

chmod +x "$SHARE/declutter" "$SHARE/install.sh" "$SHARE/tests/run.sh" 2>/dev/null || true
mkdir -p "$BIN"
ln -sf "$SHARE/declutter" "$BIN/declutter"

echo "✓ Đã cài: $BIN/declutter"

case ":$PATH:" in
  *":$BIN:"*) echo "  Chạy thử: declutter" ;;
  *)
    # macOS mặc định zsh, Linux thường bash — chỉ đúng file cần sửa
    case "${SHELL:-}" in
      */zsh)  RC="$HOME/.zshrc"  ;;
      */bash) RC="$HOME/.bashrc" ;;
      *)      RC="$HOME/.profile" ;;
    esac
    echo
    echo "  $BIN chưa nằm trong PATH. Thêm vào $RC:"
    echo
    echo "      export PATH=\"$BIN:\$PATH\""
    echo
    echo "  Rồi mở terminal mới, hoặc chạy ngay:  $BIN/declutter"
    ;;
esac

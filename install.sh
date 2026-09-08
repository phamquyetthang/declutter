#!/usr/bin/env bash
# Cài declutter vào PATH.
#   curl -fsSL https://raw.githubusercontent.com/phamquyetthang/declutter/main/install.sh | bash
# hoặc, nếu đã clone repo:  ./install.sh
set -e

REPO_URL="https://github.com/phamquyetthang/declutter.git"
PREFIX="${PREFIX:-$HOME/.local}"
SHARE="$PREFIX/share/declutter"
BIN="$PREFIX/bin"

if [ -f "$(dirname "$0")/declutter" ]; then
  SRC="$(cd "$(dirname "$0")" && pwd)"           # chạy từ repo đã clone
else
  command -v git >/dev/null || { echo "Cần git." >&2; exit 1; }
  echo "→ clone $REPO_URL"
  rm -rf "$SHARE"; mkdir -p "$(dirname "$SHARE")"
  git clone --depth 1 "$REPO_URL" "$SHARE" >/dev/null
  SRC="$SHARE"
fi

if [ "$SRC" != "$SHARE" ]; then
  rm -rf "$SHARE"; mkdir -p "$(dirname "$SHARE")"
  cp -R "$SRC" "$SHARE"
fi

mkdir -p "$BIN"
ln -sf "$SHARE/declutter" "$BIN/declutter"
chmod +x "$SHARE/declutter"

echo "✓ Đã cài: $BIN/declutter"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "  Thêm vào ~/.bashrc hoặc ~/.zshrc:  export PATH=\"$BIN:\$PATH\"" ;;
esac
echo "  Chạy thử: declutter"

#!/usr/bin/env zsh
set -euo pipefail
setopt NO_BANG_HIST
emulate -L zsh

PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"

echo "[omniterm] installing to $BIN"
mkdir -p "$BIN"

SRC_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ -f "$SRC_DIR/bin/poly" ]]; then
  cp -f "$SRC_DIR/bin/poly" "$BIN/poly"
  cp -f "$SRC_DIR/bin/omniterm" "$BIN/omniterm"
else
  for f in poly omniterm; do
    RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/YOUR_GITHUB/kydras-omniterm/main/bin/$f}"
    curl -fsSL "$RAW_URL" -o "$BIN/$f"
    chmod +x "$BIN/$f"
  done
fi

chmod +x "$BIN/poly" "$BIN/omniterm"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" ;;
esac

echo "[omniterm] installed: $(command -v poly) and $(command -v omniterm)"
echo "[omniterm] restart your shell or run: exec zsh -l

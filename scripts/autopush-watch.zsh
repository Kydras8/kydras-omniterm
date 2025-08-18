#!/usr/bin/env zsh
set -euo pipefail
setopt NO_BANG_HIST
emulate -L zsh

REPO="${1:-$HOME/kydras-omniterm}"
cd "$REPO" || exit 0
echo "[autopush] watching $(pwd) … (Ctrl-C to stop)"

# When files change, run autopush
while inotifywait -q -r -e close_write,create,delete,move --exclude '(\.git/|node_modules/|dist/|build/|\.venv/|\.logs/|outputs/)' .; do
  "$REPO/scripts/autopush.zsh" "$REPO" || true
done

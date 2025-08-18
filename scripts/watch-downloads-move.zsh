#!/usr/bin/env zsh
set -euo pipefail
setopt NO_BANG_HIST
emulate -L zsh

SRC="${1:-$HOME/Downloads}"
DST="${2:-$HOME/kydras-omniterm}"
mkdir -p "$DST"

echo "[automv] moving kydras-*.zip from $SRC -> $DST (Ctrl-C to stop)"
while inotifywait -q -e close_write,create,move "$SRC"; do
  for f in "$SRC"/kydras-*.zip(N); do
    [[ -e "$f" ]] || continue
    mv -n "$f" "$DST"/
    echo "[automv] moved: ${f:t} -> $DST/"
  done
done

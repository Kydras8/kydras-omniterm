#!/usr/bin/env zsh
set -euo pipefail
setopt NO_BANG_HIST
emulate -L zsh

REPO="${1:-$HOME/kydras-omniterm}"
SRC1="$HOME/Downloads"
SRC2="$REPO"
ARCH="$REPO/_zips"
mkdir -p "$ARCH"

echo "[auto-ingest] watching:"
echo "  - $SRC1 for kydras-*.zip"
echo "  - $SRC2 for kydras-*.zip"
echo "Press Ctrl-C to stop."

handle_zip() {
  local path="$1"
  [[ ! -f "$path" ]] && return 0
  local fname="${path:t}"

  # only process our zips
  [[ "$fname" != kydras-*.zip ]] && return 0

  # move into archive dir in repo, then ingest
  local dest="$ARCH/$fname"
  if [[ "$path" != "$dest" ]]; then
    mv -f "$path" "$dest"
    echo "[auto-ingest] moved -> $dest"
  fi
  "$REPO/scripts/ingest-zip.zsh" "$dest" "$REPO" || true
}

# initial sweep in case files already exist
for f in "$SRC1"/kydras-*.zip(N) "$SRC2"/kydras-*.zip(N); do
  [[ -e "$f" ]] && handle_zip "$f"
done

# live watch both dirs
inotifywait -m -e close_write,create,move --format '%w%f' "$SRC1" "$SRC2" \
  | while read -r path; do
      handle_zip "$path"
    done

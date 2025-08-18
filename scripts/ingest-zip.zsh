#!/usr/bin/env zsh
set -euo pipefail
setopt NULL_GLOB NO_BANG_HIST
emulate -L zsh

ZIP="${1:-}"
REPO="${2:-$HOME/kydras-omniterm}"
ARCH="$REPO/_zips"
[[ -z "$ZIP" || ! -f "$ZIP" ]] && { echo "[-] zip not found: $ZIP" >&2; exit 1; }

mkdir -p "$ARCH"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "[ingest] processing: $ZIP"
unzip -q "$ZIP" -d "$tmpdir"

# Find probable root (zip may contain kydras-omniterm/… or just subdirs)
root=""
if [[ -d "$tmpdir/kydras-omniterm" ]]; then
  root="$tmpdir/kydras-omniterm"
else
  root="$tmpdir"
fi

# Rsync known subtrees if they exist
for sub in themes bin README-v3.0.0.md README-v*.md; do
  if [[ -e "$root/$sub" ]]; then
    echo "[ingest] syncing $sub → $REPO/$sub"
    rsync -av --delete "$root/$sub" "$REPO/" 2>/dev/null || rsync -av "$root/$sub" "$REPO/"
  fi
done

# fallback: if nothing matched, sync everything but .git
if [[ -z "$(ls -A "$root" 2>/dev/null | grep -v '^\.git$' || true)" ]]; then
  echo "[ingest] nothing to copy from: $root"
else
  echo "[ingest] ensuring repo has new files indexed"
fi

# Archive the zip (keep original name, timestamp suffix if conflict)
base="${ZIP:t}"; dest="$ARCH/$base"
if [[ -e "$dest" ]]; then
  ts=$(date +%s)
  dest="$ARCH/${base:r}.$ts.zip"
fi
mv -f "$ZIP" "$dest"
echo "[ingest] archived zip -> $dest"

# Auto-commit & push (uses your existing autopush script if present)
if [[ -x "$REPO/scripts/autopush.zsh" ]]; then
  "$REPO/scripts/autopush.zsh" "$REPO" || true
else
  cd "$REPO"
  if [[ -n "$(git status --porcelain)" ]]; then
    git add -A
    git commit -m "auto-ingest: $(basename "$dest")"
    branch=$(git rev-parse --abbrev-ref HEAD)
    git push origin "$branch" || true
  fi
fi

echo "[ingest] done."

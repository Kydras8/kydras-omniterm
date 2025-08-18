#!/usr/bin/env zsh
set -euo pipefail
setopt NULL_GLOB NO_BANG_HIST
emulate -L zsh

REPO="${1:-$HOME/kydras-omniterm}"
cd "$REPO" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git remote -v >/dev/null 2>&1 || exit 0

# If changes exist, commit + push
if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  git commit -m "auto: $(hostname) $(date -Is)" || true
  branch=$(git rev-parse --abbrev-ref HEAD)
  git push origin "$branch"
fi

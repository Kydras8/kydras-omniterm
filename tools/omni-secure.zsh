#!/usr/bin/env zsh
set -euo pipefail
setopt NO_BANG_HIST
emulate -L zsh

sub="${1:-list}"

list() {
  compaudit 2>/dev/null || { echo "[secure] compaudit not available"; return 0; }
}

fix() {
  typeset -a C
  C=(${(f)"$(compaudit 2>/dev/null || true)"})
  local p
  for p in "$HOME/.zsh" "$HOME/.zshrc" "$HOME/.zsh/completions" "$HOME/.local/share/zsh" "/usr/local/share/zsh/site-functions"; do
    [[ -e "$p" ]] && C+=("$p")
  done
  typeset -A seen; typeset -a U
  for p in $C; do
    [[ -n "$p" && -e "$p" && -z "${seen[$p]}" ]] && { U+=("$p"); seen[$p]=1; }
  done
  local x
  for x in $U; do
    if [[ -d "$x" ]]; then
      chmod 755 "$x" 2>/dev/null || true
      chmod go-w "$x" 2>/dev/null || true
      find "$x" -type d -exec chmod go-w {} + 2>/dev/null || true
      find "$x" -type f -exec chmod go-w {} + 2>/dev/null || true
    else
      chmod 644 "$x" 2>/dev/null || true
      chmod go-w "$x" 2>/dev/null || true
    fi
  done
  rm -f "$HOME/.zcompdump"* 2>/dev/null || true
  echo "[secure] fixed perms + cleared zcompdump"
  echo "[secure] open a fresh OmniTerm window to re-init completion"
}

case "$sub" in
  list) list ;;
  fix)  fix  ;;
  *) echo "Usage: omniterm secure {list|fix}"; exit 2 ;;
esac

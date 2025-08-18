#!/usr/bin/env zsh
set -euo pipefail
emulate -L zsh
f="bin/omniterm"
[[ -r "$f" ]] || { echo "[-] $f not found"; exit 1; }

append_helpers() {
  cat >> "$f" <<'EOF'

# === direnv integration ===
have(){ command -v "$1" >/dev/null 2>&1; }

direnv_on() {
  have direnv || { echo "[-] install direnv first: sudo apt install -y direnv"; return 127; }
  if ! grep -q 'direnv hook zsh' "$HOME/.zshrc" 2>/dev/null; then
    printf '\n# direnv\nif command -v direnv >/dev/null 2>&1; then eval "$(direnv hook zsh)"; fi\n' >> "$HOME/.zshrc"
    echo "[direnv] hook added to ~/.zshrc (restart shell)"
  else
    echo "[direnv] hook already present"
  fi
  echo "[direnv] tip: create .envrc in your project; run: direnv allow"
}

direnv_off() {
  sed -i '/direnv hook zsh/d' "$HOME/.zshrc" 2>/dev/null || true
  echo "[direnv] hook removed from ~/.zshrc (restart shell)"
}

direnv_allow() { (cd "${1:-$PWD}" && direnv allow); }
direnv_deny()  { (cd "${1:-$PWD}" && direnv deny); }
direnv_reload(){ direnv reload; }

# === OpSec mode ===
opsec_apply_tmux() {
  # tmux-side hardening (no scrollback, no clipboard, clear history)
  tmux set -g history-limit 0       2>/dev/null || true
  tmux set -g message-limit 0       2>/dev/null || true
  tmux set -g set-clipboard off     2>/dev/null || true
  tmux setw -g monitor-activity off 2>/dev/null || true
  # purge current scrollback across panes
  tmux list-panes -a -F '#{pane_id}' 2>/dev/null | xargs -r -n1 tmux clear-history -t
}

opsec_relax_tmux() {
  # sensible defaults back on
  tmux set -g history-limit 2000    2>/dev/null || true
  tmux set -g message-limit 100     2>/dev/null || true
  tmux set -g set-clipboard on      2>/dev/null || true
}

opsec_on() {
  export OMNITERM_OPSEC=1
  tmux set-environment -g OMNITERM_OPSEC 1 2>/dev/null || true
  opsec_apply_tmux
  echo "[opsec] enabled (history disabled in new panes; tmux hardened)"
}

opsec_off() {
  unset OMNITERM_OPSEC
  tmux set-environment -gu OMNITERM_OPSEC 2>/dev/null || true
  opsec_relax_tmux
  echo "[opsec] disabled"
}

opsec_status() {
  if [[ "${OMNITERM_OPSEC:-0}" = 1 ]]; then
    echo "[opsec] ON"
  else
    echo "[opsec] OFF"
  fi
}

EOF
}

wire_dispatcher() {
  # Add dispatcher cases for direnv + opsec
  grep -q '  direnv)' "$f" || sed -i 's|^\s*\*) usage; exit 2 ;;|  direnv)\n    sub="${1:-}"; shift || true; case "$sub" in on) direnv_on;; off) direnv_off;; allow) direnv_allow "$@";; deny) direnv_deny "$@";; reload) direnv_reload;; *) echo "Usage: omniterm direnv {on|off|allow [dir]|deny [dir]|reload}"; exit 2;; esac ;;\n  opsec)\n    sub="${1:-status}"; shift || true; case "$sub" in on) opsec_on;; off) opsec_off;; status) opsec_status;; *) echo "Usage: omniterm opsec {on|off|status}"; exit 2;; esac ;;\n  *) usage; exit 2 ;;|' "$f"
}

# Harden record/log while opsec is on (insert quick guards if those funcs exist)
guard_func() {
  local name="$1" msg="$2"
  grep -n "^$name()" "$f" >/dev/null 2>&1 || return 0
  # insert guard after the opening brace of the function
  sed -i "/^$name()[[:space:]]*()*[[:space:]]*{/{n; s/^/  [[ \"\${OMNITERM_OPSEC:-0}\" = 1 ]] \&\& { echo \"[-] opsec on: $msg disabled\"; return 1; }\\n/}" "$f"
}

append_helpers
wire_dispatcher
guard_func record_start "recording"
guard_func log_start    "logging"

echo "[patch] direnv + opsec wired into bin/omniterm"

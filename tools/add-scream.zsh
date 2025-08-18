#!/usr/bin/env zsh
set -euo pipefail
emulate -L zsh
f="bin/omniterm"
[[ -r "$f" ]] || { echo "[-] $f not found"; exit 1; }

# ---------- helpers to append ----------
append_helpers() {
  cat >> "$f" <<'EOF'

# === asciinema recording ===
have(){ command -v "$1" >/dev/null 2>&1; }

record_start() {
  have asciinema || { echo "[-] install asciinema: sudo apt install -y asciinema"; return 127; }
  local dir="${OMNITERM_REC_DIR:-$HOME/kydras-omniterm/.casts}"
  mkdir -p "$dir"
  local file="$dir/${OMNITERM_SESSION:-k-omni}-$(date +%Y%m%d-%H%M%S).cast"
  tmux display-message "Recording to $file (Ctrl-D in this pane to stop)"
  tmux send-keys "asciinema rec -q '$file'" C-m
}

record_stop() {
  # sends EOF to the active pane; asciinema stops on EOF
  tmux send-keys C-d
}

record_play() {
  local file="${1:-}"
  local dir="${OMNITERM_REC_DIR:-$HOME/kydras-omniterm/.casts}"
  [[ -n "$file" ]] || file="$(ls -1t "$dir"/*.cast 2>/dev/null | head -n1 || true)"
  [[ -r "$file" ]] || { echo "[-] no cast found in $dir"; return 2; }
  asciinema play "$file"
}

# === simple job queue ===
_queue_dir(){ print -- "${OMNITERM_QUEUE_DIR:-$HOME/kydras-omniterm/.queue}"; }

queue_add() {
  local lang="${1:-:zsh}"; shift || true
  [[ "$lang" == :* ]] || { echo "Usage: omniterm queue add :lang 'code' [--title t] [--notify]"; return 2; }
  local title="job$RANDOM" notify=0
  # parse optional flags at the end
  local args=("$@")
  for i in {1..${#args[@]}}; do
    case "${args[$i]:-}" in
      --title) ((i++)); title="${args[$i]:-$title}" ;;
      --notify) notify=1 ;;
    esac
  done
  local code="$*"
  local q="$(_queue_dir)"; mkdir -p "$q"
  local fn="$q/$(date +%s)-$RANDOM.job"
  {
    echo "lang='$lang'"
    echo "title='${title//\'/}'"
    echo "notify='$notify'"
    echo "code='${code//\'/}'"
  } > "$fn"
  echo "[queue] added -> $fn"
}

queue_list() {
  local q="$(_queue_dir)"; mkdir -p "$q"
  ls -1t "$q"/*.job 2>/dev/null || echo "[queue] (empty)"
}

queue_clear() {
  local q="$(_queue_dir)"
  rm -f "$q"/*.job 2>/dev/null || true
  echo "[queue] cleared"
}

queue_run() {
  local q="$(_queue_dir)"; mkdir -p "$q"
  local sess="${OMNITERM_SESSION:-k-omni}"
  tmux has-session -t "$sess" 2>/dev/null || tmux new-session -d -s "$sess" -n zsh zsh -l
  # dedicated runner window that loops
  tmux new-window -t "$sess" -n "queue" "bash -lc '
    Q=\"$q\"
    echo \"[queue] watching \$Q (Ctrl-C to stop)\"
    while true; do
      for f in \$(ls -1 \"\$Q\"/*.job 2>/dev/null); do
        echo \"[queue] running \$f\"
        . \"\$f\"
        poly \"\$lang\" \"\$code\"
        st=\$?
        if [[ \"\$notify\" == 1 ]]; then
          command -v notify-send >/dev/null 2>&1 && notify-send \"omniterm queue\" \"\$title exited \$st\" || printf \"\a\"
        fi
        rm -f \"\$f\"
      done
      sleep 2
    done
  '"
}

EOF
}

wire_dispatcher() {
  # Insert new cases if missing
  grep -q '  record)' "$f" || sed -i 's|^\s*\*) usage; exit 2 ;;|  record)\n    sub="${1:-}"; shift || true; case "$sub" in start) record_start;; stop) record_stop;; play) record_play "$@";; *) echo "Usage: omniterm record {start|stop|play [file]}"; exit 2;; esac ;;\n  queue)\n    sub="${1:-}"; shift || true; case "$sub" in add) queue_add "$@";; list) queue_list;; run) queue_run;; clear) queue_clear;; *) echo "Usage: omniterm queue {add :lang code [--title t] [--notify]|list|run|clear}"; exit 2;; esac ;;\n  *) usage; exit 2 ;;|' "$f"
}

grep -q '=== asciinema recording ===' "$f" || append_helpers
wire_dispatcher
echo "[patch] record + queue added to bin/omniterm"

#!/usr/bin/env zsh
set -euo pipefail
emulate -L zsh

f="bin/omniterm"
[[ -r "$f" ]] || { echo "[-] $f not found"; exit 1; }

append_helpers() {
  cat >> "$f" <<'EOF'

# === modern APT (Nala) + fast mirror picker ===

have(){ command -v "$1" >/dev/null 2>&1; }

enable_parallel_apt() {
  # Prefer parallel queueing per host (safe for apt & nala)
  local cfg="/etc/apt/apt.conf.d/90omniterm-parallel"
  sudo bash -lc "cat > '$cfg' <<'C'
Acquire::Queue-Mode "host";
Acquire::Retries "3";
C"
  echo "[mirrors] enabled parallel APT in $cfg"
}

install_nala() {
  sudo apt update
  sudo apt install -y nala
  echo "[mirrors] nala installed: $(nala --version 2>/dev/null | head -n1)"
}

# Switch your 'au' maintenance alias to use nala (instead of apt/apt-fast)
speed_apt_use_nala() {
  if ! grep -q 'alias au=' "$HOME/.zshrc" 2>/dev/null; then
    printf "%s\n" 'alias au="sudo nala update && sudo nala upgrade -y && sudo nala autoremove -y && sudo nala clean"' >> "$HOME/.zshrc"
  else
    sed -i 's|^alias au=.*|alias au="sudo nala update && sudo nala upgrade -y && sudo nala autoremove -y && sudo nala clean"|' "$HOME/.zshrc"
  fi
  echo "[mirrors] set 'au' to use nala. Reload shell (exec zsh -l) to apply."
}

# Extract base URLs (column 2) from a sources.list file
_extract_urls() {
  awk '$1 ~ /^deb/ {print $2}' "$1" | sed 's|/*$||' | sort -u
}

# Benchmark a list of base URLs by timing a small index fetch
_bench_urls() {
  local urls=("$@")
  local tmp; tmp="$(mktemp)"
  for u in "${urls[@]}"; do
    # choose a small, commonly present file; fallbacks for Debian/Kali
    for path in "dists/kali-rolling/InRelease" "dists/stable/InRelease" "dists/bookworm/InRelease"; do
      if curl -m 6 -fsSL -o /dev/null -w "%{time_total}\t$u/$path\n" "$u/$path" 2>/dev/null; then
        break
      fi
    done
  done | sort -n > "$tmp"
  cat "$tmp"
  rm -f "$tmp"
}

# Update apt-fast.conf MIRRORS=( 'url1' 'url2' ... )
_update_aptfast_mirrors() {
  local urls=("$@")
  [[ ${#urls[@]} -eq 0 ]] && { echo "[mirrors] no URLs to write into apt-fast.conf"; return 0; }
  local conf="/etc/apt-fast.conf"
  local joined=""
  # quote each url for zsh-safe eval
  for u in "${urls[@]}"; do joined="$joined '$u'"; done
  sudo bash -lc "
    if [[ -f '$conf' ]]; then
      if grep -q '^MIRRORS=' '$conf'; then
        sed -i \"s|^MIRRORS=.*|MIRRORS=(${joined# })|\" '$conf'
      else
        printf '\nMIRRORS=(%s)\n' \"$joined\" >> '$conf'
      fi
    fi
  "
  echo "[mirrors] wrote top mirrors to $conf"
}

mirrors_auto() {
  enable_parallel_apt
  have nala || install_nala

  echo "[mirrors] running: sudo nala fetch --auto -y"
  # Let nala generate a tuned sources file (non-interactive)
  # It usually writes a *nala*.list; we’ll search for it.
  sudo nala fetch --auto -y || true

  local sfile=""
  for guess in /etc/apt/sources.list.d/*nala*.list /etc/apt/sources.list.d/nala/*.list /etc/apt/sources.list; do
    [[ -r "$guess" ]] && { sfile="$guess"; break; }
  done
  [[ -z "$sfile" ]] && { echo "[-] could not find a sources.list after nala fetch"; return 2; }

  echo "[mirrors] using sources from: $sfile"
  local urls=(); urls=("${(@f)$(_extract_urls "$sfile")}")
  [[ ${#urls[@]} -eq 0 ]] && { echo "[-] no URLs found in $sfile"; return 2; }

  echo "[mirrors] benchmarking ${#urls[@]} candidate mirrors..."
  local ranked; ranked="$(_bench_urls ${urls[@]})"
  print -- "$ranked" | head -n 10

  # Take top 4 URLs from the benchmark output
  local best=()
  local i=0
  while IFS=$'\t' read -r secs full; do
    # cut base (strip the "/dists/...") — we printed "$u/$path"; base is before /dists
    local base="${full%%/dists/*}"
    [[ -n "$base" ]] && best+="$base"
    (( ++i >= 4 )) && break
  done <<< "$ranked"

  # De-dup
  local uniq=("${(@u)best}")

  # Update apt-fast.conf mirrors to match the winners (if apt-fast is installed)
  if have apt-fast; then
    _update_aptfast_mirrors "${uniq[@]}"
  fi

  # Final update so APT/Nala use the tuned list immediately
  sudo apt update || true
  echo "[mirrors] done."
}

EOF
}

wire_dispatcher() {
  # Add new cases before the final default branch
  if ! grep -q 'omniterm mirrors' "$f"; then
    sed -i 's|^\s*\*) usage; exit 2 ;;|  mirrors)\n    sub="${1:-}"; shift || true; case "$sub" in auto) mirrors_auto;; *) echo "Usage: omniterm mirrors auto"; exit 2;; esac ;;\n  speed-apt)\n    sub="${1:-}"; shift || true; case "$sub" in use-nala) speed_apt_use_nala;; *) :;; esac ;;\n  *) usage; exit 2 ;;|' "$f"
  fi
}

# Make sure helpers exist once
grep -q '=== modern APT (Nala) \+ fast mirror picker ===' "$f" || append_helpers
wire_dispatcher

echo "[patch] Nala + mirrors wired into bin/omniterm"

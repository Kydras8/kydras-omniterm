#!/usr/bin/env zsh
set -euo pipefail
emulate -L zsh

f="bin/omniterm"
[[ -r "$f" ]] || { echo "[-] $f not found"; exit 1; }

# 1) Append helpers (once)
if ! grep -q '=== speed-apt integration ===' "$f"; then
  cat >> "$f" <<'EOF'

# === speed-apt integration ===
have(){ command -v "$1" >/dev/null 2>&1; }

speed_apt_install() {
  sudo apt update
  sudo apt install -y aria2 curl
  /bin/bash -c "$(curl -sL https://git.io/vokNn)"   # apt-fast quick install
  sudo sed -i \
    -e "s|^#\?MIRRORS=.*|MIRRORS=( 'http://http.kali.org/kali' )|" \
    -e "s/^#\?_MAXNUM=.*/_MAXNUM=16/" \
    -e "s/^#\?_MAXCONPERSRV=.*/_MAXCONPERSRV=10/" \
    -e "s/^#\?_SPLITCON=.*/_SPLITCON=8/" \
    -e "s/^#\?_MINSPLITSZ=.*/_MINSPLITSZ=5M/" \
    /etc/apt-fast.conf 2>/dev/null || true
  echo "[speed-apt] apt-fast installed & configured."
}

speed_apt_on() {
  if ! grep -q 'alias au=' "$HOME/.zshrc" 2>/dev/null; then
    printf "%s\n" 'alias au="sudo apt-fast update && sudo apt-fast full-upgrade -y && sudo apt-fast autoremove --purge -y && sudo apt-fast autoclean"' >> "$HOME/.zshrc"
  else
    sed -i 's|^alias au=.*|alias au="sudo apt-fast update && sudo apt-fast full-upgrade -y && sudo apt-fast autoremove --purge -y && sudo apt-fast autoclean"|' "$HOME/.zshrc"
  fi
  echo "[speed-apt] enabled. Reload shell (exec zsh -l) to use au."
}

speed_apt_off() {
  sed -i 's|^alias au=.*|alias au="sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt autoclean"|' "$HOME/.zshrc" 2>/dev/null || true
  echo "[speed-apt] disabled. Reload shell to apply."
}

speed_apt_test() {
  if command -v apt-fast >/dev/null 2>&1; then
    echo "[speed-apt] apt-fast: $(apt-fast --version 2>/dev/null | head -n1)"
    echo "[speed-apt] running update (may show debug lines)…"
    sudo apt-fast -o Debug::NoLocking=1 -o Debug::pkgAcquire::Worker=1 update || true
  else
    echo "[-] apt-fast not found. Run: omniterm speed-apt install"
    return 1
  fi
}

# === version management ===
version_file(){ print -- "${OMNITERM_VERSION_FILE:-$HOME/kydras-omniterm/VERSION}"; }
version_show(){
  local vf; vf="$(version_file)"
  [[ -r "$vf" ]] && cat "$vf" || echo "unknown"
}
version_bump(){
  local kind="patch" msg="" repo="$HOME/kydras-omniterm"
  while [[ "${1:-}" == --* ]]; do
    case "$1" in
      --major|--minor|--patch) kind="${1#--}";;
      --repo) shift; repo="${1:-$repo}";;
      *) break;;
    esac; shift || true
  done
  msg="${*:-}"
  [[ -d "$repo/.git" ]] || { echo "[-] not a git repo: $repo"; return 2; }
  local vf; vf="$(version_file)"
  local v="0.0.0"; [[ -r "$vf" ]] && v="$(<"$vf")"
  local M m p; IFS=. read -r M m p <<< "$v"
  : "${M:=0}" "${m:=0}" "${p:=0}"
  case "$kind" in
    major) ((M+=1,m=0,p=0));;
    minor) ((m+=1,p=0));;
    patch) ((p+=1));;
  esac
  local nv="${M}.${m}.${p}"
  print -- "$nv" > "$vf"
  ( cd "$repo"
    git add "$(realpath --relative-to="$repo" "$vf")" || git add VERSION
    git commit -m "${msg:-chore(version): bump to v$nv}"
    git tag "v$nv" -m "v$nv"
    git push && git push --tags
  )
  echo "[version] now $nv"
}
EOF
fi

# 2) Add dispatcher cases for speed-apt + version (before final default)
if ! grep -q 'omniterm speed-apt' "$f"; then
  sed -i 's|^\s*\*) usage; exit 2 ;;|  speed-apt)\n    sub="${1:-}"; shift || true; case "$sub" in install) speed_apt_install;; on) speed_apt_on;; off) speed_apt_off;; test) speed_apt_test;; *) echo "Usage: omniterm speed-apt {install|on|off|test}"; exit 2;; esac ;;\n  version)\n    sub="${1:-show}"; shift || true; case "$sub" in show) version_show;; bump) version_bump "$@";; *) echo "Usage: omniterm version {show|bump [--major|--minor|--patch] [message]}"; exit 2;; esac ;;\n  *) usage; exit 2 ;;|' "$f"
fi

echo "[patch] done."

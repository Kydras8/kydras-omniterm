#!/usr/bin/env zsh
set -euo pipefail
setopt NO_BANG_HIST
emulate -L zsh

fix=0
files=()
while (( $# > 0 )); do
  case "$1" in
    --fix) fix=1 ;;
    *) files+=("$1") ;;
  esac
  shift
done
if (( ${#files[@]} == 0 )); then
  print -u2 "usage: omni-lint.zsh [--fix] <file|dir> ..."
  exit 2
fi

collect(){ local p
  for p in "$@"; do
    if [[ -f "$p" ]]; then
      echo "$p"
    elif [[ -d "$p" ]]; then
      find "$p" -type f \( -name "*.sh" -o -name "*.zsh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.rb" -o -name "*.php" -o -name "*.lua" -o -name "*.go" -o -name "*.c" -o -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" -o -name "*.h" -o -name "*.hpp" -o -name "Dockerfile" \)
    fi
  done
}

lint_file(){ local f="$1" ext="${f##*.}" base="${f:t}"
  [[ "$base" == "Dockerfile" ]] && ext="Dockerfile"
  case "$ext" in
    sh)
      ((fix)) && command -v shfmt >/dev/null && shfmt -w "$f" || true
      command -v shellcheck >/dev/null && shellcheck "$f" || true
      bash -n "$f" || sh -n "$f"
      ;;
    zsh)  zsh -n "$f" ;;
    py)
      ((fix)) && command -v black >/dev/null && black -q "$f" || true
      command -v ruff  >/dev/null && ruff "$f" || true
      python3 -m py_compile "$f"
      ;;
    js)
      ((fix)) && command -v prettier >/dev/null && prettier -w "$f" || true
      command -v eslint   >/dev/null && eslint "$f" || true
      ;;
    ts)
      ((fix)) && command -v prettier >/dev/null && prettier -w "$f" || true
      if command -v tsc >/dev/null; then tsc --noEmit --pretty false -p . || tsc --noEmit --pretty false "$f"; fi
      command -v eslint >/dev/null && eslint "$f" || true
      ;;
    json) command -v jq >/dev/null && jq -e . "$f" >/dev/null ;;
    yml|yaml) command -v yamllint >/dev/null && yamllint -s "$f" ;;
    rb)
      command -v ruby >/dev/null && ruby -c "$f"
      ;;
    php)
      ((fix)) && command -v php-cs-fixer >/dev/null && php-cs-fixer fix "$f" || true
      php -l "$f"
      ;;
    lua)
      ((fix)) && command -v stylua >/dev/null && stylua "$f" || true
      command -v luac  >/dev/null && luac -p "$f" || true
      ;;
    go)
      ((fix)) && command -v gofmt >/dev/null && gofmt -w "$f" || true
      command -v golangci-lint >/dev/null && golangci-lint run "$f" || true
      ;;
    c)    command -v gcc >/dev/null && gcc -fsyntax-only "$f" ;;
    cpp|cc|cxx|hpp|h) command -v g++ >/dev/null && g++ -fsyntax-only "$f" ;;
    java) command -v javac >/dev/null && javac -Xlint "$f" ;;
    Dockerfile)
      command -v hadolint >/dev/null && hadolint "$f"
      ;;
    *) echo "[skip] $f"; return 0 ;;
  esac
}

typeset -i ok=0 fail=0
all=(${(@f)$(collect "$files[@]")})
if (( ${#all[@]} == 0 )); then
  echo "no files found"; exit 0
fi
for f in "${all[@]}"; do
  echo "[lint] $f"
  if lint_file "$f"; then ((ok++)); else ((fail++)); fi
done
echo "[summary] ok=$ok fail=$fail total=${#all[@]}"
(( fail == 0 )) || exit 1

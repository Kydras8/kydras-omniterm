#!/usr/bin/env zsh
set -euo pipefail
setopt NO_BANG_HIST
export PATH="$(pwd)/bin:$PATH"

echo "[test] zsh echo"
poly :zsh 'echo ZOK' | grep -q ZOK

echo "[test] autodetect js"
poly 'console.log(42)' | grep -q 42

echo "[test] python add"
poly :py 'print(2+3)' | grep -q 5

if command -v node >/dev/null 2>&1; then
  echo "[test] node console"
  poly :js 'console.log(7*6)' | grep -q 42
fi

if command -v gcc >/dev/null 2>&1; then
  echo "[test] c hello"
  poly :c $'#include <stdio.h>\nint main(){puts("COK");}' | grep -q COK
fi

if command -v tmux >/dev/null 2>&1; then
  echo "[test] omniterm basics"
  OMNITERM_SESSION="ci-omni" bin/omniterm start & sleep 1
  OMNITERM_SESSION="ci-omni" bin/omniterm start -d
  OMNITERM_SESSION="ci-omni" bin/omniterm new :bash demo
  OMNITERM_SESSION="ci-omni" bin/omniterm run :zsh 'echo hi from omni'
  tmux kill-session -t ci-omni
fi

echo "[test] DONE"

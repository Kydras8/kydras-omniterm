# Kydras OmniTerm

Polyglot terminal runner with multi-session launcher.

## What’s new (v0.2.0)
- **Auto-detect language** (shebangs, ```fences``` with tags, common heuristics)
- **Docker/Podman sandbox**: `--docker` or `--docker=IMAGE` (no-net, limited CPU/mem)
- **Plugin runners**: drop `~/.poly/runners.d/*.zsh` to add languages
- **Persistent multi-sessions** via **tmux** (`bin/omniterm`): open unlimited windows to run different tasks concurrently
- **CI**: GitHub Actions runs smoke tests on Ubuntu

## Install

```zsh
# Quick installer (after you publish, update Kydras8 below)
curl -fsSL https://raw.githubusercontent.com/Kydras8/kydras-omniterm/main/install.sh | zsh

# Manual
chmod +x bin/poly bin/omniterm
mkdir -p ~/.local/bin
cp bin/poly bin/omniterm ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
exec zsh -l
```

## OmniTerm (multi-session)
Run many tasks in parallel using tmux:

```zsh
omniterm start             # create/attach default session
omniterm new :zsh build    # new window named 'build' with zsh
omniterm new :py repl      # new Python REPL window
omniterm run :bash 'wget https://...'  # run a one-off job in its own window
omniterm list              # list windows
omniterm attach            # reattach if detached
omniterm kill              # kill session
```

## Poly usage

```zsh
poly :py 'print(2+2)'          # explicit
poly 'console.log(42)'         # auto-detects js
poly --docker :py 'print(1)'   # run in docker sandbox (python:3-alpine)
poly :c $'#include <stdio.h>\nint main(){puts("ok");}'
```

## Plugins
Create `~/.poly/runners.d/NAME.zsh` and implement a function:

```zsh
# Example: sqlite
poly_can sqlite
poly_run_sqlite() { print -r -- "$1" | sqlite3 -batch -noheader -csv "${2:-:memory:}"; }
```

## Test
```zsh
zsh test/test-quick.zsh
```

## License
MIT © 2025 Kydras Systems

### Recording & Queue
Record a pane and play it back later:
```zsh
omniterm record start      # Ctrl-D to stop
omniterm record play       # play last recording
```

Batch jobs with a simple queue:
```zsh
omniterm queue add :bash 'echo one; sleep 1' --title one --notify
omniterm queue add :py 'print(2+2)' --title two --notify
omniterm queue run
```

### Zsh completion
```zsh
# Installed to ~/.zsh/completions/_omniterm
# Tab-complete subcommands, languages, and themes.
```

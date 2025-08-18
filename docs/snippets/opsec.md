### OpSec mode
Lock down history and tmux scrollback for sensitive work.

```zsh
omniterm opsec on
omniterm opsec status
omniterm opsec off
```

**What it does**
- disables zsh history in new panes (NO_HISTORY)
- sets umask 077
- clears/limits tmux scrollback & clipboard
- blocks `omniterm record start` and `omniterm log start` while ON

**Tips**
- Purge existing scrollback: `tmux clear-history -a`

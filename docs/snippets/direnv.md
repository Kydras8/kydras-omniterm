### Direnv (per-project envs)
Enable once, then allow per project to auto-load `.envrc`.

```zsh
omniterm direnv on
direnv allow    # run inside a project that has .envrc
```

**Example `.envrc`**
```sh
export AWS_PROFILE=kydras-dev
PATH_add bin
LAYOUT_python=3
```

Security: `.envrc` must be explicitly allowed; keep secrets out of git.

# zsh theme: kydras-redteam
autoload -Uz colors; colors
setopt PROMPT_SUBST

git_branch() {
  local b; b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
  print -rn -- "%F{#d4af37}⎇%f %F{#b3002d}${b}%f "
}

exit_mark() { (( $? == 0 )) && print -rn "" || print -rn "%F{196}✘%f " }

PROMPT='%F{#b3002d}%*%f %F{#d4af37}%n@%m%f %F{#c8c8c8}%~%f $(git_branch)
%F{#b3002d}❯%f '
RPROMPT='$(exit_mark)'

# zsh theme: kydras-gold
autoload -Uz colors; colors
setopt PROMPT_SUBST

git_branch() {
  local b; b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
  print -rn -- "%F{#d69913}⎇%f %F{#d69913}${b}%f "
}

exit_mark() { (( $? == 0 )) && print -rn "" || print -rn "%F{196}✘%f " }

PROMPT='%F{#d69913}%*%f %F{#d69913}%n@%m%f %F{#ffffe1}%~%f $(git_branch)
%F{#d69913}❯%f '
RPROMPT='$(exit_mark)'

# zsh theme: kydras-stealth
autoload -Uz colors; colors
setopt PROMPT_SUBST

git_branch() { local b; b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return; print -rn -- "%F{#bbbbbb}${b}%f "; }
exit_mark() { (( $? == 0 )) && print -rn "" || print -rn "%F{196}✘%f "; }

PROMPT='%F{#bbbbbb}%n%f@%F{#e6e6e6}%m%f %F{#bbbbbb}%~%f
%F{#e6e6e6}$%f '
RPROMPT='$(git_branch)%F{#777777}%*%f $(exit_mark)'

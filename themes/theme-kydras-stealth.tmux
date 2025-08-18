# theme: kydras-stealth
set -g status on
set -g status-style "bg=#0a0a0a,fg=#bbbbbb"
set -g status-interval 2
set -g pane-border-style "fg=#2a2a2a"
set -g pane-active-border-style "fg=#888888"
set -g message-style "bg=#0a0a0a,fg=#e6e6e6"

setw -g window-status-format " #[fg=#777777]#I #[fg=#bbbbbb]#W "
setw -g window-status-current-format " #[bg=#e6e6e6,fg=#0a0a0a,bold] #I #[fg=#0a0a0a]#W #[default]"
setw -g window-status-separator ""

set -g status-left-length 50
set -g status-right-length 100
set -g status-left "#[fg=#e6e6e6]● #[fg=#bbbbbb]#S #[fg=#777777]| #[fg=#bbbbbb]#(whoami)@#H "
set -g status-right "#[fg=#bbbbbb]%H:%M %Y-%m-%d #[fg=#777777]⎇ #[fg=#bbbbbb]#(git -C #{pane_current_path} rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n') "

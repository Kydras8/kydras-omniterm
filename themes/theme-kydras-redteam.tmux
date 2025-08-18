# theme: kydras-redteam
set -g status on
set -g status-style "bg=#0b0b0b,fg=#c8c8c8"
set -g status-interval 2
set -g pane-border-style "fg=#3a3a3a"
set -g pane-active-border-style "fg=#d4af37"
set -g message-style "bg=#0b0b0b,fg=#d4af37"
set -g message-command-style "bg=#0b0b0b,fg=#ff4d4d"

setw -g window-status-format " #[fg=#c8c8c8]#I #[fg=#c8c8c8]#W "
setw -g window-status-current-format " #[bg=#b3002d,fg=#0b0b0b,bold] #I #[fg=#0b0b0b]#W #[default]"
setw -g window-status-separator ""

set -g status-left-length 60
set -g status-right-length 120
set -g status-left "#[fg=#d4af37]◈ #[fg=#b3002d]#S #[fg=#c8c8c8]| #[fg=#b3002d]#(whoami)@#H "
set -g status-right "#[fg=#c8c8c8]%Y-%m-%d %H:%M #[fg=#d4af37]⎇ #[fg=#b3002d]#(git -C #{pane_current_path} rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n') "

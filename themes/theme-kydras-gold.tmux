# theme: kydras-gold (auto-generated from logo)
# palette: {'bg': '#050502', 'bg_dim': '#030301', 'gold': '#d69913', 'silver': '#ffffe1', 'accent': '#d69913', 'border': '#999987', 'active_border': '#d69913'}

set -g status on
set -g status-interval 2
set -g status-justify centre
set -g status-style "bg=#050502,fg=#ffffe1"

set -g pane-border-style "fg=#999987"
set -g pane-active-border-style "fg=#d69913"

set -g message-style "bg=#050502,fg=#d69913"
set -g message-command-style "bg=#050502,fg=#d69913"

setw -g window-status-format " #[fg=#ffffe1]#I #[fg=#ffffe1]#W "
setw -g window-status-current-format " #[bg=#d69913,fg=#050502,bold] #I #[fg=#050502]#W #[default]"
setw -g window-status-separator ""

set -g status-left-length 60
set -g status-right-length 120

# Left: logo mark + session + user@host
set -g status-left "#[fg=#d69913]✦ #[fg=#d69913]#S #[fg=#ffffe1]| #[fg=#d69913]#(whoami)@#H "

# Right: time + git branch (if any)
set -g status-right "#[fg=#ffffe1]%Y-%m-%d %H:%M #[fg=#d69913]⎇ #[fg=#d69913]#(git -C #{pane_current_path} rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n') "

# Optional: if you use tmux-prefix-highlight plugin, set fallback colors
set -g @prefix_highlight_fg "#050502"
set -g @prefix_highlight_bg "#d69913"
set -g @prefix_highlight_show_copy_mode "on"

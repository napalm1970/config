function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

end

starship init fish | source
if test -f ~/.cache/ags/user/generated/terminal/sequences.txt
    cat ~/.cache/ags/user/generated/terminal/sequences.txt
end

zoxide init --cmd cd fish | source

alias pamcan=pacman
alias v=nvim
alias hh="shutdown -h now"
alias rr="reboot"
alias gg="lazygit"
alias fc="nvim ~/.config/fish/config.fish"
alias hc="nvim ~/.config/hypr/hyprland.conf"
alias wbc="nvim ~/.config/waybar/config.jsonc"
alias cat="bat"
alias y="yazi"
alias ls="eza -Ghl --color=always --icons=always"

set -Ux EDITOR nvim
set fzf_history_time_format %d-%m-%y
set -g fish_user_paths /home/napalm/.local/bin

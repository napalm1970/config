source $HOME/.config/fish/skeys.fish

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
if test -f $HOME/.cache/ags/user/generated/terminal/sequences.txt
    cat $HOME/.cache/ags/user/generated/terminal/sequences.txt
end

zoxide init --cmd cd fish | source

alias pamcan=pacman
alias v=nvim
alias hh="shutdown -h now"
alias rr="reboot"
alias gg="lazygit"
alias fc="nvim $HOME/.config/fish/config.fish"
alias hc="nvim $HOME/.config/hypr/hyprland.conf"
alias wbc="nvim $HOME/.config/waybar/config.jsonc"
alias cat="bat"
alias y="yazi"
alias ls="eza -Ghl --color=always --icons=always"
alias upd="yay -Syu"
alias doc="evince &"
alias c="clear"
alias b="btop"

set -Ux EDITOR nvim
set fzf_history_time_format %d-%m-%y
set -g fish_user_paths $HOME/.local/bin
set -Ux FZF_DEFAULT_OPTS "--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
# set -x IDF_PATH $HOME/esp/esp-idf/
fish_add_path $HOME/.local/bin
fish_add_path $HOME/esp/ESP8266_RTOS_SDK/components/esptool_py/esptool/
fish_add_path $HOME/esp/ESP8266_RTOS_SDK/components/partition_table/
fish_add_path $HOME/.espressif/tools/xtensa-lx106-elf/esp-2020r3-49-gd5524c1-8.4.0/xtensa-lx106-elf/bin
fish_add_path $HOME/.espressif/python_env/rtos3.4_py3.13_env/bin
fish_add_path $HOME/esp/ESP8266_RTOS_SDK/tools

set -x IDF_PATH $HOME/esp/ESP8266_RTOS_SDK/
fish_add_path $HOME/esp/ESP8266_RTOS_SDK/tools/

# fish_add_path $HOME/esp/xtensa-lx106-elf/bin
fish_add_path $HOME/.espressif/tools/xtensa-lx106-elf/esp-2020r3-49-gd5524c1-8.4.0/xtensa-lx106-elf/bin/
fish_add_path $HOME/.espressif/python_env/rtos3.4_py3.13_env/bin/

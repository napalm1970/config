# source $HOME/.config/fish/skeys.fish

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting

end

set -gx MANPAGER 'nvim +Man!'

# starship init fish | source
# if test -f $HOME/.cache/ags/user/generated/terminal/sequences.txt
#     cat $HOME/.cache/ags/user/generated/terminal/sequences.txt
# end

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
alias lg="lazygit"
alias upd="yay -Syu"
alias doc="evince &"
alias c="clear"
alias b="btop"

function p
    set -l selection (find ~/.password-store -type f -name "*.gpg" | sed "s|$HOME/.password-store/||; s|\.gpg\$||" | fzf --height 40% --reverse --header="Search Passwords")
    if test -n "$selection"
        pass -c "$selection"
    end
end

function gemini
    if not set -q GEMINI_API_KEY
        set -l key (pass gemini/GEMINI_API_KEY)
        if test -n "$key"
            set -gx GEMINI_API_KEY $key
        else
            echo "Error: GEMINI_API_KEY could not be retrieved from pass."
            return 1
        end
    end
    command gemini $argv
end

set -Ux EDITOR nvim
set fzf_history_time_format %d-%m-%y
set -g fish_user_paths $HOME/.local/bin
set -Ux FZF_DEFAULT_OPTS "--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

# ESP-IDF / ESP8266 SDK Paths
fish_add_path $HOME/.local/bin
set -x IDF_PATH $HOME/esp/ESP8266_RTOS_SDK/
fish_add_path $HOME/esp/ESP8266_RTOS_SDK/tools/
fish_add_path $HOME/esp/ESP8266_RTOS_SDK/components/esptool_py/esptool/
fish_add_path $HOME/esp/ESP8266_RTOS_SDK/components/partition_table/
fish_add_path $HOME/.espressif/tools/xtensa-lx106-elf/esp-2020r3-49-gd5524c1-8.4.0/xtensa-lx106-elf/bin/
fish_add_path $HOME/.espressif/python_env/rtos3.4_py3.13_env/bin/

# Auto-activate System Python Virtual Environment
if test -f $HOME/.python_venv/bin/activate.fish
    source $HOME/.python_venv/bin/activate.fish
end

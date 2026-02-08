if status is-interactive
    set -g fish_greeting
    fish_vi_key_bindings
end

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

fish_add_path $HOME/.local/bin

# Auto-activate System Python Virtual Environment
if test -f $HOME/.python_venv/bin/activate.fish
    source $HOME/.python_venv/bin/activate.fish
end

alias v nvim
alias u "yay -Syu"
alias fc "nvim $HOME/Documents/config/fish/config.fish"
alias hc "nvim $HOME/Documents/config/hypr/hyprland.conf"
alias sr "portproton $HOME/Sklad/Games/stalker2/Stalker2.exe"
alias hh "shutdown -h now"
alias rr "shutdown -r now"
alias y yazi
alias c clear

abbr -a bwl 'set -xg BW_SESSION (bw unlock --raw)'

fish_config theme choose tomorrow-night-bright
set fish_color_error red --bold

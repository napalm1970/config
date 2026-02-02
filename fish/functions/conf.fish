function conf
    # Папка с конфигами
    set -l config_dir "$HOME/Documents/config"

    # Используем fd для поиска файлов (игнорируем .git) и fzf для выбора
    set -l file (fd --type f --hidden --exclude .git . "$config_dir" | fzf --preview "bat --color=always --style=numbers --line-range=:500 {}")

    # Если файл выбран - открываем его в редакторе
    if test -n "$file"
        $EDITOR "$file"
    end
end

function fish_command_not_found
    set -l cmd $argv[1]

    # Проверяем, установлен ли pkgfile
    if not type -q pkgfile
        __fish_default_command_not_found_handler $cmd
        echo -e "\n\x1b[33mСовет: Установите 'pkgfile' (sudo pacman -S pkgfile), чтобы видеть, в каком пакете находится команда.\x1b[0m"
        return
    end

    # Ищем пакет, содержащий бинарный файл (-b)
    set -l packages (pkgfile -b $cmd 2>/dev/null)

    if test -n "$packages"
        echo -e "\x1b[1;31mКоманда '$cmd' не найдена, но может быть установлена из следующих пакетов:\x1b[0m"
        for pkg in $packages
            echo -e "  \x1b[1;34m$pkg\x1b[0m"
        end
    else
        __fish_default_command_not_found_handler $cmd
    end
end

#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Флаг Dry Run
DRY_RUN=false

# Проверка аргументов
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}[!!!] ЗАПУЩЕН РЕЖИМ DRY-RUN (ХОЛОСТОЙ ПРОГОН) [!!!]${NC}"
    echo -e "${YELLOW}Никакие изменения не будут внесены в систему.${NC}\n"
fi

# Пути
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry() { echo -e "${YELLOW}[DRY-RUN]${NC} $1"; }

# Функция для безопасного выполнения команд
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        log_dry "Выполнил бы: $*"
    else
        "$@"
    fi
}

# 1. Обновление системы и установка зависимостей
log_info "Обновление системы..."
run_cmd sudo pacman -Syu --noconfirm

if ! command -v git &> /dev/null; then
    log_info "Git не найден. Планируется установка."
    run_cmd sudo pacman -S --noconfirm git
fi

# 2. Проверка и установка yay (AUR helper)
if ! command -v yay &> /dev/null; then
    log_info "yay не найден. Планируется установка..."
    run_cmd sudo pacman -S --needed --noconfirm base-devel
    run_cmd git clone https://aur.archlinux.org/yay.git /tmp/yay
    # В dry-run мы не можем зайти в папку, которой нет
    if [ "$DRY_RUN" = false ]; then
        cd /tmp/yay
        makepkg -si --noconfirm
        cd "$DOTFILES_DIR"
        rm -rf /tmp/yay
    else
        log_dry "cd /tmp/yay && makepkg -si --noconfirm && cd BACK && rm -rf /tmp/yay"
    fi
else
    log_success "yay уже установлен."
fi

# 3. Установка пакетов из списков
install_packages() {
    local list_file="$1"
    local installer="$2"
    
    if [ -f "$list_file" ]; then
        log_info "Чтение списка пакетов из $list_file..."
        # Читаем файл, игнорируем комментарии и пустые строки
        packages=$(grep -vE "^\s*#" "$list_file" | tr '\n' ' ')
        
        if [ -n "$packages" ]; then
            log_info "Найдено пакетов: $(echo "$packages" | wc -w)"
            if [ "$installer" == "pacman" ]; then
                run_cmd sudo pacman -S --needed --noconfirm $packages
            elif [ "$installer" == "yay" ]; then
                run_cmd yay -S --needed --noconfirm $packages
            fi
        else
            log_info "Список пакетов пуст."
        fi
    else
        log_error "Файл $list_file не найден."
    fi
}

install_packages "$DOTFILES_DIR/pkglist.txt" "pacman"
install_packages "$DOTFILES_DIR/pkglist_aur.txt" "yay"

# 4. Создание симлинков (Symlinks)
link_config() {
    local folder_name="$1"
    local source_path="$DOTFILES_DIR/$folder_name"
    local target_path="$CONFIG_DIR/$folder_name"

    # Пропускаем, если исходной папки нет
    if [ ! -d "$source_path" ]; then
        log_error "Папка источника $source_path не найдена, пропускаем."
        return
    fi

    # В dry-run мы имитируем создание папки конфига
    run_cmd mkdir -p "$CONFIG_DIR"

    # Если целевая папка существует и это не симлинк - делаем бэкап
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        log_info "Конфликт: $target_path существует и это не ссылка."
        run_cmd mkdir -p "$BACKUP_DIR"
        run_cmd mv "$target_path" "$BACKUP_DIR/"
    fi

    # Если ссылка уже существует и правильная
    # (В dry-run мы проверяем реальное состояние системы)
    if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" == "$source_path" ]; then
        log_success "Ссылка для $folder_name уже настроена корректно."
    else
        # Удаляем битую ссылку или создаем новую
        if [ -L "$target_path" ]; then
             run_cmd rm "$target_path"
        fi
        run_cmd ln -s "$source_path" "$target_path"
        if [ "$DRY_RUN" = true ]; then
            log_dry "Создал бы ссылку: $target_path -> $source_path"
        else
            log_success "Создана ссылка: $folder_name"
        fi
    fi
}

log_info "Настройка конфигурационных файлов..."

# Список папок для линковки в ~/.config/
FOLDERS_TO_LINK=("fish" "hypr" "waybar" "kitty" "wofi" "yazi")

for folder in "${FOLDERS_TO_LINK[@]}"; do
    link_config "$folder"
done

# Специальная обработка для тем
THEMES_TARGET="$HOME/Documents/Themes"
# Проверка реального пути
if [ -L "$THEMES_TARGET" ] && [ "$(readlink -f "$THEMES_TARGET")" == "$DOTFILES_DIR/Themes" ]; then
     log_success "Темы уже настроены."
else
     log_info "Настройка папки Themes..."
     run_cmd mkdir -p "$HOME/Documents"
     if [ -d "$THEMES_TARGET" ] && [ ! -L "$THEMES_TARGET" ]; then
        run_cmd mkdir -p "$BACKUP_DIR/Documents"
        run_cmd mv "$THEMES_TARGET" "$BACKUP_DIR/Documents/"
     fi
     run_cmd ln -s "$DOTFILES_DIR/Themes" "$THEMES_TARGET"
fi

# 5. Пост-установка
log_info "Настройка прав доступа для скриптов..."
run_cmd chmod +x "$DOTFILES_DIR/waybar/launch.sh"
run_cmd chmod +x "$DOTFILES_DIR/scripts/"*.sh

# Смена шелла
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "fish" ]; then
    if grep -q "fish" /etc/shells; then
        run_cmd chsh -s $(which fish)
    else
        log_error "Fish не найден в /etc/shells (возможно он еще не установлен)."
    fi
else
    log_success "Fish уже используется как шелл по умолчанию."
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}--- КОНЕЦ ХОЛОСТОГО ПРОГОНА ---${NC}"
    echo "Для реальной установки запустите: ./install.sh"
else
    log_success "Установка завершена!"
fi

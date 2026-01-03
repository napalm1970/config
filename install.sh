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

# Функция для выполнения команд от имени владельца
as_user() {
    local OWNER=$(stat -c '%U' "$DOTFILES_DIR")
    if [ "$DRY_RUN" = true ]; then
        log_dry "От имени $OWNER выполнил бы: $*"
    else
        sudo -u "$OWNER" "$@"
    fi
}

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
    log_info "Git не найден. Установка..."
    run_cmd sudo pacman -S --noconfirm git
fi

# 2. Проверка и установка yay (AUR helper)
if ! command -v yay &> /dev/null; then
    log_info "yay не найден. Установка yay..."
    run_cmd sudo pacman -S --needed --noconfirm base-devel
    run_cmd git clone https://aur.archlinux.org/yay.git /tmp/yay
    if [ "$DRY_RUN" = false ]; then
        cd /tmp/yay
        makepkg -si --noconfirm
        cd "$DOTFILES_DIR"
        rm -rf /tmp/yay
    else
        log_dry "Установка yay из AUR..."
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
        packages=$(grep -vE "^\s*#" "$list_file" | tr '\n' ' ')
        
        if [ -n "$packages" ]; then
            if [ "$installer" == "pacman" ]; then
                run_cmd sudo pacman -S --needed --noconfirm $packages
            elif [ "$installer" == "yay" ]; then
                run_cmd yay -S --needed --noconfirm $packages
            fi
        fi
    fi
}

install_packages "$DOTFILES_DIR/pkglist.txt" "pacman"
install_packages "$DOTFILES_DIR/pkglist_aur.txt" "yay"

# 4. Создание симлинков (Symlinks)
link_config() {
    local folder_name="$1"
    local source_path="$DOTFILES_DIR/$folder_name"
    local target_path="$CONFIG_DIR/$folder_name"

    if [ ! -d "$source_path" ]; then return; fi

    run_cmd mkdir -p "$CONFIG_DIR"

    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        log_info "Бэкап существующего конфига $target_path..."
        run_cmd mkdir -p "$BACKUP_DIR"
        run_cmd mv "$target_path" "$BACKUP_DIR/"
    fi

    if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" == "$source_path" ]; then
        log_success "Ссылка для $folder_name уже настроена."
    else
        if [ -L "$target_path" ]; then run_cmd rm "$target_path"; fi
        run_cmd ln -s "$source_path" "$target_path"
        log_success "Создана ссылка для $folder_name"
    fi
}

log_info "Настройка конфигурационных файлов..."
FOLDERS_TO_LINK=("fish" "hypr" "waybar" "kitty" "wofi" "yazi")
for folder in "${FOLDERS_TO_LINK[@]}"; do
    link_config "$folder"
done

# Линковка starship.toml
if [ -f "$DOTFILES_DIR/starship.toml" ]; then
    run_cmd ln -sf "$DOTFILES_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
    log_success "Starship конфиг слинкован."
fi

# Обработка тем
THEMES_TARGET="$HOME/Documents/Themes"
if [ ! -L "$THEMES_TARGET" ] || [ "$(readlink -f "$THEMES_TARGET")" != "$DOTFILES_DIR/Themes" ]; then
     log_info "Настройка папки Themes..."
     run_cmd mkdir -p "$HOME/Documents"
     if [ -d "$THEMES_TARGET" ] && [ ! -L "$THEMES_TARGET" ]; then
        run_cmd mkdir -p "$BACKUP_DIR/Documents"
        run_cmd mv "$THEMES_TARGET" "$BACKUP_DIR/Documents/"
     fi
     run_cmd ln -sf "$DOTFILES_DIR/Themes" "$THEMES_TARGET"
fi

# 5. Установка системных хуков pacman
log_info "Установка хуков pacman в систему..."
HOOKS_DIR="/etc/pacman.d/hooks"
run_cmd sudo mkdir -p "$HOOKS_DIR"

for hook in "$DOTFILES_DIR/"*.hook; do
    if [ -f "$hook" ]; then
        hook_name=$(basename "$hook")
        run_cmd sudo ln -sf "$hook" "$HOOKS_DIR/$hook_name"
        log_success "Хук установлен: $hook_name"
    fi
done

# 6. Пост-установка
log_info "Настройка прав доступа для скриптов..."
run_cmd chmod +x "$DOTFILES_DIR/waybar/launch.sh"
run_cmd chmod +x "$DOTFILES_DIR/scripts/"*.sh

# Настройка Fish
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "fish" ]; then
    if grep -q "fish" /etc/shells; then
        run_cmd chsh -s $(which fish)
    fi
fi

if command -v fish &> /dev/null; then
    log_info "Добавление сокращений в Fish..."
    as_user fish -c "abbr -a dot 'cd $DOTFILES_DIR'"
    as_user fish -c "abbr -a conf 'cd $CONFIG_DIR'"
    as_user fish -c "abbr -a gs 'git status'"
    as_user fish -c "abbr -a gp 'git push origin main'"
    log_success "Сокращения Fish добавлены (dot, conf, gs, gp)."
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}--- КОНЕЦ ХОЛОСТОГО ПРОГОНА ---${NC}"
else
    log_success "Установка завершена!"
fi
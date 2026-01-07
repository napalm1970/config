# Остановка скрипта при ошибках (за исключением проверок через if)
set -euo pipefail

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Флаг Dry Run
DRY_RUN=false

# Проверка аргументов
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}[!!!] ЗАПУЩЕН РЕЖИМ DRY-RUN (ХОЛОСТОЙ ПРОГОН) [!!!]${NC}"
    echo -e "${YELLOW}Никакие изменения не будут внесены в систему.${NC}\n"
fi

# 1. Проверка пользователя (Запрет запуска от root)
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[ERROR] Пожалуйста, не запускайте этот скрипт от имени root (sudo).${NC}"
    echo -e "Запустите его как обычный пользователь. Пароль для sudo будет запрошен при необходимости."
    exit 1
fi

# Пути
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Логирование
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

# Обертка для выполнения команд от текущего пользователя (для совместимости и логирования)
as_user() {
    run_cmd "$@"
}

# Обработка временных файлов (Cleanup trap)
TEMP_DIR=""
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Функция проверки контрольной суммы (SHA256)
check_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [ ! -f "$file" ]; then
        log_error "Файл для проверки не найден: $file"
        return 1
    fi

    local actual_checksum
    actual_checksum=$(sha256sum "$file" | awk '{print $1}')

    if [ "$actual_checksum" != "$expected_checksum" ]; then
        log_error "Ошибка контрольной суммы файла $file!"
        log_error "Ожидалось: $expected_checksum"
        log_error "Получено:  $actual_checksum"
        return 1
    else
        log_success "Контрольная сумма совпадает ($file)."
        return 0
    fi
}

# --- Начало установки ---

# 1. Подготовка и установка yay
log_info "Обновление ключей Arch Linux..."
run_cmd sudo pacman -Sy --noconfirm archlinux-keyring

# Проверка и установка зависимостей для сборки (git, base-devel)
PACKAGES_TO_INSTALL=""
if ! command -v git &> /dev/null; then PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL git"; fi
if ! pacman -Qi base-devel &> /dev/null; then PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL base-devel"; fi

if [ -n "$PACKAGES_TO_INSTALL" ]; then
    log_info "Установка зависимостей для сборки yay ($PACKAGES_TO_INSTALL)..."
    run_cmd sudo pacman -S --noconfirm --needed $PACKAGES_TO_INSTALL
fi

# Проверка и установка yay
if ! command -v yay &> /dev/null; then
    log_info "yay не найден. Установка yay..."
    
    if [ "$DRY_RUN" = false ]; then
        TEMP_DIR=$(mktemp -d)
        log_info "Используется временная директория: $TEMP_DIR"
        run_cmd git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay"
        
        pushd "$TEMP_DIR/yay" > /dev/null
        run_cmd makepkg -si --noconfirm
        popd > /dev/null
    else
        log_dry "Клонирование и сборка yay в временной директории..."
    fi
else
    log_success "yay уже установлен."
fi

# 2. Полное обновление системы (Repo + AUR)
log_info "Полное обновление системы (через yay)..."
if [ "$DRY_RUN" = true ]; then
    log_dry "yay -Syu --noconfirm"
else
    yay -Syu --noconfirm
fi

# Предварительная установка nodejs и npm
log_info "Предварительная установка nodejs и npm..."
run_cmd sudo pacman -S --noconfirm --needed nodejs npm

# 3. Установка пакетов из списков
install_packages() {
    local list_file="$1"
    local installer="$2"
    
    if [ -f "$list_file" ]; then
        log_info "Чтение списка пакетов из $list_file..."
        # || true нужен, чтобы grep не валил скрипт из-за set -e, если ничего не найдено
        packages=$(grep -vE "^\s*#" "$list_file" | tr '\n' ' ' || true)
        
        if [ -n "$packages" ]; then
            log_info "Проверка установленных пакетов перед установкой..."
            # Используем --needed, но можно добавить явную проверку, если требуется строгая логика "если есть, не трогать"
            # В данном случае --needed - самый безопасный и правильный метод pacman/yay.
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

    # Бэкап только если это реальная директория/файл, а не уже наш линк
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        log_info "Бэкап существующего конфига $target_path..."
        run_cmd mkdir -p "$BACKUP_DIR"
        run_cmd mv "$target_path" "$BACKUP_DIR/"
    fi

    # Проверка, указывает ли линк уже туда, куда нужно
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
# Проверяем, не является ли это уже нужным линком
if [ ! -L "$THEMES_TARGET" ] || [ "$(readlink -f "$THEMES_TARGET")" != "$DOTFILES_DIR/Themes" ]; then
     log_info "Настройка папки Themes..."
     run_cmd mkdir -p "$HOME/Documents"
     
     # Бэкапим, если там что-то есть и это не линк
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

# 6. Настройка IgnorePkg для dracula-icons-git (Идемпотентная)
PACMAN_CONF="/etc/pacman.conf"
if grep -q "^IgnorePkg" "$PACMAN_CONF"; then
    if ! grep -q "dracula-icons-git" "$PACMAN_CONF"; then
        log_info "Добавление dracula-icons-git в IgnorePkg..."
        run_cmd sudo sed -i '/^IgnorePkg/ s/$/ dracula-icons-git/' "$PACMAN_CONF"
    else
        log_success "dracula-icons-git уже есть в IgnorePkg."
    fi
elif grep -q "^#IgnorePkg" "$PACMAN_CONF"; then
 # Если закомментировано, раскомментируем и добавляем
 log_info "Активация IgnorePkg для dracula-icons-git..."
 run_cmd sudo sed -i 's/^#IgnorePkg\s*=/IgnorePkg = dracula-icons-git/' "$PACMAN_CONF"
fi

# 7. Установка ежемесячного таймера обновления
log_info "Настройка таймера обновления иконок..."
SYSTEMD_DIR="/etc/systemd/system"
if [ -d "$DOTFILES_DIR/systemd" ]; then
    run_cmd sudo cp "$DOTFILES_DIR/systemd/"* "$SYSTEMD_DIR/"
    run_cmd sudo systemctl daemon-reload
    run_cmd sudo systemctl enable --now update-dracula-icons.timer
    log_success "Таймер обновления иконок активирован."
fi

# 8. Пост-установка
log_info "Настройка прав доступа для скриптов..."
if [ -f "$DOTFILES_DIR/waybar/launch.sh" ]; then run_cmd chmod +x "$DOTFILES_DIR/waybar/launch.sh"; fi
if [ -d "$DOTFILES_DIR/scripts" ]; then run_cmd chmod +x "$DOTFILES_DIR/scripts/"*.sh; fi

# Настройка Fish
# Более надежная проверка текущего шелла
if [[ "$SHELL" != *"/fish" ]]; then
    if grep -q "fish" /etc/shells; then
        log_info "Смена шелла по умолчанию на fish..."
        run_cmd chsh -s "$(command -v fish)"
    fi
fi

if command -v fish &> /dev/null; then
    log_info "Добавление сокращений в Fish..."
    run_cmd fish -c "abbr -a dot 'cd $DOTFILES_DIR'"
    run_cmd fish -c "abbr -a conf 'cd $CONFIG_DIR'"
    run_cmd fish -c "abbr -a gs 'git status'"
    run_cmd fish -c "abbr -a gp 'git push origin main'"
    log_success "Сокращения Fish добавлены."
fi

# 9. Установка плагинов Fish (Fisher)
if command -v fish &> /dev/null; then
    log_info "Проверка Fisher и плагинов..."
    # Проверяем наличие fisher функций
    if ! fish -c "functions -q fisher"; then
        log_info "Установка Fisher..."
        if [ "$DRY_RUN" = false ]; then
             # Скачиваем файл во временную директорию
             FISHER_INSTALLER=$(mktemp)
             curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o "$FISHER_INSTALLER"
             
             # Здесь можно добавить проверку контрольной суммы, если известен хеш
             # if check_checksum "$FISHER_INSTALLER" "EXPECTED_HASH"; then ... fi
             
             # Установка
             fish -c "source $FISHER_INSTALLER && fisher install jorgebucaran/fisher"
             rm -f "$FISHER_INSTALLER"
        else
             log_dry "Установил бы Fisher через curl (download & source)"
        fi
    fi
    
    # Установка плагинов из файла
    if [ -f "$DOTFILES_DIR/fish/fish_plugins" ]; then
        log_info "Обновление плагинов Fish..."
        run_cmd fish -c "fisher update"
    fi
fi

# 10. Установка Gemini CLI
if ! command -v gemini &> /dev/null; then
    if command -v npm &> /dev/null; then
        log_info "Установка Gemini CLI..."
        run_cmd sudo npm install -g gemini-chat-cli
    else
        log_error "npm не найден. Не могу установить Gemini CLI."
    fi
else
    log_success "Gemini CLI уже установлен."
fi

# 11. Настройка локали и шрифта консоли (TTY)
if command -v localectl &> /dev/null; then
    log_info "Настройка локалей (en_US и ru_RU)..."
    # Раскомментируем только если закомментированы
    run_cmd sudo sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
    run_cmd sudo sed -i '/^#ru_RU.UTF-8 UTF-8/s/^#//' /etc/locale.gen
    run_cmd sudo locale-gen
    
    log_info "Настройка шрифта консоли (cyr-sun16)..."
    run_cmd sudo localectl set-vc-font cyr-sun16
fi

# 12. Применение настроек GTK
if command -v gsettings &> /dev/null; then
    log_info "Применение темы GTK (Dracula) и иконок..."
    if [ "$DRY_RUN" = false ]; then
        # Выполняем gsettings от текущего пользователя
        gsettings set org.gnome.desktop.interface gtk-theme "Dracula" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Dracula" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "Obsidian" 2>/dev/null || true
    else
        log_dry "gsettings set gtk-theme Dracula"
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}--- КОНЕЦ ХОЛОСТОГО ПРОГОНА ---${NC}"
else
    log_success "Установка завершена!"
fi
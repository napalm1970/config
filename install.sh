#!/bin/bash

# ==============================================================================
# Скрипт пост-установки и настройки Arch Linux (Hyprland + Dotfiles)
# Автор: Gemini Assistant & User
# ==============================================================================

set -e

# --- Цвета для вывода ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Переменные и пути ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
SYSTEM_SDDM_DIR="/etc/sddm.conf.d"
PKG_LIST="$SCRIPT_DIR/packages.txt"

# Список директорий для линковки в ~/.config/
DIRS_TO_LINK=("fish" "hypr" "kitty" "wofi" "yazi" "waybar" "nvim" "aerc")

# Флаг тестового прогона
DRY_RUN=false

# Проверка аргумента --dry-run
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo -e "${YELLOW}================================================${NC}"
  echo -e "${YELLOW}!!! ЗАПУЩЕН РЕЖИМ DRY-RUN (ТЕСТОВЫЙ ПРОГОН)  !!!${NC}"
  echo -e "${YELLOW}Никакие изменения не будут внесены в систему.  ${NC}"
  echo -e "${YELLOW}================================================${NC}\n"
fi

# --- Вспомогательные функции ---

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_dry() { echo -e "${YELLOW}[DRY-RUN]${NC} $1"; }

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    log_dry "Выполнил бы: $*"
  else
    "$@"
  fi
}

check_not_root() {
  if [ "$EUID" -eq 0 ]; then
    log_error "Пожалуйста, не запускайте этот скрипт от имени root."
    exit 1
  fi
}

create_symlink() {
  local src="$1"
  local dest="$2"
  local name="$3"

  if [ ! -e "$src" ]; then
    log_error "Исходный файл/папка не найден: $src"
    return 1
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" == "$src" ]; then
      log_info "$name уже настроен корректно."
      return 0
    fi
    log_warn "Обнаружен конфликт для $name. Планируется бэкап."
    run_cmd mkdir -p "$BACKUP_DIR"
    run_cmd mv "$dest" "$BACKUP_DIR/"
  fi

  run_cmd ln -sf "$src" "$dest"
  if [ "$DRY_RUN" = true ]; then
    log_dry "Создал бы ссылку: $dest -> $src"
  else
    log_success "Создана ссылка для $name"
  fi
}

# --- Основная логика ---

main() {
  check_not_root

  # 1. Установка yay
  log_info "Проверка AUR-хелпера yay..."
  if ! command -v yay &>/dev/null; then
    log_info "yay не найден. Установка..."
    run_cmd sudo pacman -S --needed --noconfirm git base-devel

    if [ "$DRY_RUN" = true ]; then
      log_dry "Сборка yay..."
    else
      TEMP_DIR=$(mktemp -d)
      git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay"
      cd "$TEMP_DIR/yay"
      makepkg -si --noconfirm
      cd "$SCRIPT_DIR"
      rm -rf "$TEMP_DIR"
    fi
  else
    log_success "yay уже установлен."
  fi

  # 2. Установка программ из списка
  if [ -f "$PKG_LIST" ]; then
    log_info "Установка программ из $PKG_LIST..."
    # Читаем пакеты, убирая комментарии и пустые строки
    packages=$(grep -vE "^\s*#" "$PKG_LIST" | tr '\n' ' ')

    if [ -n "$packages" ]; then
      run_cmd yay -S --needed --noconfirm $packages
    else
      log_warn "Список пакетов пуст."
    fi
  else
    log_error "Файл $PKG_LIST не найден!"
    exit 1
  fi

  # 3. Полное обновление системы
  log_info "Обновление системы..."
  run_cmd yay -Syu --noconfirm

  # 4. Смена оболочки на fish
  log_info "Настройка fish как оболочки по умолчанию..."
  if [ "$SHELL" != "/usr/bin/fish" ]; then
    run_cmd sudo chsh -s /usr/bin/fish "$USER"
  else
    log_info "fish уже является оболочкой по умолчанию."
  fi

  # 5. Установка Gemini CLI через NPM
  log_info "Установка @google/gemini-cli..."
  run_cmd sudo npm install -g @google/gemini-cli

  # 6. Настройка конфигураций пользователя
  log_info "Настройка симлинков..."
  run_cmd mkdir -p "$CONFIG_DIR"

  for folder in "${DIRS_TO_LINK[@]}"; do
    create_symlink "$SCRIPT_DIR/$folder" "$CONFIG_DIR/$folder" "$folder"
  done

  # 6.1 Исправление прав для aerc (требует 600)
  if [ -L "$CONFIG_DIR/aerc/accounts.conf" ]; then
      log_info "Настройка прав доступа для aerc/accounts.conf..."
      # Важно: меняем права у целевого файла ссылки, если это возможно,
      # но так как это симлинк на репозиторий, меняем права файла ВНУТРИ репозитория через симлинк.
      run_cmd chmod 600 "$CONFIG_DIR/aerc/accounts.conf"
  fi

  # 7. Настройка Starship
  create_symlink "$SCRIPT_DIR/starship.toml" "$CONFIG_DIR/starship.toml" "starship.toml"

  # 8. Системные настройки (SDDM)
  log_info "Настройка SDDM..."
  run_cmd sudo mkdir -p "$SYSTEM_SDDM_DIR"

  for file in "autologin.conf" "hidpi.conf"; do
    src_file="$SCRIPT_DIR/$file"
    dest_file="$SYSTEM_SDDM_DIR/$file"
    if [ -f "$src_file" ]; then
      run_cmd sudo ln -sf "$src_file" "$dest_file"
    else
      log_warn "Файл $file не найден, пропускаем."
    fi
  done

  # 9. Включение службы
  log_info "Включение SDDM..."
  run_cmd sudo systemctl enable sddm

  # 10. Клонирование базы паролей (pass) и импорт ключей
  log_info "Настройка хранилища паролей (pass)..."
  PASS_DIR="$HOME/.password-store"

  # 10.1 Клонирование
  if [ ! -d "$PASS_DIR" ]; then
    log_info "Клонирование базы паролей из GitHub..."
    run_cmd git clone git@github.com:napalm1970/pass.git "$PASS_DIR"
  else
    log_info "Хранилище паролей уже существует в $PASS_DIR."
  fi

  # 10.2 Попытка импорта GPG ключей из хранилища
  log_info "Попытка импорта GPG ключей из pass..."
  
  if command -v pass &>/dev/null; then
    # Импорт публичного ключа
    if [ -f "$PASS_DIR/gpg/public-key.gpg" ] || pass show gpg/public-key &>/dev/null; then
         log_info "Импорт публичного ключа..."
         run_cmd bash -c "pass show gpg/public-key | gpg --import" || log_warn "Не удалось импортировать публичный ключ."
    else
         log_warn "Запись gpg/public-key не найдена в pass."
    fi

    # Импорт приватного ключа
    if [ -f "$PASS_DIR/gpg/private-key.gpg" ] || pass show gpg/private-key &>/dev/null; then
         log_info "Импорт приватного ключа..."
         log_warn "Внимание: импорт приватного ключа изнутри pass возможен только если хранилище уже расшифровано."
         if run_cmd bash -c "pass show gpg/private-key | gpg --import"; then
            log_success "Приватный ключ успешно импортирован из pass."
         else
            log_warn "Не удалось импортировать приватный ключ из pass (зашифровано)."
            
            # --- Логика Bitwarden Fallback ---
            echo -e "${YELLOW}Хотите попытаться восстановить GPG ключ из Bitwarden? (y/N)${NC}"
            read -r use_bw
            if [[ "$use_bw" =~ ^[Yy]$ ]]; then
                if command -v bw &>/dev/null; then
                    log_info "Запуск Bitwarden CLI..."
                    # Проверка статуса входа
                    if ! bw login --check &>/dev/null; then
                         echo "Пожалуйста, войдите в Bitwarden:"
                         run_cmd bw login
                    fi
                    
                    # Разблокировка хранилища, если нужно
                    if [ -z "$BW_SESSION" ]; then
                         echo "Разблокировка хранилища (введите мастер-пароль):"
                         export BW_SESSION=$(bw unlock --raw)
                    fi

                    log_info "Поиск элемента 'GPG PRIVATE KEY'..."
                    # Получение заметки и импорт (требуется jq)
                    if command -v jq &>/dev/null; then
                        if bw get item "GPG PRIVATE KEY" | jq -r '.notes' | gpg --import; then
                            log_success "GPG ключ успешно восстановлен из Bitwarden!"
                            # Повторная попытка инициализации pass
                            log_info "Повторная инициализация pass..."
                            pass git pull
                        else
                            log_error "Не удалось получить или импортировать ключ из Bitwarden (ошибка при получении item или импорте)."
                        fi
                    else
                         log_error "Утилита 'jq' не найдена. Установите jq для работы с Bitwarden JSON."
                         run_cmd sudo pacman -S --needed --noconfirm jq
                         # Повторная попытка после установки
                         if bw get item "GPG PRIVATE KEY" | jq -r '.notes' | gpg --import; then
                            log_success "GPG ключ успешно восстановлен из Bitwarden!"
                            pass git pull
                         fi
                    fi
                else
                    log_error "Bitwarden CLI (bw) не установлен."
                fi
            fi
            # ---------------------------------
         fi
    else
         log_warn "Запись gpg/private-key не найдена в pass."
    fi
  else
    log_error "Команда 'pass' не найдена. Убедитесь, что пакет установлен."
  fi

  echo ""
  if [ "$DRY_RUN" = true ]; then
    log_success "Тестовый прогон завершен."
  else
    log_success "Установка и настройка завершены!"
    [ -d "$BACKUP_DIR" ] && echo -e "${BLUE}Бэкапы в:${NC} $BACKUP_DIR"
  fi
}

setup_python_env() {
  log_info "Настройка Python Virtual Environment (~/.python_venv)..."
  VENV_DIR="$HOME/.python_venv"

  if [ ! -d "$VENV_DIR" ]; then
    run_cmd python3 -m venv "$VENV_DIR"
    log_success "Виртуальное окружение создано."
  else
    log_info "Виртуальное окружение уже существует."
  fi

  # Обновление pip и базовых инструментов внутри venv
  if [ -f "$VENV_DIR/bin/pip" ]; then
    log_info "Обновление pip, setuptools и wheel..."
    run_cmd "$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
  fi
}

trap 'echo -e "\n${RED}Скрипт прерван.${NC}"; exit 1' INT
main
setup_python_env


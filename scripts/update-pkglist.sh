#!/bin/bash
# Путь к папке конфигов
CONFIG_DIR="/home/napalm/Documents/config"

# Определяем владельца папки, чтобы git не ругался на права
OWNER=$(stat -c '%U' "$CONFIG_DIR")

# Функция для выполнения команд от имени владельца
as_user() {
    sudo -u "$OWNER" "$@"
}

# Обновляем списки во временные файлы
pacman -Qqen > "$CONFIG_DIR/pkglist.txt.tmp"
pacman -Qqem > "$CONFIG_DIR/pkglist_aur.txt.tmp"

# Проверяем, изменилось ли что-то
if diff -q "$CONFIG_DIR/pkglist.txt" "$CONFIG_DIR/pkglist.txt.tmp" >/dev/null && \
   diff -q "$CONFIG_DIR/pkglist_aur.txt" "$CONFIG_DIR/pkglist_aur.txt.tmp" >/dev/null; then
    rm "$CONFIG_DIR/pkglist.txt.tmp" "$CONFIG_DIR/pkglist_aur.txt.tmp"
    exit 0
fi

# Если есть изменения, сохраняем их
mv "$CONFIG_DIR/pkglist.txt.tmp" "$CONFIG_DIR/pkglist.txt"
mv "$CONFIG_DIR/pkglist_aur.txt.tmp" "$CONFIG_DIR/pkglist_aur.txt"

# Добавляем изменения в git от имени пользователя
cd "$CONFIG_DIR"
as_user git add pkglist.txt pkglist_aur.txt
as_user git commit -m "Auto-update package lists: $(date +'%Y-%m-%d %H:%M')"

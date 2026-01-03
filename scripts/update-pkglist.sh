#!/bin/bash
# Путь к вашей папке конфигов
CONFIG_DIR="/home/napalm/Documents/config"

# Список официальных пакетов (native)
pacman -Qqen > "$CONFIG_DIR/pkglist.txt"

# Список AUR пакетов (foreign)
pacman -Qqem > "$CONFIG_DIR/pkglist_aur.txt"

# Добавляем изменения в git автоматически (опционально)
cd "$CONFIG_DIR"
git add pkglist.txt pkglist_aur.txt
git commit -m "Auto-update package lists: $(date +'%Y-%m-%d %H:%M')"

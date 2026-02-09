#!/bin/bash
# Проверка обновлений (pacman + yay) для Waybar
# Результат пишется в JSON файл

OUTPUT_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/updates.json"
mkdir -p "$(dirname "$OUTPUT_FILE")"

if ! command -v checkupdates &>/dev/null; then
    echo '{"text": "ERR", "tooltip": "pacman-contrib not installed"}' > "$OUTPUT_FILE"
    exit 1
fi

pkg_updates=$(checkupdates 2>/dev/null | wc -l)
aur_updates=0

if command -v yay &>/dev/null; then
    aur_updates=$(yay -Qua 2>/dev/null | wc -l)
fi

total_updates=$((pkg_updates + aur_updates))

if [ "$total_updates" -gt 0 ]; then
    tooltip="Pkg: $pkg_updates\nAUR: $aur_updates"
    # Экранирование переводов строк для JSON
    tooltip=${tooltip//$'
'/\n}
    echo "{\"text\": \"$total_updates\", \"tooltip\": \"$tooltip\", \"class\": \"updates\"}" > "$OUTPUT_FILE"
else
    echo '{"text": "", "tooltip": "System is up to date"}' > "$OUTPUT_FILE"
fi

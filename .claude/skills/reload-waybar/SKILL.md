---
name: reload-waybar
description: Перезапускает Waybar через waybar/launch.sh и проверяет, что процесс жив. Использовать после правки waybar/config.jsonc или style.css.
---

# reload-waybar

Killает текущий Waybar и стартует новый, читая обновлённую конфигурацию.

## Шаги

1. Запусти скрипт перезапуска:
   ```bash
   "$CLAUDE_PROJECT_DIR/waybar/launch.sh"
   ```
   Скрипт сам делает `pkill waybar; sleep; waybar &`.

2. Подожди 1 секунду, проверь что процесс поднялся:
   ```bash
   sleep 1 && pgrep -x waybar
   ```

3. Если `pgrep` нашёл pid — сообщи "Waybar restarted (pid N)".
   Если ничего не вернулось — попробуй запустить `waybar` в foreground на 2 секунды чтобы поймать stderr:
   ```bash
   timeout 2 waybar 2>&1 | head -40
   ```
   и покажи вывод — обычно это JSON5 syntax error в `config.jsonc` или CSS error в `style.css`.

## Когда использовать

- После правки `waybar/config.jsonc` или `waybar/style.css`.
- После пересборки Rust-модулей (`weather-rs`, `mail-rs`) — чтобы подцепить новый бинарь.

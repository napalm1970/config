---
name: reload-hypr
description: Перезагружает конфигурацию Hyprland через `hyprctl reload` и проверяет лог на parse errors. Используется после правки hypr/*.conf.
---

# reload-hypr

Перезагружает Hyprland in-place без выхода из сессии.

## Шаги

1. Запусти `hyprctl reload`. Если команда вернула не-нулевой код — покажи stderr и остановись.

2. Прочитай последние 30 строк актуального лога Hyprland:
   ```bash
   tail -n 30 "/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log"
   ```

3. Просмотри вывод на наличие подстрок `error`, `failed`, `unknown keyword`, `parse error` (case-insensitive).

4. Если ошибок не найдено — сообщи кратко "Hyprland reloaded OK".
   Если найдены — покажи проблемные строки, чтобы пользователь мог исправить конфиг.

## Когда использовать

- После правки `hyprland.conf`, `keyboard.conf`, `monitors.conf`, `workspaces.conf` или любого другого `.conf` в `hypr/`.
- Не нужно для правок `hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf` — у них собственные демоны.

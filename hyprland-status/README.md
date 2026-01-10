# Hyprland Status Widget

Простой плавающий виджет для отображения текущей раскладки клавиатуры и времени в Hyprland.

## Демонстрация

Это приложение создает небольшое полупрозрачное окно без декораций, которое можно разместить в любом месте экрана.

## Зависимости

*   `hyprland`
*   `python3`
*   **PyGObject (GTK4)**: Библиотека для связи Python с GTK.
    *   **Arch Linux**: `sudo pacman -S python-gobject`
    *   **Debian/Ubuntu**: `sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-4.0`
    *   **Fedora**: `sudo dnf install python3-gobject gtk4`

## Использование

1.  Установите зависимости, указанные выше.
2.  Сделайте скрипт исполняемым:
    ```bash
    chmod +x main.py
    ```
3.  Запустите скрипт:
    ```bash
    ./main.py
    ```
    Чтобы он работал в фоне, запускайте его при старте Hyprland, добавив в `hyprland.conf`:
    ```
    exec-once = /path/to/your/project/hyprland-status/main.py
    ```

## Настройка в Hyprland

Самое главное — добавить правила для окна виджета в ваш `hyprland.conf`. Это позволит управлять его положением, размером и поведением. Имя окна задано в скрипте как `hyprland-status-widget`.

Добавьте следующие строки в ваш `~/.config/hypr/hyprland.conf`:

```conf
# Правила для виджета раскладки и времени
windowrulev2 = float, title:^(hyprland-status-widget)$
windowrulev2 = move 90% 2%, title:^(hyprland-status-widget)$
windowrulev2 = size 8% 4%, title:^(hyprland-status-widget)$
windowrulev2 = nofocus, title:^(hyprland-status-widget)$
windowrulev2 = noinitialfocus, title:^(hyprland-status-widget)$
windowrulev2 = pin, title:^(hyprland-status-widget)$
```

### Объяснение правил:
*   `float`: Делает окно плавающим.
*   `move 90% 2%`: Перемещает окно. `90%` по горизонтали (вправо) и `2%` по вертикали (вниз). Настройте под себя.
*   `size 8% 4%`: Задает размер окна в процентах от размера экрана.
*   `nofocus`, `noinitialfocus`: Окно не будет перехватывать фокус клавиатуры.
*   `pin`: Окно будет видно на всех рабочих столах.

Вы можете экспериментировать с этими значениями, чтобы разместить виджет там, где вам удобно.

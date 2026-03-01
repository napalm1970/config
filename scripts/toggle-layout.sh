#!/bin/bash
# Переключение раскладки клавиатуры для hyprland

# Получаем имя основной клавиатуры
KEYBOARD_NAME=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .name')

# Переключаем на следующую раскладку
hyprctl switchxkblayout "$KEYBOARD_NAME" next

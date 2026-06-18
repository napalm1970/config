#!/usr/bin/env python3
import subprocess
import sys
import time
import json

# Точные маппинги клавиш между английской и русской раскладками
EN = """`~@#$^&qwertyuiop[]QWERTYUIOP{}asdfghjkl;'ASDFGHJKL:"zxcvbnm,./ZXCVBNM<>?"""
RU = """ёЁ"№;:?йцукенгшщзхъЙЦУКЕНГШЩЗХЪфывапролджэФЫВАПРОЛДЖЭячсмитьбю.ЯЧСМИТЬБЮ,"""

TRANS_EN_RU = str.maketrans(EN, RU)
TRANS_RU_EN = str.maketrans(RU, EN)

def run_wtype(args):
    """Выполняет команду wtype для симуляции нажатий клавиш."""
    try:
        subprocess.run(['wtype'] + args, check=True, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        print("Ошибка: утилита 'wtype' не установлена. Установите её (например, sudo pacman -S wtype).")
        sys.exit(1)
    except subprocess.CalledProcessError:
        pass

def get_clipboard():
    """Получает текст из обычного буфера обмена."""
    try:
        return subprocess.check_output(['wl-paste'], text=True)
    except Exception:
        return ""

def set_clipboard(text):
    """Записывает текст в обычный буфер обмена."""
    subprocess.run(['wl-copy'], input=text, text=True)

def is_terminal():
    """Проверяет, является ли активное окно терминалом, используя hyprctl."""
    try:
        output = subprocess.check_output(['hyprctl', 'activewindow', '-j'], text=True)
        data = json.loads(output)
        window_class = data.get('class', '').lower()
        # Список популярных эмуляторов терминала
        terminals = ['kitty', 'alacritty', 'foot', 'wezterm', 'konsole', 'gnome-terminal', 'st', 'xterm', 'terminator', 'tilix']
        return any(term in window_class for term in terminals)
    except Exception:
        return False

def switch_layout():
    """Переключает раскладку клавиатуры в Hyprland."""
    try:
        subprocess.run(['hyprctl', 'switchxkblayout', 'all', 'next'], check=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    terminal_mode = is_terminal()

    # Задаем нужные комбинации клавиш в зависимости от активного окна
    if terminal_mode:
        copy_keys = ['-M', 'ctrl', '-M', 'shift', '-k', 'c', '-m', 'shift', '-m', 'ctrl']
        paste_keys = ['-M', 'ctrl', '-M', 'shift', '-k', 'v', '-m', 'shift', '-m', 'ctrl']
    else:
        copy_keys = ['-M', 'ctrl', '-k', 'c', '-m', 'ctrl']
        paste_keys = ['-M', 'ctrl', '-k', 'v', '-m', 'ctrl']

    old_clip = get_clipboard()

    # 1. Пробуем скопировать уже выделенный текст
    run_wtype(copy_keys)
    time.sleep(0.1) # Увеличил задержку для надежности

    text = get_clipboard()

    # 2. Если буфер обмена не изменился (ничего не было выделено)
    if text == old_clip:
        # В консоли выделение Ctrl+Shift+Left не сработает (напечатается код).
        # Поэтому если мы в консоли и текст не был выделен заранее, выходим.
        if terminal_mode:
            # Для терминала нужно предварительно выделить текст мышкой!
            return

        run_wtype(['-M', 'ctrl', '-M', 'shift', '-k', 'left', '-m', 'shift', '-m', 'ctrl'])
        time.sleep(0.1)
        run_wtype(copy_keys)
        time.sleep(0.1)
        text = get_clipboard()

    # Если текст все еще не изменился или пустой - выходим
    if not text or text == old_clip:
        return

    ru_count = sum(1 for c in text if c in RU)
    en_count = sum(1 for c in text if c in EN)

    if ru_count == 0 and en_count == 0:
        return

    if ru_count > en_count:
        converted = text.translate(TRANS_RU_EN)
    else:
        converted = text.translate(TRANS_EN_RU)

    set_clipboard(converted)
    time.sleep(0.1)

    # Вставляем переведенный текст на место старого
    run_wtype(paste_keys)
    time.sleep(0.1)

    # Восстанавливаем оригинальный буфер обмена
    set_clipboard(old_clip)

    # Переключаем раскладку (ведь это Punto Switcher)
    switch_layout()

if __name__ == '__main__':
    main()

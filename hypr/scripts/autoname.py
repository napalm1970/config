#!/usr/bin/env python3
import os
import json
import socket
import subprocess
import time

ICONS = {
    "kitty": "",
    "alacritty": "",
    "firefox": "",
    "google-chrome": "",
    "chromium": "",
    "tor-browser": "",
    "org.telegram.desktop": "",
    "viber": "",
    "discord": "",
    "jetbrains-idea-ce": "",
    "jetbrains-idea": "",
    "jetbrains-pycharm": "",
    "jetbrains-webstorm": "",
    "jetbrains-phpstorm": "",
    "jetbrains-goland": "",
    "jetbrains-clion": "",
    "jetbrains-rider": "",
    "pcmanfm": "",
    "thunar": "",
    "obsidian": "󱓧",
}
DEFAULT_ICON = ""

def update():
    try:
        # Получаем данные напрямую из hyprctl
        clients = json.loads(subprocess.check_output(["hyprctl", "-j", "clients"]))
        workspaces = json.loads(subprocess.check_output(["hyprctl", "-j", "workspaces"]))

        # Группируем иконки по воркспейсам
        ws_map = {}
        for c in clients:
            ws_id = c["workspace"]["id"]
            if ws_id < 1: continue

            cls = c.get("class", "").lower()
            # Если класс пустой (бывает при открытии), попробуем подождать или пропустить
            if not cls: continue

            icon = ICONS.get(cls, DEFAULT_ICON)
            if ws_id not in ws_map:
                ws_map[ws_id] = set()
            ws_map[ws_id].add(icon)

        # Обновляем каждый воркспейс
        for ws in workspaces:
            ws_id = ws["id"]
            if ws_id < 1: continue

            icons = sorted(list(ws_map.get(ws_id, [])))
            icon_str = " ".join(icons)
            new_name = f"{ws_id}: {icon_str}" if icon_str else str(ws_id)

            if ws["name"] != new_name:
                subprocess.run(["hyprctl", "dispatch", "renameworkspace", str(ws_id), new_name])

    except Exception as e:
        pass

def listen():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sock_path = f"{xdg_runtime}/hypr/{sig}/.socket2.sock"

    # Первое обновление
    update()

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(sock_path)
        while True:
            data = s.recv(4096).decode("utf-8")
            if not data: break

            # Если произошло любое событие с окнами или воркспейсами
            if any(ev in data for ev in ["openwindow", "closewindow", "movewindow", "workspace", "focusedmon"]):
                # Небольшая пауза, чтобы Hyprland успел обновить метаданные окна
                time.sleep(0.1)
                update()

if __name__ == "__main__":
    listen()

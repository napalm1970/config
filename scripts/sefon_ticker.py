#!/usr/bin/env python3
import socket
import json
import time
import sys
import os
import re

SOCKET_PATH = "/tmp/mpv-sefon-socket"
MAX_LEN = 20
SCROLL_INTERVAL = 0.2  # Интервал обновления анимации (скорость прокрутки)
MPV_POLL_INTERVAL = 1.0  # Интервал опроса MPV (раз в секунду)

def get_mpv_prop(sock, prop):
    try:
        cmd = {"command": ["get_property", prop]}
        sock.sendall(json.dumps(cmd).encode() + b'\n')
        # Читаем ответ. MPV может слать события, нам нужен ответ на request_id
        # Для простоты читаем буфер и ищем последнюю успешную data или пробуем разобрать
        # В идеале нужно читать построчно до нужного ответа.
        sock.settimeout(0.1)
        try:
            data = sock.recv(4096).decode()
            for line in reversed(data.split('\n')):
                if not line: continue
                try:
                    resp = json.loads(line)
                    if resp.get("error") == "success" and "data" in resp:
                        return resp.get("data")
                except:
                    pass
        except socket.timeout:
            pass
    except Exception:
        return None
    return None

def clean_title(text):
    if not text: return ""
    # Удаляем .mp3, .flac и т.д.
    text = re.sub(r'\.(mp3|flac|wav|m4a)$', '', text, flags=re.IGNORECASE)
    # Удаляем (Sefon.*) и [Sefon.*]
    text = re.sub(r'\s*[\(\[]Sefon.*?[\)\]]', '', text, flags=re.IGNORECASE)
    return text.strip()

def main():
    idx = 0
    icon = "🎵 "

    current_title = ""
    is_paused = False

    last_poll_time = 0
    sock = None

    while True:
        try:
            # 1. Подключение / Переподключение
            if sock is None:
                if os.path.exists(SOCKET_PATH):
                    try:
                        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                        sock.connect(SOCKET_PATH)
                        sock.settimeout(0.1) # Короткий таймаут для чтения
                    except Exception:
                        sock = None

            # 2. Опрос MPV (редко)
            if sock and (time.time() - last_poll_time > MPV_POLL_INTERVAL):
                try:
                    # Пробуем получить статус
                    paused_resp = get_mpv_prop(sock, "pause")
                    if paused_resp is not None:
                        is_paused = paused_resp

                        # Получаем метаданные
                        artist = get_mpv_prop(sock, "metadata/artist")
                        title = get_mpv_prop(sock, "metadata/title")
                        media_title = get_mpv_prop(sock, "media-title")

                        new_display = ""
                        if artist and title:
                            new_display = f"{artist} - {title}"
                        elif media_title:
                            new_display = media_title

                        # Очищаем итоговую строку от (Sefon.Pro) и расширений
                        new_display = clean_title(new_display)

                        # Если название изменилось, сбрасываем индекс прокрутки
                        if new_display != current_title:
                            current_title = new_display
                            idx = 0

                    else:
                        # Если не удалось получить свойство - возможно, соединение разорвано
                        sock.close()
                        sock = None
                        current_title = ""

                    last_poll_time = time.time()
                except (BrokenPipeError, ConnectionResetError):
                    sock = None
                    current_title = ""

            # 3. Анимация и вывод (часто)
            if current_title:
                full_text = f"{icon}{current_title}      "

                if len(full_text) <= MAX_LEN + 3: # +3 запас для пробелов
                    display_text = full_text.strip()
                    # Сбрасываем idx, чтобы не крутилось скрыто
                    idx = 0
                else:
                    # Прокрутка
                    display_text = full_text[idx:idx+MAX_LEN]
                    # Закольцовывание
                    if len(display_text) < MAX_LEN:
                        display_text += full_text[:MAX_LEN-len(display_text)]

                    if not is_paused:
                        idx = (idx + 1) % len(full_text)

                output = {
                    "text": display_text,
                    "class": "paused" if is_paused else "playing",
                    "tooltip": current_title
                }
            else:
                # Если нет соединения или названия
                output = {"text": "Stopped", "class": "stopped"}

            print(json.dumps(output), flush=True)

        except BrokenPipeError:
            sys.exit(0)
        except Exception:
            pass

        time.sleep(SCROLL_INTERVAL)

if __name__ == "__main__":
    main()

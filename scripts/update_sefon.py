#!/usr/bin/env python3
import time
import os
import sys
import subprocess
import importlib.metadata
import concurrent.futures
import math
import threading

def install_dependencies():
    required = {'selenium', 'webdriver-manager', 'requests', 'python-dotenv'}
    installed = {d.metadata['Name'].lower() for d in importlib.metadata.distributions()}
    missing = required - installed

    if missing:
        print(f"Installing missing dependencies: {', '.join(missing)}")
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', *missing])
            print("Dependencies installed successfully.")
            importlib.invalidate_caches()
        except subprocess.CalledProcessError as e:
            print(f"Failed to install dependencies: {e}")
            sys.exit(1)

install_dependencies()

from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.service import Service
from webdriver_manager.firefox import GeckoDriverManager

# Конфигурация
URL = "https://sefon.pro/collections/401-nu-metal/sort/clicks/"
OUTPUT_FILE = os.path.expanduser("~/Documents/config/numetal_sefon.m3u")
LOG_FILE = os.path.expanduser("~/Documents/config/scripts/sefon_update.log")
MAX_SONGS = 50  # Увеличено до 50
MAX_WORKERS = 4  # Количество потоков (браузеров)

# Блокировка для записи в лог из разных потоков
log_lock = threading.Lock()

def log(message):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    msg = f"[{timestamp}] {message}"
    with log_lock:
        print(msg)
        try:
            with open(LOG_FILE, "a") as f:
                f.write(msg + "\n")
        except:
            pass

def process_chunk(indices, driver_path):
    """Обрабатывает часть списка песен в отдельном браузере."""
    results = {}
    options = Options()
    options.add_argument("--headless")

    driver = None
    try:
        service = Service(executable_path=driver_path)
        driver = webdriver.Firefox(service=service, options=options)
        driver.get(URL)

        wait = WebDriverWait(driver, 20)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, ".mp3:not(.hide)")))

        # Получаем все элементы заново, так как это новая сессия браузера
        all_songs = driver.find_elements(By.CSS_SELECTOR, ".mp3:not(.hide)")

        for i in indices:
            # Проверка, чтобы не выйти за пределы (если песен на странице меньше, чем MAX_SONGS)
            if i >= len(all_songs):
                break

            song = all_songs[i]
            try:
                artist = song.find_element(By.CSS_SELECTOR, ".artist_name").text.strip()
                title = song.find_element(By.CSS_SELECTOR, ".song_name").text.strip()

                play_btn = song.find_element(By.CSS_SELECTOR, ".btn.play")

                # Клик с прокруткой к элементу (на всякий случай)
                driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", play_btn)
                driver.execute_script("arguments[0].click();", play_btn)

                # Ждем обновления аудио-тега
                time.sleep(2)

                audio_tag = driver.find_element(By.TAG_NAME, "audio")
                src = audio_tag.get_attribute("src")

                if src and "http" in src:
                    entry = f"#EXTINF:-1,{artist} - {title}\n{src}\n"
                    results[i] = entry
                    log(f"[T-{threading.get_ident() % 1000}] Добавлено: {artist} - {title}")
                else:
                    log(f"[T-{threading.get_ident() % 1000}] Пропуск (нет ссылки): {artist} - {title}")

            except Exception as e:
                log(f"[T-{threading.get_ident() % 1000}] Ошибка обработки песни {i}: {e}")
                continue

    except Exception as e:
        log(f"Ошибка в потоке: {e}")
    finally:
        if driver:
            driver.quit()

    return results

def update_playlist():
    log(f"Запуск обновления плейлиста Sefon (Потоков: {MAX_WORKERS}, Песен: {MAX_SONGS})...")

    try:
        # Устанавливаем драйвер один раз в главном потоке
        driver_path = GeckoDriverManager().install()

        # Разбиваем задачи на чанки
        all_indices = list(range(MAX_SONGS))
        chunk_size = math.ceil(len(all_indices) / MAX_WORKERS)
        chunks = [all_indices[i:i + chunk_size] for i in range(0, len(all_indices), chunk_size)]

        combined_results = {}

        # Запускаем потоки
        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            future_to_chunk = {executor.submit(process_chunk, chunk, driver_path): chunk for chunk in chunks}

            for future in concurrent.futures.as_completed(future_to_chunk):
                try:
                    chunk_results = future.result()
                    combined_results.update(chunk_results)
                except Exception as e:
                    log(f"Критическая ошибка в чанке: {e}")

        # Сборка и сохранение
        log("Сборка плейлиста (удаление дубликатов)...")
        playlist_content = "#EXTM3U\n"
        seen_tracks = set()

        # Сортируем по оригинальному индексу, чтобы сохранить порядок
        sorted_indices = sorted(combined_results.keys())
        for i in sorted_indices:
            entry = combined_results[i]
            # Извлекаем название трека для проверки на дубликаты
            # Формат: #EXTINF:-1,Artist - Title\nURL\n
            try:
                # Берем первую строку, удаляем префикс #EXTINF:-1,
                track_info = entry.split('\n')[0].replace('#EXTINF:-1,', '').strip()
                if track_info in seen_tracks:
                    log(f"Дубликат пропущен: {track_info}")
                    continue
                seen_tracks.add(track_info)
                playlist_content += entry
            except Exception as e:
                log(f"Ошибка при обработке дубликата для индекса {i}: {e}")
                # Если не удалось разобрать, добавляем как есть (безопасный вариант)
                playlist_content += entry

        with open(OUTPUT_FILE, "w") as f:
            f.write(playlist_content)

        log(f"Готово! Сохранено {len(seen_tracks)} уникальных треков в {OUTPUT_FILE}")

    except Exception as e:
        log(f"Общая ошибка: {e}")

if __name__ == "__main__":
    update_playlist()

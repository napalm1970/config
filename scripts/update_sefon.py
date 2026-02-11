#!/usr/bin/env python3
import time
import os
import sys
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Конфигурация
URL = "https://sefon.pro/collections/401-nu-metal/sort/clicks/"
OUTPUT_FILE = os.path.expanduser("~/Documents/config/numetal_sefon.m3u")
LOG_FILE = os.path.expanduser("~/Documents/config/scripts/sefon_update.log")
MAX_SONGS = 20  # Ограничим до 20 для теста

def log(message):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    msg = f"[{timestamp}] {message}"
    print(msg)
    try:
        with open(LOG_FILE, "a") as f:
            f.write(msg + "\n")
    except:
        pass

def update_playlist():
    log("Запуск обновления плейлиста Sefon...")

    options = Options()
    options.add_argument("--headless")

    driver = None
    try:
        driver = webdriver.Firefox(options=options)
        driver.get(URL)

        wait = WebDriverWait(driver, 20)
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, ".mp3:not(.hide)")))

        songs = driver.find_elements(By.CSS_SELECTOR, ".mp3:not(.hide)")
        log(f"Найдено песен: {len(songs)}")

        playlist_content = "#EXTM3U\n"
        count = 0

        for i, song in enumerate(songs):
            if count >= MAX_SONGS:
                break

            try:
                artist = song.find_element(By.CSS_SELECTOR, ".artist_name").text.strip()
                title = song.find_element(By.CSS_SELECTOR, ".song_name").text.strip()

                play_btn = song.find_element(By.CSS_SELECTOR, ".btn.play")
                driver.execute_script("arguments[0].click();", play_btn)

                # Ждем появления ссылки в аудио-теге
                time.sleep(2)

                audio_tag = driver.find_element(By.TAG_NAME, "audio")
                src = audio_tag.get_attribute("src")

                if src and "http" in src:
                    playlist_content += f"#EXTINF:-1,{artist} - {title}\n{src}\n"
                    log(f"Добавлено: {artist} - {title}")
                    count += 1
                else:
                    log(f"Пропуск (нет ссылки): {artist} - {title}")

            except Exception as e:
                continue

        with open(OUTPUT_FILE, "w") as f:
            f.write(playlist_content)

        log(f"Готово! Сохранено в {OUTPUT_FILE}")

    except Exception as e:
        log(f"Ошибка: {e}")
    finally:
        if driver:
            driver.quit()

if __name__ == "__main__":
    update_playlist()

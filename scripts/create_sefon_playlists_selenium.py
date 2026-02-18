#!/usr/bin/env python3
import os
import time
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

PLAYLISTS_DIR = "playlists"
QUERIES = {
    "Club": "клубная музыка",
    "NuMetal": "nu metal",
    "Techno": "techno",
    "Chillout": "chillout",
    "Lounge": "lounge"
}

def get_tracks(driver, query):
    print(f"Searching for '{query}'...")
    try:
        driver.get("https://sefon.pro/")
        time.sleep(5) # Ждем прогрузки

        search_input = WebDriverWait(driver, 15).until(EC.presence_of_element_located((By.NAME, "q")))
        search_input.clear()
        search_input.send_keys(query)
        search_input.send_keys(Keys.ENTER)

        WebDriverWait(driver, 15).until(EC.presence_of_element_located((By.CLASS_NAME, "m-track")))
        time.sleep(3)

        items = driver.find_elements(By.CLASS_NAME, "m-track")
        tracks = []
        for item in items[:50]:
            try:
                btn = item.find_element(By.CLASS_NAME, "btn-play")
                url = btn.get_attribute("data-url")
                if url:
                    if not url.startswith("http"): url = "https://sefon.pro" + url
                    artist = item.find_element(By.CLASS_NAME, "artist").text.strip()
                    song = item.find_element(By.CLASS_NAME, "song").text.strip()
                    tracks.append({"url": url, "title": f"{artist} - {song}"})
            except: continue
        return tracks
    except Exception as e:
        print(f"Error: {e}")
        return []

def main():
    options = uc.ChromeOptions()
    options.add_argument("--headless")
    # Указываем версию браузера вручную
    driver = uc.Chrome(options=options, version_main=144)

    if not os.path.exists(PLAYLISTS_DIR): os.makedirs(PLAYLISTS_DIR)

    try:
        for name, query in QUERIES.items():
            tracks = get_tracks(driver, query)
            if tracks:
                path = os.path.join(PLAYLISTS_DIR, f"{name}.m3u")
                with open(path, "w", encoding="utf-8") as f:
                    f.write("#EXTM3U\n")
                    for t in tracks:
                        f.write(f"#EXTINF:-1,{t['title']}\n{t['url']}\n")
                print(f"Saved {name} ({len(tracks)} tracks)")
            time.sleep(5)
    finally:
        driver.quit()

if __name__ == "__main__": main()

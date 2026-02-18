#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import os
import time

TARGETS = {
    "Club": "https://sefon.pro/collections/kru-toy-klubnyak/",
    "NuMetal": "https://sefon.pro/collections/nu-metal/",
    "Techno": "https://sefon.pro/collections/tehno/",
    "Chillout": "https://sefon.pro/collections/chillout-muzyka/",
    "Lounge": "https://sefon.pro/collections/lounge/"
}

PLAYLISTS_DIR = "playlists"

def get_tracks(url):
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    tracks = []
    try:
        print(f"Fetching {url}...")
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            return []

        soup = BeautifulSoup(response.text, 'html.parser')
        # Sefon использует m-track для песен
        items = soup.find_all('div', class_='m-track')

        for item in items:
            play_btn = item.find('div', class_='btn-play')
            if play_btn and play_btn.get('data-url'):
                mp3_url = play_btn.get('data-url')
                if not mp3_url.startswith('http'):
                    mp3_url = "https://sefon.pro" + mp3_url

                artist_div = item.find('div', class_='artist')
                song_div = item.find('div', class_='song')

                artist = artist_div.text.strip() if artist_div else "Unknown"
                title = song_div.text.strip() if song_div else "Unknown"

                tracks.append({
                    "url": mp3_url,
                    "title": f"{artist} - {title}"
                })

        print(f"Found {len(tracks)} tracks.")
    except Exception as e:
        print(f"Error: {e}")

    return tracks

def save_m3u(name, tracks):
    if not os.path.exists(PLAYLISTS_DIR):
        os.makedirs(PLAYLISTS_DIR)

    file_path = os.path.join(PLAYLISTS_DIR, f"{name}.m3u")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write("#EXTM3U\n")
        for track in tracks:
            f.write(f"#EXTINF:-1,{track['title']}\n")
            f.write(f"{track['url']}\n")
    print(f"Saved to {file_path}")

def main():
    for name, url in TARGETS.items():
        tracks = get_tracks(url)
        if tracks:
            save_m3u(name, tracks)
        time.sleep(1)

if __name__ == "__main__":
    main()

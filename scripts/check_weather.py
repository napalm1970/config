#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import time
import socket
import os

# Configuration
CITY = "Sompa,Kohtla-Jarve"
URL = f"https://wttr.in/{CITY}?format=j1"
MAX_RETRIES = 10
RETRY_DELAY = 5
OUTPUT_FILE = "/tmp/weather.json"

weather_icons = {
    "113": "☀️",  # Sunny
    "116": "⛅",  # PartlyCloudy
    "119": "☁️",  # Cloudy
    "122": "☁️",  # VeryCloudy
    "143": "🌫️",  # Fog
    "176": "🌦️",  # LightShowers
    "179": "🌨️",  # LightSleetShowers
    "182": "🌨️",  # LightSleet
    "185": "🌨️",  # LightSleet
    "200": "⛈️",  # ThunderyShowers
    "227": "🌨️",  # LightSnow
    "230": "❄️",  # HeavySnow
    "248": "🌫️",  # Fog
    "260": "🌫️",  # Fog
    "263": "🌦️",  # LightShowers
    "266": "🌧️",  # LightRain
    "281": "🌨️",  # LightSleet
    "284": "🌨️",  # LightSleet
    "293": "🌧️",  # LightRain
    "296": "🌧️",  # LightRain
    "299": "🌧️",  # HeavyShowers
    "302": "🌧️",  # HeavyRain
    "305": "🌧️",  # HeavyShowers
    "308": "🌧️",  # HeavyRain
    "311": "🌨️",  # LightSleet
    "314": "🌨️",  # LightSleet
    "317": "🌨️",  # LightSleet
    "320": "🌨️",  # LightSnow
    "323": "🌨️",  # LightSnowShowers
    "326": "🌨️",  # LightSnowShowers
    "329": "❄️",  # HeavySnow
    "332": "❄️",  # HeavySnow
    "335": "❄️",  # HeavySnowShowers
    "338": "❄️",  # HeavySnow
    "350": "🌨️",  # LightSleet
    "353": "🌦️",  # LightShowers
    "356": "🌧️",  # HeavyShowers
    "359": "🌧️",  # HeavyRain
    "362": "🌨️",  # LightSleetShowers
    "365": "🌨️",  # LightSleetShowers
    "368": "🌨️",  # LightSnowShowers
    "371": "❄️",  # HeavySnowShowers
    "374": "🌨️",  # LightSleetShowers
    "377": "🌨️",  # LightSleet
    "386": "⛈️",  # ThunderyShowers
    "389": "⛈️",  # ThunderyHeavyRain
    "392": "⛈️",  # ThunderySnowShowers
    "395": "❄️",  # HeavySnowShowers
}

def save_output(data):
    with open(OUTPUT_FILE, "w") as f:
        json.dump(data, f)

def get_weather():
    for attempt in range(MAX_RETRIES):
        try:
            with urllib.request.urlopen(URL, timeout=5) as response:
                data = json.loads(response.read().decode())

                current_condition = data['current_condition'][0]
                temp_C = current_condition['temp_C']
                weather_code = current_condition['weatherCode']
                weather_desc = current_condition['weatherDesc'][0]['value']
                feels_like = current_condition['FeelsLikeC']
                humidity = current_condition['humidity']
                wind_speed = current_condition['windspeedKmph']

                icon = weather_icons.get(weather_code, "")

                text = f"{icon} {temp_C}°C".strip()
                tooltip = f"<b>{weather_desc}</b>\nОщущается как: {feels_like}°C\nВлажность: {humidity}%\nВетер: {wind_speed} km/h"

                save_output({"text": text, "tooltip": tooltip, "class": "weather"})
                return

        except (urllib.error.URLError, socket.timeout):
            time.sleep(RETRY_DELAY)
        except Exception as e:
            save_output({"text": "Error", "tooltip": str(e)})
            return

    save_output({"text": "🚫", "tooltip": "No Internet Connection"})

if __name__ == "__main__":
    get_weather()

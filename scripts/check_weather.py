#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import time
import socket
import subprocess
import sys

# Configuration
LAT = "59.34027"
LON = "27.28327"
PASS_PATH = "keepass/KeePassXC-Browser Passwords/home.openweathermap.org"
MAX_RETRIES = 10
RETRY_DELAY = 5
OUTPUT_FILE = "/tmp/weather.json"  # Keep consistent with previous script

# OpenWeatherMap Icon Mapping
weather_icons = {
    "01d": "☀️",
    "01n": "🌙",  # Clear sky
    "02d": "⛅",
    "02n": "☁️",  # Few clouds
    "03d": "☁️",
    "03n": "☁️",  # Scattered clouds
    "04d": "☁️",
    "04n": "☁️",  # Broken clouds
    "09d": "🌧️",
    "09n": "🌧️",  # Shower rain
    "10d": "🌦️",
    "10n": "🌧️",  # Rain
    "11d": "⛈️",
    "11n": "⛈️",  # Thunderstorm
    "13d": "❄️",
    "13n": "❄️",  # Snow
    "50d": "🌫️",
    "50n": "🌫️",  # Mist
}


def get_api_key():
    try:
        result = subprocess.run(
            ["pass", "show", PASS_PATH], capture_output=True, text=True, check=True
        )
        # Assuming the password (API key) is on the first line
        return result.stdout.strip().splitlines()[0]
    except subprocess.CalledProcessError:
        return None
    except Exception:
        return None


def save_output(data):
    # Print to stdout as well for debugging or direct piping
    print(json.dumps(data, ensure_ascii=False))
    try:
        with open(OUTPUT_FILE, "w") as f:
            json.dump(data, f, ensure_ascii=False)
    except IOError:
        pass


def get_weather():
    api_key = get_api_key()
    if not api_key:
        save_output(
            {
                "text": "Key Error",
                "tooltip": "Could not retrieve API key from pass",
                "class": "error",
            }
        )
        return

    url = f"https://api.openweathermap.org/data/2.5/weather?lat={LAT}&lon={LON}&appid={api_key}&units=metric&lang=ru"
    forecast_url = f"https://api.openweathermap.org/data/2.5/forecast?lat={LAT}&lon={LON}&appid={api_key}&units=metric&lang=ru"

    for attempt in range(MAX_RETRIES):
        try:
            # 1. Get Current Weather
            with urllib.request.urlopen(url, timeout=5) as response:
                data = json.loads(response.read().decode())

            temp = round(data["main"]["temp"])
            feels_like = round(data["main"]["feels_like"])
            desc = data["weather"][0]["description"].capitalize()
            icon_code = data["weather"][0]["icon"]
            humidity = data["main"]["humidity"]
            wind_speed = data["wind"]["speed"]

            icon = weather_icons.get(icon_code, "❓")

            text = f"{icon} {temp}°C"
            tooltip = f"<b>{desc}</b>\nОщущается как: {feels_like}°C\nВлажность: {humidity}%\nВетер: {wind_speed} м/с"

            # 2. Get Forecast (Optional but desired)
            try:
                with urllib.request.urlopen(forecast_url, timeout=5) as response:
                    forecast_data = json.loads(response.read().decode())

                    tooltip += "\n\n<b>Прогноз:</b>"

                    seen_dates = set()
                    count = 0
                    current_date = time.strftime("%Y-%m-%d")

                    for item in forecast_data['list']:
                        dt_txt = item['dt_txt'] # "2023-10-27 12:00:00"
                        date, time_str = dt_txt.split(' ')

                        # Skip today, get 12:00 for next days
                        if date != current_date and time_str == "12:00:00":
                            if date not in seen_dates:
                                seen_dates.add(date)

                                f_temp = round(item['main']['temp'])
                                f_desc = item['weather'][0]['description']
                                f_icon_code = item['weather'][0]['icon']
                                f_icon = weather_icons.get(f_icon_code, "")

                                # Format date nicely (e.g. "27.10")
                                date_obj = time.strptime(date, "%Y-%m-%d")
                                date_nice = time.strftime("%d.%m", date_obj)

                                tooltip += f"\n{date_nice}: {f_icon} {f_temp}°C ({f_desc})"
                                count += 1
                                if count >= 3: break
            except Exception as e:
                tooltip += f"\n(Forecast error: {e})"

            save_output({"text": text, "tooltip": tooltip, "class": "weather"})
            return

        except (urllib.error.URLError, socket.timeout):
            time.sleep(RETRY_DELAY)
        except Exception as e:
            save_output({"text": "Error", "tooltip": str(e), "class": "error"})
            return

    save_output(
        {"text": "🚫", "tooltip": "No Internet Connection", "class": "disconnected"}
    )


if __name__ == "__main__":
    get_weather()

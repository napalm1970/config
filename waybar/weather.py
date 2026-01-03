#!/usr/bin/env python3
import json
import urllib.request
import sys
import os

# Configuration
CITY = "Sompa,Kohtla-Jarve"
# Using format=j1 for JSON output from wttr.in
URL = f"https://wttr.in/{CITY}?format=j1"

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

try:
    with urllib.request.urlopen(URL) as response:
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
        
        print(json.dumps({"text": text, "tooltip": tooltip, "class": "weather"}))

except Exception as e:
    print(json.dumps({"text": "Weather N/A", "tooltip": f"Error: {str(e)}"}))

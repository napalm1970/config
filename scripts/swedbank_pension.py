#!/usr/bin/env python3
"""
Скрипт для получения информации о пенсионном фонде Swedbank Pensionifond V60
и вывода в формате JSON для waybar.

Источники данных (по приоритету):
1. API Swedbank (требует авторизации через токен в pass)
2. Публичные данные с pensionikeskus.ee / nasdaqbaltic.com
3. Кэшированные данные
4. Заглушка (если ничего не работает)

Для использования API Swedbank сохраните токен в pass:
    pass insert swedbank/api_token

Настройка для waybar (~/.config/waybar/config):
    "custom/pension": {
        "format": "{}",
        "interval": 300,
        "exec": "/path/to/scripts/swedbank_pension.py",
        "return-type": "json"
    }

Стили для waybar (~/.config/waybar/style.css):
    #custom-pension.positive { color: #4caf50; }
    #custom-pension.negative { color: #f44336; }
    #custom-pension.error { color: #ff9800; }
"""

import json
import re
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

import requests

# Конфигурация
FUND_ISIN = "EE3600001731"
FUND_SHORTNAME = "SWV60"
FUND_NAME = "Swedbank Pension Fund V60"
CACHE_FILE = Path("/tmp/swedbank_v60_cache.json")
CACHE_TTL_SECONDS = 3600  # 1 час


def get_token_from_pass() -> str | None:
    """Получает токен API из pass."""
    try:
        result = subprocess.run(
            ["pass", "show", "swedbank/api_token"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    return None


def get_fund_data_swedbank_api(token: str) -> dict | None:
    """Получает данные о фонде через API Swedbank."""
    endpoints = [
        "https://api.swedbank.se/funds/V60/details",
        "https://www.swedbank.ee/api/pensions/funds/V60",
        "https://api.swedbank.com/funds/EE3600001731",
    ]

    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
        "Accept": "application/json",
        "Authorization": f"Bearer {token}",
    }

    for url in endpoints:
        try:
            response = requests.get(url, headers=headers, timeout=5)
            if response.status_code == 200:
                data = response.json()
                parsed = parse_swedbank_response(data)
                if parsed:
                    return parsed
        except (requests.RequestException, json.JSONDecodeError):
            continue

    return None


def parse_swedbank_response(data: dict) -> dict | None:
    """Парсит ответ от API Swedbank."""
    try:
        nav = data.get("nav", data.get("price", data.get("value", 0)))
        change = data.get("changePercent", data.get("change_percent", data.get("change", 0)))

        if isinstance(nav, str):
            nav = float(nav.replace(",", "."))
        if isinstance(change, str):
            change = float(change.replace(",", ".").replace("%", ""))

        return {
            "name": data.get("name", FUND_NAME),
            "nav": float(nav),
            "change": float(change),
        }
    except (ValueError, TypeError, KeyError):
        return None


def get_fund_data_nasdaq() -> dict | None:
    """
    Получает данные о фонде с Nasdaq Baltic.
    """
    url = f"https://www.nasdaqbaltic.com/en/instrument/{FUND_ISIN}/"

    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
        "Accept": "text/html,application/json,*/*",
    }

    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()

        # Ищем данные в HTML
        nav_match = re.search(r'NAV[:\s]+([\d,]+\.\d+)', response.text, re.IGNORECASE)
        change_match = re.search(r'Change[:\s]+([+-]?[\d,]+\.\d+)%', response.text, re.IGNORECASE)

        if nav_match and change_match:
            # Убираем запятые (разделители тысяч), оставляем точку для float
            nav = float(nav_match.group(1).replace(",", ""))
            change = float(change_match.group(1).replace(",", ""))
            return {
                "name": FUND_NAME,
                "nav": nav,
                "change": change,
            }

        return None

    except (requests.exceptions.RequestException, ValueError, AttributeError):
        return None


def get_fund_data_manual() -> dict | None:
    """
    Получает данные из ручного CSV файла.

    Создайте файл ~/Documents/config/scripts/swedbank_v60_data.csv
    с форматом: DATE,NAV,CHANGE
    """
    csv_file = Path(__file__).parent / "swedbank_v60_data.csv"

    try:
        if not csv_file.exists():
            return None

        with open(csv_file, "r", encoding="utf-8") as f:
            lines = f.readlines()

        # Ищем последнюю строку с данными (пропускаем комментарии)
        for line in reversed(lines):
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            parts = line.split(",")
            if len(parts) >= 3:
                nav = float(parts[1].replace(",", "."))
                change = float(parts[2].replace(",", "."))

                return {
                    "name": FUND_NAME,
                    "nav": nav,
                    "change": change,
                }
    except (ValueError, IndexError, IOError):
        pass

    return None


def get_cached_data() -> dict | None:
    """Получает данные из кэша."""
    try:
        with open(CACHE_FILE, "r") as f:
            data = json.load(f)
            cached_time = datetime.fromisoformat(data.get("timestamp", ""))
            if (datetime.now() - cached_time).total_seconds() < CACHE_TTL_SECONDS:
                return {
                    "name": data.get("name", FUND_NAME),
                    "nav": data.get("nav", 0),
                    "change": data.get("change", 0),
                    "from_cache": True,
                }
    except (FileNotFoundError, json.JSONDecodeError, ValueError):
        pass
    return None


def save_to_cache(data: dict):
    """Сохраняет данные в кэш."""
    data["timestamp"] = datetime.now().isoformat()
    try:
        CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)
    except Exception:
        pass


def format_change(change: float) -> str:
    """Форматирует изменение с знаком."""
    if change >= 0:
        return f"+{change:.2f}%"
    return f"{change:.2f}%"


def get_waybar_output(data: dict | None) -> dict:
    """Формирует вывод в формате JSON для waybar."""
    if data is None or data.get("error"):
        error_msg = data.get("error", "Нет данных") if data else "Нет данных"
        return {
            "text": "🏦 N/A",
            "tooltip": f"⚠️ Ошибка получения данных:\n{error_msg}",
            "class": "error",
        }

    fund_name = data.get("name", FUND_NAME)
    nav = data.get("nav", 0)
    change = data.get("change", 0)
    from_cache = data.get("from_cache", False)

    # Определяем класс и иконку
    if change > 0:
        status_class = "positive"
        change_icon = "📈"
    elif change < 0:
        status_class = "negative"
        change_icon = "📉"
    else:
        status_class = "neutral"
        change_icon = "➡"

    # Формируем tooltip
    tooltip_lines = [
        f"🏦 {fund_name}",
        f"💰 Стоимость пая: {nav:.4f} EUR",
        f"📊 Изменение: {change_icon} {format_change(change)}",
    ]

    if from_cache:
        tooltip_lines.append("⏱️ (данные из кэша)")

    tooltip_lines.extend([
        "",
        f"🕐 Обновлено: {datetime.now().strftime('%d.%m.%Y %H:%M')}",
    ])

    return {
        "text": f"🏦 V60 {format_change(change)}",
        "tooltip": "\n".join(tooltip_lines),
        "class": status_class,
    }


def main():
    # 1. В первую очередь проверяем кэш (чтобы не спамить запросами)
    data = get_cached_data()

    if data is None:
        # 2. Пробуем API Swedbank (если есть токен)
        token = get_token_from_pass()
        if token:
            data = get_fund_data_swedbank_api(token)

        # 3. Пробуем Nasdaq Baltic
        if data is None:
            data = get_fund_data_nasdaq()

        # 4. Пробуем ручной CSV файл
        if data is None:
            data = get_fund_data_manual()

        # Сохраняем свежие данные в кэш
        if data and not data.get("error"):
            save_to_cache(data)

    output = get_waybar_output(data)
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()

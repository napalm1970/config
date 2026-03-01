# Swedbank Pension Fund V60 Waybar Script

Скрипт для получения информации о пенсионном фонде **Swedbank Pension Fund V60** и вывода в формате JSON для waybar.

## Установка

1. Убедитесь, что у вас установлен Python 3.10+ и библиотека `requests`:
   ```bash
   pip install requests
   ```

2. Скрипт уже находится в папке `scripts/`

## Источники данных

Скрипт пытается получить данные из следующих источников (по приоритету):

1. **API Swedbank** - требует токен авторизации
2. **Nasdaq Baltic** - публичные данные
3. **Ручной CSV файл** - данные обновляются вручную
4. **Кэш** - данные из предыдущего успешного запроса

## Настройка

### Вариант 1: Использование API Swedbank (рекомендуется)

Если у вас есть доступ к API Swedbank:

1. Сохраните токен в pass:
   ```bash
   pass insert swedbank/api_token
   ```

2. Скрипт автоматически получит токен и использует API

### Вариант 2: Ручное обновление данных

1. Создайте файл `swedbank_v60_data.csv` рядом со скриптом:
   ```csv
   # DATE,NAV,CHANGE
   2026-03-01,1.2345,0.15
   ```

2. Обновляйте данные регулярно

### Вариант 3: Автоматическое обновление через cron

Добавьте в crontab:
```bash
# Обновление данных о фонде каждые 4 часа
0 */4 * * * /path/to/scripts/swedbank_pension.py > /dev/null 2>&1
```

## Настройка waybar

### ~/.config/waybar/config

```json
{
    "custom/pension": {
        "format": "{}",
        "interval": 300,
        "exec": "/home/napalm/Documents/config/scripts/swedbank_pension.py",
        "return-type": "json"
    }
}
```

### ~/.config/waybar/style.css

```css
#custom-pension {
    font-weight: bold;
    padding: 0 10px;
}

#custom-pension.positive {
    color: #4caf50;
}

#custom-pension.negative {
    color: #f44336;
}

#custom-pension.neutral {
    color: #ffeb3b;
}

#custom-pension.error {
    color: #ff9800;
}
```

## Формат вывода

```json
{
    "text": "🏦 V60 +0.15%",
    "tooltip": "🏦 Swedbank Pension Fund V60\n💰 Стоимость пая: 1.2345 EUR\n📊 Изменение: 📈 +0.15%\n\n🕐 Обновлено: 01.03.2026 13:44",
    "class": "positive"
}
```

## Классы состояний

- `positive` - фонд растёт (> 0%)
- `negative` - фонд падает (< 0%)
- `neutral` - без изменений (= 0%)
- `error` - ошибка получения данных

## Кэширование

Данные кэшируются в `/tmp/swedbank_v60_cache.json` в течение 1 часа.

## Отладка

Для просмотра подробной информации:

```bash
python3 /path/to/scripts/swedbank_pension.py | jq .
```

Для проверки кэша:

```bash
cat /tmp/swedbank_v60_cache.json | jq .
```

## Требования

- Python 3.10+
- requests
- pass (опционально, для API Swedbank)
- jq (опционально, для отладки)

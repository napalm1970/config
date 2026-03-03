#!/bin/bash

# Скрипт для обновления учетных данных mpdscribble из pass.

# Пути к секретам в 'pass'
PASS_USER_PATH="services/last.fm/username"
PASS_PASS_PATH="services/last.fm/mpdscribble"

# Путь к файлу конфигурации mpdscribble
CONFIG_FILE="/home/napalm/.mpdscribble.conf"

echo "Обновление учетных данных для mpdscribble из pass..."

# Проверка, существует ли файл конфигурации
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Ошибка: Файл конфигурации не найден по пути: $CONFIG_FILE"
    exit 1
fi

# Проверка, существуют ли записи в pass
if ! pass show "$PASS_USER_PATH" &>/dev/null; then
    echo "Ошибка: Имя пользователя не найдено в pass по пути: $PASS_USER_PATH"
    echo "Пожалуйста, добавьте его: pass insert $PASS_USER_PATH"
    exit 1
fi

if ! pass show "$PASS_PASS_PATH" &>/dev/null; then
    echo "Ошибка: Пароль не найден в pass по пути: $PASS_PASS_PATH"
    echo "Пожалуйста, добавьте его: pass insert -m $PASS_PASS_PATH"
    exit 1
fi


# Получаем имя пользователя и пароль из pass
LASTFM_USERNAME=$(pass "$PASS_USER_PATH")
LASTFM_PASSWORD=$(pass "$PASS_PASS_PATH")

# Обновляем имя пользователя и пароль в файле конфигурации с помощью sed
# `^username = ` - ищет строку, которая начинается с 'username = '
# `.*` - соответствует любой последовательности символов до конца строки
sed -i "s|^username = .*|username = $LASTFM_USERNAME|" "$CONFIG_FILE"
sed -i "s|^password = .*|password = $LASTFM_PASSWORD|" "$CONFIG_FILE"

echo "✓ Учетные данные Last.fm успешно обновлены в $CONFIG_FILE."
echo "Не забудьте установить правильные права доступа: chmod 600 $CONFIG_FILE"
echo "Возможно, потребуется перезапустить сервис mpdscribble, чтобы изменения вступили в силу."

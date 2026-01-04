#!/bin/bash

# Максимальное время ожидания (в секундах)
TIMEOUT=60
COUNTER=0

# Ждем доступности Google DNS или Cloudflare
# -c 1: один пакет
# -W 1: таймаут 1 сек
while ! ping -c 1 -W 1 8.8.8.8 &> /dev/null && ! ping -c 1 -W 1 1.1.1.1 &> /dev/null; do
    if [ $COUNTER -gt $TIMEOUT ]; then
        notify-send -u critical "Network Wait" "Таймаут ожидания сети для $1"
        exit 1
    fi
    sleep 2
    ((COUNTER+=2))
done

# Как только интернет появился, запускаем команду
exec "$@"

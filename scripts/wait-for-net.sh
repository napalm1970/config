#!/bin/bash
# Скрипт ожидания доступности сети
REMOTE_HOST="8.8.8.8"
MAX_RETRIES=20
COUNT=0

while ! ping -c 1 -W 1 $REMOTE_HOST &>/dev/null; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "Network timeout reached."
        exit 1
    fi
    echo "Waiting for network... ($COUNT/$MAX_RETRIES)"
    sleep 1
    ((COUNT++))
done

echo "Network is up!"
exit 0

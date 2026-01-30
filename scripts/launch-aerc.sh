#!/bin/bash
LOGfile="/tmp/waybar-aerc-debug.log"

echo "$(date): Attempting to start aerc" > "$LOGfile"

# Проверка, есть ли aerc
if ! command -v aerc &> /dev/null; then
    echo "Error: aerc not found in PATH" | tee -a "$LOGfile"
    read -p "Press Enter to exit..."
    exit 1
fi

echo "Path: $PATH" >> "$LOGfile"
echo "Running aerc..." >> "$LOGfile"

# Запуск aerc с захватом ошибок
/usr/bin/aerc 2>> "$LOGfile"

EXIT_CODE=$?
echo "aerc exited with code $EXIT_CODE" >> "$LOGfile"

if [ $EXIT_CODE -ne 0 ]; then
    echo "---------------------------------------------------"
    echo "AERC CRASHED with code $EXIT_CODE."
    echo "Check $LOGfile for details."
    echo "Last 5 lines of log:"
    tail -n 5 "$LOGfile"
    echo "---------------------------------------------------"
    read -p "Press Enter to close terminal..."
fi

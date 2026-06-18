#!/usr/bin/env bash

if pgrep -x "gammastep" > /dev/null; then
    echo '{"text": "󰹐", "tooltip": "Защита зрения (Gammastep): Включена", "class": "on"}'
else
    echo '{"text": "󰹏", "tooltip": "Защита зрения (Gammastep): Выключена", "class": "off"}'
fi

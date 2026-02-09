#!/bin/bash
# Запуск настройки системы через Ansible

if ! command -v ansible-playbook &>/dev/null; then
    echo "Ansible не найден. Установка..."
    sudo pacman -S --needed --noconfirm ansible
fi

cd "$(dirname "$0")/ansible" || exit

echo "Проверка зависимостей (collections)..."
ansible-galaxy collection install -r requirements.yml --upgrade

ansible-playbook playbooks/main.yml --ask-become-pass "$@"

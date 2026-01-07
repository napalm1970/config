# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Используем образ generic/arch (поддерживает VirtualBox)
  config.vm.box = "generic/arch"

  # Настройки VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
    vb.name = "Arch_Config_Test"
  end

  # Скрипт провижининга (выполняется при первом запуске)
  config.vm.provision "shell", inline: <<-SHELL
    # 1. Обновление ключей и системы
    echo "Update system..."
    pacman -Sy --noconfirm archlinux-keyring
    pacman -Syu --noconfirm

    # Установка git и base-devel (нужны для yay и клонирования)
    pacman -S --noconfirm git base-devel

    # 2. Создание пользователя napalm
    if ! id "napalm" &>/dev/null; then
        echo "Creating user napalm..."
        useradd -m -G wheel -s /bin/bash napalm
        # Установка пароля (на всякий случай, хотя используем ключи)
        echo "napalm:napalm" | chpasswd

        # Настройка sudo без пароля для группы wheel (важно для автоматизации)
        echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/10-wheel-nopasswd
    fi

    # 3. Подготовка директорий и клонирование репозитория
    # Выполняем от имени пользователя napalm, чтобы права были правильными
    sudo -u napalm bash -c '
        echo "Setting up directories..."
        mkdir -p /home/napalm/Documents

        target_dir="/home/napalm/Documents/config"

        if [ ! -d "$target_dir" ]; then
            echo "Cloning repository..."
            git clone https://github.com/napalm1970/config.git "$target_dir"
        else
            echo "Repository directory already exists. Pulling latest changes..."
            cd "$target_dir" && git pull
        fi
    '

    echo "Done! You can now run 'vagrant ssh' to enter the machine."
  SHELL
end

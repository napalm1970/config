# Мои конфиги Arch Linux (Hyprland, Fish, Waybar)

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-00A4C7?style=for-the-badge&logo=hyprland&logoColor=white)
![Fish Shell](https://img.shields.io/badge/Fish_Shell-D61159?style=for-the-badge&logo=fish-shell&logoColor=white)

Коллекция моих конфигурационных файлов (dotfiles) для Arch Linux. Сборка ориентирована на эстетику, продуктивность и управление преимущественно с клавиатуры. Основные компоненты: композитный менеджер **Hyprland**, оболочка **Fish** и панель **Waybar**.

## 🖼️ Галерея

> *Здесь можно разместить скриншоты вашего рабочего стола*

## ✨ Основные возможности

*   **Оконный менеджер:** [Hyprland](https://hyprland.org/) с использованием стандартного макета `dwindle` для динамического тайлинга.
*   **Статус-бар:** [Waybar](https://github.com/Alexays/Waybar) с кастомными Python-скриптами для:
    *   🌤️ Погоды (wttr.in)
    *   📦 Проверки обновлений (Arch/AUR)
    *   ⌨️ Отображения текущей раскладки
*   **Оболочка:** [Fish](https://fishshell.com/) с набором полезных функций и плагинов.
*   **Терминал:** [Kitty](https://sw.kovidgoyal.net/kitty/) с темами Dracula и Catppuccin.
*   **Меню запуска:** [Wofi](https://hg.sr.ht/~scoopta/wofi) с кастомной стилизацией.
*   **Файловый менеджер:** [Yazi](https://github.com/sxyazi/yazi) — невероятно быстрый консольный менеджер.
*   **Индикация:** Кастомный виджет раскладки и времени (`hyprland-status`) на базе GTK4.

## 📂 Структура репозитория

```text
├── fish/               # Конфигурация Fish и плагины
├── hypr/               # Настройки Hyprland, горячие клавиши и мониторы
├── waybar/             # Конфиг Waybar, стили и Python-скрипты
├── kitty/              # Настройки терминала Kitty
├── wofi/               # Стилизация и конфиг Wofi
├── yazi/               # Конфигурация файлового менеджера Yazi
├── scripts/            # Вспомогательные скрипты
├── hyprland-status/    # Кастомный виджет статуса (Python/GTK4)
└── Themes/             # Обои и темы оформления приложений
```

## 🚀 Быстрый старт

### 1. Подготовка
Убедитесь, что у вас установлен Arch Linux и есть доступ к интернету. Для корректного отображения интерфейса необходим Nerd Font (например, `ttf-jetbrains-mono-nerd`).

### 2. Установка
Склонируйте репозиторий и запустите скрипт автоматической настройки через Ansible. Он сам установит пакеты, создаст симлинки и настроит систему.

```bash
git clone https://github.com/napalm1970/config.git ~/Documents/config
cd ~/Documents/config
chmod +x run_ansible.sh
./run_ansible.sh --ask-vault-pass
```

**Что делает скрипт:**
*   **Ansible:** Автоматически скачивает и устанавливает Ansible.
*   **Секреты:** Использует Ansible Vault для безопасного хранения паролей (потребуется ввести пароль хранилища).
*   **Пакеты:** Устанавливает всё необходимое (pacman + AUR).
*   **Конфигурация:** Настраивает систему, сервисы и пользовательское окружение.

> **Подробная справка по запуску и тестированию:** [ANSIBLE_HELP.md](ANSIBLE_HELP.md)

## ⌨️ Горячие клавиши

| Сочетание | Действие |
| :--- | :--- |
| `SUPER + Return` | Терминал (Kitty) |
| `SUPER + Q` | Закрыть окно |
| `SUPER + D` | Меню запуска (Wofi) |
| `SUPER + E` | Файловый менеджер |
| `SUPER + B` | Браузер (Firefox) |
| `SUPER + F` | Полноэкранный режим |
| `SUPER + SPACE` | Смена раскладки |
| `SUPER + SHIFT + T` | Показать статус-виджет (Layout/Bat/Time) |

## 🤝 Участие в разработке

Если у вас есть идеи по улучшению — открывайте Issue или Pull Request. Конфиги полностью переносимы и не привязаны к конкретному имени пользователя.

## 📜 Лицензия

MIT License.

## 🙏 Благодарности

*   Сообществу [Hyprland](https://hyprland.org/) за отличный композитный менеджер.
*   Проектам [Catppuccin](https://github.com/catppuccin/catppuccin) и [Dracula](https://draculatheme.com/) за цветовые схемы.

### ⌨️ Hotkeys
| Key | Action |
|-----|--------|
| $mainMod + Return | $terminal |
| $mainMod + b | $BROWSER |
| $mainMod + t | tor |
| $mainMod SHIFT + P | pypr toggle term |
| $mainMod SHIFT + V | pypr toggle volume |
| $mainMod SHIFT + C | pypr toggle calc |
| $mainMod SHIFT + T | $runprog |
| $mainMod SHIFT + S | grim -g "$(slurp)" - | wl-copy |

**Packages:** --...

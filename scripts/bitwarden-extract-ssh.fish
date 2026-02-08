#!/usr/bin/env fish

# Скрипт для извлечения SSH ключей из Bitwarden
# Использование: ./bitwarden-extract-ssh.fish

# Безопасность: файлы создаются доступными только владельцу
umask 077

set -l SSH_DIR "$HOME/.ssh"
set -l SSH_KEY_NAME "id_ed25519"
set -l BW_ITEM_NAME "id_ed25519"

# Цвета для вывода
set -l RED '\033[0;31m'
set -l GREEN '\033[0;32m'
set -l YELLOW '\033[0;33m'
set -l NC '\033[0m' # No Color

# Проверка установки необходимых утилит
if not command -v bw &> /dev/null
    echo -e "$RED✗ Ошибка: Bitwarden CLI (bw) не установлен$NC"
    exit 1
end

if not command -v jq &> /dev/null
    echo -e "$RED✗ Ошибка: jq не установлен$NC"
    exit 1
end

# Шаг 1: Проверка статуса входа в Bitwarden
echo "Проверка статуса Bitwarden..."
set -l bw_status (bw status | jq -r '.status')

if test "$bw_status" = "unauthenticated"
    echo "Вход в Bitwarden..."
    bw login
    if test $status -ne 0
        echo -e "$RED✗ Ошибка при входе в Bitwarden$NC"
        exit 1
    end
else
    echo "✓ Уже авторизован в Bitwarden (статус: $bw_status)"
end

# Шаг 2: Разблокировка хранилища и получение session token
echo "Разблокировка хранилища..."
if set -q BW_PASSWORD; and test -n "$BW_PASSWORD"
    set -gx BW_SESSION (echo "$BW_PASSWORD" | bw unlock --raw)
else
    set -gx BW_SESSION (bw unlock --raw)
end

if test $status -ne 0
    echo -e "$RED✗ Ошибка при разблокировке хранилища$NC"
    exit 1
end

# Шаг 3: Синхронизация с сервером Bitwarden
echo "Синхронизация с сервером Bitwarden..."
bw sync
if test $status -ne 0
    echo -e "$YELLOW⚠ Предупреждение: не удалось синхронизировать с сервером$NC"
    echo "  Продолжаем с локальными данными..."
else
    echo "✓ Синхронизация завершена"
end

# Шаг 3: Создание директории ~/.ssh если не существует
if not test -d $SSH_DIR
    echo "Создание директории $SSH_DIR..."
    mkdir -p $SSH_DIR
    chmod 700 $SSH_DIR
else
    echo "Директория $SSH_DIR уже существует"
    chmod 700 $SSH_DIR
end

# Шаг 4: Извлечение SSH ключа из Bitwarden
echo "Извлечение SSH ключа '$BW_ITEM_NAME' из Bitwarden..."
bw get item "$BW_ITEM_NAME" | jq -r '.notes' > "$SSH_DIR/$SSH_KEY_NAME"
if test $status -ne 0
    echo -e "$RED✗ Ошибка при извлечении ключа из Bitwarden$NC"
    exit 1
end

# Шаг 5: Установка правильных прав доступа
echo "Установка прав доступа 600 для $SSH_DIR/$SSH_KEY_NAME..."
chmod 600 "$SSH_DIR/$SSH_KEY_NAME"

# Проверка успешности создания файла
if not test -f "$SSH_DIR/$SSH_KEY_NAME"
    echo -e "$RED✗ Ошибка: файл ключа не был создан$NC"
    exit 1
end

# Шаг 6: Проверка корректности содержимого приватного ключа
echo "Проверка корректности содержимого ключа..."
set -l key_content (cat "$SSH_DIR/$SSH_KEY_NAME")

# Проверка наличия заголовка приватного ключа
if not string match -q "*BEGIN OPENSSH PRIVATE KEY*" -- $key_content
    and not string match -q "*BEGIN RSA PRIVATE KEY*" -- $key_content
    and not string match -q "*BEGIN EC PRIVATE KEY*" -- $key_content
    and not string match -q "*BEGIN PRIVATE KEY*" -- $key_content
    echo -e "$RED✗ Ошибка: файл не содержит корректный заголовок приватного ключа$NC"
    echo "  Ожидается: '-----BEGIN OPENSSH PRIVATE KEY-----' или аналогичный"
    rm -f "$SSH_DIR/$SSH_KEY_NAME"
    exit 1
end

# Проверка наличия футера приватного ключа
if not string match -q "*END OPENSSH PRIVATE KEY*" -- $key_content
    and not string match -q "*END RSA PRIVATE KEY*" -- $key_content
    and not string match -q "*END EC PRIVATE KEY*" -- $key_content
    and not string match -q "*END PRIVATE KEY*" -- $key_content
    echo -e "$RED✗ Ошибка: файл не содержит корректный футер приватного ключа$NC"
    echo "  Ожидается: '-----END OPENSSH PRIVATE KEY-----' или аналогичный"
    rm -f "$SSH_DIR/$SSH_KEY_NAME"
    exit 1
end

echo "✓ SSH ключ успешно извлечен в $SSH_DIR/$SSH_KEY_NAME"
echo "✓ Права доступа установлены корректно"
echo "✓ Содержимое ключа прошло валидацию"

# Добавление GitHub в known_hosts для работы git clone
echo "Добавление github.com в known_hosts..."
ssh-keyscan github.com >> "$SSH_DIR/known_hosts" 2>/dev/null
chmod 600 "$SSH_DIR/known_hosts"

# ============================================================================
# СЕКЦИЯ PASS STORE: Клонирование репозитория
# ============================================================================

set -l PASS_DIR "$HOME/.password-store"
set -l PASS_REPO_URL "git@github.com:napalm1970/pass.git"

echo ""
echo "========================================="
echo "Настройка Password Store"
echo "========================================="

if not test -d "$PASS_DIR"
    echo "Клонирование репозитория pass..."
    git clone "$PASS_REPO_URL" "$PASS_DIR"
    if test $status -ne 0
        echo -e "$RED✗ Ошибка при клонировании репозитория$NC"
        # Продолжаем, возможно получится создать пустой
    else
        echo "✓ Репозиторий успешно склонирован"
    end
else
    echo "Папка $PASS_DIR уже существует, пропускаем клонирование"
end

# Установка прав 700 на папку
if test -d "$PASS_DIR"
    echo "Установка прав 700 на $PASS_DIR..."
    chmod 700 "$PASS_DIR"

    # Инициализация git в pass (если еще не инициализирован)
    echo "Инициализация git в pass..."
    pass git init

    # Проверка и добавление origin (если клонирование не удалось или папка была создана вручную)
    echo "Настройка git remote..."
    if not git -C "$PASS_DIR" remote | grep -q "origin"
        pass git remote add origin "$PASS_REPO_URL"
        pass git branch -M main
        echo "✓ Remote origin добавлен"
    else
        echo "✓ Remote origin уже существует"
    end
end

# ============================================================================
# СЕКЦИЯ GPG: Извлечение и импорт GPG приватного ключа
# ============================================================================

set -l GPG_ITEM_NAME "GPG PRIVATE KEY"
# Безопасное создание временного файла
set -l GPG_TEMP_FILE (mktemp)

# Функция для гарантированного удаления временного файла при выходе
function cleanup --on-event fish_exit
    if test -n "$GPG_TEMP_FILE" -a -f "$GPG_TEMP_FILE"
        rm -f "$GPG_TEMP_FILE"
    end
end

echo ""
echo "========================================="
echo "Извлечение GPG ключа из Bitwarden"
echo "========================================="

# Проверка установки GPG
if not command -v gpg &> /dev/null
    echo "⚠ Предупреждение: GPG не установлен, пропускаем импорт GPG ключа"
else
    # Шаг 7: Извлечение GPG ключа из Bitwarden
    echo "Извлечение GPG ключа '$GPG_ITEM_NAME' из Bitwarden..."
    bw get item "$GPG_ITEM_NAME" | jq -r '.notes' > "$GPG_TEMP_FILE"

    if test $status -ne 0
        echo -e "$RED✗ Ошибка при извлечении GPG ключа из Bitwarden$NC"
        # Файл удалится автоматически
    else
        # Шаг 8: Проверка корректности содержимого GPG ключа
        echo "Проверка корректности содержимого GPG ключа..."
        set -l gpg_content (cat "$GPG_TEMP_FILE")

        # Проверка наличия заголовка GPG приватного ключа
        if not string match -q "*BEGIN PGP PRIVATE KEY BLOCK*" -- $gpg_content
            echo -e "$RED✗ Ошибка: файл не содержит корректный заголовок GPG приватного ключа$NC"
            echo "  Ожидается: '-----BEGIN PGP PRIVATE KEY BLOCK-----'"
            # Файл удалится автоматически
        else if not string match -q "*END PGP PRIVATE KEY BLOCK*" -- $gpg_content
            echo -e "$RED✗ Ошибка: файл не содержит корректный футер GPG приватного ключа$NC"
            echo "  Ожидается: '-----END PGP PRIVATE KEY BLOCK-----'"
            # Файл удалится автоматически
        else
            echo "✓ Содержимое GPG ключа прошло валидацию"

            # Шаг 9: Импорт GPG ключа в keyring
            echo "Импорт GPG ключа в keyring..."
            gpg --import "$GPG_TEMP_FILE" 2>&1

            if test $status -eq 0
                echo "✓ GPG ключ успешно импортирован"

                # Шаг 10: Извлечение Key ID из импортированного ключа
                echo "Извлечение Key ID..."
                set -l GPG_KEY_ID (gpg --list-secret-keys --keyid-format LONG | grep -A 1 "sec" | grep -oP "(?<=sec   )[A-Z0-9]+/\K[A-F0-9]+" | head -n 1)

                if test -n "$GPG_KEY_ID"
                    echo "✓ Key ID найден: $GPG_KEY_ID"

                    # Шаг 11: Установка максимального доверия к ключу
                    echo "Установка максимального доверия к ключу..."
                    echo -e "5\ny\n" | gpg --command-fd 0 --expert --edit-key "$GPG_KEY_ID" trust quit 2>&1

                    if test $status -eq 0
                        echo "✓ Доверие к ключу установлено"
                    else
                        echo "⚠ Предупреждение: не удалось автоматически установить доверие"
                        echo "  Выполните вручную: gpg --edit-key $GPG_KEY_ID"
                    end

                    # Вывод информации о ключе
                    echo ""
                    echo "Информация об импортированном ключе:"
                    gpg --list-secret-keys "$GPG_KEY_ID"

                    # Шаг 12: Инициализация pass с GPG ключом
                    if command -v pass &> /dev/null
                        echo ""
                        echo "Инициализация pass с GPG ключом..."
                        pass init "$GPG_KEY_ID"

                        if test $status -eq 0
                            echo "✓ pass успешно инициализирован с ключом $GPG_KEY_ID"
                        else
                            echo -e "$RED✗ Ошибка при инициализации pass$NC"
                        end
                    else
                        echo ""
                        echo "⚠ Предупреждение: pass не установлен, пропускаем инициализацию"
                        echo "  Для инициализации вручную выполните: pass init $GPG_KEY_ID"
                    end
                else
                    echo "⚠ Предупреждение: не удалось извлечь Key ID"
                end
            else
                echo -e "$RED✗ Ошибка при импорте GPG ключа$NC"
            end

            # Временный файл будет удален автоматически функцией cleanup
        end
    end
end

echo ""
echo "========================================="
echo "Готово!"
echo "========================================="

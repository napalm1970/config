#!/usr/bin/env python3
"""
Скрипт для проверки почты в waybar.
Читает конфигурацию из aerc/accounts.conf и проверяет IMAP-ящики.
Выводит JSON для waybar с количеством непрочитанных писем.
"""

import configparser
import imaplib
import json
import os
import subprocess
import sys
from pathlib import Path


def get_pass(path: str) -> str | None:
    """Получить пароль из pass."""
    try:
        result = subprocess.run(
            ["pass", "show", path],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip().splitlines()[0]
    except (subprocess.CalledProcessError, IndexError):
        return None


def parse_aerc_accounts() -> list[dict]:
    """
    Парсинг aerc/accounts.conf.
    Возвращает список словарей с параметрами аккаунтов.
    """
    accounts = []
    accounts_conf = Path(os.environ.get("HOME", "~")) / ".config" / "aerc" / "accounts.conf"

    if not accounts_conf.exists():
        return accounts

    config = configparser.ConfigParser(interpolation=None)
    config.read(accounts_conf)

    for section in config.sections():
        cfg = config[section]
        account = {
            "name": section,
            "source": cfg.get("source", ""),
            "user": cfg.get("from", ""),
            "pass_cmd": cfg.get("source-cred-cmd", ""),
        }
        accounts.append(account)

    return accounts


def check_imap(account: dict) -> dict:
    """
    Проверка IMAP-ящика.
    Возвращает результат проверки.
    """
    name = account["name"]
    source = account["source"]
    from_field = account["user"]
    pass_cmd = account.get("pass_cmd", "")

    # Извлечение user из from: "Name <user@domain.com>"
    user = ""
    if "<" in from_field and ">" in from_field:
        user = from_field.split("<")[1].split(">")[0].strip()
    else:
        user = from_field.strip()

    # Парсинг source: imaps://user%40domain@host:port/...
    host = None
    port = 993
    try:
        if source.startswith("imaps://") or source.startswith("imap://"):
            prefix = "imaps://" if source.startswith("imaps://") else "imap://"
            url = source[len(prefix):]  # убрать префикс
            if "@" in url:
                host_part = url.split("@")[-1].split("/")[0]
                if ":" in host_part:
                    host, port_str = host_part.rsplit(":", 1)
                    port = int(port_str)
                else:
                    host = host_part
    except (ValueError, IndexError):
        return {"name": name, "unread": 0, "error": True, "error_msg": "Invalid source"}

    if not host:
        return {"name": name, "unread": 0, "error": True, "error_msg": "No host"}

    # Получение пароля из pass_cmd
    password = None
    if pass_cmd and pass_cmd.startswith("pass show"):
        pass_path = pass_cmd.replace("pass show", "").replace("| head -n 1 | tr -d '\\n'", "").strip()
        password = get_pass(pass_path)

    if not password:
        return {"name": name, "unread": 0, "error": True, "error_msg": "No password"}

    # Подключение к IMAP
    try:
        conn = imaplib.IMAP4_SSL(host, port)
        conn.login(user, password)
        conn.select("INBOX")

        # Поиск непрочитанных
        status, messages = conn.search(None, "UNSEEN")
        unread_count = len(messages[0].split()) if messages[0] else 0

        conn.logout()

        return {"name": name, "unread": unread_count, "error": False}

    except Exception as e:
        return {"name": name, "unread": 0, "error": True, "error_msg": str(e)}


def main():
    """Основная функция."""
    accounts = parse_aerc_accounts()

    if not accounts:
        output = {
            "text": " 0",
            "tooltip": "Нет аккаунтов в aerc/accounts.conf",
            "class": "empty",
            "alt": "0",
        }
        print(json.dumps(output, ensure_ascii=False))
        return

    results = [check_imap(acc) for acc in accounts]

    total_unread = 0
    tooltip_lines = []
    has_error = False

    for res in results:
        if res["error"]:
            tooltip_lines.append(f"{res['name']}:  {res.get('error_msg', 'Error')}")
            has_error = True
        else:
            count = res["unread"]
            total_unread += count
            if count > 0:
                tooltip_lines.append(f"{res['name']}: <b>{count}</b> новых")

    if not tooltip_lines:
        tooltip_lines.append("Нет новых писем")

    icon = "" if total_unread > 0 else ""
    css_class = "unread" if total_unread > 0 else "empty"
    if has_error:
        css_class = "error"

    output = {
        "text": f"{icon} {total_unread}",
        "tooltip": "\n".join(tooltip_lines),
        "class": css_class,
        "alt": str(total_unread),
    }

    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()

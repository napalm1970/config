---
name: deploy-check
description: Запускает Ansible playbook в режиме --check --diff чтобы показать, какие изменения будут применены. Не модифицирует систему.
---

# deploy-check

Безопасный dry-run всего Ansible-плейбука — показывает diff каждого таска, ничего не меняя.

## Шаги

1. Запусти dry-run из корня проекта:
   ```bash
   cd "$CLAUDE_PROJECT_DIR/ansible" && \
     ansible-playbook playbooks/main.yml --ask-vault-pass --check --diff
   ```
   Vault-пароль придётся ввести интерактивно — это нормально.

2. Покажи пользователю итоговую сводку Ansible (`PLAY RECOPY ...`): сколько `ok`, `changed`, `failed`, `unreachable`.

3. Если есть `changed` — выведи список затронутых тасков (имена), чтобы пользователь видел что именно поменяется.

4. **НЕ** запускай реальный apply автоматически. Если пользователь хочет применить изменения — он сам выполнит `./run_ansible.sh --ask-vault-pass`.

## Когда использовать

- Перед коммитом изменений в `ansible/roles/*/tasks/`, `ansible/roles/dotfiles/vars/main.yml`, `ansible/group_vars/`.
- Чтобы убедиться что новый таск не сломает существующие symlinks или systemd-юниты.

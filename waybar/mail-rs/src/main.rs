use imap;
use native_tls::TlsConnector;
use rayon::prelude::*;
use serde::Serialize;
use std::process::Command;

// Структура для конфигурации аккаунта
struct AccountConfig {
    name: &'static str,
    host: &'static str,
    user: &'static str,
    pass_path: &'static str,
}

// Результат проверки одного аккаунта
struct CheckResult {
    name: String,
    unread: Option<u32>,
    error: bool,
}

// JSON структура для Waybar
#[derive(Serialize)]
struct WaybarOutput {
    text: String,
    tooltip: String,
    class: String,
    alt: String,
}

fn get_pass(path: &str) -> Option<String> {
    let output = Command::new("pass")
        .arg("show")
        .arg(path)
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    // Берем первую строку и убираем пробелы/переносы
    let full_out = String::from_utf8_lossy(&output.stdout);
    let first_line = full_out.lines().next()?;
    Some(first_line.trim().to_string())
}

fn check_account(acc: &AccountConfig) -> CheckResult {
    // 1. Получаем пароль
    let password = match get_pass(acc.pass_path) {
        Some(p) => p,
        None => return CheckResult { name: acc.name.to_string(), unread: None, error: true },
    };

    // 2. Подключаемся к TLS
    let tls = match TlsConnector::builder().build() {
        Ok(t) => t,
        Err(_) => return CheckResult { name: acc.name.to_string(), unread: None, error: true },
    };

    // 3. Подключаемся к IMAP
    let client_res = imap::connect((acc.host, 993), acc.host, &tls);
    let mut client = match client_res {
        Ok(c) => c,
        Err(_) => return CheckResult { name: acc.name.to_string(), unread: None, error: true },
    };

    // 4. Логин (превращает Client в Session)
    let mut session = match client.login(acc.user, &password) {
        Ok(s) => s,
        Err(_) => return CheckResult { name: acc.name.to_string(), unread: None, error: true },
    };

    // 5. Выбираем INBOX
    if session.select("INBOX").is_err() {
        return CheckResult { name: acc.name.to_string(), unread: None, error: true };
    }

    // 6. Ищем непрочитанные
    let unread_count = match session.search("UNSEEN") {
        Ok(ids) => ids.len() as u32,
        Err(_) => 0,
    };

    let _ = session.logout();

    CheckResult {
        name: acc.name.to_string(),
        unread: Some(unread_count),
        error: false,
    }
}

fn main() {
    let accounts = vec![
        AccountConfig {
            name: "Gmail",
            host: "imap.gmail.com",
            user: "napalm1970@gmail.com",
            pass_path: "keepass/mail/Google/Google",
        },
        AccountConfig {
            name: "Yandex (Juri)",
            host: "imap.yandex.ru",
            user: "juri.pilipenko@yandex.ru",
            pass_path: "keepass/mail/yandex/juri.pilipenko@yandex.ru",
        },
        AccountConfig {
            name: "Yandex (Nap85)",
            host: "imap.yandex.ru",
            user: "nap85@yandex.ru",
            pass_path: "keepass/mail/yandex/nap85@yandex.ru",
        },
    ];

    // Параллельная проверка всех аккаунтов
    let results: Vec<CheckResult> = accounts.par_iter()
        .map(|acc| check_account(acc))
        .collect();

    let mut total_unread = 0;
    let mut tooltip_lines = Vec::new();
    let mut has_error = false;

    for res in results {
        if res.error {
            tooltip_lines.push(format!("{}:  Error/Auth", res.name));
            has_error = true;
        } else if let Some(count) = res.unread {
            total_unread += count;
            if count > 0 {
                tooltip_lines.push(format!("{}: <b>{}</b> new", res.name, count));
            } else {
               // tooltip_lines.push(format!("{}: 0", res.name));
            }
        }
    }

    if tooltip_lines.is_empty() {
        tooltip_lines.push("No new messages".to_string());
    }

    let icon = if total_unread > 0 { "" } else { "" };
    let class = if total_unread > 0 { "unread" } else { "empty" };

    // Если была ошибка, добавляем индикатор в класс или текст, по желанию
    // let text = if has_error { format!("{} {}!", icon, total_unread) } else { format!("{} {}", icon, total_unread) };

    let output = WaybarOutput {
        text: format!("{} {}", icon, total_unread),
        tooltip: tooltip_lines.join("\n"),
        class: class.to_string(),
        alt: total_unread.to_string(),
    };

    println!("{}", serde_json::to_string(&output).unwrap());
}

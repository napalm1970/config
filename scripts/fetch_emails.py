#!/usr/bin/env python3
import imaplib
import email
from email.header import decode_header
import os
import logging
import getpass
import re
from datetime import datetime

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("mail_fetcher.log"),
        logging.StreamHandler()
    ]
)

class EmailFetcher:
    def __init__(self, provider, email_user, email_pass, save_dir="downloaded_emails"):
        self.user = email_user
        self.password = email_pass
        self.save_dir = save_dir
        
        # Настройки провайдеров
        self.providers = {
            'gmail': {'host': 'imap.gmail.com', 'port': 993},
            'yandex': {'host': 'imap.yandex.com', 'port': 993}
        }
        
        if provider not in self.providers:
            raise ValueError(f"Неизвестный провайдер. Доступные: {list(self.providers.keys())}")
            
        self.host = self.providers[provider]['host']
        self.port = self.providers[provider]['port']
        self.connection = None

        if not os.path.exists(self.save_dir):
            os.makedirs(self.save_dir)

    def connect(self):
        """Подключение к серверу IMAP через SSL"""
        try:
            logging.info(f"Подключение к {self.host}:{self.port}...")
            self.connection = imaplib.IMAP4_SSL(self.host, self.port)
            self.connection.login(self.user, self.password)
            logging.info(f"Успешный вход для пользователя {self.user}")
        except Exception as e:
            logging.error(f"Ошибка подключения: {e}")
            raise

    def close(self):
        """Закрытие соединения"""
        if self.connection:
            try:
                self.connection.close()
                self.connection.logout()
                logging.info("Соединение закрыто.")
            except:
                pass

    def _clean_filename(self, s):
        """Очистка строки для использования в имени файла"""
        s = str(s).strip().replace(' ', '_')
        return re.sub(r'(?u)[^-\w.]', '', s)

    def _decode_str(self, s):
        """Декодирование заголовков (поддержка кириллицы)"""
        if s is None:
            return ""
        decoded_list = decode_header(s)
        result = ""
        for decoded_part, encoding in decoded_list:
            if isinstance(decoded_part, bytes):
                if encoding:
                    try:
                        result += decoded_part.decode(encoding)
                    except LookupError:
                        result += decoded_part.decode('utf-8', errors='ignore')
                else:
                    result += decoded_part.decode('utf-8', errors='ignore')
            else:
                result += str(decoded_part)
        return result

    def fetch_emails(self, folder="INBOX", sender_filter=None, subject_filter=None, limit=10):
        """Получение писем с фильтрацией"""
        try:
            status, messages = self.connection.select(folder)
            if status != "OK":
                logging.error(f"Не удалось открыть папку {folder}")
                return

            logging.info(f"Поиск писем в {folder}...")
            
            # Формирование критериев поиска
            search_criteria = []
            if sender_filter:
                search_criteria.append(f'(FROM "{sender_filter}")')
            if subject_filter:
                search_criteria.append(f'(SUBJECT "{subject_filter}")')
            
            # Если фильтров нет, берем все
            if not search_criteria:
                search_criteria = ['ALL']
            
            # IMAP search требует аргументы строкой или списком байтов, здесь упрощенно
            # Ищем объединяя критерии
            criteria_str = " ".join(search_criteria)
            status, msg_ids = self.connection.search(None, criteria_str)

            if status != "OK":
                logging.info("Писем по запросу не найдено.")
                return

            email_ids = msg_ids[0].split()
            logging.info(f"Найдено писем: {len(email_ids)}. Обработка последних {limit}...")

            # Обрабатываем от новых к старым
            for e_id in email_ids[::-1][:limit]:
                self._process_email(e_id)

        except Exception as e:
            logging.error(f"Ошибка при получении писем: {e}")

    def _process_email(self, email_id):
        """Извлечение и сохранение одного письма"""
        try:
            _, msg_data = self.connection.fetch(email_id, "(RFC822)")
            
            for response_part in msg_data:
                if isinstance(response_part, tuple):
                    msg = email.message_from_bytes(response_part[1])
                    
                    # Извлечение заголовков
                    subject = self._decode_str(msg["Subject"])
                    from_ = self._decode_str(msg["From"])
                    date_ = msg["Date"]

                    logging.info(f"Обработка письма: '{subject}' от '{from_}'")

                    # Извлечение тела
                    body = ""
                    if msg.is_multipart():
                        for part in msg.walk():
                            content_type = part.get_content_type()
                            content_disposition = str(part.get("Content-Disposition"))

                            if "attachment" not in content_disposition:
                                if content_type == "text/plain":
                                    try:
                                        body += part.get_payload(decode=True).decode()
                                    except:
                                        pass
                                elif content_type == "text/html" and not body:
                                    # Берем HTML только если нет plain text (или можно сохранять отдельно)
                                    try:
                                        body += part.get_payload(decode=True).decode()
                                    except:
                                        pass
                    else:
                        try:
                            body = msg.get_payload(decode=True).decode()
                        except:
                            pass

                    self._save_to_file(subject, from_, date_, body)

        except Exception as e:
            logging.error(f"Ошибка обработки письма ID {email_id}: {e}")

    def _save_to_file(self, subject, sender, date, body):
        """Сохранение письма в файл"""
        filename = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{self._clean_filename(subject)[:30]}.txt"
        filepath = os.path.join(self.save_dir, filename)
        
        try:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(f"Date: {date}\n")
                f.write(f"From: {sender}\n")
                f.write(f"Subject: {subject}\n")
                f.write("-" * 40 + "\n\n")
                f.write(body)
            logging.info(f"Письмо сохранено в: {filepath}")
        except Exception as e:
            logging.error(f"Ошибка записи файла: {e}")

def main():
    print("---" + " IMAP Email Fetcher" + "---")
    provider = input("Провайдер (gmail/yandex): ").strip().lower()
    email_user = input("Email: ").strip()
    # Используем getpass для скрытия пароля при вводе
    email_pass = getpass.getpass("Пароль (App Password): ").strip()
    
    print("\n---" + " Фильтры (нажмите Enter, чтобы пропустить)" + " ---")
    sender_filter = input("Искать от отправителя (email): ").strip() or None
    subject_filter = input("Искать по теме: ").strip() or None
    
    fetcher = None
    try:
        fetcher = EmailFetcher(provider, email_user, email_pass)
        fetcher.connect()
        fetcher.fetch_emails(
            folder="INBOX", 
            sender_filter=sender_filter, 
            subject_filter=subject_filter,
            limit=5 # Лимит писем для примера
        )
    except Exception as e:
        print(f"Критическая ошибка: {e}")
    finally:
        if fetcher:
            fetcher.close()

if __name__ == "__main__":
    main()

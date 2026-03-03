function dictation
    # Проверяем sox для записи
    if not command -v rec >/dev/null 2>&1
        echo "❌ sox (rec) не найден. Установи: sudo apt install sox"
        return 1
    end

    # Проверяем vosk-transcriber
    if not command -v vosk-transcriber >/dev/null 2>&1
        echo "❌ vosk-transcriber не найден. Установи его."
        return 1
    end

    # Создаём временный файл для записи
    set -l audio_file (mktemp --suffix=.wav)
    trap "rm -f $audio_file" EXIT

    echo "🎙️ Диктуй (Ctrl+C когда закончишь)..."

    # Записываем с микрофона (16kHz для vosk)
    rec -q $audio_file rate 16k

    # Распознаем и выводим результат
    set -l text (vosk-transcriber -m ~/.models/vosk-ru -i $audio_file 2>&1)

    if test -n "$text"
        echo "$text"
    else
        echo "🤔 Ничего не услышал." >&2
        return 1
    end
end

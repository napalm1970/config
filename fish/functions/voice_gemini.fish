function voice_gemini
    # Проверяем sox
    if not command -v rec >/dev/null 2>&1
        echo "❌ sox (rec) не найден."
        return 1
    end

    # Проверяем vosk-transcriber
    if not command -v vosk-transcriber >/dev/null 2>&1
        echo "❌ vosk-transcriber не найден."
        return 1
    end

    # Проверяем gemini-cli
    if not command -v gemini >/dev/null 2>&1
        echo "❌ gemini-cli не найден."
        return 1
    end

    # Получаем устройство микрофона по умолчанию
    set -l mic_dev (pactl list sources short 2>/dev/null | grep -v monitor | awk 'NR==1 {print $2}')
    if test -z "$mic_dev"
        echo "❌ Микрофон не найден."
        return 1
    end

    # Создаём временный файл
    set -l audio_file (mktemp --suffix=.wav)
    trap "rm -f $audio_file" EXIT

    echo "🎙️ Диктуй 5 секунд..."

    # Записываем 5 секунд с PulseAudio устройства
    rec -q -t pulseaudio "$mic_dev" $audio_file rate 16k

    # Распознаем
    set -l prompt (vosk-transcriber -m ~/.models/vosk-ru -i $audio_file 2>/dev/null)

    if test -n "$prompt"
        commandline --replace "gemini '$prompt'"
        echo "💬 Вставлено: $prompt"
        echo "↵ Enter для отправки"
    else
        echo "🤔 Ничего не услышал."
    end
end

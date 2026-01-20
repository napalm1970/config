function load_gemini_key
    set -l key (/home/napalm/build/get_key.sh $argv)
    if test $status -eq 0
        set -gx GEMINI_API_KEY $key
        echo "Ключ GEMINI_API_KEY успешно загружен."
    end
end
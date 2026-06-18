function get_idf --description 'Активировать окружение ESP-IDF (esp32)'
    # ESP-IDF не дружит с уже активным Python-venv (~/.python_venv),
    # поэтому сначала выходим из него.
    if functions -q deactivate
        deactivate
    end
    if set -q VIRTUAL_ENV
        set -e VIRTUAL_ENV
    end
    source $HOME/esp/esp-idf/export.fish
end

function gemini_context --description "Run Gemini with project context"
    set -l context (exa --tree --level=2 --ignore-glob=".git|node_modules|target|dist" 2>/dev/null; or tree -L 2 -I ".git|node_modules|target|dist")
    echo "Project structure:"
    echo "$context"
    # Здесь можно было бы запустить gemini с этим контекстом,
    # но пока просто выводим его, чтобы пользователь мог скопировать или использовать в пайпе.
end

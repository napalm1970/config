-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Подхват локальных .nvim.lua / .exrc / .nvimrc из корня проекта (требует :trust).
vim.opt.exrc = true

-- Отключаем modeline: автогенерированный STM32CubeMX main.c содержит комментарий
-- с " ex: printf(...)", который Neovim ошибочно парсит как modeline (E518).
-- Заодно убираем потенциальный вектор атаки при открытии чужих файлов.
vim.opt.modeline = false

-- Задержка перед авто-hover на CursorHold (по умолчанию у LazyVim 200мс).
-- Больше = окошко всплывает не так навязчиво при навигации курсором.
vim.opt.updatetime = 500

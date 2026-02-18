-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Move to window using the <ctrl> arrows keys
map("n", "<C-Left>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-Down>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-Up>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-Right>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Terminal mode mappings for easier window navigation
-- These mappings ensure you can switch out of the Gemini CLI or any terminal window
map("t", "<C-Left>", "<C-\\><C-n><C-w>h", { desc = "Go to left window" })
map("t", "<C-Down>", "<C-\\><C-n><C-w>j", { desc = "Go to lower window" })
map("t", "<C-Up>", "<C-\\><C-n><C-w>k", { desc = "Go to upper window" })
map("t", "<C-Right>", "<C-\\><C-n><C-w>l", { desc = "Go to right window" })

-- Maximize/Restore window
map("n", "<leader>wm", function() vim.cmd("wincmd _"); vim.cmd("wincmd |") end, { desc = "Maximize window" })
map("n", "<leader>we", function() vim.cmd("wincmd =") end, { desc = "Restore window sizes" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })

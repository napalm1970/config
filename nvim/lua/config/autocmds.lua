-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ============================================================================
-- Авто-hover: всплывающее окошко с документацией символа (функции, переменные)
-- ----------------------------------------------------------------------------
-- 1) Когда курсор стоит на символе (CursorHold, задержка = updatetime, у
--    LazyVim это 200мс).
-- 2) Когда указатель мыши наводится на символ (MouseMove).
-- ============================================================================

-- Есть ли у буфера LSP-клиент, умеющий hover
local function has_hover_client(bufnr)
  return #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" }) > 0
end

-- Уже открыто плавающее окно (hover, автодополнение и т.п.) — не дублируем
local function float_is_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      return true
    end
  end
  return false
end

-- (1) Hover при остановке курсора на символе
vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("auto_hover_cursor", { clear = true }),
  callback = function(ev)
    if float_is_open() then
      return
    end
    if not has_hover_client(ev.buf) then
      return
    end
    -- focus=false — окно не перехватывает фокус; silent — без "No information available"
    vim.lsp.buf.hover({ focus = false, silent = true, border = "rounded" })
  end,
})

-- (2) Hover при наведении мыши
vim.o.mousemoveevent = true

local mouse_win ---@type integer?
local mouse_timer ---@type uv.uv_timer_t?

local function close_mouse_float()
  if mouse_win and vim.api.nvim_win_is_valid(mouse_win) then
    pcall(vim.api.nvim_win_close, mouse_win, true)
  end
  mouse_win = nil
end

vim.keymap.set("n", "<MouseMove>", function()
  if mouse_timer then
    mouse_timer:stop()
    mouse_timer = nil
  end
  -- небольшой debounce, чтобы не слать запрос на каждый пиксель движения
  mouse_timer = vim.defer_fn(function()
    local pos = vim.fn.getmousepos()
    if pos.winid == 0 or pos.line == 0 or pos.column == 0 then
      close_mouse_float()
      return
    end
    local ok, bufnr = pcall(vim.api.nvim_win_get_buf, pos.winid)
    if not ok or not has_hover_client(bufnr) then
      close_mouse_float()
      return
    end
    local client = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" })[1]
    local params = {
      textDocument = { uri = vim.uri_from_bufnr(bufnr) },
      position = { line = pos.line - 1, character = pos.column - 1 },
    }
    client:request("textDocument/hover", params, function(err, result)
      close_mouse_float()
      if err or not result or not result.contents then
        return
      end
      local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      if not lines or vim.tbl_isempty(lines) then
        return
      end
      local _, win = vim.lsp.util.open_floating_preview(lines, "markdown", {
        border = "rounded",
        focusable = false,
        focus = false,
      })
      mouse_win = win
    end, bufnr)
  end, 250)
end, { silent = true })

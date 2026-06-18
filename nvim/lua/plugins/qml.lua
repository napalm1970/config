return {
  -- Добавляем парсер qml для treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "qmljs" })
      end
    end,
  },

  -- Настраиваем LSP сервер qmlls
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          cmd = { "qlmls6" },
        },
      },
    },
  },

  -- Добавляем qmlls в Mason для автоматической установки
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "qmlls" })
    end,
  },
}

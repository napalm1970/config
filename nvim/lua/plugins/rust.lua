return {
  -- Расширяем конфигурацию rustaceanvim
  {
    "mrcjkb/rustaceanvim",
    version = "^5", -- Рекомендуется
    lazy = false, -- Загрузка управляется самим плагином (ftplugin)
    config = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            -- настройки rust-analyzer
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = {
                  enable = true,
                },
              },
              -- Настройки команды проверки (clippy)
              check = {
                command = "clippy",
                allFeatures = true,
                extraArgs = { "--no-deps" },
              },
              -- Включение проверки при сохранении (это boolean)
              checkOnSave = true,
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
            },
          },
        },
      }
    end,
  },

  -- Улучшаем работу с crates.nvim
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
    keys = {
      { "<leader>rc", function() require("crates").open_popup() end, desc = "Show Crate Details" },
      { "<leader>rv", function() require("crates").show_versions_popup() end, desc = "Show Crate Versions" },
      { "<leader>rf", function() require("crates").show_features_popup() end, desc = "Show Crate Features" },
      { "<leader>rd", function() require("crates").open_documentation() end, desc = "Open Crate Documentation" },
      { "<leader>rh", function() require("crates").open_homepage() end, desc = "Open Crate Homepage" },
    },
  },
}

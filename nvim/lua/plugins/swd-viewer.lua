-- Просмотрщик регистров периферии (аналог Peripheral Viewer из cortex-debug).
-- Локальный плагин: /home/napalm/Documents/projects/swd_viewer
-- Читает SVD и значения регистров через активную сессию nvim-dap.
return {
  {
    dir = "/home/napalm/Documents/projects/swd_viewer",
    name = "swd-viewer.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    cmd = { "SwdViewer", "SwdViewerOpen", "SwdViewerClose", "SwdViewerRefresh" },
    opts = {
      -- nil = автоопределение SVD по device из launch.json или target из openocd.cfg.
      -- Можно зафиксировать явно, например:
      -- svd_file = "~/.local/share/stm32cube/packs/STMicroelectronics/stm32f1xx_dfp/1.2.0/SVD/STM32F103.svd",
      auto_refresh_on_stop = true,
      write_method = "memory", -- arm-none-eabi-gdb поддерживает writeMemory
      window = { position = "right", width = 56 },
    },
    config = function(_, opts)
      require("swd-viewer").setup(opts)
    end,
    keys = {
      { "<leader>dp", "<cmd>SwdViewer<cr>", desc = "Peripheral viewer (SVD)" },
    },
  },
}

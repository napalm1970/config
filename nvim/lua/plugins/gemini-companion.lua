return {
  {
    "gutsavgupta/nvim-gemini-companion",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gemini").setup({
        -- win = {
        --   preset = "right-fixed", -- Options: "right-fixed", "left-fixed", "bottom-fixed", "floating"
        --   width = 0.8,
        --   height = 0.6,
        -- },
        cmds = { "gemini", "qwen" },
        -- Override default key mappings
        on_buf = function(buf)
          -- Add your own custom mappings
          vim.api.nvim_buf_set_keymap(
            buf,
            "t",
            "<Tab>",
            '<Cmd>lua require("gemini.ideSidebar").switchSidebar()<CR>',
            { noremap = true, silent = true }
          )
          vim.api.nvim_buf_set_keymap(
            buf,
            "t",
            "<S-Tab>",
            '<Cmd>lua require("gemini.ideSidebar").switchSidebar("prev")<CR>',
            { noremap = true, silent = true }
          )
        end,
      })
    end,
    keys = {
      { "<leader>at", "<cmd>GeminiToggle<cr>", desc = "Toggle Gemini sidebar" },
      { "<leader>ac", "<cmd>GeminiSwitchToCli<cr>", desc = "Spawn or switch to AI session" },
      { "<leader>as", "<cmd>GeminiSend<cr>", mode = { "x" }, desc = "Send selection to Gemini" },
    },
  },
}

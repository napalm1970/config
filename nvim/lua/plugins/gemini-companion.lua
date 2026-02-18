return {
  "gutsavgupta/nvim-gemini-companion",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  config = function()
    -- For fzf-lua integration
    vim.ui.select = function(items, opts, onChoice)
      require("fzf-lua").fzf_exec(items, {
        prompt = opts.prompt or "Select from items",
        actions = {
          ["default"] = function(selected)
            onChoice(selected[1])
          end,
        },
        winopts = { height = math.min(0.2 + #items * 0.05, 0.6) },
      })
    end

    require("gemini").setup({
      cmds = { "gemini", "qwen" },
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

      win = {
        preset = "right-fixed", -- Options: "right-fixed", "left-fixed", "bottom-fixed", "floating"
        width = 0.8,
        height = 0.8,
      },
    })
  end,
  keys = {
    { "<leader>gg", "<cmd>GeminiToggle<cr>", desc = "Toggle Gemini sidebar" },
    { "<leader>gc", "<cmd>GeminiSwitchToCli<cr>", desc = "Spawn or switch to AI session" },
    { "<leader>gS", "<cmd>GeminiSend<cr>", mode = { "x" }, desc = "Send selection to Gemini" },
    { "<leader>g1", "<cmd>GeminiSwitchToCli tmux gemini<cr>", desc = "Tmux Gemini" },
    { "<leader>g2", "<cmd>GeminiSwitchToCli tmux qwen<cr>", desc = "Tmux Qwen" },
    { "<leader>gs", "<cmd>GeminiSwitchSidebarStyle<cr>", desc = "Switch sidebar style" },
    { "<leader>ga", "<cmd>GeminiAccept<cr>", desc = "Accept Gemini suggestion" },
    { "<C-CR>", "<cmd>GeminiAccept<cr>", desc = "Accept Gemini suggestion" },
    { "<leader>gq", "<cmd>lua require('gemini.ideSidebar').switchSidebar('qwen'); vim.cmd('GeminiToggle')<cr>", desc = "Toggle Qwen sidebar" },
    { "<leader>gQ", "<cmd>lua require('gemini.ideSidebar').switchSidebar('qwen')<cr>", desc = "Switch to Qwen Sidebar" },
  },
}

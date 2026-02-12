return -- In your lazy.nvim plugin spec
{
  "mikaoelitiana/kilo-code.nvim",
  dependencies = { "folke/which-key.nvim" },
  config = function()
    require("kilo_code").setup({
      which_key = {
        enabled = true,
        prefix = "<leader>k", -- Change this to your preferred prefix
      },
    })
  end,
}

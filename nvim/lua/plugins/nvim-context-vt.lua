return {
  {
    "haringsrob/nvim_context_vt",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    opts = {
      enabled = true,
      prefix = "", 
      highlight = "Comment",
    },
  },
}

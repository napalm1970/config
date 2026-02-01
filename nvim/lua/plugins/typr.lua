return {
  {
    "nvzone/typr",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = { "Typr", "TyprStats" },
    keys = {
        { "<leader>ut", "<cmd>Typr<cr>", desc = "Typr (Typing Practice)" },
        { "<leader>uT", "<cmd>TyprStats<cr>", desc = "Typr Stats" },
    },
  },
}

return {
  "Wansmer/langmapper.nvim",
  event = "VeryLazy",
  config = function()
    require("langmapper").setup({
      hack_keymap = true, -- автоматически транслировать все кеймапы
      ru = {
        id = "ru",
        layout = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯБЮЖЭХЪЁфисвуапршолдьтщзйкыегмцчнябюжэхъё",
      },
    })
  end,
}

return {
  {
    "robitx/gp.nvim",
    config = function()
      local conf = {
        providers = {
          google = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={{secret}}",
            secret = os.getenv("GEMINI_API_KEY"),
          },
        },
        default_command_agent = "ChatGemini",
        default_chat_agent = "ChatGemini",
        agents = {
          {
            name = "ChatGemini",
            provider = "google",
            chat = true,
            command = false,
            model = { model = "gemini-pro" },
            system_prompt = "You are a general AI assistant.",
          },
          {
             name = "CodeGemini",
             provider = "google",
             chat = false,
             command = true,
             model = { model = "gemini-pro" },
             system_prompt = "You are an AI coding assistant. Output only code or concise explanations.",
          }
        },
      }
      require("gp").setup(conf)

      -- Shortcuts
      local function keymapOptions(desc)
        return { noremap = true, silent = true, nowait = true, desc = "GPT prompt " .. desc }
      end

      vim.keymap.set({"n", "i"}, "<C-g>c", "<cmd>GpChatNew<cr>", keymapOptions("New Chat"))
      vim.keymap.set({"n", "i"}, "<C-g>t", "<cmd>GpChatToggle<cr>", keymapOptions("Toggle Chat"))
      vim.keymap.set({"n", "i"}, "<C-g>f", "<cmd>GpChatFinder<cr>", keymapOptions("Chat Finder"))
      
      vim.keymap.set("v", "<C-g>c", ":<C-u>'<,'>GpChatNew<cr>", keymapOptions("Visual Chat New"))
      vim.keymap.set("v", "<C-g>p", ":<C-u>'<,'>GpChatPaste<cr>", keymapOptions("Visual Chat Paste"))
      vim.keymap.set("v", "<C-g>r", ":<C-u>'<,'>GpRewrite<cr>", keymapOptions("Visual Rewrite"))
    end,
  },
}

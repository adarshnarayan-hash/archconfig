return {
  "Bekaboo/dropbar.nvim",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "<leader>;", function() require("dropbar.api").pick() end, desc = "Pick Symbols in Winbar" },
    { "[;", function() require("dropbar.api").goto_context_start() end, desc = "Go to Context Start" },
    { "];", function() require("dropbar.api").select_next_context() end, desc = "Select Next Context" },
  },
  opts = {},
}

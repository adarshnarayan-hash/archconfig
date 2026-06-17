return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      flavour = "mocha",
    },
  },
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = true,
    opts = {
      style = "night",
      transparent = false,
    },
  },
  {
    "rebelot/kanagawa.nvim",
    name = "kanagawa",
    lazy = false,
    priority = 1000,
    opts = {
      overrides = function(colors)
        local bg = "#0d0d0d"
        local sidebar = "#161616"
        return {
          Normal = { bg = bg },
          NormalFloat = { bg = "#16161d" },
          LineNr = { bg = sidebar, fg = "#3a3a3a" },
          CursorLineNr = { bg = sidebar, fg = "#888888", bold = true },
          SignColumn = { bg = sidebar },
          FoldColumn = { bg = sidebar },
          EndOfBuffer = { bg = bg },
          NormalNC = { bg = bg },
        }
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },
}

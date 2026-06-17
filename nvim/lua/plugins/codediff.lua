return {
  "esmuellert/codediff.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = { "CodeDiff" }, -- lazy-load on command
  -- keys = {
  --   {
  --     "<leader>gy",
  --     desc = "CodeDiff",
  --   },
  -- },
  -- opts = {
  --   -- 🔹 UI behavior
  --   split = "vertical", -- "horizontal" | "vertical"
  --   show_diff = true, -- show inline diff highlights
  --
  --   -- 🔹 diff options (passed to vim.diff)
  --   diff_opts = {
  --     algorithm = "histogram", -- better than default
  --     ignore_whitespace = false,
  --   },
  --
  --   -- 🔹 window options
  --   window = {
  --     wrap = false,
  --     number = true,
  --     relativenumber = false,
  --   },
  -- },
  config = function(_, opts)
    require("codediff").setup(opts)
  end,
}

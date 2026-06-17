return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signcolumn = true,
      numhl = true,
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "▁" },
        topdelete = { text = "‾" },
        changedelete = { text = "┃" },
        untracked = { text = "┃" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        map("n", "]h", function() gs.nav_hunk("next") end, "Next Hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Prev Hunk")
        map("n", "<leader>ghs", gs.stage_hunk, "Stage Hunk")
        map("n", "<leader>ghr", gs.reset_hunk, "Reset Hunk")
        map("v", "<leader>ghs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage Hunk")
        map("v", "<leader>ghr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghd", function() gs.diffthis("~") end, "Diff (Last Commit)")
        map("n", "<leader>ghD", function() gs.diffthis("origin/HEAD") end, "Diff (Remote HEAD)")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle Blame")
        map({ "o", "x" }, "ih", gs.select_hunk, "Select Hunk")
      end,
    },
  },
  {
    "echasnovski/mini.diff",
    event = "VeryLazy",
    opts = {
      view = { style = "number" },
    },
    keys = {
      {
        "<leader>go",
        function()
          local diff = require("mini.diff")
          diff.enable(0)
          diff.toggle_overlay(0)
        end,
        desc = "Toggle MiniDiff Overlay",
      },
    },
  },
}

-- return {}
return {
  "stevearc/oil.nvim",
  dependencies = { "mini.icons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
  },
  opts = {
    -- Autosave applies edits without a manual :w; skip the confirm popup for
    -- simple create/rename/copy (deletes still prompt).
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
    },
    keymaps = {
      ["q"] = "actions.close",
      ["gy"] = { "actions.yank_entry", opts = { modify = ":." }, desc = "Yank relative path" },
      ["gY"] = { "actions.yank_entry", opts = { modify = ":p" }, desc = "Yank absolute path" },
    },
  },
}

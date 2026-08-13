return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0", -- see https://devhints.io/semver, alternatively use '*' to use the latest tagged release
  cmd = "ASToggle", -- optional for lazy loading on command
  event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
  opts = {
    enabled = true, -- Start auto-save when Neovim opens

    -- Explicitly setting these to defaults for clarity:
    write_all_buffers = false, -- Only save the file you are currently editing
    noautocmd = false, -- Allow Format-on-save and Linters to run
    lockmarks = false, -- Don't freeze your cursor marks (a, b, c, etc.)
    debug = false, -- Don't clutter logs unless you're troubleshooting

    -- UNDO-FRIENDLY SETTINGS
    debounce_delay = 2500, -- Wait 1.5 second of silence before saving
    trigger_events = {
      -- Immediate save when you actually "leave" the file
      immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" },
      -- Deferred save: This waits for the debounce_delay (preserves undo history)
      defer_save = { "InsertLeave", "TextChanged" },
      -- If you start typing again, cancel the pending save
      cancel_deferred_save = { "InsertEnter" },
    },

    -- CONDITION: When NOT to save
    condition = function(buf)
      local fn = vim.fn

      -- 1. Don't save if the buffer isn't "modifiable" (read-only files)
      if fn.getbufvar(buf, "&modifiable") ~= 1 then
        return false
      end

      -- Oil directory buffers use buftype "acwrite"; allow them so file
      -- operations (rename/create/delete) get applied automatically.
      if fn.getbufvar(buf, "&filetype") == "oil" then
        return true
      end

      -- 2. Don't save for special "buftypes" (like terminal or quickfix)
      if fn.getbufvar(buf, "&buftype") ~= "" then
        return false
      end

      -- 3. Exclude specific filetypes that get messy with auto-save
      local excluded_filetypes = {
        "gitcommit",
        "neo-tree",
        "TelescopePrompt",
        "harpoon",
        "notify",
        "lazy",
        "mason",
      }
      if vim.tbl_contains(excluded_filetypes, fn.getbufvar(buf, "&filetype")) then
        return false
      end

      return true -- If it passes all tests, save the file!
    end,
  },
}

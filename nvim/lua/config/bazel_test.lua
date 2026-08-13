-- Run Bazel Go tests and demos from Neovim.
--
-- This repo generates proto Go code via Bazel and uses a custom test harness
-- that reads Bazel's TESTBRIDGE_TEST_ONLY env var (set by `--test_filter`), so
-- `go test` / neotest-golang don't work here; we shell out to bazel instead.
--
--  * Tests: `bazel test //pkg:all --test_filter=<TestName>` (non-interactive).
--  * Demos: `bazel run //pkg:demo -- <MethodName>` — each demo dir has a
--    `:demo` binary whose main.go calls (&Caller{}).MethodByName(arg). These are
--    interactive CLIs, so their terminal stays in insert mode for input.
local M = {}

local last_cmd = nil
local last_buf = { test = nil, demo = nil } -- previous terminal buffer per kind

-- Walk up from `path` to the Bazel workspace root.
local function workspace_root(path)
  local marker = vim.fs.find({ "MODULE.bazel", "WORKSPACE.bazel", "WORKSPACE" }, {
    upward = true,
    path = path,
  })[1]
  return marker and vim.fs.dirname(marker) or nil
end

-- Convert an absolute file path to its Bazel package label, e.g. //integrations/crelio/crelioutil
local function bazel_package(file, root)
  local dir = vim.fs.dirname(file)
  if dir == root then
    return "//"
  end
  local rel = dir:sub(#root + 2) -- strip "root/"
  return "//" .. rel
end

-- Package label + workspace root for the current buffer (or nil + notify).
local function pkg_and_root()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No file in buffer", vim.log.levels.WARN)
    return nil
  end
  local root = workspace_root(file)
  if not root then
    vim.notify("Not inside a Bazel workspace (no MODULE.bazel/WORKSPACE)", vim.log.levels.ERROR)
    return nil
  end
  return bazel_package(file, root), root
end

-- Name of the function/method enclosing the cursor (via treesitter). `filter`
-- is an optional predicate the name must satisfy (e.g. starts with "Test").
local function enclosing_name(filter)
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    return nil
  end
  while node do
    local t = node:type()
    if t == "method_declaration" or t == "function_declaration" then
      local name_node = node:field("name")[1]
      if name_node then
        local name = vim.treesitter.get_node_text(name_node, 0)
        if not filter or filter(name) then
          return name
        end
      end
    end
    node = node:parent()
  end
  return nil
end

-- kind is "test" (non-interactive, scrollable) or "demo" (interactive CLI).
local function run(cmd, root, kind)
  kind = kind or "test"
  last_cmd = { cmd = cmd, root = root, kind = kind }
  vim.notify("bazel: " .. cmd, vim.log.levels.INFO)
  -- Snacks keys terminals by cmd+cwd and only *shows* an existing one instead
  -- of re-running it. Since we keep the buffer open, wipe the previous run's
  -- buffer first so Snacks creates a fresh terminal and re-executes bazel.
  local prev = last_buf[kind]
  if prev and vim.api.nvim_buf_is_valid(prev) then
    pcall(vim.api.nvim_buf_delete, prev, { force = true })
  end
  local opts = { cwd = root, win = { position = "bottom", height = 0.4 } }
  if kind == "demo" then
    -- Demos may prompt for input; keep the terminal interactive but don't
    -- auto-close so the output stays visible after it finishes.
    opts.auto_close = false
  else
    -- Tests: non-interactive; land in normal mode to scroll/search output.
    opts.interactive = false
  end
  local term = Snacks.terminal(cmd, opts)
  last_buf[kind] = term and term.buf or nil
end

local TEST_OUTPUT = "--test_output=streamed --cache_test_results=no --test_arg=-debug-init-times --test_arg=-test.v"
-- local TEST_OUTPUT = "--test_output=streamed --test_arg=-test.v"

-- Run only the test function under the cursor.
function M.run_nearest()
  local pkg, root = pkg_and_root()
  if not pkg then
    return
  end
  local name = enclosing_name(function(n)
    return n:match("^Test") ~= nil
  end)
  if not name then
    vim.notify("Cursor is not inside a Test function", vim.log.levels.WARN)
    return
  end
  run(("bazel test %s:all --test_filter=%s %s"):format(pkg, name, TEST_OUTPUT), root, "test")
end

-- Run every test in the current file's package.
function M.run_package()
  local pkg, root = pkg_and_root()
  if not pkg then
    return
  end
  run(("bazel test %s:all %s"):format(pkg, TEST_OUTPUT), root, "test")
end

-- Resolve the demo target (pkg, root, method name) for the cursor, or nil.
local function demo_target()
  local pkg, root = pkg_and_root()
  if not pkg then
    return nil
  end
  local name = enclosing_name(nil)
  if not name then
    vim.notify("Cursor is not inside a demo method", vim.log.levels.WARN)
    return nil
  end
  return { pkg = pkg, root = root, name = name }
end

-- Launch `ENVIRONMENT=<env> bazel run //pkg:demo -- <Method> [args]`.
local function launch_demo(t, env, args)
  local cmd = ("ENVIRONMENT=%s bazel run %s:demo -- %s"):format(env, t.pkg, t.name)
  if args and args:match("%S") then
    cmd = cmd .. " " .. args
  end
  run(cmd, t.root, "demo")
end

-- Blocking yes/no guard for prod (defaults to No).
local function confirm_prod()
  return vim.fn.confirm("Run demo in PROD (real data)?", "&No\n&Yes", 1) == 2
end

-- <leader>rd: run the demo method under the cursor in staging (fast path).
function M.run_demo_staging()
  local t = demo_target()
  if t then
    launch_demo(t, "staging", nil)
  end
end

-- <leader>rp: run in prod, guarded by a confirmation prompt.
function M.run_demo_prod()
  local t = demo_target()
  if not t then
    return
  end
  if confirm_prod() then
    launch_demo(t, "prod", nil)
  else
    vim.notify("Cancelled prod demo run", vim.log.levels.INFO)
  end
end

-- <leader>ra: pick env, then enter optional args (appended after the method).
function M.run_demo_prompt()
  local t = demo_target()
  if not t then
    return
  end
  vim.ui.select({ "staging", "prod" }, { prompt = "Demo environment:" }, function(env)
    if not env then
      return
    end
    vim.ui.input({ prompt = "Extra args (optional): " }, function(args)
      if env == "prod" and not confirm_prod() then
        vim.notify("Cancelled prod demo run", vim.log.levels.INFO)
        return
      end
      launch_demo(t, env, args)
    end)
  end)
end

-- Re-run the last bazel test/demo command.
function M.run_last()
  if not last_cmd then
    vim.notify("No previous bazel run", vim.log.levels.WARN)
    return
  end
  run(last_cmd.cmd, last_cmd.root, last_cmd.kind)
end

return M

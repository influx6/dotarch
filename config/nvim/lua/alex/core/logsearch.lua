-- Search Neovim's own log files (LSP crashes, plugin logs, startup traces) that
-- never show up in :messages -- see docs/troubleshooting-errors.md.
--
-- This reuses your existing grep picker, scoped to the log directories, so you
-- get the usual panel: matches on the left, file+match preview on the right.
--
-- Backend order (first present wins): snacks.picker -> telescope live_grep ->
-- plain :grep (quickfix). The *content* search is always ripgrep; the picker
-- only draws the panel. `fff` finds files by NAME, not content, so it's not a
-- grep backend -- it's offered separately via :LogFiles for browsing the logs.

local M = {}

--- The directories Neovim + plugins write logs to, de-duplicated.
--- @return string[]
local function log_dirs()
  local seen, out = {}, {}
  for _, d in ipairs({
    vim.fn.stdpath("log"), -- ~/.local/state/nvim: lsp.log, haskell-tools.log, mason.log, nvim.log, ...
    vim.fn.stdpath("cache"), -- ~/.cache/nvim: fidget.nvim.log, diffview.log, ...
  }) do
    local p = vim.fs.normalize(d)
    if not seen[p] then
      seen[p] = true
      out[#out + 1] = p
    end
  end
  return out
end

--- Live-grep the log files, optionally seeded with `pattern`.
--- @param pattern string|nil
function M.grep(pattern)
  local dirs = log_dirs()

  -- 1) snacks.picker (primary picker in this config)
  if _G.Snacks and Snacks.picker then
    Snacks.picker.grep({
      dirs = dirs,
      glob = "*.log",
      search = pattern, -- seeds the query; nil = start empty
      title = "Nvim Logs",
    })
    return
  end

  -- 2) telescope live_grep
  local ok_ts, tb = pcall(require, "telescope.builtin")
  if ok_ts then
    tb.live_grep({
      search_dirs = dirs,
      glob_pattern = "*.log",
      default_text = pattern or "",
      prompt_title = "Nvim Logs",
    })
    return
  end

  -- 3) no picker: ripgrep into the quickfix list
  local save_prg, save_fmt = vim.o.grepprg, vim.o.grepformat
  vim.o.grepprg = "rg --vimgrep --smart-case --glob=*.log"
  vim.o.grepformat = "%f:%l:%c:%m"
  local pat = pattern or vim.fn.input("Log grep pattern: ")
  if pat ~= "" then
    local paths = table.concat(vim.tbl_map(vim.fn.fnameescape, dirs), " ")
    vim.cmd(("silent grep! %s %s"):format(vim.fn.shellescape(pat), paths))
    vim.cmd("copen")
  end
  vim.o.grepprg, vim.o.grepformat = save_prg, save_fmt
end

--- Browse the log files by name (fff -> snacks files -> telescope find_files).
function M.files()
  local dirs = log_dirs()
  local ok_fff, fff = pcall(require, "fff")
  if ok_fff and fff.find_files_in_dir then
    fff.find_files_in_dir(dirs[1]) -- fff takes a single dir
    return
  end
  if _G.Snacks and Snacks.picker then
    Snacks.picker.files({ dirs = dirs, glob = "*.log", title = "Nvim Log Files" })
    return
  end
  local ok_ts, tb = pcall(require, "telescope.builtin")
  if ok_ts then
    tb.find_files({ search_dirs = dirs, prompt_title = "Nvim Log Files" })
  end
end

-- Consistent "Logs:" prefix so these cluster together and are easy to find in
-- the command palette (Snacks.picker.commands / :Telescope commands), where the
-- desc is what's shown.
vim.api.nvim_create_user_command("LogGrep", function(o)
  M.grep(o.args ~= "" and o.args or nil)
end, { nargs = "?", desc = "Logs: grep Neovim log files (LSP/plugin errors); arg seeds the search" })

vim.api.nvim_create_user_command("LogGrepWord", function()
  M.grep(vim.fn.expand("<cword>"))
end, { desc = "Logs: grep log files for the word under the cursor" })

vim.api.nvim_create_user_command("LogFiles", function()
  M.files()
end, { desc = "Logs: browse log files by name" })

-- Keymap so it shows in the which-key panel (under the existing <leader>s
-- "search" group) for discovery + one-key kickoff. The desc is the panel label.
-- Relies on mapleader being set early in alex.core.options (before this runs).
vim.keymap.set("n", "<leader>sL", "<cmd>LogGrep<cr>", { desc = "Search Nvim logs (LSP/plugin errors)" })

return M

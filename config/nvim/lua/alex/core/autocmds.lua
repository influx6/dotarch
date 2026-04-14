-- vim.diagnostic.config({
--   virtual_text = true,
--   signs = true,
--   underline = true,
--   severity_sort = true,
--   update_in_insert = false,
--   float = {
--     border = "rounded",
--     source = "always",
--     header = "",
--     prefix = "",
--   },
-- })

-- Fixed column for diagnostics to appear.
-- The previous CursorHold auto-float was removed — it re-rendered a window on
-- every idle tick and fought with blink/LSP. Use <leader>d to open the float
-- on demand (bound in plugin-lspconfig.lua).
vim.cmd([[
set showcmd
set signcolumn=yes
]])

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
  callback = function()
    vim.opt.number = true
    vim.opt.relativenumber = true
  end,
})

-- Check for external file changes on focus/buffer-enter only. CursorHold and
-- CursorHoldI were removed: stat'ing the file on every idle tick (especially
-- in insert mode) was noticeably expensive on large buffers.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("checktime_group", { clear = true }),
  callback = function()
    vim.cmd("checktime")
  end,
})

-- Enable spell-check only where it matters (was globally on via options.lua,
-- which also activated blink's spell source on every keystroke in code files).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("spell_by_filetype", { clear = true }),
  pattern = { "markdown", "gitcommit", "text", "tex" },
  callback = function()
    vim.opt_local.spell = true
  end,
})

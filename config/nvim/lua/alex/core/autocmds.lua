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

-- Fixed column for diagnostics to appear
-- Show autodiagnostic popup on cursor hover_range
-- Goto previous / next diagnostic warning / error
-- Show inlay_hints more frequently
vim.cmd([[
set showcmd
set signcolumn=yes
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]])

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
  callback = function()
    vim.opt.number = true
    vim.opt.relativenumber = true
  end,
})

-- Check for changes on events like gaining focus or cursor movement
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("checktime_group", { clear = true }),
  callback = function()
    vim.cmd("checktime")
  end,
})

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
vim.cmd([[
set showcmd
set signcolumn=yes
]])

-- Auto-hover documentation popup (opt-out with `vim.g.auto_hover = false`).
--
-- Shows the LSP hover (types + docs) for the symbol under the cursor after the
-- cursor rests (`updatetime`). This is the popup that was previously removed;
-- the earlier version re-rendered on every idle tick and fought blink. This one
-- is guarded so it behaves:
--   * CursorHold only (normal mode) -- never insert mode, so it can't collide
--     with blink's completion-documentation window.
--   * Skips if a floating window is already open (our own hover, a diagnostic
--     float, blink, noice, etc.), so it opens once and doesn't refire/flicker.
--   * Only when a client with a hover provider is attached, and only in real
--     file buffers -- otherwise it's a no-op.
--   * `focus = false` so it never steals the cursor; the float auto-closes on
--     move, and the next rest re-opens it for the new symbol.
-- Manual hover (`K`) and the on-demand diagnostic float (`<leader>d`) are
-- unchanged; this just adds the automatic display back on top.
if vim.g.auto_hover == nil then
  vim.g.auto_hover = true
end

vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("auto_hover", { clear = true }),
  callback = function()
    if not vim.g.auto_hover then
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype ~= "" then
      return
    end
    -- Already showing a float? Leave it be (prevents per-tick re-render).
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
      end
    end
    if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" }) == 0 then
      return
    end
    -- focusable=false + focus=false: display-only, never grabs the cursor.
    vim.lsp.buf.hover({ focusable = false, focus = false })
  end,
})

-- Green border for the hover popup. noice's `hover` view (plugin-noice.lua)
-- points its FloatBorder at this group; defining it here (and re-applying on
-- ColorScheme) keeps it alive across theme switches, since a colorscheme load
-- resets custom highlights.
local function set_hover_border_hl()
  vim.api.nvim_set_hl(0, "NoiceHoverBorder", { fg = "#9ece6a" })
end
set_hover_border_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("hover_border_hl", { clear = true }),
  callback = set_hover_border_hl,
})

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

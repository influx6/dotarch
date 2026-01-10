vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt -- for easy ref

opt.spell = true
opt.spelllang = { "en_us" }

-- cursor line
opt.number = true
opt.cursorline = true -- highlight the current cursor line

opt.undofile = true

-- tabs & indentation
--
opt.expandtab = true -- Convert tabs to spaces
opt.autoindent = true -- copy indent from current line when starting new one
opt.smarttab = true
opt.smartindent = true
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- Amount of indent with << and >>, 4 spaces for indent width

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.breakindent = true

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- line wrapping
opt.wrap = false -- disable line wrapping

-- appearance

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false

-- Swap to neotree if you want to use neotree instead.
vim.g.file_manager = "oil.nvim"

-- LSP Server for Rust
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"

-- Switch to bacon-ls for rust
-- vim.g.lazyvim_rust_diagnostics = "bacon-ls"

-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "pyright"

-- Support proper session restoration
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

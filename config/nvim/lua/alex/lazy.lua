local datapath = vim.fn.stdpath("data")

local lazypath = datapath .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
    },
    { import = "alex.plugins" },
    { import = "alex.plugins.lsp" },
  },
  {
    change_detection = { notify = false },
    checker = {
      enabled = true,
      notify = false,
    },
  },
})

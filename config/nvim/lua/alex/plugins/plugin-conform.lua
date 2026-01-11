return {
  "stevearc/conform.nvim",
  lazy = true,
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cF",
      function()
        require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
      end,
      mode = { "n", "x" },
      desc = "Format Injected Langs",
    },
  },
  opts = function()
    -- local plugin = require("lazy.core.config").plugins["conform.nvim"]
    -- if plugin.config ~= M.setup then
    --   LazyVim.error({
    --     "Don't set `plugin.config` for `conform.nvim`.\n",
    --     "This will break **LazyVim** formatting.\n",
    --     "Please refer to the docs at https://www.lazyvim.org/plugins/formatting",
    --   }, { title = "LazyVim" })
    -- end

    local conform = require("conform")

    -- register auto execution when files are saved
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        require("conform").format({ bufnr = args.buf })
      end,
    })

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })

    return {
      formatters_by_ft = {
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        -- yaml = { "yamlfmt" }, -- Replace default with K8s-friendly formatter
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
        rust = { "rustfmt", lsp_format = "fallback" },
        -- Conform will run the first available formatter
        javascript = { "prettierd", "prettier", stop_after_first = true },
      },
      formatters = {
        yamlfmt = {
          command = "yamlfmt",
          args = { "-formatter", "basic", "-indentless_arrays=true" },
        },
      },
      -- format_on_save = {
      --   lsp_fallback = true,
      --   async = false,
      --   timeout_ms = 1000,
      -- },
    }
  end,
}

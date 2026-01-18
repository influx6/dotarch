-- local diagnostics = vim.g.lazyvim_rust_diagnostics
local diagnostics = vim.g.lazyvim_rust_diagnostics

function has_key(table, key)
  return table[key] ~= nil
end

function get_github_token()
  local envs = vim.fn.environ()
  if has_key(envs, "GH_TOKEN") then
    return envs["GH_TOKEN"]
  end
  vim.print("Unable to locate github GH_TOKEN environment var")
end

return {
  {
    "neovim/nvim-lspconfig",
    -- event = { "BufReadPre", "BufNewFile" },
    event = "LazyFile",
    ensure_installed = { "bacon-ls", "bacon", "pyright", "ruff" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "saghen/blink.cmp",
      "nvim-lua/plenary.nvim",
      "milanglacier/minuet-ai.nvim",
      "netmute/ctags-lsp.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      { "antosha417/nvim-lsp-file-operations", config = true },
      { "folke/neodev.nvim", opts = {} },
    },
    opts = {
      diagnostics = {
        float = {
          border = "rounded",
        },
      },
    },
    config = function()
      -- import lspconfig plugin
      local lspconfig = require("lspconfig")

      -- import mason_lspconfig plugin
      local mason_lspconfig = require("mason-lspconfig")

      -- import cmp-nvim-lsp plugin
      local cmp_nvim_lsp = require("cmp_nvim_lsp")

      local keymap = vim.keymap -- for conciseness

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = { buffer = ev.buf, silent = true }

          -- set keybinds
          opts.desc = "Show LSP references"
          keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

          opts.desc = "Go to declaration"
          keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

          opts.desc = "Show LSP definitions"
          keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

          opts.desc = "Show LSP implementations"
          keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

          opts.desc = "Show LSP type definitions"
          keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

          opts.desc = "See available code actions"
          keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

          opts.desc = "Smart rename"
          keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

          opts.desc = "Show buffer diagnostics"
          keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

          opts.desc = "Show line diagnostics"
          keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

          opts.desc = "Go to previous diagnostic"
          keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

          opts.desc = "Go to next diagnostic"
          keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

          opts.desc = "Show documentation for what is under cursor"
          keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

          opts.desc = "Restart LSP"
          keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
        end,
      })

      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- Change the Diagnostic symbols in the sign column (gutter)
      -- (not in youtube nvim video)
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      mason_lspconfig.setup({
        handler = {
          -- default handler for installed servers
          function(server_name)
            lspconfig[server_name].setup({
              capabilities = capabilities,
            })
          end,
          ["clangd"] = function()
            lspconfig["clangd"].setup({
              capabilities = capabilities,
              offset_encoding = "utf-16",
              cmd = {
                "clangd",
                "--offset-encoding=utf-16",
              },
            })
          end,
          ["svelte"] = function()
            -- configure svelte server
            lspconfig["svelte"].setup({
              capabilities = capabilities,
              on_attach = function(client, bufnr)
                vim.api.nvim_create_autocmd("BufWritePost", {
                  pattern = { "*.js", "*.ts" },
                  callback = function(ctx)
                    -- Here use ctx.match instead of ctx.file
                    client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                  end,
                })
              end,
            })
          end,
          ["rust_analyzer"] = function()
            -- configure rust-analyzer
            lspconfig["rust_analyzer"].setup({
              enabled = false,
              capabilities = capabilities,
              -- on_attach = function(client, bufnr)
              --     -- Here use ctx.match instead of ctx.file
              --     -- client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
              -- end,
            })
          end,
          ["bacon_ls"] = function()
            -- configure bacon language server
            lspconfig["bacon_ls"].setup({
              capabilities = capabilities,
              enabled = diagnostics == "bacon-ls",
              init_options = {
                -- Bacon export filename (default: .bacon-locations).
                locationsFile = ".bacon-locations",
                -- Try to update diagnostics every time the file is saved (default: true).
                updateOnSave = true,
                --  How many milliseconds to wait before updating diagnostics after a save (default: 1000).
                updateOnSaveWaitMillis = 700,
                -- Try to update diagnostics every time the file changes (default: true).
                updateOnChange = true,
                -- Try to validate that bacon preferences are setup correctly to work with bacon-ls (default: true).
                validateBaconPreferences = true,
                -- f no bacon preferences file is found, create a new preferences file with the bacon-ls job definition (default: true).
                createBaconPreferencesFile = false,
                -- Run bacon in background for the bacon-ls job (default: true)
                runBaconInBackground = false,
                -- Command line arguments to pass to bacon running in background (default "--headless -j bacon-ls")
                runBaconInBackgroundCommandArguments = "--headless -j bacon-ls",
                -- How many milliseconds to wait between background diagnostics check to synchronize all open files (default: 2000).
                synchronizeAllOpenFilesWaitMillis = 1300,
              },
            })
          end,
          ["graphql"] = function()
            -- configure graphql language server
            lspconfig["graphql"].setup({
              capabilities = capabilities,
              filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
            })
          end,
          ["emmet_ls"] = function()
            -- configure emmet language server
            lspconfig["emmet_ls"].setup({
              capabilities = capabilities,
              filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
            })
          end,
          ["lua_ls"] = function()
            -- configure lua server (with special settings)
            lspconfig["lua_ls"].setup({
              capabilities = capabilities,
              settings = {
                Lua = {
                  -- make the language server recognize "vim" global
                  diagnostics = {
                    globals = { "vim" },
                  },
                  codeLens = {
                    enable = true,
                  },
                  completion = {
                    callSnippet = "Replace",
                  },
                  doc = {
                    privateName = { "^_" },
                  },
                  hint = {
                    enable = true,
                    setType = true,
                    paramType = true,
                    -- paramName = "Disable",
                    -- semicolon = "Disable",
                    -- arrayIndex = "Disable",
                  },
                },
              },
            })
          end,
          ["ruff"] = function()
            lspconfig.ruff.setup({
              capabilities = capabilities,
              on_attach = function(client, bufnr)
                -- Register attachment to LspAttach to ensure ruff and pyright play nice
                vim.api.nvim_create_autocmd("LspAttach", {
                  group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
                  callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client == nil then
                      return
                    end
                    if client.name == "ruff" then
                      -- Disable hover in favor of Pyright
                      client.server_capabilities.hoverProvider = false
                    end
                  end,
                  desc = "LSP: Disable hover capability from Ruff",
                })

                -- Register attachment to LspAttach to ensure ruff and pyright play nice

                -- vim.lsp.config.ruff.setup({
                --   init_options = {
                --     settings = {
                --       -- Ruff language server settings go here
                --       -- logLevel = "debug",
                --       args = {},
                --       fixAll = true,
                --       organizeImports = true,
                --       showSyntaxErrors = true,
                --       lint = {
                --         enable = true,
                --         preview = true,
                --       },
                --     },
                --   },
                -- })
              end,
              settings = {
                cmd_env = { RUFF_TRACE = "messages" },
                init_options = {
                  -- Ruff language server settings go here
                  settings = {
                    logLevel = "error",
                    args = {},
                    fixAll = true,
                    organizeImports = true,
                    showSyntaxErrors = true,
                    lint = {
                      enable = true,
                      preview = true,
                    },
                  },
                },
                keys = {
                  {
                    "<leader>co",
                    vim.lsp.action["source.organizeImports"],
                    desc = "Organize Imports",
                  },
                },
              },
            })
          end,
          ["pyright"] = function()
            lspconfig.pyright.setup({
              capabilities = capabilities,
              on_attach = function(client, bufnr)
                vim.lsp.config.ruff.setup({
                  settings = {
                    pyright = {
                      -- Using Ruff's import organizer
                      disableOrganizeImports = true,
                    },
                    python = {
                      analysis = {
                        -- Ignore all files for analysis to exclusively use Ruff for linting
                        ignore = { "*" },
                      },
                    },
                  },
                })
              end,
              settings = {
                pyright = {
                  -- Using Ruff's import organizer
                  disableOrganizeImports = true,
                },
                python = {
                  analysis = {
                    -- Ignore all files for analysis to exclusively use Ruff for linting
                    ignore = { "*" },
                  },
                },
              },
            })
          end,
          ["ts_ls"] = function(_, opts)
            require("typescript").setup({ server = opts })
            return true
          end,
          ["tsserver"] = function(_, opts)
            require("typescript").setup({ server = opts })
            return true
          end,
        },
      })

      vim.lsp.config("ctags_lsp", {
        cmd = { "ctags-lsp" },
        filetypes = { "ruby", "python" },
        root_dir = vim.uv.cwd(),
      })
      vim.lsp.enable("ctags_lsp")
    end,
  },
}

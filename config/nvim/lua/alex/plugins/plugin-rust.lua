local diagnostics = vim.g.lazyvim_rust_diagnostics or "rust-analyzer"

--- Load rust-analyzer.toml from project root if present
--- @return table|nil settings table or nil if not found
local function load_rust_analyzer_toml()
  -- Find project root by looking for Cargo.toml or rust-analyzer.toml
  local root_patterns = { "rust-analyzer.toml", "Cargo.toml", ".git" }
  local root_dir = vim.fs.root(0, root_patterns)

  if not root_dir then
    return nil
  end

  local config_path = root_dir .. "/rust-analyzer.toml"
  local stat = vim.uv.fs_stat(config_path)

  if not stat or stat.type ~= "file" then
    return nil
  end

  -- Read the file content
  local file = io.open(config_path, "r")
  if not file then
    vim.notify("Failed to open rust-analyzer.toml", vim.log.levels.WARN)
    return nil
  end

  local content = file:read("*all")
  file:close()

  -- Parse TOML manually (basic parser for rust-analyzer settings)
  local settings = {}
  local current_section = settings

  for line in content:gmatch("[^\r\n]+") do
    -- Skip comments and empty lines
    if not line:match("^%s*#") and not line:match("^%s*$") then
      -- Check for section header [section.subsection]
      local section = line:match("^%s*%[([%w%.%-_]+)%]%s*$")
      if section then
        -- Navigate/create nested tables for the section
        current_section = settings
        for part in section:gmatch("[^%.]+") do
          current_section[part] = current_section[part] or {}
          current_section = current_section[part]
        end
      else
        -- Parse key = value
        local key, value = line:match("^%s*([%w_%.%-]+)%s*=%s*(.+)%s*$")
        if key and value then
          -- Parse the value
          local parsed_value
          if value == "true" then
            parsed_value = true
          elseif value == "false" then
            parsed_value = false
          elseif value:match("^%d+$") then
            parsed_value = tonumber(value)
          elseif value:match('^".*"$') then
            parsed_value = value:sub(2, -2)
          elseif value:match("^%[.*%]$") then
            -- Parse simple array of strings
            parsed_value = {}
            for item in value:gmatch('"([^"]+)"') do
              table.insert(parsed_value, item)
            end
          else
            parsed_value = value
          end

          -- Handle dotted keys (e.g., "cargo.allFeatures")
          local target = current_section
          local parts = {}
          for part in key:gmatch("[^%.]+") do
            table.insert(parts, part)
          end
          for i = 1, #parts - 1 do
            target[parts[i]] = target[parts[i]] or {}
            target = target[parts[i]]
          end
          target[parts[#parts]] = parsed_value
        end
      end
    end
  end

  vim.notify("Loaded rust-analyzer.toml from: " .. config_path, vim.log.levels.INFO)
  return settings
end

--- Deep merge two tables, with t2 values taking precedence
--- @param t1 table base table
--- @param t2 table override table
--- @return table merged table
local function deep_merge(t1, t2)
  local result = vim.deepcopy(t1)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

-- Find a way to run bacon in terminal
-- BACON_SCRATCH = nil
-- BACON_BUFFER = nil
--
-- vim.api.nvim_create_autocmd("LsPAttach", {
--   pattern = { "*.rs" },
--   callback = function(args)
--     if BACON_BUFFER == nil then
--       BACON_SCRATCH = require("scratch").create({ filetype = "rust" })
--       BACON_BUFFER = vim.api.nvim_create_buf(true, false)
--
--       local filename = ("bacon_scratch.%s.%s"):format(os.tmpname(), "log")
--
--       vim.api.nvim_buf_set_name(BACON_BUFFER, filename)
--       vim.api.nvim_set_option_value("filetype", "shell", { buf = BACON_BUFFER })
--       vim.api.nvim_win_set_buf(0, BACON_BUFFER)
--
--       print("Created bacon buffer with name: %s", filename)
--
--       local augroup = vim.api.nvim_create_augroup("scratch", {})
--       vim.api.nvim_create_autocmd("BufDelete", {
--         group = augroup,
--         buffer = BACON_BUFFER,
--         once = true,
--         callback = function()
--           local _, err = os.remove(filename)
--           if err then
--             print(("Failed to remove temp file: %s due to %s"):format(filename, err))
--             return
--           end
--         end,
--       })
--
--       -- do something
--       -- local terminal = require("toggleterm.terminal").Terminal
--       -- BACON_TERM = terminal.create_terminal({
--       --   -- cmd = ("%s -c '%s %s'"):format(vim.o.shell, opts.command, opts.path),
--       --   cmd = "bacon -j bacon-ls",
--       --   close_on_exit = false,
--       --   dir = vim.uv.cwd(),
--       -- })
--     end
--   end,
-- })

return {
  {
    "preservim/tagbar",
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
  {
    "phaazon/hop.nvim",
    opts = {},
  },
  {
    "TravonteD/luajob",
  },
  {
    "puremourning/vimspector",
  },
  {
    "folke/trouble.nvim",
  },
  {
    "m-demare/hlargs.nvim",
  },
  {
    "lukas-reineke/indent-blankline.nvim", -- to show and customize ident lines.
  },
  {
    "windwp/nvim-autopairs", -- for smart pairing of brackets.
  },
  {
    "tpope/vim-surround", -- to quickly add, remove or change brackets surrounding any text.
  },
  {
    "RRethy/vim-illuminate", -- to highlight other uses of word under cursor.
  },
  {
    "numToStr/Comment.nvim", -- to quickly comment / uncomment text.
  },

  -- {
  --   "Canop/nvim-bacon",
  --   config = function()
  --     require("bacon").setup({
  --       quickfix = {
  --         enabled = true, -- Enable Quickfix integration
  --         event_trigger = true, -- Trigger QuickFixCmdPost after populating Quickfix list
  --       },
  --     })
  --   end,
  -- },

  {
    "saecki/crates.nvim",
    -- event = { "BufRead Cargo.toml" },
    config = function()
      require("crates").setup({

        completion = {
          crates = {
            enabled = true,
          },
        },
        lsp = {
          enabled = true,
          actions = true,
          completion = true,
          hover = true,
        },
      })
    end,
  },

  {
    "mrcjkb/rustaceanvim",
    lazy = false,
    version = vim.fn.has("nvim-0.10.0") == 0 and "^4" or false,
    -- root = { "Cargo.toml", "rust-project.json" },
    -- ft = { "rust" },
    ensure_installed = { "bacon-ls", "bacon", "codelldb" },
    dependencies = {
      "mason.nvim",
      "rcarriga/nvim-dap-ui",
      "mfussenegger/nvim-dap", -- The core DAP client
      "nvim-neotest/nvim-nio",
      "mason-org/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      tools = {
        float_win_config = { auto_focus = true },
      },
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>dr", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })

          vim.keymap.set("n", "X", function()
            vim.cmd("copen") -- Open the quickfix window
            vim.diagnostic.setqflist() -- Populate with diagnostics from current buffer
          end, { desc = "rustaceanvim's hover actions", buffer = bufnr })

          vim.keymap.set("n", "K", function()
            vim.cmd.RustLsp({ "hover", "actions" })
          end, { desc = "rustaceanvim's hover actions", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxh", function()
            vim.cmd.RustLsp({ "hover", "actions" })
          end, { desc = "rustaceanvim's hover actions", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxa", function()
            vim.cmd.RustLsp("codeAction")
          end, { desc = "Code Action", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxd", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxm", function()
            vim.cmd.RustLsp("expandMacro")
          end, { desc = "Rust: expandMacro", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxe", function()
            vim.cmd.RustLsp({ "explainError", "cycle" })
          end, { desc = "Rust: explainError(cycle)", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxt", function()
            vim.cmd.RustLsp({ "renderDiagnostic", "cycle" })
          end, { desc = "Rust: renderDiagnostic", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxr", function()
            vim.cmd.RustLsp("rebuildProcMacros")
          end, { desc = "Rust: rebuildProcMacros", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxc", function()
            vim.cmd.RustLsp("openCargo")
          end, { desc = "Rust: openCargo", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxb", function()
            vim.cmd.RustLsp("openDocs")
          end, { desc = "Rust: openDocs", buffer = bufnr })

          vim.keymap.set("n", "<leader>cxj", function()
            vim.cmd.RustLsp("joinLines")
          end, { desc = "Rust: joinLines", buffer = bufnr })
        end,

        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              -- linkedProjects = true,
              buildScripts = {
                enable = true,
              },
              -- Reload rust-analyzer if the Cargo.toml/Cargo.lock file changes
              autoreload = true,
            },

            -- Add clippy lints for Rust if using rust-analyzer
            checkOnSave = diagnostics == "rust-analyzer",

            -- Enable diagnostics if using rust-analyzer
            diagnostics = {
              enable = diagnostics == "rust-analyzer",
            },

            -- Hover Actions!
            hoverActions = {
              enable = true,
            },

            -- Enable CodeLens and its various sub things
            lens = {
              enable = true,
              references = true,
              implementations = true,
              enumVariantReferences = true,
              methodReferences = true,
            },

            -- rust-analyzer language server configuration
            callinfo = {
              full = true,
            },

            -- Enable inlay hints
            inlayHints = {
              enable = true,
              typeHints = true,
              parameterHints = true,
            },

            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["leptos-macro"] = { "server" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
            files = {
              excludeDirs = {
                ".direnv",
                ".git",
                ".github",
                ".gitlab",
                "bin",
                "node_modules",
                "target",
                "venv",
                ".venv",
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      -- Check if mason.nvim is available using pcall
      local mason_ok, _ = pcall(require, "mason")
      if mason_ok then
        local codelldb = vim.fn.exepath("codelldb")
        if codelldb ~= "" then
          local codelldb_lib_ext = vim.uv.os_uname().sysname == "Linux" and ".so" or ".dylib"
          local library_path = vim.fn.expand("$MASON/opt/lldb/lib/liblldb" .. codelldb_lib_ext)
          opts.dap = {
            adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, library_path),
          }
        end
      end

      -- Load project-specific rust-analyzer.toml if present
      local project_settings = load_rust_analyzer_toml()
      if project_settings then
        -- Merge project settings into opts.server.default_settings["rust-analyzer"]
        local ra_settings = opts.server.default_settings["rust-analyzer"] or {}
        opts.server.default_settings["rust-analyzer"] = deep_merge(ra_settings, project_settings)
      end

      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
      if vim.fn.executable("rust-analyzer") == 0 then
        vim.notify(
          "rust-analyzer not found in PATH, please install it.\nhttps://rust-analyzer.github.io/",
          vim.log.levels.ERROR,
          { title = "rustaceanvim" }
        )
      end

      -- Basic nvim-dap-ui setup
      require("dapui").setup()
      -- Keymaps (example)
      vim.keymap.set("n", "<leader>du", require("dapui").toggle)
      vim.keymap.set("n", "<leader>dc", require("dap").continue)
      vim.keymap.set("n", "<leader>dt", require("dap").toggle_breakpoint)
    end,
  },

  -- {
  --     "neovim/nvim-lspconfig",
  --     opts = {
  --         servers = {
  --             bacon_ls = {
  --                 enabled = diagnostics == "bacon-ls",
  --             },
  --             rust_analyzer = { enabled = false },
  --         },
  --         setup = {

  --             -- If you enable this rustaceanvim will not functionm
  --             -- basically its as it outlines itself, it will disable
  --             -- rustaceanvim for lspconfig else if enabled, ensure Mason, installs
  --             -- bacon and bacon-ls
  --             --
  --             -- Correctly setup lspconfig for rust
  --             bacon_ls = function()
  --                 vim.lsp.config.bacon_ls.setup({
  --                     init_options = {
  --                         -- Bacon export filename (default: .bacon-locations).
  --                         locationsFile = ".bacon-locations",
  --                         -- Try to update diagnostics every time the file is saved (default: true).
  --                         updateOnSave = true,
  --                         --  How many milliseconds to wait before updating diagnostics after a save (default: 1000).
  --                         updateOnSaveWaitMillis = 700,
  --                         -- Try to update diagnostics every time the file changes (default: true).
  --                         updateOnChange = true,
  --                         -- Try to validate that bacon preferences are setup correctly to work with bacon-ls (default: true).
  --                         validateBaconPreferences = true,
  --                         -- f no bacon preferences file is found, create a new preferences file with the bacon-ls job definition (default: true).
  --                         createBaconPreferencesFile = false,
  --                         -- Run bacon in background for the bacon-ls job (default: true)
  --                         runBaconInBackground = false,
  --                         -- Command line arguments to pass to bacon running in background (default "--headless -j bacon-ls")
  --                         runBaconInBackgroundCommandArguments = "--headless -j bacon-ls",
  --                         -- How many milliseconds to wait between background diagnostics check to synchronize all open files (default: 2000).
  --                         synchronizeAllOpenFilesWaitMillis = 1300,
  --                     },
  --                 })

  --                 return true
  --             end,
  --         },
  --     },
  -- },
}

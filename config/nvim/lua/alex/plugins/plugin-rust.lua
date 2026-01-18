local diagnostics = vim.g.lazyvim_rust_diagnostics or "rust-analyzer"

--- Get the rust-analyzer log file path
--- Uses XDG_STATE_HOME or falls back to ~/.local/state
--- @return string log file path
local function get_rust_analyzer_logfile()
  local state_dir = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
  local log_dir = state_dir .. "/nvim/rust-analyzer"

  -- Ensure log directory exists
  vim.fn.mkdir(log_dir, "p")

  -- Use date-based log file name for easier debugging
  local date = os.date("%Y-%m-%d")
  return string.format("%s/rust-analyzer-%s.log", log_dir, date)
end

--- Get the sysroot for the current project's toolchain
--- Respects rust-toolchain.toml if present in the project
--- @return string|nil sysroot path or nil if rustc not found
local function get_rust_sysroot()
  -- Run rustc --print sysroot from the current buffer's directory
  -- This respects rust-toolchain.toml
  local bufdir = vim.fn.expand("%:p:h")
  if bufdir == "" then
    bufdir = vim.uv.cwd()
  end

  local result = vim.fn.systemlist({ "rustc", "--print", "sysroot" })
  if vim.v.shell_error == 0 and result[1] then
    return vim.fn.trim(result[1])
  end

  -- Fallback: try rustup default sysroot
  result = vim.fn.systemlist({ "rustup", "run", "stable", "rustc", "--print", "sysroot" })
  if vim.v.shell_error == 0 and result[1] then
    return vim.fn.trim(result[1])
  end

  return nil
end

--- Load environment variables from .cargo/config.toml if present
--- Handles both simple string values and table values with {value, relative, force}
--- @param root_dir string|nil project root directory
--- @return table<string, string> environment variables
local function load_cargo_env(root_dir)
  if not root_dir then
    return {}
  end

  local config_path = root_dir .. "/.cargo/config.toml"
  local stat = vim.uv.fs_stat(config_path)

  if not stat or stat.type ~= "file" then
    return {}
  end

  local file = io.open(config_path, "r")
  if not file then
    return {}
  end

  local content = file:read("*all")
  file:close()

  local env_vars = {}
  local in_env_section = false

  for line in content:gmatch("[^\r\n]+") do
    -- Skip comments and empty lines
    if not line:match("^%s*#") and not line:match("^%s*$") then
      -- Check for section header
      local section = line:match("^%s*%[([%w_%-%.]+)%]%s*$")
      if section then
        in_env_section = (section == "env")
      elseif in_env_section then
        -- Parse env variable definitions
        -- Format 1: VAR_NAME = "value"
        -- Format 2: VAR_NAME = { value = "path", relative = true, force = true }
        local var_name, var_value = line:match("^%s*([%w_]+)%s*=%s*(.+)%s*$")
        if var_name and var_value then
          -- Check if it's a simple string value
          local simple_value = var_value:match('^"([^"]*)"$')
          if simple_value then
            env_vars[var_name] = simple_value
          else
            -- Parse table format: { value = "...", relative = true/false, force = true/false }
            local table_value = var_value:match('^{(.+)}$')
            if table_value then
              local value = table_value:match('value%s*=%s*"([^"]*)"')
              local is_relative = table_value:match("relative%s*=%s*true") ~= nil

              if value then
                if is_relative then
                  -- Make relative paths absolute based on project root
                  env_vars[var_name] = root_dir .. "/" .. value
                else
                  env_vars[var_name] = value
                end
              end
            end
          end
        end
      end
    end
  end

  if next(env_vars) then
    vim.notify(
      string.format("Loaded %d env vars from .cargo/config.toml", vim.tbl_count(env_vars)),
      vim.log.levels.INFO
    )
  end

  return env_vars
end

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
        -- Custom log file location (instead of /tmp)
        logfile = get_rust_analyzer_logfile(),

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
              -- Sysroot will be set dynamically in config function
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

      -- Find project root
      local root_patterns = { "Cargo.toml", "rust-toolchain.toml", ".git" }
      local root_dir = vim.fs.root(0, root_patterns)

      -- Set sysroot dynamically based on project's toolchain (respects rust-toolchain.toml)
      local sysroot = get_rust_sysroot()
      if sysroot then
        opts.server.default_settings["rust-analyzer"].cargo.sysroot = sysroot
      end

      -- Load environment variables from .cargo/config.toml
      local cargo_env = load_cargo_env(root_dir)
      if next(cargo_env) then
        -- Merge with existing extraEnv or create new
        local existing_env = opts.server.default_settings["rust-analyzer"].cargo.extraEnv or {}
        opts.server.default_settings["rust-analyzer"].cargo.extraEnv = vim.tbl_extend("force", existing_env, cargo_env)
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

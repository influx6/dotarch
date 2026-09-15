-- Haskell IDE support via haskell-tools.nvim (by mrcjkb, the same author as
-- rustaceanvim). Like rustaceanvim, it fully manages the language server
-- itself, so it must NOT be registered through mason-lspconfig/lspconfig.
--
-- HLS comes from ghcup (`haskell-language-server-wrapper` on PATH), which
-- version-matches the project's GHC. We deliberately do not install HLS via
-- mason, which would ship a single build that drifts from the local toolchain.
--
-- Provides: HLS diagnostics, hlint (bundled in HLS), Hoogle type search,
-- a GHCi REPL, evaluate-in-comment code lenses, GHCi-based debugging through
-- nvim-dap (via phoityne's haskell-debug-adapter), and a ghcid reload loop.

-- ghcid: a GHCi daemon that reloads on save and streams errors/warnings (and
-- optionally re-runs an expression). It is NOT a debugger -- no breakpoints or
-- stepping -- but it is a far more robust alternative to haskell-debug-adapter
-- for the everyday save -> errors -> rerun cycle. We run it in a toggleterm
-- terminal pinned to the project root, cached per (root, command) so toggling
-- reuses the same watcher.
local ghcid_terminals = {}

--- Find the project root for ghcid (cabal/stack aware).
--- @return string
local function haskell_project_root()
  local root = vim.fs.root(0, { "cabal.project", "stack.yaml", "hie.yaml", ".git" })
  if not root then
    local matches = vim.fs.find(function(name)
      return name:match("%.cabal$")
    end, { upward = true, path = vim.api.nvim_buf_get_name(0) })
    root = matches[1] and vim.fs.dirname(matches[1]) or vim.fn.getcwd()
  end
  return root
end

--- Toggle a ghcid terminal for the current project.
--- @param extra_args string|nil extra ghcid args, e.g. "-T ':main'"
local function toggle_ghcid(extra_args)
  if vim.fn.executable("ghcid") ~= 1 then
    vim.notify(
      "ghcid not found on PATH. Install with: cabal install ghcid",
      vim.log.levels.WARN,
      { title = "haskell-tools" }
    )
    return
  end
  local ok, tt = pcall(require, "toggleterm.terminal")
  if not ok then
    vim.notify("toggleterm.nvim not available for ghcid", vim.log.levels.WARN, { title = "haskell-tools" })
    return
  end

  local root = haskell_project_root()
  local cmd = extra_args and ("ghcid " .. extra_args) or "ghcid"
  local key = root .. "|" .. cmd
  local term = ghcid_terminals[key]
  if not term then
    term = tt.Terminal:new({
      cmd = cmd,
      dir = root,
      direction = "horizontal",
      close_on_exit = false,
      hidden = true,
    })
    ghcid_terminals[key] = term
  end
  term:toggle()
end

return {
  "mrcjkb/haskell-tools.nvim",
  version = "^10",
  ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
  dependencies = {
    -- DAP: haskell-tools drives phoityne's haskell-debug-adapter through
    -- nvim-dap. dap-ui mirrors the Rust setup in plugin-rust.lua.
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    -- ghcid runs in a toggleterm terminal (see toggle_ghcid above).
    "akinsho/toggleterm.nvim",
  },
  init = function()
    -- haskell-tools has no setup() — it reads vim.g.haskell_tools on load.
    vim.g.haskell_tools = {
      tools = {
        -- Prefer telescope for Hoogle results when available, else fall back
        -- to the web backend (no local Hoogle DB required).
        hoogle = { mode = "auto" },
        hover = { auto_focus = false },
      },
      hls = {
        -- capabilities are auto-detected from cmp_nvim_lsp / blink.cmp.
        default_settings = {
          haskell = {
            -- Match the formatter used by conform (ormolu is installed).
            formattingProvider = "ormolu",
            cabalFormattingProvider = "cabalfmt",
            -- hlint is bundled with HLS; keep its diagnostics + code actions.
            plugin = {
              hlint = { globalOn = true },
            },
          },
        },
        on_attach = function(_, bufnr, ht)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          -- HLS relies heavily on code lenses (eval, add type sig, etc.)
          map("n", "<leader>cl", vim.lsp.codelens.run, "Haskell: run code lens")
          map("n", "<leader>ea", ht.lsp.buf_eval_all, "Haskell: eval all snippets")

          -- Hoogle search for the symbol under the cursor
          map("n", "<leader>hs", ht.hoogle.hoogle_signature, "Haskell: Hoogle signature")

          -- GHCi REPL
          map("n", "<leader>rr", ht.repl.toggle, "Haskell: toggle package REPL")
          map("n", "<leader>rf", function()
            ht.repl.toggle(vim.api.nvim_buf_get_name(0))
          end, "Haskell: toggle buffer REPL")
          map("n", "<leader>rq", ht.repl.quit, "Haskell: quit REPL")

          -- ghcid: fast reload/error loop (robust alternative to DAP).
          -- <leader>rg watches for errors; <leader>rG also re-runs :main.
          map("n", "<leader>rg", function()
            toggle_ghcid()
          end, "Haskell: toggle ghcid (reload loop)")
          map("n", "<leader>rG", function()
            toggle_ghcid("-T ':main'")
          end, "Haskell: toggle ghcid + run :main on reload")

          -- Debugging (nvim-dap). haskell-tools generates launch configs from
          -- the cabal/stack project; <leader>dd discovers them, then the
          -- shared dap keymaps (<leader>dc/dt/du) drive the session.
          map("n", "<leader>dd", function()
            ht.dap.discover_configurations(bufnr)
          end, "Haskell: discover DAP configurations")
        end,
      },
      -- Only advertise the debug adapter when its binary is present, so a
      -- machine without haskell-debug-adapter simply has no Haskell DAP
      -- rather than a broken adapter. Install with:
      --   cabal install haskell-debug-adapter ghci-dap
      dap = vim.fn.executable("haskell-debug-adapter") == 1
          and {
            cmd = { "haskell-debug-adapter" },
            logLevel = "Warning",
            auto_discover = true,
          }
        or nil,
    }
  end,
  config = function()
    -- Work around an upstream haskell-tools bug (v10.0.1): its ftplugin fires
    -- for ANY buffer that gets filetype=haskell -- including transient buffers
    -- like picker preview buffers -- and starts HLS on them. HLS's on_init
    -- callback runs asynchronously and captures that buffer number; if the
    -- buffer is wiped before on_init fires, it throws
    --   ON_INIT_CALLBACK_ERROR ... lsp/init.lua:24: Invalid buffer id
    -- The plugin doesn't expose on_init, so we guard lsp.start instead: only
    -- attach HLS to real, on-disk file buffers (buftype == ""). The lazy_require
    -- proxy delegates to this same module table, so the ftplugin sees the wrap.
    local lsp = require("haskell-tools.lsp")
    if not lsp._buftype_guard_installed then
      local orig_start = lsp.start
      lsp.start = function(bufnr)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(bufnr)
          and vim.bo[bufnr].buftype == ""
          and vim.api.nvim_buf_get_name(bufnr) ~= ""
        then
          return orig_start(bufnr)
        end
      end
      lsp._buftype_guard_installed = true
    end

    -- Shared nvim-dap-ui setup (guarded so it runs once even though
    -- plugin-rust.lua also initialises dap-ui).
    if not vim.g._dapui_configured then
      require("dapui").setup()
      vim.g._dapui_configured = true
    end

    -- Shared DAP keymaps (match the ones in plugin-rust.lua).
    local dap = require("dap")
    vim.keymap.set("n", "<leader>du", require("dapui").toggle, { desc = "DAP: toggle UI" })
    vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: continue" })
    vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })

    if vim.fn.executable("haskell-debug-adapter") ~= 1 then
      vim.notify(
        "haskell-debug-adapter not found; Haskell debugging is disabled.\n"
          .. "Install it with: cabal install haskell-debug-adapter ghci-dap",
        vim.log.levels.WARN,
        { title = "haskell-tools" }
      )
    end
  end,
}

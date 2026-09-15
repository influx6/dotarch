-- Haskell IDE support via haskell-tools.nvim (by mrcjkb, the same author as
-- rustaceanvim). Like rustaceanvim, it fully manages the language server
-- itself, so it must NOT be registered through mason-lspconfig/lspconfig.
--
-- HLS comes from ghcup (`haskell-language-server-wrapper` on PATH), which
-- version-matches the project's GHC. We deliberately do not install HLS via
-- mason, which would ship a single build that drifts from the local toolchain.
--
-- Provides: HLS diagnostics, hlint (bundled in HLS), Hoogle type search,
-- a GHCi REPL, evaluate-in-comment code lenses, and GHCi-based debugging
-- through nvim-dap (via phoityne's haskell-debug-adapter).

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

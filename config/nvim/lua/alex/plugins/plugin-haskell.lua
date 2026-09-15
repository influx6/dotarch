-- Haskell IDE support via haskell-tools.nvim (by mrcjkb, the same author as
-- rustaceanvim). Like rustaceanvim, it fully manages the language server
-- itself, so it must NOT be registered through mason-lspconfig/lspconfig.
--
-- HLS comes from ghcup (`haskell-language-server-wrapper` on PATH), which
-- version-matches the project's GHC. We deliberately do not install HLS via
-- mason, which would ship a single build that drifts from the local toolchain.
--
-- Provides: HLS diagnostics, hlint (bundled in HLS), Hoogle type search,
-- a GHCi REPL, and evaluate-in-comment code lenses.

return {
  "mrcjkb/haskell-tools.nvim",
  version = "^10",
  ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
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
        end,
      },
    }
  end,
}

-- fff.nvim — Rust-backed fuzzy file finder.
-- Replaces Telescope for file-finding keymaps (<leader>ff, <leader>fr).
-- Telescope is still used for live_grep, LSP pickers, todos, textcase, etc.
--
-- Requires a Rust toolchain to build on install/update.
return {
  {
    "dmtrKovalenko/fff.nvim",
    build = "cargo build --release",
    -- Load on first use of the keymaps below.
    keys = {
      {
        "<leader>ff",
        function()
          require("fff").find_files()
        end,
        desc = "Find files (fff.nvim)",
      },
      {
        "<leader>fF",
        function()
          require("fff").find_in_git_root()
        end,
        desc = "Find files in git root (fff.nvim)",
      },
    },
    ---@module "fff"
    ---@type fff.Config
    opts = {
      -- Use frecency so recently-opened files rank high — this replaces
      -- the previous `<leader>fr` Telescope oldfiles binding.
      prompt = "  ",
    },
  },
}

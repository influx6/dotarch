return {
    "nvim-telescope/telescope.nvim",
    -- Track `master`: the `0.1.x` release branch is abandoned (no commits since
    -- May 2024) and still calls the pre-0.11 `vim.lsp.util.make_position_params`
    -- without a position_encoding, which warns on Neovim >= 0.11. `master` passes
    -- the client offset_encoding. Run `:Lazy update telescope.nvim` to move to it.
    branch = "master",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
        "folke/todo-comments.nvim",
        -- Standalone Hoogle picker for Haskell (:Telescope hoogle / <leader>hh):
        -- queries the hoogle CLI directly (local DB if generated via
        -- :HsHoogleGenerate, else web). Independent of HLS. Note: this is NOT
        -- what haskell-tools' <leader>hs uses -- that goes through HLS hover and
        -- has its own Telescope picker. See plugin-haskell.lua.
        "luc-tielen/telescope_hoogle",
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        telescope.setup({
            defaults = {
                path_display = { "smart" },
                mappings = {
                    i = {
                        ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                        ["<C-j>"] = actions.move_selection_next,     -- move to next result
                        ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                    },
                },
            },
        })

        telescope.load_extension("fzf")
        -- Hoogle picker (:Telescope hoogle, or <leader>hh in Haskell buffers).
        pcall(telescope.load_extension, "hoogle")

        -- set keymaps
        local keymap = vim.keymap -- for conciseness

        -- File-finder keymaps (<leader>ff, <leader>fr) are owned by fff.nvim.
        -- See lua/alex/plugins/plugin-fff.lua. Telescope keeps live_grep,
        -- grep_string, todos, and LSP pickers — fff.nvim does not cover them.
        keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
        keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
        keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
    end,
}

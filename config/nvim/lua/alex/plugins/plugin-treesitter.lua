return {
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPre", "BufNewFile" },
        -- event = "LazyFile",
        build = ":TSUpdate",
        dependencies = {
            "windwp/nvim-ts-autotag",
        },
        -- nvim-treesitter on `main` no longer manages highlighting/indent/
        -- autotag/incremental-selection itself — those live in Neovim core
        -- (`vim.treesitter.start`) and LazyVim's base config, which creates the
        -- FileType autocmd that enables the highlighter. Defining our own
        -- `config` here would *replace* that autocmd and disable highlighting,
        -- so we only contribute `opts` (deep-merged with LazyVim's) instead.
        opts_extend = { "ensure_installed" },
        opts = {
            -- ensure these language parsers are installed
            ensure_installed = {
                "bash", "c", "cpp", "css", "diff", "dockerfile", "go",
                "gomod", "gosum", "graphql", "haskell", "html",
                "javascript", "json", "jsonc", "latex", "lua", "luadoc",
                "make", "markdown", "markdown_inline", "python",
                "query", "regex", "rust", "scss", "sql", "svelte",
                "terraform", "toml", "tsx", "typescript", "typst", "vim",
                "vimdoc", "vue", "yaml",
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        event = "VeryLazy",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        opts = {
            textobjects = {
                select = {
                    enable = true,

                    -- Automatically jump forward to textobj, similar to targets.vim
                    lookahead = true,

                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        -- You can optionally set descriptions to the mappings (used in the desc parameter of
                        -- nvim_buf_set_keymap) which plugins like which-key display
                        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
                        -- You can also use captures from other query groups like `locals.scm`
                        ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
                    },
                    -- You can choose the select mode (default is charwise 'v')
                    --
                    -- Can also be a function which gets passed a table with the keys
                    -- * query_string: eg '@function.inner'
                    -- * method: eg 'v' or 'o'
                    -- and should return the mode ('v', 'V', or '<c-v>') or a table
                    -- mapping query_strings to modes.
                    selection_modes = {
                        ["@parameter.outer"] = "v", -- charwise
                        ["@function.outer"] = "V",  -- linewise
                        ["@class.outer"] = "<c-v>", -- blockwise
                    },
                    -- If you set this to `true` (default is `false`) then any textobject is
                    -- extended to include preceding or succeeding whitespace. Succeeding
                    -- whitespace has priority in order to act similarly to eg the built-in
                    -- `ap`.
                    --
                    -- Can also be a function which gets passed a table with the keys
                    -- * query_string: eg '@function.inner'
                    -- * selection_mode: eg 'v'
                    -- and should return true or false
                    include_surrounding_whitespace = true,
                },
            },
        },
    },
}

return {

    -- AI completion
    {

        "milanglacier/minuet-ai.nvim",
        config = function()
            -- provider = 'openai_fim_compatible',
            -- provider_options = {
            --        openai_fim_compatible = {
            --            api_key = 'DEEPSEEK_API_KEY',
            --            name = 'deepseek',
            --            optional = {
            --                max_tokens = 256,
            --                top_p = 0.9,
            --            },
            --        },
            --    },
            --
            -- provider = 'openai_compatible',
            -- provider_options = {
            --     openai_compatible = {
            --         end_point = 'https://api.deepseek.com/v1/chat/completions',
            --         api_key = 'DEEPSEEK_API_KEY',
            --         name = 'deepseek',
            --         optional = {
            --             max_tokens = 256,
            --             top_p = 0.9,
            --         },
            --     },
            -- },
            --
            --
            --     provider = 'openai_fim_compatible',
            -- n_completions = 1, -- recommend for local model for resource saving
            -- -- I recommend beginning with a small context window size and incrementally
            -- -- expanding it, depending on your local computing power. A context window
            -- -- of 512, serves as an good starting point to estimate your computing
            -- -- power. Once you have a reliable estimate of your local computing power,
            -- -- you should adjust the context window to a larger value.
            -- context_window = 512,
            -- provider_options = {
            --     openai_fim_compatible = {
            --         api_key = 'TERM',
            --         name = 'Ollama',
            --         end_point = 'http://localhost:11434/v1/completions',
            --         model = 'qwen2.5-coder:7b',
            --         optional = {
            --             max_tokens = 56,
            --             top_p = 0.9,
            --         },
            --     },
            -- },
            --
            --
            -- Customizing Prompts
            --
            --
            -- local gemini_prompt = [[
            -- You are the backend of an AI-powered code completion engine. Your task is to
            -- provide code suggestions based on the user's input. The user's code will be
            -- enclosed in markers:
            --
            -- - `<contextAfterCursor>`: Code context after the cursor
            -- - `<cursorPosition>`: Current cursor location
            -- - `<contextBeforeCursor>`: Code context before the cursor
            -- ]]
            --
            -- local gemini_few_shots = {}
            --
            -- gemini_few_shots[1] = {
            --     role = 'user',
            --     content = [[
            -- # language: python
            -- <contextBeforeCursor>
            -- def fibonacci(n):
            --     <cursorPosition>
            -- <contextAfterCursor>
            --
            -- fib(5)]],
            -- }
            --
            -- local gemini_chat_input_template =
            --     '{{{language}}}\n{{{tab}}}\n<contextBeforeCursor>\n{{{context_before_cursor}}}<cursorPosition>\n<contextAfterCursor>\n{{{context_after_cursor}}}'
            --
            --
            -- gemini_few_shots[2] = require('minuet.config').default_few_shots[2]
            --
            -- require('minuet').setup {
            --     provider = 'gemini',
            --     provider_options = {
            --         gemini = {
            --             system = {
            --                 prompt = gemini_prompt,
            --             },
            --             few_shots = gemini_few_shots,
            --             chat_input = {
            --                 template = gemini_chat_input_template,
            --             },
            --             optional = {
            --                 generationConfig = {
            --                     maxOutputTokens = 256,
            --                     topP = 0.9,
            --                 },
            --                 safetySettings = {
            --                     {
            --                         category = 'HARM_CATEGORY_DANGEROUS_CONTENT',
            --                         threshold = 'BLOCK_NONE',
            --                     },
            --                     {
            --                         category = 'HARM_CATEGORY_HATE_SPEECH',
            --                         threshold = 'BLOCK_NONE',
            --                     },
            --                     {
            --                         category = 'HARM_CATEGORY_HARASSMENT',
            --                         threshold = 'BLOCK_NONE',
            --                     },
            --                     {
            --                         category = 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            --                         threshold = 'BLOCK_NONE',
            --                     },
            --                 },
            --             },
            --         },
            --     },
            -- }
            require("minuet").setup({
                -- Your configuration options here
                -- Ollama based
                provider = "openai_fim_compatible",
                n_completions = 1, -- recommend for local model for resource saving
                -- I recommend beginning with a small context window size and incrementally
                -- expanding it, depending on your local computing power. A context window
                -- of 512, serves as an good starting point to estimate your computing
                -- power. Once you have a reliable estimate of your local computing power,
                -- you should adjust the context window to a larger value.
                context_window = 1512,
                provider_options = {
                    openai_fim_compatible = {
                        api_key = "TERM",
                        name = "Ollama",
                        end_point = "http://127.0.0.1:11434/v1/completions",
                        model = "qwen2.5-coder:3b",
                        optional = {
                            max_tokens = 56,
                            top_p = 0.9,
                        },
                    },
                },
            })
        end,
    },

    -- {
    --   "yetone/avante.nvim",
    --   event = "VeryLazy",
    --   version = false, -- Never set this value to "*"! Never!
    --   opts = {
    --     -- add any opts here
    --     -- for example
    --     -- provider = "openai",
    --     -- openai = {
    --     --   endpoint = "https://api.openai.com/v1",
    --     --   model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
    --     --   timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
    --     --   temperature = 0,
    --     --   max_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
    --     --   --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
    --     -- },
    --     --
    --     -- For Deepseek-r1
    --     -- provider = "ollama",
    --     -- ollama = {
    --     --   model = "deepseek-r1:70b",
    --     -- },
    --     --
    --     provider = "ollama",
    --     ollama = {
    --       -- model = "deepseek-r1:70b",
    --       -- model = "qwq:latest", -- to use latest qwuen reasoning model
    --       model = "gemma3:12b", -- to use latest google open source model
    --     },
    --   },
    --   -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    --   build = "make",
    --   -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    --   dependencies = {
    --     "nvim-treesitter/nvim-treesitter",
    --     "stevearc/dressing.nvim",
    --     "nvim-lua/plenary.nvim",
    --     "MunifTanjim/nui.nvim",
    --     --- The below dependencies are optional,
    --     "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    --     "ibhagwan/fzf-lua", -- for file_selector provider fzf
    --     "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    --     {
    --       -- support for image pasting
    --       "HakonHarnes/img-clip.nvim",
    --       event = "VeryLazy",
    --       opts = {
    --         -- recommended settings
    --         default = {
    --           embed_image_as_base64 = false,
    --           prompt_for_file_name = false,
    --           drag_and_drop = {
    --             insert_mode = true,
    --           },
    --           -- required for Windows users
    --           use_absolute_path = true,
    --         },
    --       },
    --     },
    --     {
    --       -- Make sure to set this up properly if you have lazy=true
    --       "MeanderingProgrammer/render-markdown.nvim",
    --       opts = {
    --         file_types = { "markdown", "Avante" },
    --       },
    --       ft = { "markdown", "Avante" },
    --     },
    --   },
    -- },
}

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- Live-render markdown in the buffer: headings, bold/italic, lists, tables,
    -- code blocks, links and callouts drawn with extmarks while the raw
    -- markdown underneath stays fully editable.
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown", "markdown.mdx", "norg", "rmd", "org", "codecompanion" },
    opts = {
      code = {
        sign = false,
        width = "block",
        left_pad = 1,
        right_pad = 1,
        -- Keep the ``` fences visible instead of concealing them.
        conceal_delimiters = false,
      },
      heading = {
        sign = false,
        icons = {},
      },
      checkbox = {
        enabled = false,
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = require("render-markdown").get,
        set = require("render-markdown").set,
      }):map("<leader>um")
    end,
  },
}

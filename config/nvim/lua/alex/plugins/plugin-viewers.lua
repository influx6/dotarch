return {
  {
    "basola21/PDFview",
    lazy = false,
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  {
    "r-pletnev/pdfreader.nvim",
    lazy = false,
    dependencies = {
      "folke/snacks.nvim", -- image rendering
      "nvim-telescope/telescope.nvim", -- pickers
    },
    config = function()
      require("pdfreader").setup()
    end,
  },
}

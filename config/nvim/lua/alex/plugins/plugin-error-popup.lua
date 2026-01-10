return {
  {
    "folke/noice.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      -- "rcarriga/nvim-notify", -- used as a fallback
    },
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      messages = {
        -- set position to center
        position = "center",
        -- optional: adjust the size
        view = "popup",
      },
    },
  },
}

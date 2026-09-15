return {
    "rmagatti/auto-session",
    -- Load at startup so a session is always auto-saved on exit (a lazy trigger
    -- could miss the save if you quit before the plugin loads).
    lazy = false,
    keys = {
        { "<leader>wr", "<cmd>SessionRestore<CR>", desc = "Restore session for cwd" },
        { "<leader>ws", "<cmd>SessionSave<CR>", desc = "Save session for cwd" },
        { "<leader>wf", "<cmd>SessionSearch<CR>", desc = "Find/search sessions" },
    },
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
        -- Auto-save the session on exit; restore is manual (via <leader>wr or the
        -- greeter's "Restore Session" button). Set auto_restore = true to reopen
        -- the cwd's session automatically on launch.
        auto_save = true,
        auto_restore = false,
        -- Don't create/restore sessions in these dirs (home, browse dirs, etc.).
        suppressed_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    },
}

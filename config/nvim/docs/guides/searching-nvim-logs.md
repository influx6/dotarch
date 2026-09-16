# Guide: searching Neovim's logs to find an error

When something breaks in Neovim, the useful detail is usually **not** in
`:messages` — it's in a log file (LSP server crashes, plugin internals, startup
traces). This guide shows the fast way to search all of them at once. For the
full map of *where* each kind of error hides, see
[`../troubleshooting-errors.md`](../troubleshooting-errors.md).

## TL;DR

| You want to… | Do this |
|---|---|
| Search inside all logs, live | `<leader>sL` or `:LogGrep` |
| Search for a specific term | `:LogGrep exit code` |
| Search the word under the cursor | `:LogGrepWord` |
| Browse the log files by name | `:LogFiles` |

## How to launch it

Three ways, all discoverable — you don't have to memorize the command:

1. **Which-key panel:** press `<leader>` then `s` (the "search" group) and look
   for **"Search Nvim logs"** on `L`. Pick it and start typing.
2. **Command palette:** open it (`Snacks.picker.commands()`) and type `Logs` —
   the three `Logs:` commands are listed with descriptions; hit Enter to run.
3. **Ex command:** `:LogGrep`, `:LogGrepWord`, or `:LogFiles`.

## What you get

`:LogGrep` opens your normal grep picker — **matches on the left, file + match
preview on the right** — but scoped to the log directories, searching *inside*
the files. Just type; results filter live. Enter jumps to that line in the log.

`:LogGrep <term>` seeds the search (e.g. `:LogGrep Aeson`). `:LogGrepWord` seeds
it with the word under your cursor.

## How it works (so you can tweak it)

Defined in [`../../lua/alex/core/logsearch.lua`](../../lua/alex/core/logsearch.lua).

- **Backends, first present wins:** `snacks.picker` → `telescope live_grep` →
  plain `:grep` into the quickfix list. The *content* search is always
  **ripgrep**; the picker only draws the panel.
- **`fff` is not a grep backend** — it finds files by *name*, not contents, so
  it powers `:LogFiles` (browsing) rather than `:LogGrep` (searching inside).
- **Where it searches:** `stdpath('log')` (`~/.local/state/nvim/` — `lsp.log`,
  `haskell-tools.log`, `mason.log`, `nvim.log`, …) and `stdpath('cache')`
  (`~/.cache/nvim/` — `fidget.nvim.log`, `diffview.log`), matching `*.log`.

### Change the key or add more

```lua
-- e.g. also bind word-under-cursor search:
vim.keymap.set("n", "<leader>sW", "<cmd>LogGrepWord<cr>", { desc = "Search Nvim logs for <cword>" })
```

### Add another log directory

Edit `log_dirs()` in `logsearch.lua` and add the path (it de-dupes for you).

## Worked example

The HLS server kept dying with only *"Client haskell-tools.nvim quit with exit
code 1"* in the UI — nothing useful in `:messages`. `:LogGrep exit` (or
`:LogGrep Error in`) surfaced the real cause straight from `lsp.log`:

```
haskell-language-server-wrapper: Aeson exception:
Error in $.cradle.cabal[4]: key "component" not found
```

…an invalid `hie.yaml`. One search, root cause found — no guessing which log to
open.

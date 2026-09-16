# Where to look when something errors in Neovim

`:messages` only captures what Neovim printed through `:echo`/`:echomsg`/
`nvim_echo` and a subset of notifications. A huge class of errors never lands
there: **LSP server crashes, async/scheduled callback failures, startup errors
before the UI, and anything a plugin writes to its own log file.** This is the
map of where those actually go.

Paths on this machine (from `:echo stdpath('log')` / `'state'` / `'cache'`):

- `stdpath('log')` = `stdpath('state')` = `~/.local/state/nvim/`
- `stdpath('cache')` = `~/.cache/nvim/`

## Fastest path: `:LogGrep` (search all logs at once)

Defined in `lua/alex/core/logsearch.lua`. It opens your grep picker (snacks →
telescope → plain `:grep` fallback) scoped to every log directory, so you get
the familiar panel — matches on the left, file+match preview on the right —
searching *inside* all the log files at once:

```vim
:LogGrep                 " live-grep the logs; just start typing (e.g. 'error', 'exit code')
:LogGrep Aeson           " seed the search with a term
:LogGrepWord             " grep the word under the cursor
:LogFiles                " browse the log files by name (fff/snacks/telescope)
```

The content search is ripgrep; the picker only draws the panel. Bind a key if
you like, e.g. `vim.keymap.set("n", "<leader>se", "<cmd>LogGrep<cr>")`.

## Symptom → where to look (start here)

| Symptom | Look here first |
|---|---|
| "Client X quit with exit code 1" / LSP misbehaving | `:LspLog` → `~/.local/state/nvim/lsp.log` |
| A red toast flashed and vanished | notifier history: `:Notifications` (snacks) / `:Fidget history` |
| Error only while a plugin runs a command | that plugin's own log (see list below) |
| Something broke at **startup** (before UI) | `nvim --headless +qa` (stderr), or `nvim -V3` |
| A keymap/autocmd/async callback silently does nothing | `:messages` right after, then raise verbosity (below) |
| "why did this option/map get set?" | `:verbose set <opt>?` / `:verbose map <lhs>` |
| Plugin failed to load / update | `:Lazy log`, `:Lazy` (press `L` on the plugin) |

## The big one: LSP crashes (`:messages` shows almost nothing)

The "quit with exit code 1" popup is a dead end — the real error is in the LSP
log. Worked example from this repo: `haskell-tools.nvim` kept dying and
`:messages` only had the one-line quit notice. The actual cause was in
`~/.local/state/nvim/lsp.log`:

```
haskell-language-server-wrapper: Aeson exception:
Error in $.cradle.cabal[4]: key "component" not found
```

(An invalid `hie.yaml` — a `cabal:` list entry with no `component:`.) Nothing
about that reached `:messages`.

How to read it:

```vim
:LspLog                       " opens ~/.local/state/nvim/lsp.log
:lua vim.lsp.set_log_level("debug")   " then reproduce; far more detail
```

```bash
tail -n 80 ~/.local/state/nvim/lsp.log     # server stderr lands here
```

The server's own stderr (cabal errors, wrapper crashes, stack traces) is logged
with an `"rpc" … "stderr"` tag. Grep for the server name or `Error`.

## Per-plugin log files (these NEVER show in `:messages`)

Under `~/.local/state/nvim/`:

- `lsp.log` — all LSP clients (HLS, copilot-language-server, etc.)
- `haskell-tools.log` — haskell-tools plugin internals
- `mason.log` — tool/LSP installs (also `:MasonLog`)
- `nvim.log` — Neovim's own internal log (`$NVIM_LOG_FILE`)
- `nio.log` — nvim-nio async runtime
- `fff+*.log` — the fff file picker

Under `~/.cache/nvim/`:

- `fidget.nvim.log` — the notifier
- `diffview.log` — diffview

When in doubt, list what changed recently:

```bash
ls -lt ~/.local/state/nvim/*.log ~/.cache/nvim/*.log | head
```

## Errors that happen at startup (before the UI exists)

`:messages` may be cleared or the error may abort a plugin silently. Surface
them by running Neovim non-interactively — errors go to **stderr**:

```bash
nvim --headless "+qa"          # prints Lua/config errors to the terminal
nvim -V3 2>&1 | less           # verbose: every sourced file + errors
nvim -V9/tmp/nvim-verbose.log  # dump very verbose trace to a file
```

`-V3` is the fastest way to see "which file blew up and why" during config load.

## Async / scheduled callback errors (the sneaky ones)

Errors inside `vim.schedule(...)`, timers, autocmd callbacks, and LSP handlers
often print once via `nvim_err_writeln` and then scroll away — or, if wrapped in
`pcall`, vanish entirely. To catch them:

- Check `:messages` **immediately** after triggering the action.
- Raise the floor: `:set verbose=9` (very noisy) around the repro, then reset.
- For LSP specifically, `vim.lsp.set_log_level("debug")` + `:LspLog`.
- If a plugin swallows errors in `pcall`, temporarily read its notify history
  (`:Notifications`) — many plugins route caught errors to `vim.notify`, which
  the notifier keeps even after the toast disappears.

## Health checks (config-level problems, not runtime errors)

```vim
:checkhealth                   " everything
:checkhealth vim.lsp           " client/server wiring, root dir, capabilities
:checkhealth haskell-tools     " HLS version, cradle, tool paths
:checkhealth lazy              " plugin spec problems
```

## Quick capture recipes

```vim
" dump :messages to a file you can grep
:redir > /tmp/nvim-messages.txt | silent messages | redir END

" see the last error with a stack trace
:lua print(debug.traceback())
```

```bash
# follow the LSP log live in another terminal while you repro in nvim
tail -f ~/.local/state/nvim/lsp.log
```

## TL;DR order of operations

1. `:messages` (cheap, but assume it's incomplete).
2. `:LspLog` / `~/.local/state/nvim/lsp.log` for anything LSP.
3. The specific plugin's log under `~/.local/state/nvim/` or `~/.cache/nvim/`.
4. `nvim --headless +qa` or `nvim -V3` for startup-time errors.
5. `:checkhealth <thing>` for wiring/config problems.

# Neovim Performance Review — 2026-04-14

Context: configuration felt "incredibly slow" while editing Rust. This document
records the issues found during review and the fixes applied.

## Root causes (ranked by impact)

### 1. blink.cmp LSP source was synchronous with a 2s timeout
`lua/alex/plugins/lsp/plugin-blink.lua`

```lua
lsp = { async = false, timeout_ms = 2000, ... }
```

With `async = false`, every keystroke blocks the completion menu waiting on the
LSP provider — up to 2000 ms on a busy rust-analyzer. This is the single worst
setting for typing latency on Rust projects.

**Fix:** `async = true`. Completions now render as soon as any source returns,
and rust-analyzer results stream in without blocking the UI.

### 2. blink.cmp loaded 15+ completion sources on every keystroke
Every keystroke triggered: `lsp`, `path`, `snippets`, `buffer`, `ripgrep`,
`spell`, `references`, `dictionary`, `omni`, `emoji`, `css_vars`, `nerdfont`,
`digraphs`, `git`, `conventional_commits`. Several are expensive:

- `ripgrep` spawns `rg` across the project on every prefix
- `spell` walks treesitter captures at the cursor
- `git` / `conventional_commits` only make sense in `gitcommit`
- `emoji` / `nerdfont` / `dictionary` / `references` are noise in code files

**Fix:** `default` trimmed to `{ "lsp", "path", "snippets", "buffer" }`. The
rest are moved behind `per_filetype` so they only run where they're useful:

- `gitcommit` — adds `git`, `conventional_commits`, `emoji`, `dictionary`, `spell`
- `markdown` — adds `ripgrep`, `dictionary`, `spell`, `emoji`, `references`
- `css` / `scss` — adds `css_vars`, `nerdfont`
- `sql` — adds `dadbod`
- Code filetypes (rust, go, python, ts, …) — adds `ripgrep` only (kept per user
  preference) but no spell/dictionary/emoji bloat.

#### blink-ripgrep debouncing

blink.cmp has no per-source time-debounce ("wait N ms after last keystroke"),
but it exposes **keyword-length gating**, which is a better fit for ripgrep:

- `min_keyword_length = 5` on the blink source — blink will not call the
  ripgrep provider until you've typed 5 characters. Typing `let x = vec.`
  fires zero `rg` invocations.
- `prefix_min_len = 5` inside blink-ripgrep itself — second gate, belt and
  braces.
- `async = true` — even when `rg` does run, it cannot block the menu. LSP and
  buffer results render immediately; ripgrep results stream in whenever they
  finish.
- `score_offset = 1` — ripgrep matches sort below LSP/snippets/buffer so they
  never push real completions out of view.

Net effect: "spawn rg after you've typed a meaningful identifier, in the
background, never blocking." Gated by intent (keyword length) rather than
time. If 5 is still too eager on a given machine, bump both numbers to 6 or 7.

### 3. Treesitter installed every parser
`ensure_installed = "all"` in `plugin-treesitter.lua` forces a build of every
parser on `:TSUpdate`, bloats startup, and wastes disk.

**Fix:** explicit list of the languages actually in use.

### 4. rust-analyzer was configured to do maximum work
`plugin-rust.lua` default settings:

```
cargo.allFeatures = true
cargo.buildScripts.enable = true
procMacro.enable = true
checkOnSave = true           -- runs clippy on every save
lens.enable = true + all sub-references
inlayHints.enable = true
```

On a non-trivial crate, this keeps rust-analyzer at 100% CPU almost continuously,
which starves the editor and compounds with issue #1.

**Fix:**
- `allFeatures = false` (was the main offender for large workspaces)
- `checkOnSave` switched to `cargo check` (clippy on-demand, not every save)
- `lens.enable = false` (enable on demand)
- `inlayHints` kept — they're cheap compared to the above
- `procMacro` kept — required for most modern crates

### 5. rustaceanvim loaded eagerly
`lazy = false` was set alongside `ft = { "rust" }`. `lazy = false` wins, so
rustaceanvim plus its dep chain (dap, dap-ui, nio, tree_climber_rust, mason,
lspconfig) loaded on every nvim startup, even for a markdown file.

**Fix:** removed `lazy = false`. `ft = { "rust" }` now takes effect.

### 6. Unrelated plugins piggybacked on plugin-rust.lua
The rust plugin file declared ~11 top-level eager specs with no `event` / `ft` /
`cmd`: `tagbar`, `hop.nvim`, `luajob`, `vimspector`, `hlargs`,
`indent-blankline`, `nvim-autopairs`, `vim-surround`, `vim-illuminate`,
`Comment.nvim`, `todo-comments`, `trouble`. Several duplicated plugins already
declared elsewhere in the config.

**Fix:** duplicates removed; remaining specs gated with `event = "VeryLazy"`
or `ft = "rust"` where appropriate.

### 7. CursorHold autocmd storm
`core/autocmds.lua` had:

```lua
autocmd CursorHold  * lua vim.diagnostic.open_float(...)
autocmd {FocusGained, BufEnter, CursorHold, CursorHoldI} -> checktime
```

`CursorHoldI` + `checktime` runs while typing in insert mode and stats the file
on every idle tick. `CursorHold` + auto diagnostic float re-renders a window on
every pause. Both fight with the LSP.

**Fix:** `checktime` limited to `FocusGained` + `BufEnter`. Auto diagnostic
float removed (use `<leader>d` to open it on demand — already bound).

### 8. Global spell-check
`opt.spell = true` globally enabled spell-check in every buffer including `.rs`,
which also activated blink's `spell` source walking treesitter captures on
every keystroke.

**Fix:** `spell = false` globally, enabled per-filetype for `markdown`,
`gitcommit`, `text` via autocmd.

### 9. Synchronous shell calls during Rust plugin config
`get_rust_sysroot`, `get_rust_sysroot_src`, and `load_cargo_env` invoke
`rustup run … rustc --print sysroot` and read TOML via blocking
`vim.fn.system` / `io.open` during the `config` function. First `.rs` open
pays 2× rustup latency (~200–600 ms each) plus potential luarocks install.

**Fix (deferred):** left as-is for now — it runs once per session and
rustaceanvim is correctly lazy-loaded on `ft = rust`. Flagged for a future
async rewrite using `vim.system`.

## Other cleanups applied

- `plugin-lspconfig.lua` — removed `minuet-ai.nvim` dependency (plugin is
  commented out everywhere).
- `plugin-lspconfig.lua` — `rust_analyzer` handler was double-registering
  alongside rustaceanvim; left disabled so rustaceanvim remains the sole owner.

## File picker migration: Telescope → fff.nvim

`fff.nvim` (dmtrKovalenko) is a Rust-backed fuzzy file finder, substantially
faster than Telescope on large repos. **It only does file finding** — not
live_grep, not LSP pickers, not todos. So the migration is partial:

- `<leader>ff` — find files → **fff.nvim**
- `<leader>fr` — recent files → **fff.nvim** (fff keeps its own frecency db)
- `<leader>fs` — live grep → stays Telescope
- `<leader>fc` — grep word under cursor → stays Telescope
- `<leader>ft` — todos → stays Telescope
- `gd`, `gi`, `gR`, `gt`, `<leader>D` (LSP pickers) → stay Telescope

Telescope is still required by `plugin-terraform.lua`, `plugin-textcase.lua`,
`plugin-harpoon.lua`, and `plugin-lspconfig.lua`, so it is not removed.

## How to verify

- `:Lazy profile` — should show a shorter startup and fewer eager plugins.
- `:checkhealth blink.cmp` — confirm source list is smaller outside markdown.
- Type in a `.rs` file — completions should appear instantly; rust-analyzer
  results stream in without blocking.
- `:RustLsp` server status — rust-analyzer should settle to idle after indexing
  instead of running clippy continuously.

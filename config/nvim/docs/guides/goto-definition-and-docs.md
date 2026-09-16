# Go-to-definition, docs popups & Haskell navigation

How code navigation and documentation display are wired in this config, and the
design decisions behind them. Written after building the Haskell navigation
stack, but most of it (smart `gd`, auto-hover) is language-agnostic.

If you just want the keys, see the tables below. If you're here to *change*
something or understand *why* it's built this way, read the sections.

---

## The one navigation key: `gd`

`gd` is a **single smart key with a 3-tier fallback** — press it and it walks
down until something answers:

1. **LSP definition.** Ask the language server. If it has a definition, open it
   through the Telescope `lsp_definitions` picker (single result jumps, multiple
   let you choose).
2. **ctags.** If the LSP has nothing but a tag exists for the symbol (on the
   buffer's `&tags`), open it through the Telescope `tags` picker.
3. **Docs fallback (per-filetype, optional).** If 1 and 2 both miss, call the
   filetype's registered "open docs" handler. Haskell opens the symbol's
   Haddock/Hackage page in the browser via Hoogle. Languages with no registered
   handler just stop after tier 2 (a notification), exactly like the old `gd`.

**Why one key instead of separate maps:** you rarely know in advance whether a
symbol is local (LSP), in a dependency (ctags), or only reachable as docs
(Hoogle). Chaining means muscle memory is one key; the tiers are an
implementation detail.

- Code: [`lua/alex/lib/goto.lua`](../../lua/alex/lib/goto.lua) (generic).
- Wiring: bound as `gd` for **every** LSP buffer in
  [`plugin-lspconfig.lua`](../../lua/alex/plugins/lsp/plugin-lspconfig.lua)'s
  global `LspAttach` autocmd — so it applies to rust-analyzer, pyright, clangd,
  HLS, etc. Buffer-local, so it overrides the global `gd` from snacks/telescope
  in any LSP buffer.

### Extending tier 3 to another language

Tier 3 is a registry. From anywhere (ideally the language's plugin file):

```lua
require("alex.lib.goto").register_doc_fallback({ "rust" }, function(word)
  -- open docs for `word` however that language does it, e.g.
  -- vim.cmd.RustLsp("openDocs")  -- rustaceanvim
end)
```

Only Haskell registers one today (see below). rust-analyzer's
`experimental/externalDocs` (`:RustLsp openDocs`) is the obvious next candidate.

### Related keys (not `gd`)

| Key | Does |
|-----|------|
| `Ctrl-]` | Raw ctags jump (what tier 2 automates); `g]` shows the menu for overloaded names, `Ctrl-t` jumps back. |
| `gD` | LSP declaration. |
| `gR` / `gr` | References. |
| `gi` / `gt` | Implementations / type definition. |

---

## ctags with fast-tags (the tier-2 engine)

HLS (and some other servers) can't navigate into external dependencies
([HLS #708](https://github.com/haskell/haskell-language-server/issues/708)).
ctags fills that gap — name-based, no server, instant.

**Haskell tags are automatic:**

- On the first Haskell buffer of a project each session, HLS attaching triggers
  a background index build (installing [`fast-tags`](https://github.com/elaforge/fast-tags)
  via cabal if missing).
- On every save, the saved file's tags are refreshed incrementally (cheap).

**Where tags live and why:** Neovim's cache dir
(`~/.cache/nvim/haskell-tags/`), one file per project root plus a shared
`deps.tags`. **Not** in the repo (no stray `tags` file / `.gitignore` churn) and
**not** in the transient `~/.cache/hls-deps` source cache. Buffer-local `&tags`
points at absolute paths, so `Ctrl-]` (and tier 2 of `gd`) work regardless of
`:cd`.

| Command / key | Does |
|---------------|------|
| `:HsTags` / `<leader>ht` | (Re)generate the current project's index |
| `:HsTagsDeps` / `<leader>hT` | Index unpacked dependency sources (the `:HsDep` cache) into `deps.tags` |
| `:HsTagsInstall` | Install `fast-tags` via cabal |

To reach a **library**: `:HsDep aeson` unpacks its source into
`~/.cache/hls-deps`, then `:HsTagsDeps` indexes everything unpacked so far —
after which `Ctrl-]`/`gd` land inside those libraries.

The generator is also a standalone script (single source of truth; the editor
shells out to it):

```sh
config/nvim/scripts/haskell-tags.sh --out ~/.cache/nvim/haskell-tags/proj.tags .
config/nvim/scripts/haskell-tags.sh --help
```

**For other languages:** the tier-2 fallback works for any buffer with a tags
file on `&tags`. Generate one however you like (e.g. `ctags -R` with
universal-ctags), or mirror the fast-tags pattern with a per-filetype generator.

---

## Hoogle — two independent paths

There are two Hoogle entry points, and it's worth knowing which is which because
they do *not* share a backend.

| Key | Path | Goes through HLS? | What it does |
|-----|------|-------------------|--------------|
| `<leader>hs` | haskell-tools | **Yes** (`textDocument/hover`) | Gets the **type signature under the cursor** from HLS, Hoogle-searches it, shows results in haskell-tools' *own* Telescope picker (`hoogle.mode = "auto"`). Falls back to `<cword>` if no HLS client. |
| `<leader>hh` / `:Telescope hoogle` | `telescope_hoogle` extension | **No** | You *type* a name or type sig; queries the `hoogle` CLI directly. Standalone, works with or without HLS. |

haskell-tools does **not** delegate to the `telescope_hoogle` extension — they're
separate and coexist. `hoogle.mode = "auto"` only governs haskell-tools'
`<leader>hs` picker.

- `<leader>ho` / `:HsDocs [symbol]` — open the symbol's Haddock docs in the
  browser directly (same as `gd`'s tier 3, on demand).
- `:HsHoogleGenerate` / `<leader>hg` — build the **local** Hoogle database so
  everything works offline. Re-run after installing/upgrading packages.

**Mental model:** `gd` is for *navigating*; `<leader>hs`/`<leader>hh` are for
*searching/discovering* APIs (they land in a results picker, they don't jump to
your project source).

---

## Documentation popups (hover)

Three separate things show documentation — don't confuse them:

1. **Auto-hover on idle.** Rest the cursor on a symbol; after `updatetime` the
   LSP hover (types + docs) pops up automatically. Restored in
   [`core/autocmds.lua`](../../lua/alex/core/autocmds.lua) — toggle with
   `vim.g.auto_hover = false`.
2. **Manual hover (`K`).** The same hover, on demand. Also focusable (press `K`
   again / it grabs focus so you can scroll). Bound in `plugin-lspconfig.lua`
   (and per-language in `plugin-haskell.lua` / `plugin-rust.lua`).
3. **Completion docs.** The side window next to the blink completion menu
   (`blink … completion.documentation.auto_show = true`).

**Why auto-hover was rebuilt carefully:** an earlier version re-rendered a window
on every idle tick and fought blink. The current one is guarded:

- `CursorHold` only (normal mode) — never insert mode, so it can't collide with
  blink's completion-doc window.
- Skips if any floating window is already open — opens once, no per-tick
  flicker.
- Only fires when a hover-capable client is attached, in real file buffers.
- `focus = false` / `focusable = false` — display-only, never steals the cursor;
  the float auto-closes on move and re-opens on the next rest.

noice renders the hover (it overrides `vim.lsp.util` markdown display). Its
`lsp.hover.silent` is set to `true` so auto-hover doesn't flash "No information
available" when you rest on a symbol with no docs — see
[`plugin-noice.lua`](../../lua/alex/plugins/plugin-noice.lua).

**Styling** (both auto-hover and `K`, since both render through noice): the
popup has a rounded **green** border and inner padding so it lifts off the page.
Two knobs:

- Border/padding live in noice's `hover` view (`views.hover` in
  `plugin-noice.lua`) — `border.style`, `border.padding = { top/bottom, left/right }`.
- Position: `anchor = "NW"` + `position = { row = 3, col = 0 }` forces the popup
  *below* the symbol (the default `anchor = "auto"` flips it up over your code).
  Adjust `position.row` to move it up/down.
- The green colour is the `NoiceHoverBorder` highlight, defined in
  [`core/autocmds.lua`](../../lua/alex/core/autocmds.lua) (re-applied on
  `ColorScheme`). Change the `fg` there to recolour the border.

---

## Where each piece lives

| File | Role |
|------|------|
| [`lua/alex/lib/goto.lua`](../../lua/alex/lib/goto.lua) | Generic smart `gd` (LSP → ctags → per-filetype docs) + the doc-fallback registry |
| [`lua/alex/plugins/lsp/plugin-lspconfig.lua`](../../lua/alex/plugins/lsp/plugin-lspconfig.lua) | Binds `gd`/`K`/`gr`/… on `LspAttach` for all servers |
| [`lua/alex/plugins/plugin-haskell.lua`](../../lua/alex/plugins/plugin-haskell.lua) | Haskell ctags integration, Hoogle helpers, tier-3 docs registration, `:Hs*` commands |
| [`scripts/haskell-tags.sh`](../../scripts/haskell-tags.sh) | fast-tags generator (project / deps / incremental); shell-runnable |
| [`lua/alex/plugins/plugin-telescope.lua`](../../lua/alex/plugins/plugin-telescope.lua) | Loads the `telescope_hoogle` extension (`<leader>hh`) |
| [`lua/alex/core/autocmds.lua`](../../lua/alex/core/autocmds.lua) | Auto-hover on `CursorHold` |
| [`lua/alex/plugins/plugin-noice.lua`](../../lua/alex/plugins/plugin-noice.lua) | Renders hover; `lsp.hover.silent = true` |

Haskell-specific setup (toolchain, REPL, DAP, ghcid) is documented separately in
[`../haskell.md`](../haskell.md).

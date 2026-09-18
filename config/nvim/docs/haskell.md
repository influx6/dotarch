# Haskell in Neovim

Everything wired up for productive Haskell work: LSP, formatting, linting,
Hoogle, a GHCi REPL, a `ghcid` reload loop, and a stepping debugger.

Config lives in [`lua/alex/plugins/plugin-haskell.lua`](../lua/alex/plugins/plugin-haskell.lua)
(plus treesitter and conform entries — see [Where it's configured](#where-its-configured)).

---

## TL;DR keymaps

All keymaps are **buffer-local to Haskell files** (they only exist once HLS
attaches to a `.hs` buffer). `<leader>` is the space bar.

| Keymap        | What it does                                              |
|---------------|----------------------------------------------------------|
| **LSP / editing** | (HLS is running — standard `gd`, `gr`, `K`, `<leader>ca` etc. apply) |
| `<leader>cl`  | Run the code lens under the cursor (eval, add type sig…)  |
| `<leader>ea`  | Evaluate all `-- >>>` comment snippets in the buffer      |
| **Navigation / search** |                                                |
| `gd`          | Goto definition — **LSP → ctags → Hoogle docs** (3-tier fallback) |
| `Ctrl-]`      | Jump straight to the ctags definition (project **and** unpacked deps) |
| `<leader>hs`  | Hoogle search for the type signature under the cursor     |
| `<leader>hh`  | Hoogle search picker (Telescope)                          |
| `<leader>ho`  | Open the symbol's Haddock docs in the browser (`:HsDocs`) |
| `<leader>hd`  | Browse a dependency's unpacked source (`:HsDep`)          |
| `<leader>ht`  | (Re)generate this project's ctags                         |
| `<leader>hT`  | Index unpacked dependency sources into ctags              |
| `<leader>hg`  | Generate the local Hoogle database                        |
| **REPL (GHCi)** |                                                        |
| `<leader>rr`  | Toggle a GHCi REPL for the current **package**            |
| `<leader>rf`  | Toggle a GHCi REPL for the current **file**               |
| `<leader>rq`  | Quit the REPL                                             |
| **ghcid (reload loop)** |                                                |
| `<leader>rg`  | Toggle a `ghcid` watcher (recompiles + shows errors on save) |
| `<leader>rG`  | Same, but also re-runs `:main` on every reload           |
| **Debugging (DAP)** |                                                    |
| `<leader>dd`  | Discover launch configs from the cabal/stack project      |
| `<leader>dc`  | Start / continue a debug session                          |
| `<leader>dt`  | Toggle a breakpoint on the current line                   |
| `<leader>du`  | Toggle the debugger UI                                    |

> `<leader>dc`/`<leader>dt`/`<leader>du` are shared with the Rust debugger
> (defined in both `plugin-haskell.lua` and `plugin-rust.lua`).

---

## Which tool for which job

There are three overlapping "run my code" workflows. Pick by what you need:

- **`ghcid` (`<leader>rg`) — the everyday loop.** Fast, rock-solid
  save → errors/warnings → (optionally) rerun. No breakpoints. This is what
  you'll reach for 90% of the time. Robust across GHC versions.
- **GHCi REPL (`<leader>rr`) — poke at things interactively.** Load your
  package into `ghci`, call functions, inspect values by hand.
- **DAP debugger (`<leader>dd` → `<leader>dc`) — actual stepping.**
  Breakpoints, step in/over, inspect thunks. Powered by `haskell-debug-adapter`
  (a DAP wrapper over the built-in GHCi debugger `:break`/`:step`/`:trace`).
  Genuinely useful but more fragile — see [Debugging notes](#debugging-notes).

---

## Go-to-definition & search

Haskell navigation is layered, because HLS alone can't do it all (it still won't
`gd` into dependencies — upstream [HLS #708](https://github.com/haskell/haskell-language-server/issues/708)).
Three complementary layers, from most precise to most reaching:

**`gd` is a single smart key with a 3-tier fallback** — press it and it works
its way down until something answers. Implemented in
[`lua/alex/lib/goto.lua`](../lua/alex/lib/goto.lua), wired as `gd` for all LSP
buffers in `plugin-lspconfig.lua` (language-agnostic; the Haskell-specific tier 3
is registered from `plugin-haskell.lua`):

1. **LSP definition.** Asks HLS; if it has one, opens it through the Telescope
   picker (single result jumps, multiple let you choose). Its blind spot is
   external dependencies.
2. **ctags.** If HLS has nothing but a tag exists, opens it through the Telescope
   `tags` picker. [`fast-tags`](https://github.com/elaforge/fast-tags) indexes
   your project *and* (via `:HsTagsDeps`) unpacked dependency sources.
3. **Hoogle docs.** If LSP *and* ctags both miss — the symbol lives in a
   dependency whose source isn't indexed — it searches Hoogle and opens that
   symbol's **Haddock/Hackage docs page in your browser** (one match opens
   directly; several offer a chooser). You can at least read the API.

Related, always available:

- **`Ctrl-]`** — the raw ctags jump (what tier 2 automates), name-based; `g]`
  shows the menu for overloaded names.
- **`<leader>ho` / `:HsDocs [symbol]`** — trigger tier 3 (open Haddock docs)
  directly, without going through `gd`.
- **Hoogle search (`<leader>hs` / `<leader>hh`)** — search by name or type
  signature (`a -> [a] -> Bool`) when you don't have a cursor on the symbol.
  Uses the local DB if generated, else the web.

> Tier 3 is a per-filetype hook (`require("alex.lib.goto").register_doc_fallback`),
> so other languages can add their own "open docs" fallback; only Haskell
> registers one today.

### ctags with fast-tags

**It's automatic.** The first time you open a Haskell file in a project (per
session), the setup installs `fast-tags` if missing and generates the index in
the background. On every save, the saved file's tags are refreshed incrementally
(cheap). Then just hit `Ctrl-]` on a symbol; `Ctrl-t` jumps back.

Where the tags live and why:

- **In Neovim's cache** (`~/.cache/nvim/haskell-tags/`), one file per project
  root, plus a shared `deps.tags`. **Not** in your repo (no stray `tags` file to
  `.gitignore`) and **not** in the HLS dep-source cache (that dir is transient).
- Buffer-local `&tags` points at those **absolute** paths, so `Ctrl-]` works no
  matter what your `:cd` is.

Manual control:

| Command / key | What it does |
|---------------|--------------|
| `:HsTags` / `<leader>ht` | (Re)generate the current project's index |
| `:HsTagsDeps` / `<leader>hT` | Index the unpacked dependency sources (`:HsDep` cache) into `deps.tags` |
| `:HsTagsInstall` | Install `fast-tags` via cabal |

To jump into a **library**: `:HsDep aeson` unpacks its source into
`~/.cache/hls-deps`, then `:HsTagsDeps` (`<leader>hT`) indexes everything you've
unpacked so far — after that `Ctrl-]` lands inside those libraries too.

**From the shell**, the same generator is available standalone:

```sh
config/nvim/scripts/haskell-tags.sh --out ~/.cache/nvim/haskell-tags/proj.tags .
config/nvim/scripts/haskell-tags.sh --help
```

### Hoogle

There are **two independent Hoogle paths** — worth understanding which is which:

- `<leader>hs` — **HLS-level.** haskell-tools asks HLS (`textDocument/hover`) for
  the **type signature under the cursor**, then Hoogle-searches it. With
  `hoogle.mode = "auto"` it renders results in haskell-tools' *own* Telescope
  picker (local DB if a `hoogle` binary exists, else web; browser if Telescope
  is absent). If no HLS client is attached it falls back to the word under the
  cursor.
- `<leader>hh` / `:Telescope hoogle` — **standalone.** The `telescope_hoogle`
  extension queries the `hoogle` CLI directly (local DB, else web). It does *not*
  go through HLS, and haskell-tools does *not* delegate to it — the two coexist.
- `:HsHoogleGenerate` / `<leader>hg` — build the **local** Hoogle database so
  both paths work offline and instantly. Re-run after installing/upgrading
  packages so it reflects your current world (`hoogle generate`).

---

## Toolchain (where the binaries come from)

Neovim does **not** install the Haskell toolchain — it discovers binaries on
`PATH`. Manage them with [`ghcup`](https://www.haskell.org/ghcup/) and `cabal`.

| Binary                            | Provides                    | Installed via |
|-----------------------------------|-----------------------------|---------------|
| `ghc`, `cabal`, `stack`           | compiler + build tools      | ghcup         |
| `haskell-language-server-wrapper` | HLS (LSP); auto-matches the project's GHC | ghcup |
| `fourmolu`                        | formatter (used by conform) | mise / cabal  |
| `hlint`                           | linter (bundled into HLS)   | mise / cabal  |
| `ghcid`                           | reload loop                 | `cabal install ghcid` |
| `fast-tags`                       | ctags for `Ctrl-]` (auto-installed on first Haskell buffer) | `cabal install fast-tags` |
| `hoogle`                          | type/API search (`<leader>hh`/`<leader>hs`) | `cabal install hoogle` |
| `haskell-debug-adapter`, `ghci-dap` | DAP debugger              | cabal (see below) |

`cabal` installs executables to `~/.cabal/bin`, which is added to `PATH` in
[`shell/load_ghc`](../../../shell/load_ghc). HLS itself comes from ghcup (not
Mason) on purpose, so it always version-matches the GHC of the project you open.

Check what you have:

```sh
ghcup list -c installed
for b in ghc cabal hls fourmolu hlint ghcid haskell-debug-adapter; do
  printf '%-24s ' "$b"; command -v "$b" || echo MISSING
done
```

---

## Setup from scratch

```sh
# 1. Toolchain (compiler, cabal, stack, HLS)
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
ghcup install ghc recommended && ghcup set ghc recommended
ghcup install hls latest      && ghcup set hls latest

# 2. Formatter + linter (if not already via mise)
cabal install fourmolu hlint

# 3. ghcid reload loop
cabal install ghcid

# 4. Navigation & search: ctags + Hoogle
#    (fast-tags is also auto-installed the first time you open a Haskell file)
cabal install fast-tags hoogle
hoogle generate            # build the local Hoogle DB (or :HsHoogleGenerate)

# 5. DAP debugger  -- NOTE the hie-bios pin, see Debugging notes
cabal install haskell-debug-adapter ghci-dap --constraint 'hie-bios < 0.16'
```

Then open any `.hs` file in a cabal/stack project. On first launch, Neovim's
treesitter installs the `haskell` parser and HLS starts automatically.

---

## Formatting & linting

- **Formatter:** `fourmolu`, via `conform.nvim` (see
  [`plugin-conform.lua`](../lua/alex/plugins/plugin-conform.lua),
  `haskell = { "fourmolu" }`). Format-on-save is currently off; format with your
  normal conform keymap or `:lua require('conform').format()`. HLS is also set
  to use `fourmolu` so LSP formatting agrees. Both read the project's
  `fourmolu.yaml` (discovered upward from the file), so per-project style is
  picked up automatically — `ormolu` would ignore that file.
- **Linter:** `hlint` runs **inside HLS** — you get suggestions as diagnostics
  and `<leader>ca` code actions ("Apply hint"). No separate nvim-lint wiring.
- **`.cabal` files:** formatted with `cabalfmt` if installed
  (`cabal install cabal-fmt`).

---

## Debugging notes

`haskell-debug-adapter` is GHCi-based and historically finicky. Two things to
know:

1. **Build constraint.** Version `0.0.42.0` does not compile against
   `hie-bios >= 0.21` (an API change to `getCompilerOptions`). Pin it:

   ```sh
   cabal install haskell-debug-adapter ghci-dap --constraint 'hie-bios < 0.16'
   ```

2. **It's optional.** `plugin-haskell.lua` only registers the DAP adapter when
   the `haskell-debug-adapter` binary is on `PATH`. Without it, everything else
   (HLS, ghcid, REPL) still works; you'll just see a one-time notification that
   debugging is disabled.

Debugging flow: open a file in a cabal/stack project → `<leader>dd` to discover
launch configs → set breakpoints with `<leader>dt` → `<leader>dc` to start and
pick a config → `<leader>du` for the variables/stack UI. Under the hood the
adapter is registered as `dap.adapters.ghc` and configs land in
`dap.configurations.haskell`.

If stepping misbehaves, fall back to `ghcid` + `Debug.Trace`/`print` — it's the
more reliable loop.

---

## Where it's configured

| File | Role |
|------|------|
| [`lua/alex/plugins/plugin-haskell.lua`](../lua/alex/plugins/plugin-haskell.lua) | haskell-tools.nvim (HLS, Hoogle, REPL, DAP) + ghcid toggleterm helper + ctags integration |
| [`scripts/haskell-tags.sh`](../scripts/haskell-tags.sh) | fast-tags generator (project / deps / incremental); shell-runnable, and what the ctags integration shells out to |
| [`lua/alex/plugins/plugin-telescope.lua`](../lua/alex/plugins/plugin-telescope.lua) | `telescope_hoogle` extension (the `<leader>hh` picker) |
| [`lua/alex/plugins/plugin-treesitter.lua`](../lua/alex/plugins/plugin-treesitter.lua) | `haskell` parser in `ensure_installed` |
| [`lua/alex/plugins/plugin-conform.lua`](../lua/alex/plugins/plugin-conform.lua) | `haskell = { "fourmolu" }` |
| [`shell/load_ghc`](../../../shell/load_ghc) | ghcup + `~/.cabal/bin` on `PATH` |

The LSP is [`haskell-tools.nvim`](https://github.com/mrcjkb/haskell-tools.nvim)
(by the same author as `rustaceanvim`). Like rustaceanvim, it manages the
language server itself, so HLS is **not** registered through
Mason/`lspconfig` — don't add it there.

---

## Troubleshooting

- **HLS won't start / wrong GHC:** ensure `haskell-language-server-wrapper` is
  on `PATH` (`ghcup set hls latest`) and the project builds (`cabal build`).
  Check `:LspInfo` and `:checkhealth haskell-tools`.
- **`ghcid` keymap does nothing:** `ghcid` not installed
  (`cabal install ghcid`) or you're not in a project it can load. Run `ghcid`
  in the project dir from a shell to see the raw error.
- **No debugging:** `haskell-debug-adapter` not on `PATH` — see
  [Debugging notes](#debugging-notes) (mind the `hie-bios` pin).
- **`Ctrl-]` says "tag not found":** the index may still be generating (it runs
  in the background on first open), or `fast-tags` wasn't installed yet — run
  `:HsTags` (or `:HsTagsInstall` first). For symbols in a **dependency**, unpack
  it with `:HsDep <pkg>` then `:HsTagsDeps`. Check `:set tags?` to confirm the
  cache files are listed.
- **Hoogle picker empty / offline:** run `:HsHoogleGenerate` to build the local
  database (or ensure network access for the web fallback).
- **Plugin failed to clone:** if a plugin repo 404s, git prompts for a username
  and fails under Neovim ("terminal prompts disabled"). Fix the repo path in
  the spec — the URL is dead, not your credentials.

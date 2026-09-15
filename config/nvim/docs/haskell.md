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
| `<leader>hs`  | Hoogle search for the type signature under the cursor     |
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

## Toolchain (where the binaries come from)

Neovim does **not** install the Haskell toolchain — it discovers binaries on
`PATH`. Manage them with [`ghcup`](https://www.haskell.org/ghcup/) and `cabal`.

| Binary                            | Provides                    | Installed via |
|-----------------------------------|-----------------------------|---------------|
| `ghc`, `cabal`, `stack`           | compiler + build tools      | ghcup         |
| `haskell-language-server-wrapper` | HLS (LSP); auto-matches the project's GHC | ghcup |
| `ormolu`                          | formatter (used by conform) | mise / cabal  |
| `hlint`                           | linter (bundled into HLS)   | mise / cabal  |
| `ghcid`                           | reload loop                 | `cabal install ghcid` |
| `haskell-debug-adapter`, `ghci-dap` | DAP debugger              | cabal (see below) |

`cabal` installs executables to `~/.cabal/bin`, which is added to `PATH` in
[`shell/load_ghc`](../../../shell/load_ghc). HLS itself comes from ghcup (not
Mason) on purpose, so it always version-matches the GHC of the project you open.

Check what you have:

```sh
ghcup list -c installed
for b in ghc cabal hls ormolu hlint ghcid haskell-debug-adapter; do
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
cabal install ormolu hlint

# 3. ghcid reload loop
cabal install ghcid

# 4. DAP debugger  -- NOTE the hie-bios pin, see Debugging notes
cabal install haskell-debug-adapter ghci-dap --constraint 'hie-bios < 0.16'
```

Then open any `.hs` file in a cabal/stack project. On first launch, Neovim's
treesitter installs the `haskell` parser and HLS starts automatically.

---

## Formatting & linting

- **Formatter:** `ormolu`, via `conform.nvim` (see
  [`plugin-conform.lua`](../lua/alex/plugins/plugin-conform.lua),
  `haskell = { "ormolu" }`). Format-on-save is currently off; format with your
  normal conform keymap or `:lua require('conform').format()`. HLS is also set
  to use `ormolu` so LSP formatting agrees.
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
| [`lua/alex/plugins/plugin-haskell.lua`](../lua/alex/plugins/plugin-haskell.lua) | haskell-tools.nvim (HLS, Hoogle, REPL, DAP) + ghcid toggleterm helper |
| [`lua/alex/plugins/plugin-treesitter.lua`](../lua/alex/plugins/plugin-treesitter.lua) | `haskell` parser in `ensure_installed` |
| [`lua/alex/plugins/plugin-conform.lua`](../lua/alex/plugins/plugin-conform.lua) | `haskell = { "ormolu" }` |
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
- **Plugin failed to clone:** if a plugin repo 404s, git prompts for a username
  and fails under Neovim ("terminal prompts disabled"). Fix the repo path in
  the spec — the URL is dead, not your credentials.

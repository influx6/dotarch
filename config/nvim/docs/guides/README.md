# Guides

Task-focused how-tos for this Neovim config. (Reference material — full option
dumps, plugin configs — lives one level up in `docs/`.)

## Available guides

- [Searching Neovim's logs to find an error](searching-nvim-logs.md) —
  `:LogGrep` / `<leader>sL`: grep inside all log files at once when `:messages`
  is empty.
- [Yanking lines](yanking-lines.md) — `yy` and every yank/register/clipboard
  binding, plus the `<leader>y` file-path copies.
- [Go-to-definition, docs popups & Haskell navigation](goto-definition-and-docs.md)
  — the 3-tier `gd` (LSP → ctags → Hoogle docs), fast-tags, the two Hoogle
  paths, and the auto-hover popup. Language-agnostic where noted.

## Related reference

- [Where to look when something errors in Neovim](../troubleshooting-errors.md)
  — the map of every place errors hide (LSP log, per-plugin logs, startup
  stderr, async callbacks) and which to check for a given symptom.
- [Haskell / HLS setup](../haskell.md) — Haskell IDE tooling notes.

## Adding a guide

Drop a `kebab-case-name.md` in this folder and add a line to the list above.
Keep guides action-first: what the reader wants to do, the one command to do it,
then the how/why. Link to the relevant config file (e.g.
`../../lua/alex/core/logsearch.lua`) so the guide and the code stay connected.

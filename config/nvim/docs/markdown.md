# Markdown in Neovim

Live in-buffer rendering via
[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim):
headings, bold/italic, lists, tables, code blocks, links and callouts are drawn
with extmarks as you read, while the raw markdown underneath stays fully
editable. There is no preview window — you edit the markdown and see the
rendered result in the same buffer.

Config lives in
[`../lua/alex/plugins/plugin-markdown.lua`](../lua/alex/plugins/plugin-markdown.lua).

---

## TL;DR

| You want to… | Do this |
|---|---|
| Toggle rendering on/off | `<leader>um` |
| See which filetypes render | `markdown`, `markdown.mdx`, `org`, `rmd`, `norg`, `codecompanion` |
| Change rendering options | edit `opts` in `plugin-markdown.lua` |
| Reload after editing config | `:Lazy reload render-markdown.nvim` |
| Full option reference | `:h render-markdown` or the [README](https://github.com/MeanderingProgrammer/render-markdown.nvim) |

## How it loads

- **Lazy-loaded on filetype** (`ft = { … }`), so it costs nothing until you open
  one of the listed filetypes.
- Renders with **extmarks** — buffer contents are never modified, so editing,
  undo, LSP and spell-check all behave normally.
- Treesitter still does the syntax highlighting; render-markdown layers the
  visual rendering on top. The two coexist.

## Common tweaks

All options live in the `opts = { … }` block of `plugin-markdown.lua`. The ones
worth reaching for:

| Option | Here | What it controls |
|---|---|---|
| `code.conceal_delimiters` | `false` | Keep the ``` fences visible (`true` conceals them) |
| `code.width` | `"block"` | Background width: `"block"` = code width, `"full"` = window width |
| `code.left_pad` / `code.right_pad` | `1` | Padding inside the code block (cells; `< 1` = % of window) |
| `code.sign` | `false` | The sign-column marker next to code blocks |
| `heading.icons` | `{}` | Custom heading prefixes/icons |
| `checkbox.enabled` | `false` | Render `- [ ]` as actual checkboxes |

### Code blocks — padding and fences

The defaults here are intentional: **one cell of padding on both sides** and the
**``` fences left visible** (the language name still shows above the block):

```lua
code = {
  sign = false,
  width = "block",
  left_pad = 1,
  right_pad = 1,
  conceal_delimiters = false,
},
```

- Want more breathing room? Bump `left_pad` / `right_pad` to `2`.
- Want the fences hidden again? Set `conceal_delimiters = true`.
- Want the background to span the full window? Set `width = "full"` (then
  `right_pad` no longer applies).

### Enable checkbox rendering

```lua
checkbox = { enabled = true },
```

## Adding another filetype

Add it to the `ft` list in `plugin-markdown.lua`:

```lua
ft = { "markdown", "markdown.mdx", "norg", "rmd", "org", "codecompanion", "adoc" },
```

render-markdown needs the matching treesitter parser installed — see
[`../lua/alex/plugins/plugin-treesitter.lua`](../lua/alex/plugins/plugin-treesitter.lua).

## Related

- [Where to look when something errors in Neovim](troubleshooting-errors.md)
- [Guides](guides/README.md) — task-focused how-tos.

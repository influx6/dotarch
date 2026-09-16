# Guide: yanking lines (and everything around yank)

The short answer to "how do I yank a whole line without selecting it first":

```
yy      " yank the current line, in normal mode -- no visual select needed
```

`Y` does the same thing in this config (it's left at its default, `Y` = `yy`).
Because `clipboard` is set to `unnamedplus` (see `lua/alex/core/options.lua`),
that yank also lands in your **system clipboard** automatically — no `"+`
needed.

## Whole lines

| Keys | Yanks |
|---|---|
| `yy` / `Y` | the current line |
| `3yy` | 3 lines, starting at the cursor |
| `yj` / `y2j` | current line + 1 (or 2) below (motion `j`) |
| `yk` | current line + the one above |
| `yap` | a paragraph (with trailing blank line); `yip` = inner paragraph |
| `:%y` | the whole file |
| `:5,10y` | lines 5–10 (a range) |
| `:.,+3y` | current line + next 3 |

The cursor stays put on a line yank, so you can `yy` then move and `p`.

## Part of a line (no selecting either)

| Keys | Yanks |
|---|---|
| `y$` | cursor → end of line |
| `y0` / `y^` | cursor → start of line / first non-blank |
| `yw` / `yiw` | a word / inner word |
| `yi"` `ya(` … | inside/around text objects (quotes, brackets, tags) |

## Registers & the clipboard

Yanks go to the unnamed register **and** the system clipboard (`+`) by default
here. To be explicit or use a named register, prefix with `"<reg>`:

| Keys | Effect |
|---|---|
| `"+yy` | yank line explicitly to the system clipboard |
| `"ayy` | yank line into register `a` (append with `"Ayy`) |
| `"0p` | paste the last *yank* (register `0` survives deletes) |
| `:registers` | list every register's contents |

Deletes (`dd`, `x`) also fill the clipboard here; use register `0` (`"0p`) when
you want the last thing you *yanked*, not deleted.

## Pasting

| Keys | Effect |
|---|---|
| `p` / `P` | paste after / before the cursor (linewise for a line yank) |
| `]p` | paste and re-indent to the current line |
| `"+p` | paste from the system clipboard explicitly |

## Your custom yanks — file paths (not line content)

These copy the **current file's path** to the system clipboard (`+` register)
and show a confirmation notification. Defined in `lua/alex/core/keymaps.lua`;
visible in which-key under `<leader>y`.

| Key | Copies | Example |
|---|---|---|
| `<leader>ya` | absolute path (`%:p`) | `/home/you/Dev/talstack/src/Talstack/Web/Routes.hs` |
| `<leader>yr` | path relative to cwd (`%:.`) | `src/Talstack/Web/Routes.hs` |
| `<leader>yf` | filename (`%:t`) | `Routes.hs` |
| `<leader>yb` | basename, no extension (`%:t:r`) | `Routes` |

## Handy extras

- **Yank a line and keep your place after moving:** `yy` doesn't move the
  cursor, so `yyp` duplicates the current line below.
- **Yank a visual selection without the cursor jumping to the top:** in visual
  mode `y` leaves you at the selection start; ``y`>`` (yank, then jump to the
  end mark) if you'd rather end up at the bottom.
- **Repeat a yank across lines quickly:** `V` then `j`/`k` to grow a linewise
  selection, `y` to yank — but for a fixed count `3yy` is faster than selecting.

# Atuin configuration

[Atuin](https://atuin.sh) replaces the shell's history with a synced, searchable
history and an interactive search UI. This directory holds its configuration
alongside `config.toml`.

- **Config file:** `config.toml`
- **Loaded by:** `eval "$(atuin init zsh)"` in `~/.zshrc`, plus
  `shell/load_atuin` (sourced from `shell/config`).

> Note: `~/.config/atuin/config.toml` is a *copy* of this file, not a symlink —
> `shell/load_symlinks` links the whole `atuin` dir but `~/.config/atuin` already
> exists as a real directory, so a nested `atuin -> dotarch/config/atuin` link is
> created instead. Keep the two copies in sync when you edit either one.

## Shell-level keybindings

These are set by `atuin init zsh` and the overrides at the bottom of
`shell/load_atuin`. They fire while you are at the prompt (not inside the TUI).

| Key | Mode | Widget | Purpose |
|-----|------|--------|---------|
| `↑` (up arrow) | emacs / viins / vicmd | `atuin-up-search` | Open history search (kept — this is the primary shortcut) |
| `Ctrl-r` | emacs / viins | `atuin-search` | Open history search |
| `?` | vicmd (vim normal) | `atuin-up-search-vicmd` | Open history search — **rebound here from `k`** |
| `k` | vicmd (vim normal) | `up-line-or-history` | **Vim navigation** — restored so `k` moves up a line, not history search |
| `/` | vicmd (vim normal) | `atuin-search` | Open history search |

> Atuin's default `init zsh` binds `k` (in vim command mode) to its history
> search. Because we use vim navigation, `shell/load_atuin` rebinds `k` back to
> `up-line-or-history` and moves that history-search trigger to `?`. The up-arrow
> binding is intentionally left alone.

## TUI keybindings (inside the search UI)

Once the search UI is open, navigation depends on the `keymap_mode` in
`config.toml`:

| `keymap_mode` | Behavior |
|---------------|----------|
| `emacs` | Emacs-style editing (default) |
| `vim-insert` | Starts in insert mode; `esc` enters normal mode |
| `vim-normal` | Vim-style `h`/`j`/`k`/`l` navigation |
| `auto` | Follows the shell's keymap |

### Common keys (emacs / vim-insert)

| Key | Action |
|-----|--------|
| `↑` / `↓` or `Ctrl-n` / `Ctrl-p` | Move selection up / down |
| `Ctrl-j` / `Ctrl-k` | Move selection down / up |
| `Enter` | Accept selected entry and run it (see `enter_accept`) |
| `Tab` / `→` | Put the selection on the command line for editing |
| `Esc` / `Ctrl-[` | Exit the UI |
| `Ctrl-r` | Cycle filter mode |
| `Ctrl-s` | Cycle search mode |
| `Ctrl-y` | Copy selection to clipboard |
| `Ctrl-u` | Clear the input line |
| `Ctrl-w` | Delete word before cursor |
| `Ctrl-h` / `Backspace` | Delete character before cursor |
| `Ctrl-d` | Delete char after cursor (or exit if input is empty) |
| `Ctrl-l` | Redraw |
| `Ctrl-b` / `Ctrl-f` | Move cursor left / right |
| `Alt-b` / `Alt-f` | Move cursor word-left / word-right |
| `Ctrl-a` / `Ctrl-e` | Move cursor to start / end of line |
| `Alt-1` … `Alt-9` | Return the Nth entry without executing |

### Vim normal mode

| Key | Action |
|-----|--------|
| `j` / `k` | Move selection down / up |
| `h` / `l` | Move cursor left / right |
| `0` / `$` | Cursor to start / end of line |
| `w` / `b` / `e` | Word motion (right / left / end) |
| `i` / `a` / `A` / `I` | Enter insert mode |
| `x` | Delete character after cursor |
| `d d` | Clear the input line |
| `D` | Clear to end of line |
| `C` | Delete to end of line and enter insert mode |
| `g g` / `G` | Jump to top / bottom of results |
| `H` / `M` / `L` | Jump to top / middle / bottom of the visible screen |
| `Ctrl-u` / `Ctrl-d` | Half-page up / down |
| `Ctrl-b` / `Ctrl-f` | Full page up / down |
| `/` / `?` | Clear input and enter insert mode (search) |
| `Esc` / `Ctrl-[` | Exit the UI |
| `Enter` | Accept selected entry and run it |

## Customizing keybindings

Atuin 18+ exposes every binding via `[keymap.*]` tables in `config.toml`. When
any `[keymap]` setting is present, the legacy `[keys]` section is ignored
entirely. You only list the keys you want to change; unmentioned keys keep
their defaults.

Sections: `[keymap.emacs]`, `[keymap.vim-normal]`, `[keymap.vim-insert]`,
`[keymap.inspector]`, `[keymap.prefix]`.

Keys are written as TOML strings (`"ctrl-c"`, `"alt-f"`, `"g g"` for a
sequence). Disable a binding with `noop`:

```toml
[keymap.vim-normal]
"h" = "noop"   # disable h navigation
"x" = "delete" # rebind x to delete the selected entry
```

Conditional rules let one key do different things by state:

```toml
[keymap.emacs]
"down" = [
  { when = "list-at-start", action = "exit" },
  { action = "select-next" },
]
```

Common actions: `select-next`, `select-previous`, `accept`,
`return-selection`, `return-original`, `exit`, `cursor-left`, `cursor-right`,
`delete-char-before`, `clear-line`, `copy`, `delete`, `toggle-tab`,
`vim-enter-normal`, `vim-enter-insert`, `noop`.

See the upstream docs for the full action list and condition reference:
<https://docs.atuin.sh/configuration/advanced-key-binding/>

# OmniWM

[Niri-style](https://omniwm.app) tiling window manager for macOS, and the
replacement for the previous `yabai` + `skhd` setup.

The single file in this directory — `settings.toml` — is the **complete**
OmniWM configuration. It is symlinked into place by the macOS installer:

```
~/.config/omniwm/settings.toml  ->  config/omniwm/settings.toml
```

OmniWM **live-reloads** this file on save, so edits take effect immediately
(no restart). The Settings GUI also rewrites it in place, and because it is a
schema-versioned snapshot (`schemaVersion = 4`), every section is required —
don't strip a section out by hand.

---

## Modifier layers (the mental model)

The keybindings are arranged in four `Alt`-led layers, preserving the old
yabai/skhd muscle memory. `Alt` here is the macOS **Option (⌥)** key — the
config file spells it `Option`, this document spells it `Alt`.

| Layer | Leader | Purpose |
|---|---|---|
| Focus | `Alt` | move focus, switch workspaces |
| Move | `Alt+Shift` | move windows, move to workspace/monitor, float/fullscreen |
| Column | `Ctrl+Alt` | reorder columns, balance, palette/menus |
| Resize | `Ctrl+Shift` | directional window/column sizing |

---

## Keybindings

### Focus — `Alt`

| Keys | Action |
|---|---|
| `Alt+H` | Focus left (west) |
| `Alt+J` | Focus down (south) |
| `Alt+K` | Focus up (north) |
| `Alt+L` | Focus right (east) |
| `Alt+S` / `Alt+G` | Focus previous / next monitor |
| `Ctrl+Cmd+Grave` | Focus last monitor |
| `Alt+Tab` | Focus previous window (focus history) |

### Workspaces — `Alt+1…9`

| Keys | Action |
|---|---|
| `Alt+1` … `Alt+9` | Switch to workspace 1–9 |
| `Ctrl+Alt+Tab` | Back-and-forth between the last two workspaces |

### Move — `Alt+Shift`

| Keys | Action |
|---|---|
| `Alt+Shift+H/J/K/L` | Move focused window left/down/up/right |
| `Alt+Shift+1…9` | Move window to workspace 1–9 |
| `Alt+Shift+S` / `Alt+Shift+G` | Move window to left / right monitor |
| `Alt+Shift+P` / `Alt+Shift+N` | Move window to workspace up / down |
| `Alt+Shift+T` | Toggle float on the focused window |
| `Alt+Shift+M` | Toggle fullscreen |
| `Alt+Shift+R` | Toggle workspace layout (niri ⇄ dwindle) |
| `Alt+Shift+O` | Toggle overview |

### Column — `Ctrl+Alt`

| Keys | Action |
|---|---|
| `Ctrl+Alt+H` / `Ctrl+Alt+L` | Move focused column left / right |
| `Ctrl+Alt+K` / `Ctrl+Alt+J` | Move column up / down (dwindle-only; no-op in niri) |
| `Ctrl+Alt+E` | Balance column sizes |
| `Ctrl+Alt+Space` | Open command palette |
| `Ctrl+Alt+M` | Open menu anywhere |
| `Ctrl+Alt+Tab` | Workspace back-and-forth |

### Resize — `Ctrl+Shift`

Directional resize, in vim terms:

| Keys | Action |
|---|---|
| `Ctrl+Shift+H` | Shrink column width (narrower) — *left* |
| `Ctrl+Shift+L` | Grow column width (wider) — *right* |
| `Ctrl+Shift+K` | Grow window height (taller) — *up* |
| `Ctrl+Shift+J` | Shrink window height (shorter) — *down* |

These map onto OmniWM's niri sizing actions:

- **primary span** (`Ctrl+Shift+H/L`) = the focused column's width
- **secondary span** (`Ctrl+Shift+K/J`) = a window's height within its column

> ⚠️ Resize is only visible when there is something to resize: column width
> needs **≥ 2 columns**, and window height needs **≥ 2 windows stacked in one
> column**. A single full-width window (`singleWindowFit = "fill"`) shows no
> change on either axis — that is expected, not a broken binding.

### Misc — `Alt`

| Keys | Action |
|---|---|
| `Alt+Grave` | Toggle quake terminal |

---

## Mouse & trackpad

| Gesture | Action |
|---|---|
| `Option` + left-drag | Move the window under the cursor |
| `Option` + right-drag | Resize the window under the cursor |
| 3-finger scroll + `Option+Shift` | Scroll between niri columns |

Trackpad window-move / window-resize gestures, workspace swipes, and the
overview gesture are all **disabled** (see `[gestures]`) in favour of the
keyboard and mouse mappings above.

---

## Workspaces

Nine workspaces, named `1`–`9`, all in the **niri** layout:

| Workspace | Display | Monitor |
|---|---|---|
| 1–7 | `1`…`7` | main |
| 8 | ❤️ | **secondary** |
| 9 | 🚀 | **secondary** |

The two secondary-display workspaces are the *last two* (`8` and `9`), reached
with `Alt+8` / `Alt+9`.

---

## Settings highlights

The file is mostly stock OmniWM with a few intentional deviations:

- **Layout** — `niri` is the default; `[niri]` sets 2 visible containers,
  5% resize step, and primary-span presets `⅓ / ½ / ⅔`.
- **Gaps** — 12px inner + outer, mirroring the old yabai padding.
- **Borders** — 5px, in a green accent matching the old yabai focus border.
- **Focus** — `followsMouse = false` (explicit keyboard focus only).
- **IPC** — `general.ipcEnabled = true`, so `omniwmctl` can drive anything the
  built-in keybindings don't cover.
- **Quake terminal** — enabled, centered at 50%×50%, toggled with `Alt+Grave`.
- **Workspace bar / hidden bar** — enabled.

### App rules

`[[appRules]]` holds OmniWM's stock minimum-size rules for common apps
(Chrome, Safari, Zed, Firefox, Discord, Outlook, …), plus the old yabai
`manage=off` list translated to **float**:

- System Settings (`com.apple.systempreferences`)
- Calculator (`com.apple.calculator`)
- Karabiner-Elements (`org.pqrs.Karabiner-Elements`)
- Ghostty quick-terminal floating panel (`com.mitchellh.ghostty`, `AXFloatingWindow`)

---

## Command-line control

With IPC enabled, `omniwmctl` (installed at `/opt/homebrew/bin/omniwmctl`) can
drive OmniWM for anything not covered by the keybindings. A few useful calls:

```sh
omniwmctl ping                    # is OmniWM running?
omniwmctl version                 # version + protocol
omniwmctl command focus right     # same as Alt+L
omniwmctl command resize horizontal grow
omniwmctl query workspaces --format json
omniwmctl subscribe windows-changed
```

Run `omniwmctl help` for the full command list.

---

## Notes & troubleshooting

- **`skhd` is kept but unused.** Its config (`config/skhd/skhdrc`) is
  intentionally empty; all window-manager keys now live here in OmniWM's own
  `hotkeys` array. `skhd` remains installed/started as an escape hatch for any
  future non-WM hotkeys.
- **A shortcut doesn't fire?** Check **Settings → Keyboard Shortcuts** and
  **Settings → Troubleshooting** for registration issues, then look for another
  hotkey tool (skhd, Raycast, Karabiner) holding the same chord. Bindings that
  use only `Alt` can pause while another app holds Secure Input (e.g. a
  password prompt); chords that include `Ctrl` or `Cmd` keep working.
- **Resize appears to do nothing** — see the note under Resize: it only shows
  when there are multiple columns (width) or multiple stacked windows (height).
- **Key names** in `binding` are human-readable (`H`, `1`, `Equal`, `Minus`,
  `Grave`, `Tab`, `Space`, `Left Arrow` …); modifiers are written in
  `Control+Option+Shift+Command` order.

---

## Editing

1. Edit `settings.toml` (this file) — OmniWM live-reloads on save.
2. For per-app float/min-size rules, the Settings GUI is often easier than hand-editing the `appRules` array.
3. Commit the result; the dotfiles installer re-symlinks on next run.

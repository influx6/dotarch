# macOS installers

Scripts to install and configure macOS tooling. Each script sources
`$DOTFILES/shell/load_functions`, uses the shared `no_command`/`has_command`
helpers, and is idempotent — safe to re-run.

## Run everything

```bash
DOTFILES=/path/to/dotarch bash installers/macosx/install.sh
```

If `$DOTFILES` is already exported, just run `./installers/macosx/install.sh`.
The entrypoint refuses to run on non-macOS systems.

## Layout

| Path | What it does |
| --- | --- |
| `install.sh` | Orchestrator — runs the steps below in order. |
| `core/brew.sh` | Installs Homebrew and loads its shellenv (Apple Silicon / Intel). |
| `development/openjdk.sh` | Installs OpenJDK and links it for `/usr/libexec/java_home`. |
| `desktop/yabai.sh` | Installs [yabai], symlinks the config, starts the service. |
| `desktop/skhd.sh` | Installs [skhd], symlinks the config, starts the service. |

Each installer can also be run on its own (with `$DOTFILES` set).

## yabai + skhd

Window-manager config lives with the rest of the dotfiles and is symlinked
into place by the installers:

- `config/yabai/yabairc` → `~/.config/yabai/yabairc` (made executable)
- `config/skhd/skhdrc`  → `~/.config/skhd/skhdrc`

Keybindings and layout are inspired by
<https://www.josean.com/posts/yabai-setup> — `alt` (option) is the leader:
`alt - h/j/k/l` moves focus, `shift + alt - …` swaps/moves windows and spaces.
See `config/skhd/skhdrc` for the full list.

The base tiling setup works **without disabling SIP**. The optional scripting
addition (borders, opacity, extra space operations) requires partially
disabling SIP and a sudoers entry — see the note printed by `desktop/yabai.sh`.

On first launch, grant **Accessibility** (and **Input Monitoring** for skhd)
under System Settings → Privacy & Security, then restart the services:

```bash
yabai --restart-service
skhd --restart-service
```

[yabai]: https://github.com/koekeishiya/yabai
[skhd]: https://github.com/koekeishiya/skhd

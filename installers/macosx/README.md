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
| `development/cli.sh` | Core CLI tooling via brew (ripgrep, neovim, tmux, zellij, go, gnupg, sops, …). |
| `development/openjdk.sh` | Installs OpenJDK and links it for `/usr/libexec/java_home`. |
| `desktop/yabai.sh` | Installs [yabai], symlinks the config, starts the service. |
| `desktop/skhd.sh` | Installs [skhd], symlinks the config, starts the service. |
| `apps/casks.sh` | GUI apps via brew cask (orbstack). |
| `config/spaces-hotkeys.sh` | Enables `Ctrl + 1..9` to switch Mission Control desktops. |

The orchestrator also runs the shared, cross-platform toolchain installers in
`installers/every/`: `rust.sh` (rustup), `ghc.sh` (ghcup), `mise.sh`,
`ohmyzsh.sh` and `ohmybash.sh`.

Each installer can also be run on its own (with `$DOTFILES` set).

Language runtimes (`node`, `python`, `ruby`, `fzf`, `wrangler`) are managed by
**mise** from `config/mise/config.toml`, not brew — so they're not duplicated in
`development/cli.sh`.

## Spaces: Ctrl + 1..9

`config/spaces-hotkeys.sh` wires up `Ctrl + <n>` to jump straight to desktop
_n_. macOS leaves most of these unset by default (which is why switching dies
past `Ctrl+4`). The shortcuts only fire for desktops that **exist**, so create
9 desktops in Mission Control first. A logout/login may be needed for all nine
to take effect.

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

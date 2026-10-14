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
| `desktop/omniwm.sh` | Installs [OmniWM], symlinks the config. |
| `desktop/skhd.sh` | Installs [skhd], symlinks the (now empty) config, starts the service. |
| `desktop/fonts.sh` | Installs fonts via Homebrew Cask (JetBrains Mono Nerd Font). |
| `apps/casks.sh` | GUI apps via brew cask (orbstack). |
| `apps/screen-tools.sh` | Screenshot / screen-recording / GIF tools (shottr, kap, licecap, screen-studio, xnapper + ffmpeg/gifski/gifsicle/imagemagick/vhs). |
| `config/spaces-hotkeys.sh` | Enables `Ctrl + 1..9` to switch Mission Control desktops. |

The orchestrator also runs the shared, cross-platform toolchain installers in
`installers/every/`: `rust.sh` (rustup), `ghc.sh` (ghcup), `mise.sh`,
`ohmyzsh.sh` and `ohmybash.sh`.

Each installer can also be run on its own (with `$DOTFILES` set).

## On demand (`install_one` / `install_all`)

`shell/load_installer` exposes two shell functions (available in any interactive
shell) that resolve scripts for the current OS — on macOS they search
`installers/macosx` then `installers/every`:

```bash
install_one omniwm         # installers/macosx/desktop/omniwm.sh
install_one skhd           # installers/macosx/desktop/skhd.sh
install_one fonts          # installers/macosx/desktop/fonts.sh
install_one spaces-hotkeys # installers/macosx/config/spaces-hotkeys.sh
install_one git-agecrypt   # falls back to installers/every/git-agecrypt.sh

install_all desktop        # every *.sh in installers/macosx/desktop/
install_all config         # ... /config/   (e.g. spaces-hotkeys)
install_all development     # ... /development/ (cli, openjdk)
install_all apps           # ... /apps/      (casks)
```

Language runtimes (`node`, `python`, `ruby`, `fzf`, `wrangler`) are managed by
**mise** from `config/mise/config.toml`, not brew — so they're not duplicated in
`development/cli.sh`.

## Spaces: Ctrl + 1..9

`config/spaces-hotkeys.sh` wires up `Ctrl + <n>` to jump straight to desktop
_n_. macOS leaves most of these unset by default (which is why switching dies
past `Ctrl+4`). The shortcuts only fire for desktops that **exist**, so create
9 desktops in Mission Control first. A logout/login may be needed for all nine
to take effect.

## OmniWM + skhd

Window-manager config lives with the rest of the dotfiles and is symlinked
into place by the installers:

- `config/omniwm/settings.toml` → `~/.config/omniwm/settings.toml`
- `config/skhd/skhdrc`         → `~/.config/skhd/skhdrc` (empty; see below)

[OmniWM] is a Niri-style tiling window manager for macOS (Apple Silicon,
macOS 26+). It ships its own keybinding manager — bindings live in the
`hotkeys` array of `settings.toml` — so the vim-style `alt` (option) keymap is
defined natively in `config/omniwm/settings.toml` rather than in skhd. The file
is a complete, live-reloaded snapshot (also editable via Settings), so it must
stay whole — see the header comment in the file for what differs from OmniWM's
defaults.

**skhd is retained but intentionally empty**: the installer still installs and
starts it, so it's available for any future non-WM hotkeys, but no keybindings
are configured in it. OmniWM's IPC is enabled (`general.ipcEnabled = true`), so
`omniwmctl` is on PATH as an optional escape hatch for anything the built-in
bindings can't express (e.g. `omniwmctl command consume-or-expel-window-left`).

On first launch, grant **Accessibility** and **Input Monitoring** under System
Settings → Privacy & Security, turn off **"Displays have separate Spaces"** in
Desktop & Dock → Mission Control, then click **Start OmniWM** in the app.

**yabai is retired.** `desktop/yabai.sh` and `config/yabai/yabairc` are kept in
the repo for reference but are no longer wired into the default install flow.
If you had yabai running, stop it so it doesn't tile alongside OmniWM:

```bash
yabai --stop-service
brew services stop yabai
```

[omniwm]: https://omniwm.app
[skhd]: https://github.com/koekeishiya/skhd

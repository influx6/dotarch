#!/bin/bash

# macOS installer entrypoint.
#
# Usage:
#   DOTFILES=/path/to/dotarch bash installers/macosx/install.sh
# or, with $DOTFILES already exported in your shell:
#   ./installers/macosx/install.sh

# Resolve DOTFILES if the caller didn't export it.
if [ -z "$DOTFILES" ]; then
  DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  export DOTFILES
fi

source "$DOTFILES/shell/load_functions"

if ! is_mac; then
  echo "installers/macosx is only for macOS. Aborting."
  exit 1
fi

MACOS="$DOTFILES/installers/macosx"
EVERY="$DOTFILES/installers/every"

# All steps are idempotent and safe to re-run.

# brew is sourced (not run) so its shellenv is available to later steps.
source "$MACOS/core/brew.sh"

# Shared, cross-platform toolchains (official installers; live in every/).
source "$EVERY/rust.sh"     # rustup + stable toolchain
source "$EVERY/ghc.sh"      # ghcup: ghc / cabal / stack + haskell tools
source "$EVERY/mise.sh"     # mise + tools pinned in config/mise/config.toml
source "$EVERY/ohmyzsh.sh"  # oh-my-zsh
source "$EVERY/ohmybash.sh" # oh-my-bash

# macOS packages.
source "$MACOS/development/cli.sh"     # brew CLI tooling
source "$MACOS/development/openjdk.sh" # openjdk (+ link into /Library/Java)
source "$MACOS/desktop/yabai.sh"       # tiling WM
source "$MACOS/desktop/skhd.sh"        # hotkey daemon
source "$MACOS/desktop/fonts.sh"       # fonts (JetBrains Mono Nerd Font)
source "$MACOS/apps/casks.sh"          # GUI apps (orbstack)
source "$MACOS/apps/screen-tools.sh"   # screenshot / recording / gif tools

# macOS system tweaks.
source "$MACOS/config/spaces-hotkeys.sh" # Ctrl+1..9 -> switch desktops

echo
echo "macOS setup complete."

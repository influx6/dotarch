#!/bin/bash

source "$DOTFILES/shell/load_functions"

# Fonts via Homebrew Cask (macOS).
# JetBrains Mono Nerd Font — matches config/ghostty/config and the Neovim icon
# plugins (bufferline devicons, aerial, blink-nerdfont).
if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
  brew install --cask font-jetbrains-mono-nerd-font
fi

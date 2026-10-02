#!/bin/bash

source $DOTFILES/shell/load_functions

# GUI apps via Homebrew Cask (macOS).
# orbstack: fast Docker/Linux VM runtime (Docker Desktop replacement).
if ! brew list --cask orbstack &>/dev/null; then
  brew install --cask orbstack
fi

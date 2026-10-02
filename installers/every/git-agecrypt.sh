#!/bin/bash

source $DOTFILES/shell/load_functions

# Transparent age encryption for git (clean/smudge filters), with the age
# private key stored in 1Password. See docs/secrets.md for the full setup.
#
# This installs the three pieces:
#   age          - encryption backend
#   op           - 1Password CLI (holds the age key)
#   git-agecrypt - the git clean/smudge filter (not in brew; built from source)

# --- age --------------------------------------------------------------------
if no_command age; then
  if is_mac && has_command brew; then
    brew install age
  elif is_archlinux; then
    yay -S --noconfirm --needed age
  elif is_ubuntu; then
    sudo apt-get update && sudo apt-get install -y age
  fi
fi

# --- op (1Password CLI) -----------------------------------------------------
if no_command op; then
  if is_mac && has_command brew; then
    brew install --cask 1password-cli
  else
    echo "Install the 1Password CLI for your OS:"
    echo "  https://developer.1password.com/docs/cli/get-started/"
  fi
fi

# --- git-agecrypt -----------------------------------------------------------
if no_command git-agecrypt; then
  if has_command cargo; then
    cargo install --git https://github.com/vlaci/git-agecrypt
  else
    echo "cargo not found. Run installers/every/rust.sh first, then re-run this."
  fi
fi

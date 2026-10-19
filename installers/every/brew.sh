#!/bin/bash

source $DOTFILES/shell/load_functions

# Homebrew bootstrap (macOS + Linux). Ensures `brew` is on PATH for the rest of
# this run, then leaves the caller to install formulae.

if no_command brew; then
  echo "Installing Homebrew.."
  /bin/bash -c "$(fetch https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available for the rest of this run (any supported prefix).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
  eval "$($HOME/.linuxbrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

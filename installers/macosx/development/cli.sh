#!/bin/bash

source $DOTFILES/shell/load_functions

# Core CLI tooling via Homebrew (macOS).
#
# Deliberately NOT here:
#   - node / python / ruby / fzf / wrangler  -> managed by mise (every/mise.sh)
#   - openjdk                                -> development/openjdk.sh (also links JDK)
#   - yabai / skhd                           -> desktop/*.sh
#   - orbstack                               -> apps/casks.sh

brew install \
  atuin \
  direnv \
  ripgrep \
  neovim \
  tmux \
  zellij \
  go \
  gnupg \
  git-crypt \
  sops \
  cmake \
  cmake-docs \
  pkgconf \
  protobuf \
  snappy \
  libpq \
  lld \
  lldb \
  gdb \
  ollama

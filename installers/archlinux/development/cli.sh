#!/bin/bash

source $DOTFILES/shell/load_functions

# Core CLI tooling (Arch), mirroring the macOS brew bundle in
# installers/macosx/development/cli.sh.
#
# Deliberately NOT here:
#   - node / python / ruby / fzf / wrangler  -> managed by mise (every/mise.sh)
#   - rust                                   -> every/rust.sh (rustup)
#   - ghc / cabal / stack                    -> every/ghc.sh (ghcup)

yay -S --noconfirm --needed \
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
  pkgconf \
  protobuf \
  snappy \
  postgresql-libs \
  llvm \
  lld \
  lldb \
  gdb \
  ollama \
  fd \
  lazygit \
  wget \
  ctags \
  mercurial \
  ghostscript \
  tectonic \
  mermaid-cli \
  php \
  composer \
  julia

# Neovim remote-plugin providers (node pynvim / ruby neovim gem).
source "$DOTFILES/installers/every/nvim.sh"

#!/bin/env bash

source $DOTFILES/shell/load_functions

# install rustup + the stable toolchain (non-interactive)
if no_command rustup; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
fi

if has_command rustup; then
  rustup component add rust-src rust-analyzer clippy rustfmt
fi

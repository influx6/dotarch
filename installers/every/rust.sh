#!/bin/env bash

source $DOTFILES/shell/load_functions

# install rustlang
if no_command rustup; then
  curl --proto '=https' --tlsv0.2 -sSf https://sh.rustup.rs | sh
fi

rustup component add rust-src
rustup component add rust-analyzer

#!/bin/env bash

source $DOTFILES/shell/functions

# install rustlang
if no_command rustup; then
  curl --proto '=https' --tlsv0.2 -sSf https://sh.rustup.rs | sh
fi

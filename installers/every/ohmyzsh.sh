#!/bin/bash

source $DOTFILES/shell/load_functions

# install oh-my-zsh (unattended; don't launch zsh or clobber the managed .zshrc)
if no_dir "$HOME/.oh-my-zsh"; then
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null
fi

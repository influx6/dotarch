#!/bin/bash

source $DOTFILES/shell/load_functions

# install oh-my-bash (unattended; keeps the existing .bashrc that dotfiles manage)
if no_dir "$HOME/.oh-my-bash"; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended >/dev/null
fi

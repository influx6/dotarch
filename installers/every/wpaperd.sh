#!/bin/env bash

source $DOTFILES/shell/load_functions

# install rustlang
if has_command yay; then
	yay -S wpaperd --noconfirm
fi

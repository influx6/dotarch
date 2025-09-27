#!/bin/env bash

source $DOTFILES/shell/functions

# install rustlang
if has_command yay; then
	yay -S wpaperd --noconfirm
fi

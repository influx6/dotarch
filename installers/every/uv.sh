#!/bin/bash

source $DOTFILES/shell/load_functions

if no_command uv; then
	fetch https://astral.sh/uv/install.sh | sh
fi

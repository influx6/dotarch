#!/bin/bash

source $DOTFILES/shell/functions

if no_command uv; then
	curl -LsSf https://astral.sh/uv/install.sh | sh
fi

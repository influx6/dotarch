#!/bin/bash

source $DOTFILES/shell/functions

if has_command npm; then
	npm install -g neovim
fi

if has_command pipx; then
	pipx install --upgrade pynvim
fi

if has_command uv; then
	uv tool install --upgrade pynvim
fi

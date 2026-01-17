#!/bin/bash

source $DOTFILES/shell/functions

if no_command uv; then
	curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if no_command ruby; then
	mise install ruby
fi

if has_command gem; then
	gem install neovim
fi

if has_command npm; then
	npm install -g neovim
fi

if has_command pipx; then
	pip install --upgrade pynvim
fi

if has_command uv; then
	uv tool install --upgrade pynvim
fi

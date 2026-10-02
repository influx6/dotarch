#!/bin/bash

source $DOTFILES/shell/load_functions

# install mise (polyglot runtime/tool manager)
if no_command mise; then
  curl https://mise.run | sh
fi

# mise lands in ~/.local/bin; make sure it's reachable for the rest of this run.
export PATH="$HOME/.local/bin:$PATH"

if has_command mise; then
  # Ruby builds against the system toolchain via idiomatic .ruby-version files.
  mise settings add idiomatic_version_file_enable_tools ruby 2>/dev/null || true

  # Install every tool pinned in the global config. config/mise/config.toml is
  # symlinked to ~/.config/mise/config.toml (see shell/load_symlinks), so this
  # provisions fzf, node, python, the ctags-lsp go tool and wrangler.
  mise install
fi

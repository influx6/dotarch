#!/bin/bash

source $DOTFILES/shell/load_functions

# GHC Haskell toolchain via ghcup (ghc + cabal + stack), plus the cabal-installed
# dev helpers used for editing/formatting Haskell. Works on macOS and Linux.

if no_command ghcup; then
  export BOOTSTRAP_HASKELL_NONINTERACTIVE=1
  export BOOTSTRAP_HASKELL_GHC_VERSION=recommended
  export BOOTSTRAP_HASKELL_CABAL_VERSION=recommended
  export BOOTSTRAP_HASKELL_INSTALL_STACK=1
  # dotfiles own PATH/env (see shell/load_ghc); don't let the installer edit rc files.
  export BOOTSTRAP_HASKELL_ADJUST_BASHRC=0
  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
fi

# Make ghcup/ghc/cabal available for the rest of this run.
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"
export PATH="$HOME/.cabal/bin:$PATH"

if has_command ghcup; then
  ghcup install ghc recommended --set
  ghcup install cabal recommended --set
  ghcup install stack recommended --set
  # Optional language server (large build); uncomment if you want it:
  # ghcup install hls recommended --set
fi

# Haskell CLI tools (build from source via cabal — this can take a while).
if has_command cabal; then
  cabal update
  cabal install --overwrite-policy=always \
    fourmolu \
    ghcid \
    hoogle \
    fast-tags \
    ghc-tags \
    weeder
fi

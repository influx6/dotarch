#!/bin/bash

source $DOTFILES/shell/load_functions

# VNC clients (Homebrew Cask) for connecting to a remote VNC server.
# tigervnc: TigerVNC viewer.
# vnc-viewer: RealVNC VNC Viewer.
if ! brew list --cask tigervnc &>/dev/null; then
  brew install --cask tigervnc
fi

if ! brew list --cask vnc-viewer &>/dev/null; then
  brew install --cask vnc-viewer
fi

# macOS also ships a built-in VNC client — Finder → Go → Connect to Server, or:
#   open vnc://<host>:5900

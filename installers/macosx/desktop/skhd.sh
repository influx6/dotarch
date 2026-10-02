#!/bin/bash

source $DOTFILES/shell/load_functions

# skhd hotkey daemon — drives yabai via the keybindings in config/skhd/skhdrc.

if no_command skhd; then
  echo "Installing skhd.."
  brew install koekeishiya/formulae/skhd
fi

# Symlink config into ~/.config/skhd/skhdrc.
mkdir -p "$HOME/.config/skhd"
ln -sfn "$DOTFILES/config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"

echo "Starting skhd service.."
skhd --start-service

cat <<'EOF'

skhd is installed and running. macOS will ask for Accessibility (and Input
Monitoring) permission on first run — grant it in System Settings -> Privacy &
Security, then run:
  skhd --restart-service

Keybindings use alt (option) as the leader, e.g. alt - h/j/k/l to move focus.
See config/skhd/skhdrc for the full list.
EOF

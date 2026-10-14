#!/bin/bash

source $DOTFILES/shell/load_functions

# OmniWM tiling window manager (Niri-style for macOS).
# https://omniwm.app — free, open-source, Apple Silicon + macOS 26 (Tahoe).
# Config lives in the repo at config/omniwm/settings.toml and is symlinked into
# ~/.config/omniwm/settings.toml. It also provides its own keybinding manager
# (the `hotkeys` array in settings.toml), so skhd is no longer needed for the WM.

if no_command omniwmctl; then
  echo "Installing OmniWM.."
  brew install --cask omniwm
fi

# Symlink config into ~/.config/omniwm/settings.toml.
mkdir -p "$HOME/.config/omniwm"
ln -sfn "$DOTFILES/config/omniwm/settings.toml" "$HOME/.config/omniwm/settings.toml"

cat <<'EOF'

OmniWM is installed and its settings are symlinked into
~/.config/omniwm/settings.toml (live-reloaded on save, or edit via
Settings -> Keyboard Shortcuts / etc.).

On first launch:
  1. Open OmniWM (Spotlight or /Applications/OmniWM.app).
  2. Grant Accessibility AND Input Monitoring when prompted, under
     System Settings -> Privacy & Security.
  3. Open System Settings -> Desktop & Dock -> Mission Control and turn OFF
     "Displays have separate Spaces" (required for multi-monitor tiling).
  4. Click "Start OmniWM" in the app.

IPC is enabled in settings.toml (general.ipcEnabled = true), so `omniwmctl` is
on PATH and can drive anything the built-in keybindings don't cover — e.g.:
  omniwmctl command consume-or-expel-window-left

If you were running yabai, stop it (it must not tile alongside OmniWM):
  yabai --stop-service
  brew services stop yabai
EOF

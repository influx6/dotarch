#!/bin/bash

source $DOTFILES/shell/load_functions

# yabai tiling window manager.
# Config lives in the repo at config/yabai/yabairc and is symlinked into
# ~/.config/yabai/yabairc (yabai requires the file to be executable).

if no_command yabai; then
  echo "Installing yabai.."
  brew install koekeishiya/formulae/yabai
fi

# Symlink config and make it executable (yabai won't run a non-exec rc).
mkdir -p "$HOME/.config/yabai"
ln -sfn "$DOTFILES/config/yabai/yabairc" "$HOME/.config/yabai/yabairc"
chmod +x "$DOTFILES/config/yabai/yabairc"

echo "Starting yabai service.."
yabai --start-service

cat <<'EOF'

yabai is installed and running with the base (tiling) setup — no SIP changes
needed. On first run macOS will ask for Accessibility permission; grant it in
System Settings -> Privacy & Security -> Accessibility, then run:
  yabai --restart-service

OPTIONAL scripting addition (window borders, opacity, extra space ops) needs
SIP partially disabled plus a passwordless sudoers entry. To enable:
  1. Reboot into recovery, run `csrutil enable --without fs --without debug --without nvram`.
  2. Add the sudoers rule (regenerate after every yabai upgrade):
       echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d' ' -f1) $(which yabai) --load-sa" \
         | sudo tee /private/etc/sudoers.d/yabai
  3. Uncomment the scripting-addition lines at the top of config/yabai/yabairc.
EOF

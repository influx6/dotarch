#!/bin/bash

source $DOTFILES/shell/load_functions

# Enable Ctrl + 1..9 to switch directly to Mission Control desktops (spaces).
#
# macOS only wires up a couple of the "Switch to Desktop N" shortcuts out of the
# box and leaves the rest unset, which is why switching stops working past
# Ctrl+3/Ctrl+4. This sets all nine, enabled, under the Ctrl modifier.
#
# IMPORTANT: a shortcut only fires for a desktop that actually EXISTS. Open
# Mission Control and create 9 desktops (or let yabai create them) so every
# Ctrl+N has a space to switch to.

if ! is_mac; then
  echo "spaces-hotkeys.sh is macOS-only. Skipping."
  return 0 2>/dev/null || exit 0
fi

# Virtual keycodes for the number-row keys 1..9 on a US layout.
keycodes=(18 19 20 21 23 22 26 28 25)
ctrl=262144 # 0x40000 == Control modifier

for n in $(seq 1 9); do
  hotkey_id=$((117 + n)) # "Switch to Desktop N" symbolic hotkey ids: 118..126
  ascii=$((48 + n))      # ascii for the digit '1'..'9' == 49..57
  keycode=${keycodes[$((n - 1))]}

  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$hotkey_id" "
    <dict>
      <key>enabled</key><true/>
      <key>value</key>
      <dict>
        <key>type</key><string>standard</string>
        <key>parameters</key>
        <array>
          <integer>$ascii</integer>
          <integer>$keycode</integer>
          <integer>$ctrl</integer>
        </array>
      </dict>
    </dict>"
done

# Reload the symbolic hotkeys and bounce the Dock so Mission Control picks them up.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
killall Dock 2>/dev/null || true

cat <<'EOF'
Configured Ctrl+1..9 to switch to Desktops 1..9.

If some don't switch:
  - Open Mission Control and make sure you actually have 9 desktops.
  - Verify under System Settings -> Keyboard -> Keyboard Shortcuts ->
    Mission Control that "Switch to Desktop N" is enabled.
  - You may need to log out/in once for all bindings to take effect.
EOF

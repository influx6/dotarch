#!/bin/bash

# macOS installer entrypoint.
#
# Usage:
#   DOTFILES=/path/to/dotarch bash installers/macosx/install.sh
# or, with $DOTFILES already exported in your shell:
#   ./installers/macosx/install.sh

# Resolve DOTFILES if the caller didn't export it.
if [ -z "$DOTFILES" ]; then
  DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  export DOTFILES
fi

source "$DOTFILES/shell/load_functions"

if ! is_mac; then
  echo "installers/macosx is only for macOS. Aborting."
  exit 1
fi

MACOS="$DOTFILES/installers/macosx"

# brew is sourced (not run) so its shellenv is available to later steps.
source "$MACOS/core/brew.sh"

# Each step is idempotent and safe to re-run.
source "$MACOS/development/openjdk.sh"
source "$MACOS/desktop/yabai.sh"
source "$MACOS/desktop/skhd.sh"

echo
echo "macOS setup complete."

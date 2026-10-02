#!/bin/bash

source $DOTFILES/shell/load_functions

# Screenshot / screen-recording / GIF tooling for macOS.
# Runnable on demand: `install_one screen-tools` or via `install_all apps`.

# --- GUI apps (brew cask) ---------------------------------------------------
# Free / open source:
#   shottr        - screenshot capture, annotation, scrolling capture, OCR, pixel measure
#   kap           - open-source screen recorder, exports mp4 / GIF
#   licecap       - dead-simple animated GIF screen capture
# Premium (cask installs the app; bring your own license):
#   screen-studio - polished screen recorder/editor, auto-zoom (https://screen.studio)
casks=(shottr kap licecap screen-studio)
for c in "${casks[@]}"; do
  if brew list --cask "$c" &>/dev/null; then
    echo "cask already installed: $c"
  else
    brew install --cask "$c"
  fi
done

# Other premium options (uncomment to install; all paid, license separate):
# brew install --cask cleanshot    # CleanShot X
# brew install --cask gifox        # Gifox — GIF recorder
# brew install --cask screenflow   # ScreenFlow — recording + editing

# --- CLI tools (brew formula) -----------------------------------------------
#   ffmpeg      - record/convert video; the workhorse for video -> gif
#   gifski      - highest-quality GIF encoder (from video / frames)
#   gifsicle    - optimise, resize and manipulate GIFs
#   imagemagick - general image / GIF frame manipulation
#   vhs         - scripted terminal GIFs (great for README / docs demos)
brew install ffmpeg gifski gifsicle imagemagick vhs

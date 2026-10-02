#!/bin/bash

source $DOTFILES/shell/load_functions

# Screenshot / GIF / video CLI tooling, installed with each OS's package
# manager where available, with language-toolchain fallbacks otherwise.
#
#   ffmpeg      - record/convert video; the workhorse for video -> gif
#   gifski      - highest-quality GIF encoder (from video / frames)
#   gifsicle    - optimise, resize and manipulate GIFs
#   imagemagick - general image / GIF frame manipulation
#   vhs         - scripted terminal GIFs (great for README / docs demos)

if is_mac; then
  if has_command brew; then
    brew install ffmpeg gifski gifsicle imagemagick vhs
  else
    echo "brew missing — run installers/macosx/core/brew.sh first."
  fi

elif is_archlinux; then
  # ffmpeg/gifsicle/imagemagick/vhs are in the official repos; gifski is in the
  # AUR — yay handles both.
  yay -S --noconfirm --needed ffmpeg gifski gifsicle imagemagick vhs

elif is_ubuntu; then
  sudo apt-get update
  sudo apt-get install -y ffmpeg gifsicle imagemagick

  # gifski: not packaged in apt -> cargo
  if no_command gifski; then
    if has_command cargo; then
      cargo install gifski
    else
      echo "gifski: install rust first (installers/every/rust.sh), then re-run."
    fi
  fi

  # vhs: not packaged in apt -> go install (needs ffmpeg + ttyd at runtime)
  if no_command vhs; then
    sudo apt-get install -y ttyd 2>/dev/null || echo "note: vhs needs 'ttyd' at runtime; install it separately if apt lacks it."
    if has_command go; then
      go install github.com/charmbracelet/vhs@latest
    else
      echo "vhs: install go first (or use Charm's apt repo: https://charm.sh/), then re-run."
    fi
  fi

else
  echo "media-tools: unsupported OS."
fi

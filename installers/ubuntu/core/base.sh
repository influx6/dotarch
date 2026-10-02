#!/bin/bash

source $DOTFILES/shell/load_functions

# Base build tooling (Ubuntu/Debian) — the equivalent of Arch's base-devel.
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  curl \
  wget \
  git \
  ca-certificates \
  pkg-config \
  software-properties-common

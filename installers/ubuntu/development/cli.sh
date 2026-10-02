#!/bin/bash

source $DOTFILES/shell/load_functions

# Core CLI tooling (Ubuntu/Debian), mirroring the macOS brew bundle.
#
# Deliberately NOT here:
#   - node / python / ruby / fzf / wrangler  -> managed by mise (every/mise.sh)
#   - rust                                   -> every/rust.sh (rustup)
#   - ghc / cabal / stack                    -> every/ghc.sh (ghcup)
#
# Several tools are missing from apt (or shipped too old), so they use their
# official installers further down. Note: apt's neovim can lag upstream; swap in
# the unstable PPA or a release tarball if you need a newer version.

sudo apt-get update
sudo apt-get install -y \
  direnv \
  ripgrep \
  tmux \
  gnupg \
  git-crypt \
  cmake \
  pkg-config \
  protobuf-compiler \
  libsnappy-dev \
  libpq-dev \
  llvm \
  lld \
  lldb \
  gdb \
  golang-go \
  neovim

mkdir -p "$HOME/.local/bin"

# --- tools not packaged in apt (or too old) ---------------------------------

# atuin — shell history
if no_command atuin; then
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# zellij — terminal multiplexer (latest release binary)
if no_command zellij; then
  case "$(uname -m)" in
    aarch64 | arm64) ztarget="aarch64-unknown-linux-musl" ;;
    *) ztarget="x86_64-unknown-linux-musl" ;;
  esac
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ztarget}.tar.gz" | tar -xz -C "$tmp"
  mv "$tmp/zellij" "$HOME/.local/bin/zellij" && chmod +x "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
fi

# sops — secrets management (official release binary)
if no_command sops; then
  case "$(uname -m)" in
    aarch64 | arm64) sarch="arm64" ;;
    *) sarch="amd64" ;;
  esac
  ver="$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest | grep -oE '"tag_name": *"v[^"]+"' | head -n1 | grep -oE 'v[0-9.]+')"
  if [ -n "$ver" ]; then
    curl -fsSL "https://github.com/getsops/sops/releases/download/${ver}/sops-${ver}.linux.${sarch}" -o "$HOME/.local/bin/sops"
    chmod +x "$HOME/.local/bin/sops"
  fi
fi

# ollama — local LLM runtime
if no_command ollama; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

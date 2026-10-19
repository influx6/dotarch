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
  neovim \
  fd-find \
  ghostscript \
  mercurial \
  universal-ctags \
  php-cli \
  composer

mkdir -p "$HOME/.local/bin"

# fd-find ships as `fdfind` on Debian/Ubuntu (the `fd` name is taken); expose
# it under the `fd` name that Neovim/telescope/snacks look for.
if no_command fd && has_command fdfind; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# --- tools not packaged in apt (or too old) ---------------------------------

# atuin — shell history
if no_command atuin; then
  fetch https://setup.atuin.sh | sh
fi

# zellij — terminal multiplexer (latest release binary)
if no_command zellij; then
  case "$(uname -m)" in
    aarch64 | arm64) ztarget="aarch64-unknown-linux-musl" ;;
    *) ztarget="x86_64-unknown-linux-musl" ;;
  esac
  tmp="$(mktemp -d)"
  fetch "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ztarget}.tar.gz" | tar -xz -C "$tmp"
  mv "$tmp/zellij" "$HOME/.local/bin/zellij" && chmod +x "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
fi

# sops — secrets management (official release binary)
if no_command sops; then
  case "$(uname -m)" in
    aarch64 | arm64) sarch="arm64" ;;
    *) sarch="amd64" ;;
  esac
  ver="$(fetch https://api.github.com/repos/getsops/sops/releases/latest | grep -oE '"tag_name": *"v[^"]+"' | head -n1 | grep -oE 'v[0-9.]+')"
  if [ -n "$ver" ]; then
    fetch "https://github.com/getsops/sops/releases/download/${ver}/sops-${ver}.linux.${sarch}" > "$HOME/.local/bin/sops"
    chmod +x "$HOME/.local/bin/sops"
  fi
fi

# ollama — local LLM runtime
if no_command ollama; then
  fetch https://ollama.com/install.sh | sh
fi

# lazygit — git TUI (official release binary; apt's is stale)
if no_command lazygit; then
  case "$(uname -m)" in
    aarch64 | arm64) larch="arm64" ;;
    *) larch="x86_64" ;;
  esac
  ver="$(fetch https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -oE '"tag_name": *"v[^"]+"' | head -n1 | grep -oE 'v[0-9.]+')"
  if [ -n "$ver" ]; then
    fetch "https://github.com/jesseduffield/lazygit/releases/download/${ver}/lazygit_${ver#v}_Linux_${larch}.tar.gz" | tar -xz -C "$HOME/.local/bin" lazygit
  fi
fi

# tectonic — LaTeX engine (snacks.image LaTeX rendering; official release binary)
if no_command tectonic; then
  case "$(uname -m)" in
    aarch64 | arm64) ttarget="aarch64-unknown-linux-musl" ;;
    *) ttarget="x86_64-unknown-linux-musl" ;;
  esac
  tag="$(fetch https://api.github.com/repos/tectonic-typesetting/tectonic/releases/latest | grep -oE '"tag_name": *"tectonic@[^"]+"' | head -n1 | grep -oE 'tectonic@[0-9.]+')"
  ver="${tag#tectonic@}"
  if [ -n "$ver" ]; then
    fetch "https://github.com/tectonic-typesetting/tectonic/releases/download/${tag}/tectonic-${ver}-${ttarget}.tar.gz" | tar -xz -C "$HOME/.local/bin" tectonic
  fi
fi

# mermaid-cli — mermaid diagram rendering (needs node, provided by mise)
if no_command mmdc && has_command npm; then
  npm install -g @mermaid-js/mermaid-cli
fi

# julia — via juliaup (official installer)
if no_command julia; then
  fetch https://install.julialang.org | sh -s -- --yes
fi

# Neovim remote-plugin providers (node pynvim / ruby neovim gem).
source "$DOTFILES/installers/every/nvim.sh"

# Language toolchains (java/kotlin/clojure/perl/lua + LSP servers) via brew.
source "$DOTFILES/installers/every/langs.sh"

#!/bin/bash

source $DOTFILES/shell/load_functions

# Language toolchains via Homebrew: Java, Kotlin, Clojure, Perl and Lua, plus
# their LSP servers (jdtls, clojure-lsp). brew is available on macOS and Linux
# alike, so this is a single cross-platform script.
#
# brew keeps a few of these keg-only (openjdk, perl), meaning their binaries are
# not symlinked into the brew prefix. We expose them by linking their binaries
# into ~/.local/bin, which shell/load_paths keeps ahead of /usr/bin on PATH.

# Ensure brew is installed and on PATH for the rest of this run.
source "$DOTFILES/installers/every/brew.sh"

mkdir -p "$HOME/.local/bin"

# Resolve the real JDK home. brew's openjdk nests the JDK inside
# libexec/openjdk.jdk/Contents/Home on macOS, but is the plain prefix on Linux.
openjdk_home() {
  if is_mac && [ -d "$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home" ]; then
    echo "$(brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home"
  else
    echo "$(brew --prefix openjdk)"
  fi
}

# Java + JVM languages + their LSP servers.
brew install \
  openjdk \
  kotlin \
  clojure \
  clojure-lsp \
  jdtls

# Perl + cpanminus (for the Neovim::Ext remote-plugin provider).
brew install \
  perl \
  cpanminus

# Lua + luarocks.
brew install luarocks

# Lua dev tools that mason would otherwise install on first nvim launch, so
# they're deterministically on PATH: digestif (LaTeX LSP) and luacheck (Lua
# linter). Both are luarocks rocks, so this works identically on every platform.
luarocks install digestif

# luacheck 1.x does not run on Lua 5.5: 5.5 made generic `for` loop variables
# `const`, and luacheck reassigns one (standards.lua). Build it against lua@5.4
# instead. `luarocks --lua-version=5.4` targets the user tree (~/.luarocks), and
# its wrapper already points at the matching lua5.4; ~/.local/bin is on PATH.
brew install lua@5.4
PATH="$(brew --prefix lua@5.4)/bin:$PATH" \
  luarocks --lua-version=5.4 install luacheck
ln -sf "$HOME/.luarocks/bin/luacheck" "$HOME/.local/bin/luacheck"

# Tree-sitter CLI (grammar dev; nvim-treesitter compiles its own parsers).
brew install tree-sitter-cli

# Expose keg-only JDK binaries (java, javac, jar, jshell, jcmd, keytool, …).
for bin in "$(openjdk_home)/bin"/*; do
  ln -sf "$bin" "$HOME/.local/bin/$(basename "$bin")"
done

# Expose brew's keg-only perl so nvim's provider check finds it with Neovim::Ext.
ln -sf "$(brew --prefix perl)/bin/perl" "$HOME/.local/bin/perl"

# Install the Neovim::Ext provider module into brew perl (non-interactive).
PATH="$(brew --prefix perl)/bin:$PATH" \
  PERL_MM_USE_DEFAULT=1 PERL_CPANM_OPT="--notest" \
  cpanm Neovim::Ext

echo
echo "Language toolchains installed. JAVA_HOME=$(openjdk_home)"

#!/bin/bash

source $DOTFILES/shell/load_functions

# tree-sitter-norg parser (Neorg). nvim-treesitter no longer ships a "norg"
# parser in its registry, so snacks.image reports it as missing. Compile it from
# the upstream grammar (parser.c + C++ scanner.cc are both checked in) and drop
# it where Neovim looks for parsers, alongside the ones nvim-treesitter built.

PARSER_DIR="$HOME/.local/share/nvim/site/parser"
PARSER_SO="$PARSER_DIR/norg.so"

if [ -f "$PARSER_SO" ]; then
  echo "norg parser already installed."
  exit 0
fi

# Pick the compilers: C for parser.c, C++ for scanner.cc (POSIX `cc`/`c++`, or
# the clang/gcc spellings on minimal installs).
CC=""
CXX=""
for c in cc clang gcc; do has_command "$c" && { CC="$c"; break; }; done
for c in c++ clang++ g++; do has_command "$c" && { CXX="$c"; break; }; done

if [ -z "$CC" ] || [ -z "$CXX" ]; then
  echo "norg: need a C and C++ compiler (cc/c++). Skipping parser build."
  exit 0
fi

mkdir -p "$PARSER_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fetch "https://github.com/nvim-neorg/tree-sitter-norg/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp"
cd "$tmp/tree-sitter-norg-main" || exit 1

"$CC"  -std=c99 -fPIC -I src -c src/parser.c  -o parser.o
"$CXX"          -fPIC -I src -c src/scanner.cc -o scanner.o
"$CXX" -shared -o norg.so parser.o scanner.o

cp norg.so "$PARSER_SO"
echo "norg parser installed to $PARSER_SO"

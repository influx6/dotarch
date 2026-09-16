#!/usr/bin/env bash
# haskell-tags.sh — generate ctags for Haskell with fast-tags.
#
# Why fast-tags: it is Haskell-aware (universal-ctags' Haskell support is weak),
# very fast, and supports incremental single-file updates. This script is the
# single source of truth for tag generation; the Neovim Haskell setup shells out
# to it (see lua/alex/plugins/plugin-haskell.lua), and you can run it by hand.
#
# Jobs:
#   Full project index      : haskell-tags.sh --out FILE [ROOT]      (ROOT defaults to $PWD)
#   Dependency-source index  : haskell-tags.sh --deps DEPDIR --out FILE
#   Incremental single file  : haskell-tags.sh --update FILE --out FILE
#   Install fast-tags        : haskell-tags.sh --install
#
# Tags are written to an explicit --out path so Neovim can point &tags at it.
# By design they are NOT written into the project tree (keeps the repo clean).
set -euo pipefail

# cabal installs fast-tags here; make sure it is reachable even under a bare
# environment (e.g. when invoked by Neovim's vim.system, which does not source
# your shell rc).
CABAL_BIN="${CABAL_BIN:-$HOME/.cabal/bin}"
export PATH="$HOME/.ghcup/bin:$CABAL_BIN:$PATH"

usage() {
  # Print the leading comment block (skip the shebang), stripping "# ".
  awk 'NR>1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"
}

die() { printf 'haskell-tags: %s\n' "$*" >&2; exit 1; }

ensure_fast_tags() {
  command -v fast-tags >/dev/null 2>&1 && return 0
  if [ "${1:-}" = "install" ]; then
    command -v cabal >/dev/null 2>&1 || die "cabal not found; install GHCup first"
    echo "Installing fast-tags via cabal (one-time, may take a few minutes)..." >&2
    cabal install fast-tags
    command -v fast-tags >/dev/null 2>&1 || die "fast-tags still not on PATH after install ($CABAL_BIN)"
    return 0
  fi
  die "fast-tags not found. Install with: cabal install fast-tags  (or: $0 --install)"
}

OUT="" ROOT="" DEPS="" UPDATE="" DO_INSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --out)     OUT="$2"; shift 2;;
    --deps)    DEPS="$2"; shift 2;;
    --update)  UPDATE="$2"; shift 2;;
    --install) DO_INSTALL=1; shift;;
    -h|--help) usage; exit 0;;
    --)        shift; break;;
    -*)        die "unknown option: $1";;
    *)         ROOT="$1"; shift;;
  esac
done

if [ "$DO_INSTALL" = 1 ]; then
  ensure_fast_tags install
  echo "fast-tags: $(command -v fast-tags)"
  exit 0
fi

ensure_fast_tags

# Incremental single-file update (used by Neovim on save). fast-tags merges the
# file's tags into the existing --out file in place.
if [ -n "$UPDATE" ]; then
  [ -n "$OUT" ] || die "--update requires --out"
  mkdir -p "$(dirname "$OUT")"
  exec fast-tags -o "$OUT" "$UPDATE"
fi

# Dependency-source index (recurse an unpacked-sources directory).
if [ -n "$DEPS" ]; then
  [ -n "$OUT" ] || die "--deps requires --out"
  [ -d "$DEPS" ] || die "dependency dir not found: $DEPS"
  mkdir -p "$(dirname "$OUT")"
  fast-tags -R -o "$OUT" "$DEPS"
  echo "haskell-tags: wrote dependency tags -> $OUT"
  exit 0
fi

# Full project index.
ROOT="${ROOT:-$PWD}"
[ -d "$ROOT" ] || die "project dir not found: $ROOT"
OUT="${OUT:-$ROOT/tags}"
mkdir -p "$(dirname "$OUT")"
fast-tags -R -o "$OUT" "$ROOT"
echo "haskell-tags: wrote project tags -> $OUT"

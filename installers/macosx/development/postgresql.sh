#!/bin/bash

source $DOTFILES/shell/load_functions

# PostgreSQL server binaries (initdb / postgres / pg_ctl) for macOS.
#
# Why this is separate from development/cli.sh's `libpq`:
#   libpq ships only the CLIENT tools (psql, pg_dump, ...). The talstack test
#   suite's default path (tmp-postgres) builds a throwaway PG *cluster* on disk
#   per run, so it needs the SERVER binaries too. See shell/load_postgres, which
#   puts this keg-only formula on PATH.
#
# Pinned to 16 to match CI (.github/workflows/pr.yml runs against postgres:16).

if ! brew list postgresql@16 &>/dev/null; then
  echo "Installing postgresql@16.."
  brew install postgresql@16
fi

# postgresql@16 is keg-only (not symlinked). Expose it for THIS run so the
# verification below works; shell/load_postgres adds it to PATH persistently.
PG_BIN="$(brew --prefix)/opt/postgresql@16/bin"
export PATH="$PG_BIN:$PATH"

if command -v initdb &>/dev/null; then
  echo "postgresql@16 installed. initdb -> $(command -v initdb)"
else
  echo "postgresql@16 installed, but initdb is not on PATH."
  echo "Open a new shell (shell/load_postgres adds $PG_BIN), or add it by hand:"
  echo "  export PATH=\"$PG_BIN:\$PATH\""
fi

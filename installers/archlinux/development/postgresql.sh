#!/bin/bash

source $DOTFILES/shell/load_functions

# PostgreSQL server binaries (initdb / postgres / pg_ctl) for Arch Linux.
#
# Why this is separate from development/cli.sh's `postgresql-libs`:
#   postgresql-libs is only the CLIENT library (libpq). The talstack test suite's
#   default path (tmp-postgres) builds a throwaway PG *cluster* on disk per run,
#   so it needs the SERVER package. Arch's `postgresql` installs initdb/postgres/
#   pg_ctl straight into /usr/bin, so no PATH wiring is needed.

if no_command initdb; then
  echo "Installing postgresql (server).."
  yay -S --noconfirm --needed postgresql
fi

if has_command initdb; then
  echo "postgresql installed. initdb -> $(command -v initdb)"
else
  echo "postgresql install finished, but initdb is still not on PATH."
fi

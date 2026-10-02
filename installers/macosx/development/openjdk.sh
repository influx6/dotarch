#!/bin/bash

source $DOTFILES/shell/load_functions

# OpenJDK via Homebrew. brew keeps openjdk keg-only, so we expose it to the
# system Java wrappers (/usr/libexec/java_home) and to the shell.

if ! brew list openjdk &>/dev/null; then
  echo "Installing openjdk.."
  brew install openjdk
fi

BREW_PREFIX="$(brew --prefix)"

# Let the macOS java launcher discover this JDK.
JVM_DIR="/Library/Java/JavaVirtualMachines"
JDK_LINK="$JVM_DIR/openjdk.jdk"
if [ ! -L "$JDK_LINK" ]; then
  echo "Linking openjdk into $JVM_DIR (requires sudo).."
  sudo mkdir -p "$JVM_DIR"
  sudo ln -sfn "$BREW_PREFIX/opt/openjdk/libexec/openjdk.jdk" "$JDK_LINK"
fi

echo "openjdk installed. Verify with: /usr/libexec/java_home -V"
echo "If a shell can't find 'java', ensure JAVA_HOME is set, e.g.:"
echo "  export JAVA_HOME=\"\$($BREW_PREFIX/bin/brew --prefix openjdk)/libexec/openjdk.jdk/Contents/Home\""

#!/bin/bash

source $DOTFILES/shell/load_functions

# openjdk itself is installed by every/langs.sh (brew, keg-only, binaries linked
# into ~/.local/bin). This exposes the JDK to the system Java launcher
# (/usr/libexec/java_home) so macOS apps that use it can discover the JDK.

BREW_PREFIX="$(brew --prefix)"

JVM_DIR="/Library/Java/JavaVirtualMachines"
JDK_LINK="$JVM_DIR/openjdk.jdk"
if [ ! -L "$JDK_LINK" ]; then
  echo "Linking openjdk into $JVM_DIR (requires sudo).."
  sudo mkdir -p "$JVM_DIR"
  sudo ln -sfn "$BREW_PREFIX/opt/openjdk/libexec/openjdk.jdk" "$JDK_LINK"
fi

echo "openjdk exposed to /usr/libexec/java_home."

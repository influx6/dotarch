#!/bin/bash

source $DOTFILES/shell/load_functions

if no_command aider; then
    if has_command pip; then
        pip install aider-install
        aider-install
    fi
fi

#!/bin/bash

source $DOTFILES/shell/functions
source $DOTFILES/installers/every/brew.sh

yay -S --noconfirm --needed \
  cargo clang llvm mise \
  imagemagick tk \
  mariadb-libs postgresql-libs \
  github-cli \
  lazygit lazydocker


# # install github sync
# if no_dir $HOME/.github-org-sync; then
#   git clone https://github.com/oxzi/github-orga-sync ~/.github-org-sync && cd ~/.github-org-sync && go install && cd -
# fi

# install go (brew is required)
if no_command go && has_command brew; then
  brew install go
fi

# install mise
if no_command mise; then
  curl https://mise.run | sh
fi

if has_command mise; then
  # install nodejs and setup root
  mise install node
  mise use --global node

  # install python basis
  mise install python@3.8.9
  mise install python@3.9.0
  mise install python@3.10.0
  mise install python@3.11.8
  mise install python@3.12.10
  mise use --global python@3.12.10
fi

#!/bin/sh

source $Dotfiles/shell/load_functions

if no_command "ulauncher"; then
	mkidr -p ~/apps
	cd ~/apps
	git clone https://aur.archlinux.org/ulauncher.git && cd ulauncher && makepkg -is
	cd -
fi

yay -S --needed --noconfirm wmctrl

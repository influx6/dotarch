#!/bin/bash

source $DOTFILES/shell/functions

yay -S --noconfirm --needed tree zoxide ripgrep exa fd fzf walker lazygit lazydocker btop impala bluetui fastfetch typora dropbox tailscale xournal++ steam 

# if no_command "atuin"; then 
# 	curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
# 	yay -S --needed --noconfirm bash-preexec
# fi

yay -S --noconfirm --needed viu chafa ueberzugpp luarocks jdk-openjdk ttf-noto-emoji gnome-icon-theme breeze-icons adwaita-icon-theme \ 
  papirus-icon-theme lxappearance ttf-font-awesome ttf-noto-emoji ttf-noto-fonts-cjk shared-mime-info mmdc ast-grep lua noto-fonts noto-fonts-cjk noto-fonts-emoji adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts system-config-printer cups cups-pdf system-config-printer hplip ghostscript cups cups-pdf ghostscript gsfonts gutenprint foomatic-db foomatic-db-engine foomatic-db-nonfree foomatic-db-ppds foomatic-filters hplip system-config-printer


fc-cache -vf

sudo locale-gen

localectl set-locale LANG=en_US.UTF-8

sudo systemctl enable --now cups
sudo systemctl enable --now cups.socket
sudo systemctl start cups.service

sudo usermod -aG lp,sys $USER


#!/bin/bash



mise use -g fzf@latest
mise use -g python@3.12.10

pip install wheel setuptools pip build installer

sudo pacman -Rns --noconfirm dms-shell-bin

sudo pacman -S --noconfirm --asdeps aylurs-gtk-shell-git wireplumber libgtop bluez bluez-utils networkmanager dart-sass wl-clipboard upower gvfs gtksourceview3 libsoup3 \ 
  python python-gpustat brightnessctl pywal pacman-contrib power-profiles-daemon grimblast wf-recorder btop swww wordnet
 
sudo pacman -S $(pacman -Sgq nerd-fonts)

sudo pacman -S --noconfirm --asdeps \
  niri fuzzel waybar \
  python3  \
  ffmpeg ffmpeg-dev \
  python-virtualenv \
  gtkmm3 \
  jsoncpp \
  libsigc++ \
  fmt \
  wayland \
  chrono-date \
  spdlog \
  gtk3 \
  gobject-introspection \
  libgirepository \
  libpulse \
  thunar thunar-volman \
  tumbler \
  exo libxfce4util xfdesktop \
  xfce4-dev-tools \
  libnl \
  libappindicator-gtk3 \
  libdbusmenu-gtk3 \
  libmpdclient \
  sndio \
  libevdev \
  libxkbcommon \
  upower \
  meson \
  cmake \
  libgtk-3-dev gtk3 \
  scdoc \
  wayland-protocols \
  glib2-devel \
  waybar \
  fuzzel \
  python-imageio-ffmpeg  \
  mako  nwg-look greetd \
  alacritty \
  swaybg \
  swayidle \
  swaylock-effects \
  xwayland-satellite \
  xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk \
  udiskie \
  matugen \
  wl-clipboard cliphist cava qt6-multimedia-ffmpeg \
  niri xwayland-satellite xdg-desktop-portal-gtk alacritty \
  polkit-gnome wpaperd swww waypaper wallrizz hyprpaper


yay -S --noconfirm python-imageio-ffmpeg nirius waybar-niri-taskbar ashell 

# niri-companion:
#
# niri-genconfig – allows having configuration groups for layered niri ✨ setups
# niri-workspaces – creates sessions for different tasks.
# niri-ipcext – performs IPC-like modifications.

uv tool install niri-companion

cd ~/apps 
git clone git@github.com:fabienjuif/swaytreesave.git
cargo install --path ./swaytreesave
cd -

# curl -sSL https://hyprlax.com/install.sh | bash

# Uncomment this if you want dms-shell instead
#
# yay -S --noconfirm dms-shell-bin
# systemctl --user add-wants niri.service dms

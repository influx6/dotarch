#!/bin/bash


yay -S niri fuzzel waybar 

mise use -g fzf@latest

yay -S --asdeps --needed \
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
  scdoc \
  wayland-protocols \
  glib2-devel

sudo pacman -Syu niri xwayland-satellite xdg-desktop-portal-gnome xdg-desktop-portal-gtk alacritty
yay -S --needed --noconfirm dms-shell-bin matugen wl-clipboard cliphist cava qt6-multimedia-ffmpeg

systemctl --user add-wants niri.service dms

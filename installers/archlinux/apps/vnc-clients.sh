#!/bin/bash

# VNC clients for connecting to a remote VNC server.
# tigervnc ships the `vncviewer` CLI + viewer; remmina is a full remote-desktop
# client (VNC/RDP/SSH); realvnc-vnc-viewer is RealVNC's VNC Viewer (AUR).
sudo pacman -S --needed --noconfirm tigervnc remmina

# RealVNC viewer lives in the AUR; install one-by-one so a failure doesn't stop the rest.
yay -S --needed --noconfirm realvnc-vnc-viewer ||
  echo -e "\e[31mFailed to install realvnc-vnc-viewer. Continuing without!\e[0m"

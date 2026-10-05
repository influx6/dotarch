#!/bin/sh

# VNC clients for connecting to a remote VNC server.
# tigervnc-viewer: TigerVNC viewer. remmina: remote-desktop client (VNC/RDP/SSH).
sudo apt update
sudo apt install -y tigervnc-viewer remmina

# RealVNC VNC Viewer isn't in apt — download the .deb from realvnc.com, or just
# use Remmina (installed above), which also speaks VNC.

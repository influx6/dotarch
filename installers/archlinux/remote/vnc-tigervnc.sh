#!/bin/bash
# Option B — a separate virtual desktop over VNC using TigerVNC.
#
# TigerVNC (vncserver/Xvnc) is already installed on this box; this installs a
# lightweight desktop to run inside the VNC session and wires up the startup
# script. Unlike Option A, remote users get their own desktop, not the niri one.

set -euo pipefail

# Desktop environment to run inside the VNC session
sudo pacman -S --needed --noconfirm xfce4 tigervnc

# Launch the desktop when a session starts (the default would be bare twm)
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
chmod +x ~/.vnc/xstartup

# Set the VNC password once (interactive)
if [ ! -f ~/.vnc/passwd ]; then
  vncpasswd
fi

echo
echo "Start a desktop:  vncserver -geometry 1920x1080 :1"
echo "Connect from another machine to this host on port 5901."

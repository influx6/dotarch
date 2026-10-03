#!/bin/bash
# Firewall for remote access: block all incoming except SSH + VNC, allow all outgoing.
#
# Installs ufw + gufw (the GTK frontend), then resets any previous rules so that
# ONLY the policy below applies. Distinct from development/firewall.sh, which
# also opens LocalSend and Docker DNS.

set -euo pipefail

# Install the firewall and its graphical frontend
sudo pacman -S --needed --noconfirm ufw gufw

# Start from a clean slate so only the rules below apply (also disables ufw).
yes | sudo ufw reset >/dev/null 2>&1 || true

# Default policy: deny everything incoming, allow everything outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (this host listens on 22)
sudo ufw allow 22/tcp comment 'SSH'

# Allow VNC: wayvnc (5900) and TigerVNC virtual displays (5901-5903)
sudo ufw allow 5900/tcp comment 'VNC (wayvnc)'
sudo ufw allow 5901:5903/tcp comment 'VNC (TigerVNC virtual displays)'

# Enable (force skips the interactive y/N prompt)
sudo ufw --force enable

sudo ufw status verbose

#!/bin/bash
# Firewall for remote access.
#
# Default-deny incoming, allow all outgoing, and explicitly open SSH + VNC while
# preserving the LocalSend and Docker rules previously set up by
# development/firewall.sh. There is no reset — every command is idempotent, so
# re-running this never drops an existing rule.

set -euo pipefail

# Install the firewall, its GTK frontend, and the Docker helper (AUR)
sudo pacman -S --needed --noconfirm ufw gufw
yay -S --needed --noconfirm ufw-docker

# Default policy: deny everything incoming, allow everything outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (this host listens on 22)
sudo ufw allow 22/tcp comment 'SSH'

# Allow VNC: wayvnc (5900) and TigerVNC virtual displays (5901-5903)
sudo ufw allow 5900/tcp comment 'VNC (wayvnc)'
sudo ufw allow 5901:5903/tcp comment 'VNC (TigerVNC virtual displays)'

# Preserve existing rules (from development/firewall.sh):
# LocalSend
sudo ufw allow 53317/tcp comment 'LocalSend'
sudo ufw allow 53317/udp comment 'LocalSend'
# Docker containers resolving DNS through the host
sudo ufw allow in on docker0 to any port 53 comment 'Docker DNS'

# Enable (force skips the interactive y/N prompt)
sudo ufw --force enable

# Protect published Docker ports so they don't bypass the firewall
sudo ufw-docker install
sudo ufw reload

sudo ufw status verbose

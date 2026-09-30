#!/bin/bash

# Brother MFC-T920DW — driverless print + scan. No proprietary Brother driver:
# the printer advertises AirPrint / IPP Everywhere for printing and eSCL + WSD
# for scanning, so CUPS and sane-airscan drive it natively. Safe to re-run.

# Print stack: CUPS with IPP Everywhere, auto-discovery, and the GUI printer tool
sudo pacman -S --noconfirm --needed \
  cups cups-filters cups-browsed system-config-printer avahi nss-mdns

# Scan stack: driverless scanning via eSCL ("AirScan") and WSD
sudo pacman -S --noconfirm --needed sane sane-airscan

# Discovery layer and the print/scan services
sudo systemctl enable --now avahi-daemon.service
sudo systemctl enable --now cups.service
sudo systemctl enable --now cups-browsed.service

# Auto-create a queue for the Brother (and any other AirPrint printer) as it appears
if ! grep -q '^CreateRemotePrinters Yes' /etc/cups/cups-browsed.conf; then
  echo 'CreateRemotePrinters Yes' | sudo tee -a /etc/cups/cups-browsed.conf
fi

# Let the current user print and scan (idempotent; no-ops if already in lp)
sudo usermod -aG lp "$USER"

echo "Brother MFC-T920DW setup complete."
echo "It should auto-appear shortly — check with:  lpstat -p"
echo "Scan with:  simple-scan  or  skanlite"

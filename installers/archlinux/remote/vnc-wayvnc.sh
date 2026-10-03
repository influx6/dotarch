#!/bin/bash
# Option A — share the live niri (Wayland) desktop over VNC.
#
# niri is Smithay-based, so screen capture works out of the box, but its virtual
# keyboard/pointer is incomplete. wl-uinput-proxy re-implements input on top of
# the kernel's uinput, which is what makes typing/scrolling/hotkeys actually work.

set -euo pipefail

# ---- Packages --------------------------------------------------------------
# wayvnc: the VNC server that captures the Wayland desktop (official repos).
sudo pacman -S --needed --noconfirm wayvnc

# wl-uinput-proxy: input proxy (crates.io — not in the AUR).
if ! command -v wl-uinput-proxy &>/dev/null; then
  cargo install wl-uinput-proxy
fi

# ---- Let the proxy create /dev/uinput devices ------------------------------
sudo modprobe uinput
sudo tee /etc/udev/rules.d/90-uinput.rules >/dev/null <<'EOF'
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF
sudo udevadm control --reload
sudo udevadm trigger

if ! id -nG "$USER" | grep -qw input; then
  sudo usermod -aG input "$USER"
  echo "NOTE: added '$USER' to the 'input' group — log out/in before starting wayvnc."
fi

# ---- Authentication (self-signed cert + password) --------------------------
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc"
mkdir -p "$CONF_DIR"

if [ ! -f "$CONF_DIR/server.crt" ] || [ ! -f "$CONF_DIR/server.key" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$CONF_DIR/server.key" -out "$CONF_DIR/server.crt" \
    -days 3650 -subj "/CN=wayvnc" >/dev/null 2>&1
  chmod 600 "$CONF_DIR/server.key"
fi

# neatvnc only accepts PKCS#1 PEM ("BEGIN RSA PRIVATE KEY"); OpenSSL 3.x emits
# PKCS#8 by default, so force the traditional format with -traditional.
if [ ! -f "$CONF_DIR/rsa.pem" ]; then
  openssl genrsa -traditional -out "$CONF_DIR/rsa.pem" 2048 >/dev/null 2>&1
  chmod 600 "$CONF_DIR/rsa.pem"
fi

# Password: $VNC_PASSWORD, an interactive prompt, or a generated one.
if [ -z "${VNC_PASSWORD:-}" ]; then
  if [ -t 0 ]; then
    read -rsp "VNC password: " VNC_PASSWORD; echo
  else
    VNC_PASSWORD="$(openssl rand -base64 12)"
    echo "Generated VNC password: $VNC_PASSWORD"
  fi
fi

cat > "$CONF_DIR/config" <<EOF
address=0.0.0.0
port=5900
enable_auth=true
certificate_file=$CONF_DIR/server.crt
private_key_file=$CONF_DIR/server.key
rsa_private_key_file=$CONF_DIR/rsa.pem
password=$VNC_PASSWORD
EOF
chmod 600 "$CONF_DIR/config"

# ---- systemd user service (auto-start with the graphical session) ----------
# Resolve the proxy's real path (cargo/mise/brew all install to different roots).
if command -v wl-uinput-proxy &>/dev/null; then
  WUIPROXY_BIN="$(command -v wl-uinput-proxy)"
else
  WUIPROXY_BIN="$HOME/.cargo/bin/wl-uinput-proxy"
fi

UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$UNIT_DIR"
cat > "$UNIT_DIR/wayvnc.service" <<EOF
[Unit]
Description=WayVNC — VNC server for the Wayland desktop
After=graphical-session.target
PartOf=graphical-session.target

[Service]
ExecStart=$WUIPROXY_BIN wayvnc
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable wayvnc.service
if ! systemctl --user start wayvnc.service; then
  echo "NOTE: could not start wayvnc now — check 'systemctl --user status wayvnc'."
  echo "      If the user was just added to the 'input' group, log out/in first."
fi

echo
echo "wayvnc is configured and should be running on port 5900."
echo "Connect from another machine to this host:5900 (auth enabled)."

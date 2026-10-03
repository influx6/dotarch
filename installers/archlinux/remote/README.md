# Remote access (VNC) — Arch Linux installers

Idempotent scripts that set up VNC remote access to this machine plus a firewall
that lets VNC (and SSH) in while keeping everything else closed. Each script is
safe to re-run.

| Script | What it does |
| --- | --- |
| `vnc-wayvnc.sh` | **Option A** — share the live niri (Wayland) desktop over VNC. |
| `vnc-tigervnc.sh` | **Option B** — a separate virtual Xfce desktop over VNC. |
| `firewall.sh` | ufw + gufw, default-deny incoming, allow SSH + VNC (and preserve LocalSend/Docker). |

This machine runs the **niri** Wayland compositor (Smithay-based). niri can
capture the screen, but its virtual keyboard/pointer is incomplete, so Option A
pairs `wayvnc` with `wl-uinput-proxy` to make remote input actually work.

---

## Option A — share the live niri desktop (wayvnc)

### Install

```bash
bash installers/archlinux/remote/vnc-wayvnc.sh
```

### What it sets up

- **`wayvnc`** (official repos) — the VNC server that captures the niri desktop
  via `ext-image-copy-capture`.
- **`wl-uinput-proxy`** (crates.io, via `cargo install`) — re-implements the
  virtual keyboard/pointer on the kernel's `uinput`, because niri's own virtual
  input is incomplete. Without it you can see the screen but not type or scroll.
- `/etc/udev/rules.d/90-uinput.rules` — lets the `input` group create
  `/dev/uinput` devices (and adds your user to that group).
- A self-signed TLS certificate + RSA key under `~/.config/wayvnc/` for
  authenticated, encrypted VNC.
- A **systemd user service** (`wayvnc.service`) that starts wayvnc with the
  graphical session and survives reboots.

### Password

The default VNC password is **`darkvoid`**. To use a different one, either:

```bash
# override at install time
VNC_PASSWORD='something-else' bash installers/archlinux/remote/vnc-wayvnc.sh
```

or edit the config directly (see [Changing the password](#changing-the-password)).

> This is a convenience default for a LAN-only setup. If the machine is ever
> reachable from outside your network, set a stronger password.

### Connect

From another machine on the LAN, point any VNC client at `<this-host-ip>:5900`
(e.g. `192.168.128.24:5900`):

- TigerVNC (`vncviewer`), RealVNC, Remmina, or any VNC client.
- **Username:** leave blank.
- **Password:** `darkvoid` (or whatever you set).
- Accept the self-signed certificate warning on first connect.

---

## Managing the service

The server runs as a per-user systemd service:

```bash
systemctl --user status wayvnc           # is it running?
systemctl --user start wayvnc
systemctl --user stop wayvnc
systemctl --user restart wayvnc
systemctl --user enable wayvnc           # auto-start on login (done by the script)
systemctl --user disable wayvnc
```

Logs:

```bash
journalctl --user -u wayvnc -f           # follow live
journalctl --user -u wayvnc -n 100       # last 100 lines
```

To run it by hand instead of the service (foreground):

```bash
wl-uinput-proxy wayvnc
```

## Changing the password

1. Edit `~/.config/wayvnc/config` and set `password=<new value>`.
2. Restart the service:

   ```bash
   systemctl --user restart wayvnc
   ```

Alternatively, re-run the installer with an override — it rewrites the config
and restarts the service:

```bash
VNC_PASSWORD='new-secret' bash installers/archlinux/remote/vnc-wayvnc.sh
```

---

## Option B — separate virtual desktop (TigerVNC)

If you want a clean remote desktop *instead of* sharing the live one:

```bash
bash installers/archlinux/remote/vnc-tigervnc.sh
```

This installs `xfce4` + TigerVNC and writes `~/.vnc/xstartup` so a session
launches Xfce. Then:

```bash
vncpasswd                              # set a VNC password (once)
vncserver -geometry 1920x1080 :1       # start display :1
```

Connect to `<host-ip>:5901` (display `:N` maps to port `5900+N`). Stop it with:

```bash
vncserver -kill :1
```

---

## Firewall (ufw + gufw)

`firewall.sh` installs `ufw` + `gufw` (the GTK frontend) and applies:

- **Default:** deny all incoming, allow all outgoing.
- **Open incoming:**
  - SSH — `22/tcp`
  - VNC — `5900/tcp` (wayvnc) and `5901-5903/tcp` (TigerVNC displays)
  - LocalSend — `53317/tcp` + `53317/udp`
  - Docker DNS — `53` on `docker0`
- **`ufw-docker`** protection so published Docker ports can't bypass the firewall.

The script is **additive and idempotent** — it never resets or drops existing
rules, so it's safe to re-run.

### Manage

```bash
sudo ufw status verbose                # show all rules
sudo ufw allow 1234/tcp comment '...'  # open a port
sudo ufw delete allow 1234/tcp         # remove it
sudo ufw disable                       # turn off
sudo ufw enable                        # turn on
```

`gufw` is the graphical frontend — launch it from the app menu to manage rules
visually.

---

## Troubleshooting

- **`Unsupported RSA private key format` / wayvnc segfaults on start** — OpenSSL
  3.x writes PKCS#8 keys by default, but neatvnc only accepts PKCS#1. The script
  generates the RSA key with `openssl genrsa -traditional`; if you regenerate
  `~/.config/wayvnc/rsa.pem` yourself, keep the `-traditional` flag.
- **Can see the screen but can't type/click** — `wl-uinput-proxy` isn't running
  or `/dev/uinput` isn't accessible. Check `systemctl --user status wayvnc` and
  that your user is in the `input` group (`id -nG`); re-login if you just joined.
- **Client rejects the certificate** — expected on first connect; the cert is
  self-signed, so accept it once.
- **Can't connect at all** — confirm the firewall allows the port
  (`sudo ufw status`) and that wayvnc is listening (`ss -tlnp | grep 5900`).

# DNS Breaks on PIA VPN (github.com won't resolve)

## Symptom

While the PIA VPN is connected, some hostnames fail to resolve even though the
network works fine:

- `git push` / `git fetch` fails with:
  `ssh: Could not resolve hostname github.com: No address associated with hostname`
- `curl https://github.com` fails, but `curl https://google.com` works.
- It looks random: some sites work, some don't.

## Root Cause

The failing hosts all have **no IPv6 (AAAA) DNS record** (github.com is one of
them). The working ones have AAAA records. That is the tell.

What actually happens:

1. PIA full-tunnels all traffic through `tun0`.
2. That makes the LAN's DHCP DNS server (the Wi-Fi router, e.g. `192.168.31.1`)
   **unreachable** — packets to it now go into the tunnel and die.
3. But `systemd-resolved` still lists that dead server as the **default-route
   DNS** on `wlan0`. PIA only rewrites `/etc/resolv.conf` (`foreign` mode); it
   does not fix resolved's per-link config.
4. `getaddrinfo()` does a combined A + AAAA lookup. For a domain **with** AAAA,
   at least one answer comes back and the call succeeds. For a domain **without**
   AAAA (github.com), the only "answer" is the failure from the dead LAN server,
   so glibc returns "no address" and the whole lookup fails.

Key evidence from the broken state:

- `getent hosts github.com` -> works (IPv4-only legacy path, `gethostbyname`)
- `getent ahosts github.com` -> empty / non-zero exit (`getaddrinfo`, A+AAAA)
- `resolvectl query github.com` -> `does not have any RR of the requested type`
- `resolvectl query -4 github.com` -> returns the A record fine
- `dig @<vpn-dns> github.com A` -> works; `dig @<lan-dns> ...` -> connection refused

## The Fix

Point the physical link's DNS at PIA's own resolver (`10.0.0.243`) instead of the
now-unreachable LAN DNS.

### Runtime (applies immediately, reverts on reconnect)

```bash
sudo resolvectl dns wlan0 10.0.0.243
sudo resolvectl flush-caches
```

### Persistent (automatic on every VPN up/down)

Installed as a NetworkManager dispatcher script:

`/etc/NetworkManager/dispatcher.d/90-pia-vpn-dns`

- On tunnel **up**  -> `resolvectl dns wlan0 10.0.0.243` + flush
- On tunnel **down** -> `resolvectl revert wlan0` + flush (restores DHCP DNS)

The tracked source lives in this repo at
`config/NetworkManager/dispatcher.d/90-pia-vpn-dns`. To (re)install it on a fresh
machine:

```bash
sudo install -o root -g root -m 0755 \
  ~/dotarch/config/NetworkManager/dispatcher.d/90-pia-vpn-dns \
  /etc/NetworkManager/dispatcher.d/90-pia-vpn-dns
```

Notes:
- The script hardcodes `phys_if="wlan0"` and `vpn_dns="10.0.0.243"`. If you
  switch the underlying link to ethernet, edit `phys_if` in that file.
- `10.0.0.243` is PIA's internal resolver and is stable across PIA servers.
- To undo: `sudo rm /etc/NetworkManager/dispatcher.d/90-pia-vpn-dns`.

## How to Diagnose Next Time

Run these in order. Each line tells you where the failure is.

```bash
# 1. Is it DNS-only? (name fails but the route to the IP is fine)
getent hosts github.com        # legacy IPv4 path — usually still works
getent ahosts github.com       # getaddrinfo (what ssh/curl use) — this is what fails

# 2. Confirm the A/AAAA split
resolvectl query github.com    # combined: fails in the broken state
resolvectl query -4 github.com # A only: succeeds -> confirms AAAA is the problem
resolvectl query -6 github.com # AAAA: "does not have any RR" for no-IPv6 hosts

# 3. See which DNS servers resolved is using, and on which link
resolvectl status              # look for stale per-link DNS + Default Route: yes
resolvectl dns                 # per-link DNS server list

# 4. Probe each DNS server directly to find the dead one
dig +short @10.0.0.243 github.com A       # PIA resolver — should answer
dig +short @192.168.31.1 github.com A     # LAN router — "connection refused" while on VPN

# 5. Prove connectivity is fine (only DNS is broken)
ssh -o HostKeyAlias=github.com -T git@$(getent hosts github.com | awk '{print $1}')
# "Host key verification failed" or a successful auth = the network path works,
# so the problem is name resolution, not routing/firewall.
```

## Emergency One-Off Push (if DNS is broken and you can't fix it yet)

Push over GitHub's resolved IP while still verifying its real host key:

```bash
IP=$(getent hosts github.com | awk '{print $1}')
GIT_SSH_COMMAND="ssh -o HostKeyAlias=github.com" \
  git push "git@${IP}:influx6/dotarch.git" HEAD:master
```

Nothing is persisted; it just sidesteps the broken `getaddrinfo` for one command.

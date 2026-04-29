# PiHole + DNS over HTTPS

## Overview
This sets up PiHole for DNS-level ad/tracker blocking with encrypted upstream DNS via
DNS over HTTPS (DoH) using dnscrypt-proxy. Two containers run via Docker Compose:

1. **dnscrypt-proxy** - Built from source, forwards DNS queries to Cloudflare over HTTPS
2. **PiHole** - Intercepts spam, trackers, and malicious domains

## Requirements
- Docker and Docker Compose
- Port 53 available on the host (see below)

## Ubuntu: Free up port 53
```bash
sudo nano /etc/systemd/resolved.conf

# Uncomment and set:
DNSStubListener=no

# Save and reboot
```

## Setup
On first install, the Docker build needs DNS to pull images and clone repos. If this
machine is your network's DNS server and nothing is running yet, temporarily point the
system to an external resolver:
```bash
sudo sh -c 'echo "nameserver 1.1.1.1" > /etc/resolv.conf'
```

Then build and start:
```bash
git clone https://github.com/jbencina/vpn.git
cd vpn
docker compose build
docker compose up -d
```

Once the stack is running, restore the system DNS to point back at this machine
(`nameserver <this machine's IP>`) so all queries go through PiHole.

PiHole is configured to use dnscrypt-proxy (`127.0.0.1#5053`) as its upstream resolver.
You may need to update the upstream in PiHole's admin UI or `/etc/pihole/pihole.toml` if
the setting doesn't persist from the environment variable.

## Bridge networking
The default `docker-compose.yaml` uses host networking, which is simplest for a dedicated
DNS box. For cloud VMs or shared hosts where you want container isolation, use the bridge
variant:
```bash
docker compose -f docker-compose.bridge.yaml up -d
```

This places containers on a private `172.20.0.0/24` subnet with static IPs and explicit
port mappings. When using bridge mode, update `listen_addresses` in
`dnscrypt-proxy/dnscrypt-proxy.toml` to `'0.0.0.0:5053'`.

## Updating
Run the update script to pull the latest PiHole image and rebuild dnscrypt-proxy from
the latest upstream release:
```bash
./update-server
```

## WireGuard VPN
To use PiHole ad blocking and DoH when away from your network, install
[PiVPN](https://pivpn.io) on the same host:
```bash
curl -L https://install.pivpn.io | bash
```

During setup, set the DNS to the VPN host's tunnel address (e.g. `10.15.20.1`) so all
VPN client traffic routes through PiHole.

## Verify DoH
Visit https://1.1.1.1/help to confirm DNS over HTTPS is working.

## References
- https://github.com/pi-hole/docker-pi-hole
- https://github.com/DNSCrypt/dnscrypt-proxy
- https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/

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

## Networking
Both containers run on a private `172.20.0.0/24` bridge network with static IPs, and PiHole
publishes ports 53 (TCP/UDP) and 80 to the host. PiHole is configured to use
dnscrypt-proxy (`172.20.0.3#5053`) as its upstream resolver via `FTLCONF_dns_upstreams`.
Because that setting comes from the environment, it is pinned and cannot be changed in the
admin UI — edit `docker-compose.yaml` to change upstreams.

`FTLCONF_dns_listeningMode: 'ALL'` is required in bridge mode. PiHole's default (`LOCAL`)
only answers clients on a subnet attached to its own interface, which is just
`172.20.0.0/24` inside the container, so LAN clients would be refused.

## Admin password
On first start, PiHole v6 generates a random admin/API password and logs it. The hash is
stored in `etc-pihole/pihole.toml`, so it persists across restarts and updates:
```bash
docker logs pihole 2>&1 | grep -i password
```
If that first-start log is gone, set a new one:
```bash
docker exec -it pihole pihole setpassword
```
To pin it in config instead, set `FTLCONF_webserver_api_password` in `docker-compose.yaml`.

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

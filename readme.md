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
```bash
git clone https://github.com/jbencina/vpn.git
cd vpn
docker compose build
docker compose up -d
```

PiHole is configured to use dnscrypt-proxy (`127.0.0.1#5053`) as its upstream resolver.
You may need to update the upstream in PiHole's admin UI or `/etc/pihole/pihole.toml` if
the setting doesn't persist from the environment variable.

## Updating
Run the update script to pull the latest PiHole image and rebuild dnscrypt-proxy from
the latest upstream release:
```bash
./update-server
```

## Verify DoH
Visit https://1.1.1.1/help to confirm DNS over HTTPS is working.

## References
- https://github.com/pi-hole/docker-pi-hole
- https://github.com/DNSCrypt/dnscrypt-proxy
- https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/

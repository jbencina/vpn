# Installing Wireguard, PiHole, Cloudflared VPN
## Overview
This guide provides a complete reference for setting up your own Wireguard VPN server
with PiHole for malicious/advertising DNS blocking and Cloudflared tunnel for DNS over
HTTPS. Three components are covered in this guide:

1. Wireguard VPN - Encryption between your device & the server
2. PiHole - Interception of spam, trackers, and malicious urls
3. Cloudflared - DNS over HTTPS to Cloudflare to prevent DNS hijacking and snooping

## Provisioning a Server
You can use your cloud provider of choice here (or run it at your home). Google Cloud
offers free VM instances which is likely sufficient for most users. But you can run
this pretty much anywhere with little modifications.

Regardless of platform, you'll want to make sure that:
1. The server has a static public-facing IP address
2. The server has the Wireguard UDP port open

## Docker Install
We'll be using Docker Compose to run PiHole/Cloudflared. Follow the standard install
guides appropriate for your server:
1. Install Docker CE - https://docs.docker.com/install/linux/docker-ce/ubuntu/
2. Install Docker Compose - Docker Compose is now included in the main instructions

Configure Docker to automatically start
```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

## Ubuntu instructions
We'll need to free up port 53 on Ubuntu by running the following commands
```bash
sudo nano /etc/systemd/resolved.conf

# Uncomment the following line, changing the value to np
# Save and reboot

DNSStubListener=no
```

## Debian instructions
If working with Debian, you'll find some packages are not already installed like on
Ubuntu. You'll have to install the Linux headers and dig for everything to run smoothly
```bash
sudo apt-get install linux-headers-$(uname -r)
sudo apt install dnsutils
```
## Wireguard Install
The easiest install path is to simply use PiVPN which enables you to choose either
Wireguard (or OpenVPN) as your backend. You can run the latest installer using either
the interactive method (https://docs.pivpn.io/install/)
```bash
curl -L https://install.pivpn.io | bash
```

Since we are using PiHole and Cloudflared, be sure to route your DNS to 0.0.0.0 during
PiVPN setup.

## Pihole / Cloudflared
We run both these services as a simple Docker compose. No configuration changes to
`docker-compose.yaml` should be needed except for PiHole the time zone. What this does
is spins up 2 Docker containers.
- One contains the Cloudflared DNS over HTTPS
- One contains PiHole which uses the supplied Docker image

Each is assigned a static IP and PiHole is configured to use Cloudflared as its
DNS resolver. To kick off the service:

```bash
wget https://raw.githubusercontent.com/jbencina/vpn/master/docker-compose.yaml
sudo docker compose pull
sudo docker compose up -d
```

## Conclusion
You can now connect to Wireguard from your client and enjoy ad free browsing.
You can also visit https://1.1.1.1/help to verify that DNS over HTTPS is working

## References
These guides helped me piece this together and provide more details than this guide alone
https://github.com/pi-hole/docker-pi-hole
https://www.wireguard.com/install/
https://developers.cloudflare.com/1.1.1.1/dns-over-https/cloudflared-proxy/

Other setup guides
https://www.reddit.com/r/pihole/comments/bl4ka8/guide_pihole_on_the_go_with_wireguard/
https://medium.com/@aveek/setting-up-pihole-wireguard-vpn-server-and-client-ubuntu-server-fc88f3f38a0a

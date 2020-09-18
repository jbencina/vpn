# Installing Wireguard, PiHole, Cloudflared VPN
## Overview
This guide provides a complete reference for setting up your own Wireguard VPN server with PiHole for malicious/advertising DNS blocking and
Cloudflared for DNS over HTTPS. There are many VPN providers that simplify this process for you, but the approach in this guide gives you
full control and ownership of the setup.

There are two reasons why you would want this setup:
1. Secured VPN connection when using wifi networks outside of your home
2. Automatic blocking of advertisting, tracking, and malicious domains

## Provisioning a Server
You can use your cloud provider of choice here (or run it at your home). I'm using a Google Cloud g1-small instance which runs about $13/mo for
24x7. The steps are pretty simple:
1. Launch a g1-small instance in the region closest to you. I used the latest Ubuntu LTS version for the base image.
2. Assign a static IP address to the instance once available.
3. Decide what port Wireguard will run on and expose only that UDP port via the Google VPC firewall. You can open SSH as well, but I keep SSH closed making it accessible via the VPN connection only.
4. Generate an SSH key on your desktop/laptop/mobile device and transfer the public key to the Metadata section under GCP Compute. The key should have your Google username as the comment.

## Docker Install
We'll be using Docker to run PiHole/Cloudflared:
1. SSH into the machine
2. Install Docker CE - https://docs.docker.com/install/linux/docker-ce/ubuntu/
3. Install Docker Compose - https://docs.docker.com/compose/install/

## Debian instructions
If working with Debian, you'll find some packages are not already installed like on Ubuntu. You'll have to install
the Linux headers and dig for everything to run smoothly

```
sudo apt-get install linux-headers-$(uname -r)
sudo apt install dnsutils
```

## Wireguard Install
Wireguard is our VPN service as a lightweight alternative to OpenVPN. It is still considered a new product with some debate on whether it is more or less secure than OpenVPN. I like Wireguard for its simple setup and stateless connection. The latter is great for mobile devices since it means your phone will always use the VPN tunnel without having to manually rejoin if the connection breaks.

SSH into your server and enable IP forwarding

```
nano /etc/sysctl.conf
net.ipv4.ip_forward = 1

# Reload
sudo sysctl --system
```

Install Wireguard using apt get. We'll also generate the server's keypair.

```
sudo apt-get update
sudo apt-get install wireguard
```

Next let's run the configuration script for the Wireguard server

```
sudo sh vpn/scripts/make-server.sh
Server Port: <Pick a port to run on>
Server Device: <Pick a the network device to foward to. Typically eth0>
```

This creates a public/private key in the Wireguard folder along with a Wireguard
wg0.conf file. If you are unsure of the correct network device name try running
`route -n` to see which should be used.

Next we can create a new client using the client script:

```
sudo sh vpn/scripts/make-client.sh
Client name: <Pick a friendly name for the client>
Client IP Last Octet: <Choose a number from 2-254. Unique per client>
```

This creates the public/private keypair for the client in `/keys`. The config files
are saved to `/configs`. Copy the peer config into the Wireguard config.
```
# Copy this [Peer] block
cat configs/CLIENT_NAME_peer.conf

# Append it to your wg0.conf
sudo nano /etc/wireguard/wg0.conf
```

Let's start Wireguard and set it as a service so it always runs.

```
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

To quickly move the client config to your mobile device use a QR code generator tool

```
sudo apt install qrencode
cat configs/CLIENT_NAME.conf | qrencode -t UTF8
```

## Pihole / Cloudflared
We run both these services as a simple Docker compose. No configuration changes to `docker-compose.yaml` should be needed except for the time zone. What this does is spins up 2 Docker containers.
- One contains a DNS over HTTPS proxy which I've put into a Docker https://developers.cloudflare.com/1.1.1.1/dns-over-https/cloudflared-proxy/
- One contains PiHole which uses the supplied Docker image

Each is assigned a static IP and PiHole is configured to use cloudflared as its DNS resolver. To kick off the service:

```
ln -s vpn/docker-compose.yaml docker-compose.yaml
sudo docker-compose up -d
```

Note: If you are running Ubuntu, make sure to follow the pihole docker instructions on
disabling systemd-resolved which conflicts with port 53

## Conclusion
You can now connect to Wireguard from your client and enjoy ad free browsing. You can also visit https://1.1.1.1/help to verify that DNS over HTTPS is working

## References
These guides helped me piece this together and provide more details than this guide alone
https://github.com/pi-hole/docker-pi-hole
https://www.wireguard.com/install/
https://developers.cloudflare.com/1.1.1.1/dns-over-https/cloudflared-proxy/

Other setup guides
https://www.reddit.com/r/pihole/comments/bl4ka8/guide_pihole_on_the_go_with_wireguard/
https://medium.com/@aveek/setting-up-pihole-wireguard-vpn-server-and-client-ubuntu-server-fc88f3f38a0a

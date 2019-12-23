# Installing Wireguard, PiHole, Cloudflared VPN
## Overview
This guide provides a complete reference for setting up your own Wireguard VPN server with PiHole for malicious/advertising DNS blocking and Cloudflared for DNS over HTTPS. There are many VPN providers that simplify this process for you, but the approach in this guide gives you full control and ownership of the setup.

There are two reasons why you would want this setup:
1. Secured VPN connection when using wifi networks outside of your home
2. Automatic blocking of advertisting, tracking, and malicious domains

## Google Cloud
You can use your cloud provider of choice here (or run it at your home). I'm using a Google Cloud g1-small instance which runs about $13/mo for 24x7. The steps are pretty simple:
1. Launch a g1-small instance in the region closest to you. I used the latest Ubuntu LTS version for the base image.
2. Assign a static IP address to the instance once available.
3. Decide what port Wireguard will run on and expose only that UDP port via the Google VPC firewall. You can open SSH as well, but I keep SSH closed making it accessible via the VPN connection only.
4. Generate an SSH key on your desktop/laptop/mobile device and transfer the public key to the Metadata section under GCP Compute. The key should have your Google username as the comment.

## Docker Install
We'll be using Docker to run PiHole/Cloudflared:
1. SSH into the machine
2. Install Docker CE - https://docs.docker.com/install/linux/docker-ce/ubuntu/
3. Install Docker Compose - https://docs.docker.com/compose/install/

## Wireguard Install
Wireguard is our VPN service as a lightweight alternative to OpenVPN. It is still considered a new product with some debate on whether it is more or less secure than OpenVPN. I like Wireguard for its simple setup and stateless connection. The latter is great for mobile devices since it means your phone will always use the VPN tunnel without having to manually rejoin if the connection breaks.

SSH into your server and enable IP forwarding
```
nano /etc/sysctl.conf
net.ipv4.ip_forward = 1
```

Install Wireguard using apt get. We'll also generate the server's keypair.
```
sudo add-apt-repository ppa:wireguard/wireguard
sudo apt-get update
sudo apt-get install wireguard
cd /etc/wireguard
wg genkey | tee privatekey | wg pubkey > publickey
nano wg0.conf
```

We'll create the `wg0.conf` file in `/etc/wireguard` by pasting in the following settings. The `[Interface]` section you should update with the private key from the previous step (`cat privatekey`) and whichever available port you'd like to use. You add new `[Peer]` sections for each desktop/laptop/phone. When you install the iOS client for example, it will display the public key which you should paste in here.
```
[Interface]
PrivateKey = xxx
Address = 10.0.0.1/24,fd86:ea04:1111::1/64
ListenPort = 12345
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE; ip6tables -t nat -D POSTROUTING -o ens4 -j MASQUERADE

[Peer]
PublicKey = xxx
PresharedKey = xxx # Generate with wg genpsk for each peer
AllowedIPs = 10.0.0.2/32,fd86:ea04:1111::2/128 # Increment by one for each new client
```
Let's start Wireguard and set it as a service so it always runs.
```
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```
On your client devices you should have a mirror configuration such as below. It's important to note that Wireguard is not only looking for the right keys, but also that clients are using the expected IP address it's been assigned to in the server config.
```
[Interface]
PrivateKey = device_key
Address = 10.0.0.2/32, fd86:ea04:1111::2/128 # Match to server config
DNS = 10.0.0.1
MTU = 1360 # Addresses issue with GCP UDP

[Peer]
PublicKey = server_public_key
PresharedKey = server_psk
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = server_ip/port
```
## Pihole / Cloudflared
We run both these services as a simple Docker compose. No configuration changes to `docker-compose.yaml` should be needed except for the time zone. What this does is spins up 2 Docker containers.
- One contains a DNS over HTTPS proxy which I've put into a Docker https://developers.cloudflare.com/1.1.1.1/dns-over-https/cloudflared-proxy/
- One contains PiHole which uses the supplied Docker image

Each is assigned a static IP and PiHole is configured to use cloudflared as its DNS resolver.
1. Copy `docker-compose.yaml` to `~/docker-compose.yaml`
2. Run `sudo docker-compose up -d`

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
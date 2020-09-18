#!/bin/bash
# Modified from PiVPN https://github.com/pivpn/pivpn/blob/master/scripts/wireguard/makeCONF.sh

if [ ! -d "keys" ]; then
    mkdir "keys"
fi

if [ ! -d "configs" ]; then
    mkdir "configs"
fi

PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

read -p "Client name: " CLIENT_NAME
read -p "Client IP Last Octet (eg. 10.0.53.x): " CLIENT_IP

wg genkey | tee "keys/${CLIENT_NAME}_priv" | wg pubkey > "keys/${CLIENT_NAME}_pub"
wg genpsk | tee "keys/${CLIENT_NAME}_psk" &> /dev/null
echo "Generated keys..."

echo -n "[Interface]
PrivateKey = $(cat "keys/${CLIENT_NAME}_priv")
Address = 10.0.53.${CLIENT_IP}/32, fd86:ea04:1111::${CLIENT_IP}/128
DNS = 10.0.53.1

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
PresharedKey = $(cat "keys/${CLIENT_NAME}_psk")
Endpoint = ${PUBLIC_IP}:54800
AllowedIPs = 0.0.0.0/0, ::0/0" > "configs/${CLIENT_NAME}.conf"

echo "Generated config..."

echo -n "[Peer]
PublicKey = $(cat "keys/${CLIENT_NAME}_pub")
PresharedKey = $(cat "keys/${CLIENT_NAME}_psk")
AllowedIPs = 10.0.53.${CLIENT_IP}/32, fd86:ea04:1111::${CLIENT_IP}/128" > "configs/${CLIENT_NAME}_peer.conf"

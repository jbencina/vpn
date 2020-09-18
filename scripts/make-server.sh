#!/bin/bash

read -p "Server Path: " SERVER_PATH
read -p "Server Port: " SERVER_PORT
read -p "Server Device: " SERVER_DEVICE

if [ ! -d ${SERVER_PATH} ]; then
    mkdir ${SERVER_PATH}
fi

wg genkey | tee "${SERVER_PATH}/privatekey" | wg pubkey > "${SERVER_PATH}/publickey"
echo "Generated keys..."

echo -n "[Interface]
PrivateKey = $(cat "${SERVER_PATH}/privatekey")
Address = 10.0.0.1/24,fd86:ea04:1111::1/64
ListenPort = ${SERVER_PORT}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_DEVICE} -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${SERVER_DEVICE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_DEVICE} -j MASQUERADE; ip6tables -t nat -D POSTROUTING -o ${SERVER_DEVICE} -j MASQUERADE" > "${SERVER_PATH}/wg0.conf"

echo "Generated server config..."

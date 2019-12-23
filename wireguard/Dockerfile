# This Dockerfile is not complete and WIP
FROM ubuntu:latest
RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository ppa:wireguard/wireguard && \
    apt-get update && apt-get install -y wireguard iptables
RUN wg genkey | tee privatekey | wg pubkey > publickey
COPY wg0.conf /etc/wireguard
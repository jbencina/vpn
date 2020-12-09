FROM debian:latest
RUN apt-get update && apt-get install -y curl dnsutils
RUN curl https://bin.equinox.io/a/3wiMFEesiD8/cloudflared-2020.12.0-linux-amd64.deb --output cloudflared-stable-linux-amd64.deb
RUN apt install /cloudflared-stable-linux-amd64.deb

ENV TZ="UTC" \
  TUNNEL_METRICS="0.0.0.0:49312" \
  TUNNEL_DNS_ADDRESS="0.0.0.0" \
  TUNNEL_DNS_PORT="5053" \
  TUNNEL_DNS_UPSTREAM="https://1.1.1.1/dns-query,https://1.0.0.1/dns-query"

RUN cloudflared --version
ENTRYPOINT ["cloudflared"]
CMD [ "proxy-dns" ]
HEALTHCHECK --interval=30s --timeout=20s --start-period=10s CMD dig +short @127.0.0.1 -p 5053 cloudflare.com A || exit 1
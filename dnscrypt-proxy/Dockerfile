FROM golang:alpine AS build
RUN apk add --no-cache git curl
RUN LATEST=$(curl -sSL https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4) \
    && echo "Building dnscrypt-proxy ${LATEST}" \
    && git clone --depth 1 --branch "${LATEST}" https://github.com/DNSCrypt/dnscrypt-proxy.git /src
WORKDIR /src/dnscrypt-proxy
RUN go build -o /dnscrypt-proxy .

FROM alpine
COPY --from=build /dnscrypt-proxy /usr/local/bin/dnscrypt-proxy
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
ENTRYPOINT ["dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/dnscrypt-proxy.toml"]

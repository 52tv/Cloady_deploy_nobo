FROM alpine:3.22

ARG SING_BOX_VERSION=1.14.4

RUN apk add --no-cache ca-certificates openssl wget \
    && wget -qO- "https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-amd64-musl.tar.gz" \
        | tar xz -C /tmp \
    && mv "/tmp/sing-box-${SING_BOX_VERSION}-linux-amd64-musl/sing-box" /usr/local/bin/sing-box \
    && chmod +x /usr/local/bin/sing-box \
    && rm -rf /tmp/sing-box-* \
    && sing-box version

COPY config.template /opt/sing-box/config.template
COPY start.sh /opt/sing-box/start.sh
RUN chmod +x /opt/sing-box/start.sh

EXPOSE 30080/tcp
EXPOSE 30080/udp

CMD ["/opt/sing-box/start.sh"]

#!/bin/sh
set -eu

STATE=/var/lib/sing-box
CONF=/etc/sing-box/config.json
TEMPLATE=/opt/sing-box/config.template
SNI="${HY2_SNI:-www.bing.com}"

mkdir -p "$STATE" "$(dirname "$CONF")"

# HY2 requires a TLS certificate. Generated once and kept on the volume so the
# key never appears in the image or in the app's environment.
if [ ! -s "$STATE/hy2-key.pem" ] || [ ! -s "$STATE/hy2-cert.pem" ]; then
    openssl ecparam -name prime256v1 -genkey -noout -out "$STATE/hy2-key.pem"
    openssl req -new -x509 -key "$STATE/hy2-key.pem" -out "$STATE/hy2-cert.pem" \
        -days 3650 -subj "/CN=$SNI" -addext "subjectAltName=DNS:$SNI"
    chmod 600 "$STATE/hy2-key.pem"
fi

for var in VLESS_UUID REALITY_PRIVATE_KEY REALITY_SHORT_ID HY2_PASSWORD HY2_OBFS_PASSWORD REALITY_HANDSHAKE_SERVER WS_PATH; do
    eval "value=\${$var:-}"
    [ -n "$value" ] || { echo "missing required variable: $var" >&2; exit 1; }
done

sed \
    -e "s|__VLESS_UUID__|$VLESS_UUID|g" \
    -e "s|__REALITY_PRIVATE_KEY__|$REALITY_PRIVATE_KEY|g" \
    -e "s|__REALITY_SHORT_ID__|$REALITY_SHORT_ID|g" \
    -e "s|__REALITY_HANDSHAKE_SERVER__|$REALITY_HANDSHAKE_SERVER|g" \
    -e "s|__HY2_PASSWORD__|$HY2_PASSWORD|g" \
    -e "s|__HY2_OBFS_PASSWORD__|$HY2_OBFS_PASSWORD|g" \
    -e "s|__WS_PATH__|$WS_PATH|g" \
    "$TEMPLATE" > "$CONF"

chmod 600 "$CONF"

sing-box check -c "$CONF"
exec sing-box run -c "$CONF"

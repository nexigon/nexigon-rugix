#!/usr/bin/env bash

set -euo pipefail

VERSION=${RECIPE_PARAM_VERSION}
USE_MUSL=${RECIPE_PARAM_USE_MUSL}

case "${RUGIX_ARCH}" in
    "amd64")
        if [ "${USE_MUSL}" = "true" ]; then
            TARGET="x86_64-unknown-linux-musl"
        else
            TARGET="x86_64-unknown-linux-gnu"
        fi
        ;;
    "arm64")
        if [ "${USE_MUSL}" = "true" ]; then
            TARGET="aarch64-unknown-linux-musl"
        else
            TARGET="aarch64-unknown-linux-gnu"
        fi
        ;;
    *)
        echo "Unsupported architecture '${RUGIX_ARCH}'."
        exit 1
esac

curl -sfSL \
    -o /usr/bin/nexigon-agent \
    -H "X-Nexigon-Download: true" \
    "https://downloads.nexigon.dev/nexigon-agent/$VERSION/assets/$TARGET/nexigon-agent"

chmod 755 /usr/bin/nexigon-agent

mkdir -p /etc/rugix/state
cat >/etc/rugix/state/nexigon.toml <<EOF
[[persist]]
directory = "/etc/nexigon/agent/ssl"
EOF

install -D -m 644 "${RECIPE_DIR}/files/nexigon-agent.service" -t /etc/systemd/system
systemctl enable nexigon-agent

install -D -m 755 "${RECIPE_DIR}/files/nexigon-device-fingerprint" -t /usr/libexec/nexigon

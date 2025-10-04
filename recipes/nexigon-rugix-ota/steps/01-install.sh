#!/bin/bash

set -euo pipefail

install -D -m 755 "${RECIPE_DIR}/files/nexigon-rugix-ota" -t /usr/bin
install -D -m 644 "${RECIPE_DIR}/files/nexigon-rugix-ota.service" -t /lib/systemd/system
install -D -m 644 "${RECIPE_DIR}/files/nexigon-rugix-ota.timer" -t /lib/systemd/system

sed -i "s|@@INTERVAL@@|${RECIPE_PARAM_INTERVAL}|g" /lib/systemd/system/nexigon-rugix-ota.timer

echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"
. "${RUGIX_PROJECT_DIR}/.env"

if [ -z "${NEXIGON_REPOSITORY:-}" ]; then
    echo "[ERROR] NEXIGON_REPOSITORY is not set"
    exit 1
fi

if [ -z "${NEXIGON_PACKAGE:-}" ]; then
    echo "[ERROR] NEXIGON_PACKAGE is not set"
    exit 1
fi

cat <<EOF >/etc/nexigon-rugix-ota.conf
VERSION_PATH="${NEXIGON_REPOSITORY}/${NEXIGON_PACKAGE}/stable"
EOF

systemctl enable nexigon-rugix-ota.timer

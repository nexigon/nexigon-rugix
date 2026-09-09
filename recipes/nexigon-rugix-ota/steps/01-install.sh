#!/bin/bash

set -euo pipefail

install -D -m 755 "${RECIPE_DIR}/files/nexigon-rugix-ota" -t /usr/bin
install -D -m 644 "${RECIPE_DIR}/files/nexigon-rugix-ota.service" -t /lib/systemd/system
install -D -m 644 "${RECIPE_DIR}/files/nexigon-rugix-ota.timer" -t /lib/systemd/system

sed -i "s|@@INTERVAL@@|${RECIPE_PARAM_INTERVAL}|g" /lib/systemd/system/nexigon-rugix-ota.timer

if [ -f "${RUGIX_PROJECT_DIR}/.env" ]; then
    echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"
    . "${RUGIX_PROJECT_DIR}/.env"
fi

if { [ -n "${NEXIGON_REPOSITORY:-}" ] && [ -z "${NEXIGON_PACKAGE:-}" ]; } \
    || { [ -z "${NEXIGON_REPOSITORY:-}" ] && [ -n "${NEXIGON_PACKAGE:-}" ]; }; then
    echo "[ERROR] NEXIGON_REPOSITORY and NEXIGON_PACKAGE must be set together"
    exit 1
fi

if [ -n "${NEXIGON_REPOSITORY:-}" ]; then
    cat <<EOF >/etc/nexigon-rugix-ota.json
{"path": "${NEXIGON_REPOSITORY}/${NEXIGON_PACKAGE}/${RECIPE_PARAM_TAG}", "rugix": {"useBundleHash": ${RECIPE_PARAM_USE_BUNDLE_HASH}}}
EOF
else
    cat <<EOF >/etc/nexigon-rugix-ota.json
{"rugix": {"useBundleHash": ${RECIPE_PARAM_USE_BUNDLE_HASH}}}
EOF
fi

if [ -d "${RECIPE_DIR}/cmds" ]; then
    install -D -m 644 "${RECIPE_DIR}"/cmds/*.toml -t /etc/nexigon/agent/commands
fi

systemctl enable nexigon-rugix-ota.timer

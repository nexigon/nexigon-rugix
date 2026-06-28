#!/usr/bin/env bash

set -euo pipefail

mkdir -p /etc/nexigon
cp "${RECIPE_DIR}/files/nexigon-agent.toml" /etc/nexigon/agent.toml

if [ "${RECIPE_PARAM_PROVISIONING}" = "true" ]; then
    cat >> /etc/nexigon/agent.toml <<EOF

[provisioning]
enabled = true
EOF
else
    # Inject static deployment configuration from the local environment.
    echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"
    . "${RUGIX_PROJECT_DIR}/.env"

    if [ -z "${NEXIGON_HUB_URL:-}" ]; then
        echo "[ERROR] NEXIGON_HUB_URL is not set"
        exit 1
    fi

    if [ -z "${NEXIGON_TOKEN:-}" ]; then
        echo "[ERROR] NEXIGON_TOKEN is not set"
        exit 1
    fi

    cat >> /etc/nexigon/agent.toml <<EOF

hub-url = "${NEXIGON_HUB_URL}"
token = "${NEXIGON_TOKEN}"
EOF
fi

echo "${RECIPE_PARAM_EXTRA_CONFIG}" >> /etc/nexigon/agent.toml

#!/usr/bin/env bash

set -euo pipefail

install -D -m 644 "${RECIPE_DIR}/files/nexigon-agent.toml" -t /etc/nexigon/agent.toml

# Inject configuration from local environment.
echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"
. "${RUGIX_PROJECT_DIR}/.env"
sed -i "s@%%HUB_URL%%@${NEXIGON_HUB_URL}@g" /etc/nexigon/agent.toml
sed -i "s@%%TOKEN%%@${NEXIGON_TOKEN}@g" /etc/nexigon/agent.toml

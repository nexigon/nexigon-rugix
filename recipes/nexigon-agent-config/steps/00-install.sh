#!/usr/bin/env bash

set -euo pipefail

mkdir -p /etc/nexigon
cp "${RECIPE_DIR}/files/nexigon-agent.toml" /etc/nexigon/agent.toml

# Inject configuration from local environment.
echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"
. "${RUGIX_PROJECT_DIR}/.env"
sed -i "s@%%HUB_URL%%@${NEXIGON_HUB_URL}@g" /etc/nexigon/agent.toml
sed -i "s@%%TOKEN%%@${NEXIGON_TOKEN}@g" /etc/nexigon/agent.toml

echo "${RECIPE_PARAM_EXTRA_CONFIG}" >> /etc/nexigon/agent.toml

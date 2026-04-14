#!/bin/bash
set -euo pipefail

install -D -m 644 "${RECIPE_DIR}"/cmds/*.toml -t /etc/nexigon/agent/commands
install -D -m 755 "${RECIPE_DIR}"/files/* -t /usr/libexec/nexigon

#!/usr/bin/env bash

set -euo pipefail

install -D -m 755 "${RECIPE_DIR}/files/nexigon-device-identity" -t /usr/libexec/nexigon

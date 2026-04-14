#!/bin/bash

set -euo pipefail

install -D -m 755 "${RECIPE_DIR}/files/nexigon-rugix-watchdog" -t /usr/libexec/nexigon
install -D -m 644 "${RECIPE_DIR}/files/nexigon-rugix-watchdog.service" -t /lib/systemd/system
install -D -m 644 "${RECIPE_DIR}/files/nexigon-rugix-watchdog.timer" -t /lib/systemd/system

sed -i "s|@@TIMEOUT@@|${RECIPE_PARAM_TIMEOUT}|g" /lib/systemd/system/nexigon-rugix-watchdog.timer

systemctl enable nexigon-rugix-watchdog.timer

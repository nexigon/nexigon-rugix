#!/bin/bash
set -euo pipefail

case "${RECIPE_PARAM_USE_BUNDLE_HASH}" in
    true | false)
        ;;
    *)
        echo "[ERROR] use_bundle_hash must be true or false" >&2
        exit 1
        ;;
esac

install -D -m 644 "${RECIPE_DIR}"/cmds/*.toml -t /etc/nexigon/agent/commands
install -D -m 755 "${RECIPE_DIR}"/files/* -t /usr/libexec/nexigon

sed -i \
    "s|@@USE_BUNDLE_HASH@@|${RECIPE_PARAM_USE_BUNDLE_HASH}|g" \
    /usr/libexec/nexigon/nexigon-rugix-apps-deploy

install -D -m 644 "${RECIPE_DIR}"/systemd/* -t /lib/systemd/system
sed -i \
    "s|^DEFAULT_USE_BUNDLE_HASH = \"false\"$|DEFAULT_USE_BUNDLE_HASH = \"${RECIPE_PARAM_USE_BUNDLE_HASH}\"|" \
    /usr/libexec/nexigon/nexigon-rugix-apps-reconcile
mkdir -p /etc/rugix/state
cat >/etc/rugix/state/nexigon-rugix-apps.toml <<EOF
[[persist]]
directory = "/var/lib/nexigon/rugix-apps"
EOF
systemctl enable nexigon-rugix-apps-reconcile.timer

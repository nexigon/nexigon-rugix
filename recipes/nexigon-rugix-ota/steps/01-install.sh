#!/bin/bash

set -euo pipefail

if [ ! -f /etc/nexigon/agent.toml ]; then
    echo "[ERROR] /etc/nexigon/agent.toml does not exist, include nexigon-agent-config"
    exit 1
fi

timespan_secs() {
    local total=0 value unit part multiplier seconds
    local -a parts
    if [[ -z "${1//[[:space:]]/}" || "$1" == *$'\n'* ]]; then
        echo "[ERROR] invalid time span '$1'" >&2
        exit 1
    fi
    read -r -a parts <<<"$1"
    for part in "${parts[@]}"; do
        if [[ ! "${part}" =~ ^([0-9]+)(s|sec|m|min|h|d)?$ ]]; then
            echo "[ERROR] invalid time span '$1'" >&2
            exit 1
        fi
        value=${BASH_REMATCH[1]}
        unit=${BASH_REMATCH[2]:-s}
        value=${value#"${value%%[!0]*}"}
        value=${value:-0}
        seconds=$((10#${value}))
        if [[ "${seconds}" != "${value}" ]]; then
            echo "[ERROR] time span '$1' is out of range" >&2
            exit 1
        fi
        case "${unit}" in
        s | sec) multiplier=1 ;;
        m | min) multiplier=60 ;;
        h) multiplier=3600 ;;
        d) multiplier=86400 ;;
        esac
        seconds=$((seconds * multiplier))
        if ((seconds < 0 || seconds / multiplier != value || total + seconds < total)); then
            echo "[ERROR] time span '$1' is out of range" >&2
            exit 1
        fi
        total=$((total + seconds))
    done
    echo "${total}"
}

CHECK_INTERVAL_SECS=$(timespan_secs "${RECIPE_PARAM_INTERVAL}")
CHECK_JITTER_SECS=$(timespan_secs "${RECIPE_PARAM_JITTER}")
if [ "${CHECK_INTERVAL_SECS}" -eq 0 ]; then
    echo "[ERROR] interval must be positive"
    exit 1
fi

case "${RECIPE_PARAM_USE_BUNDLE_HASH}" in
true | false) ;;
*)
    echo "[ERROR] use_bundle_hash must be 'true' or 'false'"
    exit 1
    ;;
esac

if [ -f "${RUGIX_PROJECT_DIR}/.env" ]; then
    echo ".env" >>"${LAYER_REBUILD_IF_CHANGED}"
    . "${RUGIX_PROJECT_DIR}/.env"
fi

if { [ -n "${NEXIGON_REPOSITORY:-}" ] && [ -z "${NEXIGON_PACKAGE:-}" ]; } ||
    { [ -z "${NEXIGON_REPOSITORY:-}" ] && [ -n "${NEXIGON_PACKAGE:-}" ]; }; then
    echo "[ERROR] NEXIGON_REPOSITORY and NEXIGON_PACKAGE must be set together"
    exit 1
fi

if [ -z "${RECIPE_PARAM_TAG}" ]; then
    echo "[ERROR] tag must not be empty"
    exit 1
fi

for name in "${NEXIGON_REPOSITORY:-}" "${NEXIGON_PACKAGE:-}" "${RECIPE_PARAM_TAG}"; do
    if [[ "${name}" =~ [\"\\/[:space:][:cntrl:]] ]]; then
        echo "[ERROR] '${name}' must not contain quotes, backslashes, slashes, or whitespace"
        exit 1
    fi
done

cat >>/etc/nexigon/agent.toml <<TOML

[integrations.rugix.system-updates]
enabled = true
check-interval-secs = ${CHECK_INTERVAL_SECS}
check-jitter-secs = ${CHECK_JITTER_SECS}
use-bundle-hash = ${RECIPE_PARAM_USE_BUNDLE_HASH}
TOML

if [ -n "${NEXIGON_REPOSITORY:-}" ]; then
    echo "path = \"${NEXIGON_REPOSITORY}/${NEXIGON_PACKAGE}/${RECIPE_PARAM_TAG}\"" \
        >>/etc/nexigon/agent.toml
fi

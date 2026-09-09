#!/usr/bin/env bash

# Exercises optional hash verification and signature-verification fallback.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
HANDLER="${ROOT}/recipes/nexigon-rugix-apps/files/nexigon-rugix-apps-deploy"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "${TEST_DIR}"' EXIT

mkdir -p "${TEST_DIR}/bin"

cat >"${TEST_DIR}/bin/nexigon-agent" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$*" in
    "repositories versions info version-with-hash")
        printf '%s\n' '{"assets":[{"assetId":"asset-1","filename":"app.rugixb","metadata":{"rugix":{"bundleHash":"sha512-256:expected"}}}]}'
        ;;
    "repositories versions info version-without-hash")
        printf '%s\n' '{"assets":[{"assetId":"asset-2","filename":"app.rugixb","metadata":{}}]}'
        ;;
    "repositories issue-url asset-1")
        printf '%s\n' '{"url":"https://example.invalid/app.rugixb"}'
        ;;
    "repositories issue-url asset-2")
        printf '%s\n' '{"url":"https://example.invalid/legacy-app.rugixb"}'
        ;;
    *)
        echo "unexpected nexigon-agent invocation: $*" >&2
        exit 1
        ;;
esac
EOF

cat >"${TEST_DIR}/bin/rugix-ctrl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >"${RUGIX_CTRL_ARGS}"
printf '%s\n' '{"name":"app","generation":1}'
EOF

chmod +x "${TEST_DIR}/bin/nexigon-agent" "${TEST_DIR}/bin/rugix-ctrl"

export PATH="${TEST_DIR}/bin:${PATH}"
export RUGIX_CTRL_ARGS="${TEST_DIR}/rugix-ctrl-args"

printf '%s\n' '{"versionId":"version-with-hash"}' \
    | NEXIGON_RUGIX_APPS_USE_BUNDLE_HASH=true "${HANDLER}" >/dev/null

expected='apps install --bundle-hash sha512-256:expected https://example.invalid/app.rugixb'
actual=$(cat "${RUGIX_CTRL_ARGS}")
if [ "$actual" != "$expected" ]; then
    echo "unexpected Rugix Ctrl arguments: $actual" >&2
    exit 1
fi

# A missing metadata hash leaves verification to Rugix's configured trust root.
printf '%s\n' '{"versionId":"version-without-hash"}' \
    | NEXIGON_RUGIX_APPS_USE_BUNDLE_HASH=true "${HANDLER}" >/dev/null

expected='apps install https://example.invalid/legacy-app.rugixb'
actual=$(cat "${RUGIX_CTRL_ARGS}")
if [ "$actual" != "$expected" ]; then
    echo "unexpected legacy Rugix Ctrl arguments: $actual" >&2
    exit 1
fi

# Disabling metadata hashes also leaves verification to Rugix, even when the
# selected Nexigon asset carries a hash.
printf '%s\n' '{"versionId":"version-with-hash"}' \
    | NEXIGON_RUGIX_APPS_USE_BUNDLE_HASH=false "${HANDLER}" >/dev/null

expected='apps install https://example.invalid/app.rugixb'
actual=$(cat "${RUGIX_CTRL_ARGS}")
if [ "$actual" != "$expected" ]; then
    echo "unexpected signature-verification arguments: $actual" >&2
    exit 1
fi

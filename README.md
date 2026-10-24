# Rugix Recipes and Layers for Nexigon

The default branch provides the recipes for the new Nexigon Agent integrations.
Add the repository to your `rugix-bakery.toml`:

```toml
[repositories]
nexigon = { git = "https://github.com/nexigon/nexigon-rugix.git" }
```

For Nexigon Agent 0.6.x and the standalone OTA service, pin the compatible
recipe branch instead:

```toml
[repositories]
nexigon = { git = "https://github.com/nexigon/nexigon-rugix.git", branch = "v0.3" }
```

We follow [Cargo's flavor of semantic versioning](https://doc.rust-lang.org/cargo/reference/resolver.html#semver-compatibility).
The default branch tracks development and may introduce incompatible changes.
Pin a tested revision when builds must be reproducible.

## Provisioning Images

The `nexigon-agent-config` recipe can build tokenless images for pairing-key
provisioning:

```toml
[parameters."nexigon/nexigon-agent-config"]
provisioning = "true"
```

In this mode, the recipe does not read `.env` and does not bake a deployment
token into the image. The agent starts its local provisioning endpoint and
stores redeemed credentials under `/var/lib/nexigon/agent`.

The OTA recipe can also be installed without a repository path. The agent
then stays idle until the `dev.nexigon.ota.config` device property supplies a
`path`, which is useful for images that are paired after they have been
flashed.

## System Updates

The development recipes described here require the new Nexigon Agent shipped
with platform 2026.4. The `v0.3` branch remains compatible with Nexigon Agent
0.6.x and uses the standalone OTA service.

The `nexigon-rugix-ota` recipe enables the Rugix system update integration of
the agent by appending an `[integrations.rugix.system-updates]` section to
`/etc/nexigon/agent.toml`. Include `nexigon-agent-config` in the same layer or
a parent layer. The OTA recipe runs after the agent configuration recipe and
preserves configuration inherited from a parent. It includes
`nexigon-rugix-watchdog` as a dependency. If `.env` sets `NEXIGON_REPOSITORY`
and `NEXIGON_PACKAGE`, the image tracks the `tag` of that package by default. Set both variables together, or
omit both to select the path later through `dev.nexigon.ota.config`.

```toml
[parameters."nexigon/nexigon-rugix-ota"]
# Time between update checks, such as `4h` or `1h 30min`.
interval = "4h"
# Maximum random delay of scheduled checks, so that devices do not reach
# Nexigon Hub at once.
jitter = "5min"
# Tag of the default version path.
tag = "stable"
```

Both time parameters accept integer seconds or whitespace-separated values
with the units `s`, `sec`, `m`, `min`, `h`, and `d`, for example `1h 30min`.
The interval must be positive; a zero jitter disables random delays.

The agent provides `nexigon.ota.check` as a built-in command when commands
are enabled. For example, add the following to the agent configuration
recipe's `extra_config`, alongside any existing settings:

```toml
[parameters."nexigon/nexigon-agent-config"]
extra_config = """
[commands]
enabled = true
"""
```

Periodic update checks work without commands enabled. Do not also configure
`[integrations.rugix.system-updates]` in `extra_config`; the OTA recipe writes
that section. Do not include the old OTA script or timer in the same image.

## Bundle Hash Verification

The `nexigon-rugix-apps` deployment command can use a bundle hash from
`metadata.rugix.bundleHash`. When enabled and the selected `.rugixb` asset has
this metadata, the command passes the hash to Rugix Ctrl. When the metadata is
absent, Rugix Ctrl performs its normal signature verification instead. Enable
metadata hashes with:

```toml
[parameters."nexigon/nexigon-rugix-apps"]
use_bundle_hash = "true"
```

System updates use the same optional-hash behavior:

```toml
[parameters."nexigon/nexigon-rugix-ota"]
use_bundle_hash = "true"
```

## Testing

The system-update tests run both configuration recipes in an isolated
filesystem. They need Docker and Python 3.11 or later in the container:

```sh
docker run --rm -v "$PWD:/src:ro" -w /src python:3.13-slim \
    python3 tests/test-system-updates.py
```

The app-deployment regression test needs Bash and jq:

```sh
bash tests/test-app-deploy.sh
```

## Licensing

This project is licensed under either [MIT](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-MIT) or [Apache 2.0](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-APACHE) at your opinion.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you, as defined in the Apache 2.0 license, shall be dual licensed as above, without any additional terms or conditions.

---

Made with ❤️ by [Silitics](https://www.silitics.com)

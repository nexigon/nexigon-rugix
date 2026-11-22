# Rugix Recipes and Layers for Nexigon

To make the recipes and layers available, include the following in your `rugix-bakery.toml`:

```toml
[repositories]
nexigon = { git = "https://github.com/nexigon/nexigon-rugix.git", branch = "v0.4" }
```

We follow [Cargo's flavor of semantic versioning](https://doc.rust-lang.org/cargo/reference/resolver.html#semver-compatibility).
You can also use the most recent development version by omitting the `branch` property.
Please be aware that this may break your builds if we introduce backwards-incompatible changes.

The `v0.4` recipes install Nexigon Agent 0.7, which updates the system and the
apps of a device itself. For Nexigon Agent 0.6, use `v0.3`.

## Agent Compatibility

This recipe line defaults to Nexigon Agent `v0.7.0`. Override the `version`
parameter of `nexigon-agent` or `nexigon-agent-rpi` to select another Agent
release.

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

## System Updates and Apps

Nexigon Agent installs system updates with Rugix Ctrl and manages Rugix Apps
once its configuration enables the integrations. Add the watchdog, which rolls
back a new system that the agent does not commit, and enable the integrations
in the `extra_config` parameter:

```toml
recipes = [
    # ...
    "nexigon/nexigon-agent",
    "nexigon/nexigon-agent-config",
    "nexigon/nexigon-rugix-watchdog",
]

[parameters."nexigon/nexigon-agent-config"]
extra_config = """
[integrations.rugix.system-updates]
enabled = true
path = "my-repo/gateway-os/stable"

[integrations.rugix.apps]
enabled = true
"""
```

Without `path`, a device does not update until the `dev.nexigon.ota.config`
device property supplies one, which suits images that are paired after they
have been flashed. With `use-bundle-hash = true`, either integration verifies
bundles with the hash from the `metadata.rugix.bundleHash` metadata of an
asset, if present, instead of the bundle signature.

[System Updates](https://docs.nexigon.dev/agent/next/concepts/system-updates)
and [Rugix Apps](https://docs.nexigon.dev/agent/next/concepts/rugix-apps)
describe the integrations and their settings.

## Upgrading from v0.3

The `nexigon-rugix-ota` and `nexigon-rugix-apps` recipes are gone. Nexigon Agent
0.7 provides their functionality, including the commands that check for
updates and start, stop, roll back, and remove apps. To upgrade:

1. Switch the `branch` of the repository to `v0.4`.
2. Remove `nexigon/nexigon-rugix-ota` and `nexigon/nexigon-rugix-apps` from
   your layers and keep `nexigon/nexigon-rugix-watchdog`.
3. Enable the integrations as shown above. Set `path` to
   `<repository>/<package>/<tag>` with the `NEXIGON_REPOSITORY` and
   `NEXIGON_PACKAGE` that the update recipe read from `.env` and its `tag`
   parameter. The `interval` parameter becomes `check-interval-secs`, and
   `use_bundle_hash` becomes `use-bundle-hash`.

Devices keep their update and app configuration and status. The
[upgrade guide](https://docs.nexigon.dev/agent/next/upgrading) describes how
to roll out the first image built this way.

## Licensing

This project is licensed under either [MIT](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-MIT) or [Apache 2.0](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-APACHE) at your opinion.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you, as defined in the Apache 2.0 license, shall be dual licensed as above, without any additional terms or conditions.

---

Made with ❤️ by [Silitics](https://www.silitics.com)

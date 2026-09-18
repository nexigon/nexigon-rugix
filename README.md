# Rugix Recipes and Layers for Nexigon

To make the recipes and layers available, include the following in your `rugix-bakery.toml`:

```toml
[repositories]
nexigon = { git = "https://github.com/nexigon/nexigon-rugix.git", branch = "v0.3" }
```

We follow [Cargo's flavor of semantic versioning](https://doc.rust-lang.org/cargo/reference/resolver.html#semver-compatibility).
You can also use the most recent development version by omitting the `branch` property.
Please be aware that this may break your builds if we introduce backwards-incompatible changes.

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

The OTA recipe can also be installed without a repository path. It remains
idle until the `dev.nexigon.ota.config` device property supplies a `path`,
which is useful for images that are paired after they have been flashed.
Before pairing, the OTA check exits cleanly without leaving its systemd
oneshot service in a failed state.

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

## Licensing

This project is licensed under either [MIT](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-MIT) or [Apache 2.0](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-APACHE) at your opinion.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you, as defined in the Apache 2.0 license, shall be dual licensed as above, without any additional terms or conditions.

---

Made with ❤️ by [Silitics](https://www.silitics.com)

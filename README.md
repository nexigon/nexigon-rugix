# Rugix Recipes and Layers for Nexigon

To make the recipes and layers available, include the following in your `rugix-bakery.toml`:

```toml
[repositories]
nexigon = { git = "https://github.com/nexigon/nexigon-rugix.git", branch = "v0" }
```

We follow [Cargo's flavor of semantic versioning](https://doc.rust-lang.org/cargo/reference/resolver.html#semver-compatibility).
You can also use the most recent development version by omitting the `branch` property.
Please be aware that this may break your builds if we introduce backwards-incompatible changes.

## ⚖️ Licensing

This project is licensed under either [MIT](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-MIT) or [Apache 2.0](https://github.com/nexigon/nexigon-rugix/blob/main/LICENSE-APACHE) at your opinion.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you, as defined in the Apache 2.0 license, shall be dual licensed as above, without any additional terms or conditions.

---

Made with ❤️ by [Silitics](https://www.silitics.com)

"""Exercise the real configuration recipes in an isolated Docker filesystem."""

import os
import shlex
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = Path("/etc/nexigon/agent.toml")
OTA_RECIPE = ROOT / "recipes/nexigon-rugix-ota"
CONFIG_RECIPE = ROOT / "recipes/nexigon-agent-config"


@unittest.skipUnless(
    Path("/.dockerenv").exists(), "Run this test in Docker; recipes write to /etc."
)
class SystemUpdateRecipeTests(unittest.TestCase):
    def setUp(self):
        self.project = tempfile.TemporaryDirectory()
        self.addCleanup(self.project.cleanup)
        CONFIG.parent.mkdir(parents=True, exist_ok=True)
        CONFIG.unlink(missing_ok=True)
        with (OTA_RECIPE / "recipe.toml").open("rb") as source:
            parameters = tomllib.load(source)["parameters"]
        self.env = {
            **os.environ,
            "RUGIX_PROJECT_DIR": self.project.name,
            "LAYER_REBUILD_IF_CHANGED": str(
                Path(self.project.name) / "rebuild-if-changed"
            ),
            **{
                "RECIPE_PARAM_" + name.upper(): parameter["default"]
                for name, parameter in parameters.items()
            },
        }
        self.env.pop("NEXIGON_REPOSITORY", None)
        self.env.pop("NEXIGON_PACKAGE", None)

    def configure_agent(self, provisioning=True, extra_config=""):
        subprocess.run(
            ["bash", str(CONFIG_RECIPE / "steps/00-install.sh")],
            env={
                **self.env,
                "RECIPE_DIR": str(CONFIG_RECIPE),
                "RECIPE_PARAM_PROVISIONING": str(provisioning).lower(),
                "RECIPE_PARAM_EXTRA_CONFIG": extra_config,
            },
            capture_output=True,
            text=True,
            check=True,
        )

    def write_environment(self, **values):
        (Path(self.project.name) / ".env").write_text(
            "".join(f"{name}={shlex.quote(value)}\n" for name, value in values.items())
        )

    def install(self, **parameters):
        return subprocess.run(
            ["bash", str(OTA_RECIPE / "steps/01-install.sh")],
            env={
                **self.env,
                "RECIPE_DIR": str(OTA_RECIPE),
                **{
                    "RECIPE_PARAM_" + name.upper(): value
                    for name, value in parameters.items()
                },
            },
            cwd=self.project.name,
            check=False,
            capture_output=True,
            text=True,
        )

    def configuration(self):
        return tomllib.loads(CONFIG.read_text())

    def test_inherited_provisioning_image_waits_for_a_path(self):
        """An OTA layer preserves a parent's provisioning and terminal settings without .env."""
        self.configure_agent(extra_config="[terminal]\nenabled = true")
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        config = self.configuration()
        self.assertTrue(config["provisioning"]["enabled"])
        self.assertTrue(config["terminal"]["enabled"])
        self.assertEqual(
            config["integrations"]["rugix"]["system-updates"],
            {
                "enabled": True,
                "check-interval-secs": 14400,
                "check-jitter-secs": 300,
                "use-bundle-hash": False,
            },
        )
        self.assertFalse(Path("/etc/nexigon-rugix-ota.json").exists())

    def test_static_image_keeps_credentials_and_extra_configuration(self):
        """The OTA recipe preserves credentials and commands while setting its default channel."""
        self.write_environment(
            NEXIGON_HUB_URL="https://example.invalid",
            NEXIGON_TOKEN="deployment_test",
            NEXIGON_REPOSITORY="factory",
            NEXIGON_PACKAGE="gateway-os",
        )
        self.configure_agent(
            provisioning=False, extra_config="[commands]\nenabled = true"
        )
        result = self.install(
            interval="1h 30min", jitter="0s", tag="testing", use_bundle_hash="true"
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        config = self.configuration()
        self.assertEqual(config["token"], "deployment_test")
        self.assertEqual(config["hub-url"], "https://example.invalid")
        self.assertTrue(config["commands"]["enabled"])
        self.assertEqual(
            config["integrations"]["rugix"]["system-updates"],
            {
                "enabled": True,
                "path": "factory/gateway-os/testing",
                "check-interval-secs": 5400,
                "check-jitter-secs": 0,
                "use-bundle-hash": True,
            },
        )
        self.assertIn(
            ".env", Path(self.env["LAYER_REBUILD_IF_CHANGED"]).read_text().splitlines()
        )

    def test_time_units_and_decimal_values(self):
        """Configured durations produce integer seconds, including values with leading zeros."""
        self.configure_agent()
        original = CONFIG.read_text()
        for interval, expected in [
            ("08m", 480),
            ("2d 3h 4min 5sec", 183845),
            ("90", 90),
        ]:
            with self.subTest(interval=interval):
                CONFIG.write_text(original)
                result = self.install(interval=interval)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(
                    self.configuration()["integrations"]["rugix"]["system-updates"][
                        "check-interval-secs"
                    ],
                    expected,
                )

    def test_invalid_parameters_leave_configuration_unchanged(self):
        """Malformed durations, overflow, unsafe TOML strings, and non-booleans fail before writing."""
        self.configure_agent()
        original = CONFIG.read_bytes()
        # A glob must not be expanded into a valid-looking duration.
        (Path(self.project.name) / "4h").touch()
        for parameters in [
            {"interval": "0s"},
            {"interval": ""},
            {"interval": "*"},
            {"interval": "-1h"},
            {"interval": "1h30min"},
            {"interval": "1h\n2h"},
            {"interval": "9223372036854775808"},
            {"interval": "18446744073709551616s"},
            {"interval": "9223372036854775807d"},
            {"interval": "9223372036854775807s 1s"},
            {"jitter": " "},
            {"use_bundle_hash": "yes"},
            {"tag": ""},
            {"tag": 'bad"tag'},
            {"tag": "bad/tag"},
            {"tag": "bad\\tag"},
            {"tag": "bad tag"},
        ]:
            with self.subTest(parameters=parameters):
                result = self.install(**parameters)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(CONFIG.read_bytes(), original)

    def test_invalid_repository_paths_leave_configuration_unchanged(self):
        """An incomplete or TOML-unsafe repository path cannot corrupt the agent configuration."""
        self.configure_agent()
        original = CONFIG.read_bytes()
        for values in [
            {"NEXIGON_REPOSITORY": "factory"},
            {"NEXIGON_PACKAGE": "gateway-os"},
            {"NEXIGON_REPOSITORY": 'bad"repo', "NEXIGON_PACKAGE": "gateway-os"},
            {"NEXIGON_REPOSITORY": "factory", "NEXIGON_PACKAGE": "bad\npackage"},
        ]:
            with self.subTest(values=values):
                self.write_environment(**values)
                result = self.install()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(CONFIG.read_bytes(), original)

    def test_missing_agent_configuration_fails(self):
        """Recipe ordering mistakes fail instead of writing an incomplete standalone configuration."""
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("nexigon-agent-config", result.stdout + result.stderr)
        self.assertFalse(CONFIG.exists())


if __name__ == "__main__":
    unittest.main()

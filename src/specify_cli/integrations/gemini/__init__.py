"""Gemini CLI integration."""

from ..base import IntegrationOption, TomlIntegration


class GeminiIntegration(TomlIntegration):
    key = "gemini"
    config = {
        "name": "Gemini CLI",
        "folder": ".gemini/",
        "commands_subdir": "commands",
        "install_url": "https://github.com/google-gemini/gemini-cli",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".gemini/commands",
        "format": "toml",
        "args": "{{args}}",
        "extension": ".toml",
    }
    multi_install_safe = True

    @classmethod
    def options(cls) -> list[IntegrationOption]:
        return [
            IntegrationOption(
                "--hooks",
                is_flag=False,
                default="true",
                help="Enable/disable runtime hooks (true|false, default: true)",
            ),
        ]

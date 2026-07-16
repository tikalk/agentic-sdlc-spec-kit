"""Qwen Code integration."""

from ..base import IntegrationOption, MarkdownIntegration


class QwenIntegration(MarkdownIntegration):
    key = "qwen"
    config = {
        "name": "Qwen Code",
        "folder": ".qwen/",
        "commands_subdir": "commands",
        "install_url": "https://github.com/QwenLM/qwen-code",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".qwen/commands",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md",
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

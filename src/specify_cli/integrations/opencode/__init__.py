"""opencode integration."""

from ..base import MarkdownIntegration


class OpencodeIntegration(MarkdownIntegration):
    key = "opencode"
    config = {
        "name": "opencode",
        "folder": ".opencode/",
        "commands_subdir": "commands",
        "install_url": "https://opencode.ai",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".opencode/commands",
        "legacy_dir": ".opencode/command",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md",
    }

    CANONICAL_TO_NATIVE = {
        # OpenCode V2 renamed the tool hooks: the plugin registers them via
        # ctx.tool.hook("execute.before" | "execute.after", ...).
        "pre_tool_use": "execute.before",
        "post_tool_use": "execute.after",
        # session_start maps to the V2 session "context" hook (not the
        # session.created event) so the handler's stdout is injected into the
        # system prompt — session.created has no output channel. The hook
        # fires per LLM request, which keeps the context present across
        # compaction at the cost of running the handler per turn.
        "session_start": "context",
        # user_prompt_submit maps to the V2 session "prompt" hook so handler
        # stdout is appended to the user's message text.
        "user_prompt_submit": "prompt",
        "session_end": "session.deleted",
    }
    events_config_file = "opencode.json"
    events_format = "ts-plugin"

    def build_exec_args(
        self,
        prompt: str,
        *,
        model: str | None = None,
        output_json: bool = True,
    ) -> list[str] | None:
        args = [self._resolve_executable(), "run"]
        # Apply operator-injected extra args before the prompt-derived
        # --command and the canonical --format/-m flags so Spec Kit's
        # later appends remain authoritative under repeated-flag CLI
        # semantics.
        self._apply_extra_args_env_var(args)

        message = prompt
        if prompt.startswith("/"):
            command, _, remainder = prompt[1:].partition(" ")
            if command:
                args.extend(["--command", command])
                message = remainder

        if model:
            args.extend(["-m", model])
        if output_json:
            args.extend(["--format", "json"])
        if message:
            args.append(message)
        return args

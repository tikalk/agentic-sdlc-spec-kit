"""
Extension-level fork customizations.

Leaf module with zero internal dependencies. Contains only constants that
configure fork-specific extension behavior, independent of the init/theming
or alias-resolution subsystems.

Dependency direction (locked):
    _extension_fork.py  (THIS MODULE - pure constants, no imports)
            ^
            |
    _core_fork.py        (imports this module; alias/MCP/skill logic)
            ^
            |
    _init_fork.py        (imports _core_fork and this module; theming/hooks)

Anything added here MUST NOT import from sibling _fork modules.
"""

# Command namespaces allowed in extension commands
# Upstream only allows "speckit", fork also allows "adlc"
EXTENSION_NAMESPACES = ["speckit", "adlc"]

# Enable short alias format: {extension}.{command} (e.g., architect.init)
EXTENSION_ALIAS_PATTERN_ENABLED = True

# Install command template for fork (used in self check output)
FORK_INSTALL_COMMAND = "uv tool install agentic-sdlc-specify-cli --force --from git+https://github.com/tikalk/agentic-sdlc-spec-kit.git@{tag}"

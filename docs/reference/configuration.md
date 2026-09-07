# Project Configuration

Use `specify config` to inspect and safely change supported settings that were
recorded when you initialized a project. Run these commands from the project
root, or set `SPECIFY_INIT_DIR` to the project root.

## Inspect Configuration

```bash
specify config list
specify config list --json
specify config get script
```

`list` shows the persisted initialization settings and a summary of installed
extensions. `--json` prints both as machine-readable JSON.

## Change Supported Initialization Settings

```bash
specify config set feature-numbering timestamp
```

Supported values are:

| Setting | Values |
| --- | --- |
| `feature-numbering` | `sequential`, `timestamp` |

Script type, the active integration, and skills layout are owned by
`specify integration`. Changing a script type requires regenerating the
installed agent files:

```bash
specify integration upgrade <integration> --script py
```

Use the active integration key to update both its commands and the script
setting shown by `config get script`. Supported script types are `sh`, `ps`,
and `py`. Upgrade checks manifest hashes and refuses to overwrite modified
files without `--force`; review those changes before choosing to overwrite them.

The selected type applies where a template supplies that variant. Some bundled
preset overrides, including the `agentic-sdlc` plan command, supply only `sh`
and `ps` and fall back to a supported variant when `py` is selected. Inspect
generated commands before assuming every helper uses Python.

Use `specify integration use <integration>` to select an installed integration.
For layout changes, use `specify integration upgrade <integration>
--integration-options="..."` with that integration's supported options. For
example, Copilot supports `--integration-options="--commands"`. Layout options
vary by integration; `ai-skills` is not a universal toggle.

`here` and `speckit-version` are read-only initialization metadata. Known
read-only settings and unknown keys produce distinct errors when set.

## Change or Remove the Team Directives Source

```bash
specify config set team-ai-directives /absolute/path/to/team-ai-directives
# A ZIP URL is also supported:
specify config set team-ai-directives https://github.com/example/team-ai-directives/archive/refs/heads/main.zip
specify config unset team-ai-directives
```

Setting a source validates it, ensures the bundled governance extension is
installed without replacing an existing one, merges its `.mcp.json` when
present, and installs any source-declared default skills that are not already
present.
Unsetting it removes the governance extension and the saved source setting.
Copied team skills are intentionally left in the active agent's skills
directory for manual review.

Installation is not transactional. If synchronization or skill installation
fails, the command exits with an error and leaves the previous saved source
unchanged. The extension and some skills may already have been installed.
Inspect and repair incomplete skill files, correct the reported cause, and
retry the same `config set team-ai-directives` command. Existing skill files
are skipped, even if a failed copy left them incomplete; retry alone does not
repair those files. No automatic rollback is attempted.

If the extension is absent, `unset` still clears a saved source and reports
that cleanup. If neither exists, it reports that the setting is already unset.

## Manage Extensions

`specify config extension` exposes the existing extension lifecycle under the
configuration namespace. It has the same behavior as `specify extension`.

```bash
specify config extension list
specify config extension add tdd
specify config extension disable tdd
specify config extension enable tdd
specify config extension remove tdd
```

Use `specify config extension --help` to see the full extension command set.

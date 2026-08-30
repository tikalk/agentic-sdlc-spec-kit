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
specify config set script py
specify config set feature-numbering timestamp
```

Supported values are:

| Setting | Values |
| --- | --- |
| `script` | `sh`, `ps`, `py` |
| `feature-numbering` | `sequential`, `timestamp` |

The active coding-agent integration and skills layout are not configurable
through this command because changing them requires regenerating agent files.
Use `specify integration use <integration>` instead.

## Change or Remove the Team Directives Source

```bash
specify config set team-ai-directives /absolute/path/to/team-ai-directives
# A ZIP URL is also supported:
specify config set team-ai-directives https://github.com/example/team-ai-directives/archive/refs/heads/main.zip
specify config unset team-ai-directives
```

Setting a source validates it, ensures the bundled governance extension is
installed without replacing an existing one, and installs any source-declared
default skills that are not already present.
Unsetting it removes the governance extension and the saved source setting.
Copied team skills are intentionally left in the active agent's skills
directory for manual review.

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

# Local Development Guide

This guide shows how to iterate on the `specify` CLI locally without publishing a release or committing to `main` first.

> Scripts are available as Bash (`.sh`), PowerShell (`.ps1`), and Python (`.py`) variants. Interactive `specify init` prompts you to choose one; non-interactive runs (no TTY, or `--non-interactive`) default to a shell variant for your OS. Pass `--script sh|ps|py` to select explicitly.

## 1. Clone and Switch Branches

```bash
git clone https://github.com/github/spec-kit.git
cd spec-kit
# Work on a feature branch
git checkout -b your-feature-branch
```

## 2. Run the CLI Directly (Fastest Feedback)

You can execute the CLI via the module entrypoint without installing anything:

```bash
# From repo root
python -m src.specify_cli --help
python -m src.specify_cli init demo-project --integration claude --ignore-agent-tools --script sh
```

If you prefer invoking the script file style (uses shebang):

```bash
python src/specify_cli/__init__.py init demo-project --script ps
```

## 3. Use Editable Install (Isolated Environment)

Create an isolated environment using `uv` so dependencies resolve exactly like end users get them:

```bash
# Create & activate virtual env (uv auto-manages .venv)
uv venv
source .venv/bin/activate  # or on Windows PowerShell: .venv\Scripts\Activate.ps1

# Install project in editable mode
uv pip install -e .

# Now 'specify' entrypoint is available
specify --help
```

Re-running after code edits requires no reinstall because of editable mode.

## 4. Verify Post-Initialization Configuration

Use a disposable project so configuration changes do not alter a real project.
From the repository root, save the repository path and create a temporary test
project:

```bash
SPECIFY_SRC="$(pwd)"
SPECIFY="$SPECIFY_SRC/.venv/bin/specify"
TEST_ROOT="$(mktemp -d)"
"$SPECIFY" init "$TEST_ROOT/project" \
  --integration copilot --ignore-agent-tools --script sh
cd "$TEST_ROOT/project"
```

`"$SPECIFY" ...` executes the editable `specify` console entry point from the
current working tree. The previous section creates that environment. If you
prefer uv to manage the environment, use `uv run --project "$SPECIFY_SRC"
specify ...` instead.

Run the read and mutation commands and verify each result:

```bash
"$SPECIFY" config list
"$SPECIFY" config list --json
"$SPECIFY" config get script

"$SPECIFY" integration upgrade copilot --script py
"$SPECIFY" config get script

"$SPECIFY" config set feature-numbering timestamp
"$SPECIFY" config get feature-numbering
```

The final two `get` commands must print `py` and `timestamp`. The corresponding
values in `"$TEST_ROOT/project/.specify/init-options.json"` must match.
Inspect `.github/skills/` and compare helper invocations with the selected
templates. Core templates supporting `py` use `scripts/python/`; bundled
preset overrides without a `py` variant can still invoke shell helpers.

Verify that integration ownership is enforced:

```bash
"$SPECIFY" config set integration claude
"$SPECIFY" config set script sh
"$SPECIFY" config set ai-skills true
"$SPECIFY" config set here true
```

Each command must fail without changing saved settings. Integration selection
must point to `specify integration use`, script and layout changes to
`specify integration upgrade`, and `here` must be identified as read-only.

Verify extension delegation using the bundled `git` extension:

```bash
"$SPECIFY" config extension list
"$SPECIFY" config extension add git
"$SPECIFY" config extension list
"$SPECIFY" config extension disable git
"$SPECIFY" config extension enable git
"$SPECIFY" config extension remove git
```

The extension must appear as installed, disabled, enabled, and then absent in
the corresponding list output.

If you have a valid team-directives source, verify its lifecycle too. Replace
the placeholder with a local directory or supported archive URL:

```bash
TEAM_DIRECTIVES_SOURCE="/absolute/path/to/team-ai-directives"
"$SPECIFY" config set team-ai-directives "$TEAM_DIRECTIVES_SOURCE"
"$SPECIFY" config get team-ai-directives
"$SPECIFY" config unset team-ai-directives
```

`get` must report the resolved source, and `unset` must remove the saved source
and governance extension while warning that copied team skills remain for
manual review.

## 5. Invoke with uvx Directly From Git (Current Branch)

`uvx` can run from a local path (or a Git ref) to simulate user flows:

```bash
uvx --from . specify init demo-uvx --integration copilot --ignore-agent-tools --script sh
```

You can also point uvx at a specific branch without merging:

```bash
# Push your working branch first
git push origin your-feature-branch
uvx --from git+https://github.com/github/spec-kit.git@your-feature-branch specify init demo-branch-test --script ps
```

### 5a. Absolute Path uvx (Run From Anywhere)

If you're in another directory, use an absolute path instead of `.`:

```bash
uvx --from /mnt/c/GitHub/spec-kit specify --help
uvx --from /mnt/c/GitHub/spec-kit specify init demo-anywhere --integration copilot --ignore-agent-tools --script sh
```

Set an environment variable for convenience:

```bash
export SPEC_KIT_SRC=/mnt/c/GitHub/spec-kit
uvx --from "$SPEC_KIT_SRC" specify init demo-env --integration copilot --ignore-agent-tools --script ps
```

(Optional) Define a shell function:

```bash
specify-dev() { uvx --from /mnt/c/GitHub/spec-kit specify "$@"; }
# Then
specify-dev --help
```

## 6. Testing Script Permission Logic

After running an `init`, check that shell scripts are executable on POSIX systems:

```bash
ls -l scripts | grep .sh
# Expect owner execute bit (e.g. -rwxr-xr-x)
```

On Windows you will instead use the `.ps1` scripts (no chmod needed).

## 7. Scaffold a Built-In Integration

Use the integration scaffold command to create the initial Python package and
test skeleton for a new built-in integration:

```bash
specify integration scaffold my-agent --type markdown
specify integration scaffold my-agent --type toml
specify integration scaffold my-agent --type yaml
specify integration scaffold my-agent --type skills
```

Hyphenated keys are converted to Python-safe package names, for example
`my-agent` creates `src/specify_cli/integrations/my_agent/` and
`tests/integrations/test_integration_my_agent.py`.

The scaffold does not register the integration automatically. Review the
generated metadata, then add the import and `_register()` call in
`src/specify_cli/integrations/__init__.py`.

## 8. Run Lint / Basic Checks

CI enforces `ruff check src tests` (see `.github/workflows/test.yml`), so run it locally before pushing:

```bash
uvx ruff check src tests
```

You can also quickly sanity check importability:

```bash
python -c "import specify_cli; print('Import OK')"
```

## 9. Build a Wheel Locally (Optional)

Validate packaging before publishing:

```bash
uv build
ls dist/
```

Install the built artifact into a fresh throwaway environment if needed.

## 10. Using a Temporary Workspace

When testing `init --here` in a dirty directory, create a temp workspace:

```bash
mkdir /tmp/spec-test && cd /tmp/spec-test
python -m src.specify_cli init --here --integration claude --ignore-agent-tools --script sh  # if repo copied here
```

Or copy only the modified CLI portion if you want a lighter sandbox.

## 11. Debug Network / TLS Issues

> **Deprecated:** The `--skip-tls` flag is a no-op and has no effect.
> It was previously used to bypass TLS validation during local testing.
> If you encounter TLS errors (e.g., on a corporate network), configure your
> environment's certificate store or proxy instead.
>
> For example, set `SSL_CERT_FILE` or configure `HTTPS_PROXY` / `HTTP_PROXY`.

## 12. Rapid Edit Loop Summary

| Action | Command |
| --- | --- |
| Run CLI directly | `python -m src.specify_cli --help` |
| Editable install | `uv pip install -e .` then `specify ...` |
| Local uvx run (repo root) | `uvx --from . specify ...` |
| Local uvx run (abs path) | `uvx --from /mnt/c/GitHub/spec-kit specify ...` |
| Git branch uvx | `uvx --from git+URL@branch specify ...` |
| Build wheel | `uv build` |

## 13. Cleaning Up

Remove build artifacts / virtual env quickly:

```bash
rm -rf .venv dist build *.egg-info
```

## 14. Common Issues

| Symptom | Fix |
| --- | --- |
| `ModuleNotFoundError: typer` | Run `uv pip install -e .` |
| Scripts not executable (Linux) | Re-run init or `chmod +x scripts/*.sh` |
| Git commands unavailable | Install the git extension with `specify extension add git` |
| Wrong script type downloaded | Pass `--script sh`, `--script ps`, or `--script py` explicitly |
| TLS errors on corporate network | Configure your environment's certificate store or proxy. The `--skip-tls` flag is deprecated and has no effect. |

## 15. Next Steps

- Update docs and run through Quick Start using your modified CLI
- Open a PR when satisfied
- (Optional) Tag a release once changes land in `main`

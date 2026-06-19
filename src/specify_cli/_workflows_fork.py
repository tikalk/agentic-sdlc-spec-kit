"""
Workflow-dispatch fork customizations.

Leaf module with zero internal dependencies. Controls whether workflow
steps stream CLI output to the terminal (True) or capture it for state
persistence (False).

Dependency direction (locked):
    _workflows_fork.py  (THIS MODULE - pure constants, no internal imports)

Workflow step modules import this module with a try/except fallback so
upstream builds get the default streaming behaviour and the fork gets
captured output for richer ``state.json`` records.
"""


def get_workflow_stream_default() -> bool:
    """Return whether workflow steps should stream output to the terminal.

    The upstream default (``True``) streams live CLI output to the
    terminal but discards ``stdout``/``stderr`` in ``state.json``.
    The fork returns ``False`` so that steps capture output for
    downstream consumers (analysis, reporting).

    Returns:
        ``False`` — workflow steps capture output for state persistence.
    """
    return False

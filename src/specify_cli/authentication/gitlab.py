"""GitLab authentication provider."""

from __future__ import annotations

from .base import AuthProvider


class GitLabAuth(AuthProvider):
    """GitLab authentication provider.

    Supports:
    - ``bearer`` scheme: Authorization: Bearer <token>
    - ``basic-pat`` scheme: Private-Token: <token> (GitLab-specific header)
    """

    key = "gitlab"
    supported_auth_schemes = ("bearer", "basic-pat")

    def auth_headers(self, token: str, auth_scheme: str) -> dict[str, str]:
        """Return auth headers based on scheme."""
        if auth_scheme == "bearer":
            return {"Authorization": f"Bearer {token}"}
        elif auth_scheme == "basic-pat":
            # GitLab-specific header for personal access tokens
            return {"Private-Token": token}
        else:
            raise ValueError(
                f"GitLabAuth does not support auth scheme {auth_scheme!r}"
            )

"""Shared GitLab-authenticated HTTP helpers.

Used by ExtensionCatalog and PresetCatalog to attach
GITLAB_TOKEN / GL_TOKEN credentials to requests targeting
GitLab-hosted domains, while preventing token leakage to
third-party hosts on redirects.
"""

import os
import urllib.request
from urllib.parse import urlparse
from typing import Dict, FrozenSet

# GitLab-owned hostnames that should receive the Authorization header.
# Includes common GitLab instances (gitlab.com and self-hosted).
GITLAB_HOSTS: FrozenSet[str] = frozenset({
    "gitlab.com",
    "gitlab.tikalk.dev",
    # Add other GitLab instances as needed
})


def build_gitlab_request(url: str) -> urllib.request.Request:
    """Build a urllib Request, adding a GitLab auth header when available.

    Reads GITLAB_TOKEN or GL_TOKEN from the environment and attaches an
    ``Authorization: Bearer <value>`` or ``Private-Token: <value>`` header
    when the target hostname is one of the known GitLab-owned domains.
    Non-GitLab URLs are returned as plain requests so credentials are
    never leaked to third-party hosts.
    """
    headers: Dict[str, str] = {}
    gitlab_token = (os.environ.get("GITLAB_TOKEN") or "").strip()
    gl_token = (os.environ.get("GL_TOKEN") or "").strip()
    token = gitlab_token or gl_token or None
    hostname = (urlparse(url).hostname or "").lower()
    if token and hostname in GITLAB_HOSTS:
        # GitLab supports both Bearer and Private-Token headers
        # Private-Token is the traditional GitLab way
        headers["Private-Token"] = token
    return urllib.request.Request(url, headers=headers)


class _StripGitLabAuthOnRedirect(urllib.request.HTTPRedirectHandler):
    """Redirect handler that drops the Private-Token header when leaving GitLab.

    Prevents token leakage to CDNs or other third-party hosts that GitLab
    may redirect to. Auth is preserved as long as the redirect target remains
    within GITLAB_HOSTS.
    """

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        original_auth = req.get_header("Private-Token")
        new_req = super().redirect_request(req, fp, code, msg, headers, newurl)
        if new_req is not None:
            hostname = (urlparse(newurl).hostname or "").lower()
            if hostname in GITLAB_HOSTS:
                if original_auth:
                    new_req.add_unredirected_header("Private-Token", original_auth)
            else:
                new_req.headers.pop("Private-Token", None)
                new_req.unredirected_hdrs.pop("Private-Token", None)
        return new_req


def open_gitlab_url(url: str, timeout: int = 10):
    """Open a URL with GitLab auth, stripping the header on cross-host redirects.

    When the request carries a Private-Token header, a custom redirect
    handler drops that header if the redirect target is not a GitLab-owned
    domain, preventing token leakage to CDNs or other third-party hosts.
    """
    req = build_gitlab_request(url)

    if not req.get_header("Private-Token"):
        return urllib.request.urlopen(req, timeout=timeout)

    opener = urllib.request.build_opener(_StripGitLabAuthOnRedirect)
    return opener.open(req, timeout=timeout)


def is_gitlab_host(url: str) -> bool:
    """Check if a URL is hosted on a known GitLab instance."""
    hostname = (urlparse(url).hostname or "").lower()
    return hostname in GITLAB_HOSTS


def add_gitlab_host(hostname: str) -> None:
    """Add a new GitLab host to the known hosts list.

    This allows users to register their self-hosted GitLab instances.
    """
    global GITLAB_HOSTS
    GITLAB_HOSTS = GITLAB_HOSTS | {hostname.lower()}

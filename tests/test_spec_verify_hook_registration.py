from pathlib import Path

import yaml


def test_after_implement_includes_optional_spec_verify_hook():
    repo_root = Path(__file__).parent.parent
    config_path = repo_root / ".specify" / "extensions.yml"
    config = yaml.safe_load(config_path.read_text(encoding="utf-8"))

    hooks = config["hooks"]["after_implement"]
    verify_hooks = [h for h in hooks if h.get("command") == "adlc.spec.verify"]

    assert len(verify_hooks) == 1, "Expected one adlc.spec.verify after_implement hook"
    hook = verify_hooks[0]
    assert hook["extension"] == "spec"
    assert hook["enabled"] is True
    assert hook["optional"] is True
    assert hook["condition"] is None
    assert "verification evidence" in hook["description"].lower()

"""Tests for Docker OpenCode integration."""

import json
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
from specify_cli.integrations.opencode import OpencodeIntegration
from specify_cli.integrations.opencode.docker_manager import DockerManager


class TestDockerManager:
    """Tests for DockerManager class."""

    def test_docker_manager_init(self):
        """Test DockerManager initialization."""
        manager = DockerManager()
        assert manager.container_name == "opencode-dev"
        assert manager.http_url == "http://localhost:9000"
        assert manager.timeout == 60

    def test_docker_manager_custom_config(self):
        """Test DockerManager with custom configuration."""
        manager = DockerManager(
            compose_file="custom.yml",
            container_name="custom-opencode",
            http_url="http://127.0.0.1:8000"
        )
        assert manager.compose_file == Path("custom.yml")
        assert manager.container_name == "custom-opencode"
        assert manager.http_url == "http://127.0.0.1:8000"

    @patch("subprocess.run")
    def test_docker_up_success(self, mock_run):
        """Test successful docker up command."""
        mock_run.side_effect = [
            MagicMock(returncode=0),  # docker-compose up
            MagicMock(returncode=0),  # curl health check (via HTTP)
        ]

        manager = DockerManager()
        with patch.object(manager, "check_container_ready", return_value=True):
            result = manager.docker_up()
            assert result is True

    @patch("subprocess.run")
    def test_docker_down_success(self, mock_run):
        """Test successful docker down command."""
        mock_run.return_value = MagicMock(returncode=0)

        manager = DockerManager()
        result = manager.docker_down()
        assert result is True

    @patch("subprocess.run")
    def test_docker_status_running(self, mock_run):
        """Test docker status when container is running."""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps([{"Service": "opencode", "State": "running"}])
        )

        manager = DockerManager()
        status = manager.docker_status()
        assert status is not None
        assert status["status"] == "running"
        assert status["running"] is True

    @patch("httpx.get")
    def test_check_container_ready_success(self, mock_get):
        """Test container health check success."""
        mock_get.return_value = MagicMock(status_code=200)

        manager = DockerManager()
        result = manager.check_container_ready(timeout=5)
        assert result is True
        mock_get.assert_called_once()

    @patch("httpx.get")
    def test_check_container_ready_timeout(self, mock_get):
        """Test container health check timeout."""
        mock_get.side_effect = Exception("Connection refused")

        manager = DockerManager(timeout=1)  # Short timeout for testing
        result = manager.check_container_ready(timeout=1)
        assert result is False

    @patch("subprocess.run")
    def test_get_container_logs(self, mock_run):
        """Test retrieving container logs."""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="log line 1\nlog line 2"
        )

        manager = DockerManager()
        logs = manager.get_container_logs(lines=50)
        assert "log line" in logs


class TestOpencodeIntegration:
    """Tests for OpenCode integration Docker support."""

    def test_load_opencode_config_no_file(self, tmp_path):
        """Test loading config when file doesn't exist."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        config = integration._load_opencode_config(project_root)
        assert config == {"mode": "local"}

    def test_load_opencode_config_exists(self, tmp_path):
        """Test loading existing config file."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        spec_dir = project_root / ".specify"
        spec_dir.mkdir()

        config_data = {
            "mode": "docker",
            "docker": {
                "enabled": True,
                "http_url": "http://localhost:9000"
            }
        }

        config_file = spec_dir / "opencode.json"
        with open(config_file, "w") as f:
            json.dump(config_data, f)

        loaded = integration._load_opencode_config(project_root)
        assert loaded["mode"] == "docker"
        assert loaded["docker"]["enabled"] is True

    def test_is_docker_mode_false_by_default(self, tmp_path):
        """Test that Docker mode is false by default."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()
        (project_root / ".specify").mkdir()

        assert integration._is_docker_mode(project_root) is False

    def test_is_docker_mode_enabled_in_config(self, tmp_path):
        """Test Docker mode when enabled in config."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        spec_dir = project_root / ".specify"
        spec_dir.mkdir()

        config_file = spec_dir / "opencode.json"
        with open(config_file, "w") as f:
            json.dump({"mode": "docker"}, f)

        assert integration._is_docker_mode(project_root) is True

    @patch.dict("os.environ", {"OPENCODE_MODE": "docker"})
    def test_is_docker_mode_from_env_var(self, tmp_path):
        """Test Docker mode from environment variable."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        assert integration._is_docker_mode(project_root) is True

    @patch("httpx.post")
    def test_call_docker_opencode_success(self, mock_post, tmp_path):
        """Test successful Docker OpenCode API call."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        spec_dir = project_root / ".specify"
        spec_dir.mkdir()

        config_file = spec_dir / "opencode.json"
        with open(config_file, "w") as f:
            json.dump({"mode": "docker", "docker": {"http_url": "http://localhost:9000"}}, f)

        mock_post.return_value = MagicMock(
            status_code=200,
            json=lambda: {"result": "success"}
        )

        result = integration._call_docker_opencode(
            "/spec.test hello",
            project_root=project_root
        )

        assert result["exit_code"] == 0
        assert "success" in result["stdout"]

    @patch("httpx.post")
    def test_call_docker_opencode_connection_error(self, mock_post, tmp_path):
        """Test Docker OpenCode API connection error."""
        import httpx

        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        spec_dir = project_root / ".specify"
        spec_dir.mkdir()

        config_file = spec_dir / "opencode.json"
        with open(config_file, "w") as f:
            json.dump({"mode": "docker", "docker": {"http_url": "http://localhost:9000"}}, f)

        mock_post.side_effect = httpx.ConnectError("Connection failed")

        result = integration._call_docker_opencode(
            "/spec.test hello",
            project_root=project_root
        )

        assert result["exit_code"] == 1
        assert "Docker running" in result["stderr"] or "Failed to connect" in result["stderr"]

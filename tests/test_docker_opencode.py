"""Tests for Docker OpenCode integration."""

import json
from pathlib import Path
from unittest.mock import MagicMock, patch

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

    def test_docker_manager_custom_config(self, tmp_path, monkeypatch):
        """Test DockerManager with custom configuration (relative compose path)."""
        monkeypatch.chdir(tmp_path)
        manager = DockerManager(
            compose_file="custom.yml",
            container_name="custom-opencode",
            http_url="http://127.0.0.1:8000",
        )
        assert manager.compose_file == (tmp_path / "custom.yml").resolve()
        assert manager.container_name == "custom-opencode"
        assert manager.http_url == "http://127.0.0.1:8000"

    @patch("specify_cli.integrations.opencode.docker_manager.subprocess.run")
    def test_docker_up_success(self, mock_run):
        """Test successful docker up command."""
        mock_run.return_value = MagicMock(returncode=0)

        manager = DockerManager()
        with patch.object(manager, "check_container_ready", return_value=True):
            result = manager.docker_up()
            assert result is True

    @patch("specify_cli.integrations.opencode.docker_manager.subprocess.run")
    def test_docker_down_success(self, mock_run):
        """Test successful docker down command."""
        mock_run.return_value = MagicMock(returncode=0)

        manager = DockerManager()
        result = manager.docker_down()
        assert result is True

    @patch("specify_cli.integrations.opencode.docker_manager.subprocess.run")
    def test_docker_status_running(self, mock_run):
        """Test docker status when container is running."""
        mock_run.side_effect = [
            MagicMock(returncode=0),
            MagicMock(
                returncode=0,
                stdout=json.dumps([{"Service": "opencode", "State": "running"}]),
            ),
        ]

        manager = DockerManager()
        status = manager.docker_status()
        assert status is not None
        assert status["status"] == "running"
        assert status["running"] is True

    @patch("specify_cli.integrations.opencode.docker_manager.httpx.get")
    def test_check_container_ready_success(self, mock_get):
        """Test container health check success."""
        mock_get.return_value = MagicMock(status_code=200)

        manager = DockerManager()
        result = manager.check_container_ready(timeout=5)
        assert result is True
        mock_get.assert_called_once()

    @patch("specify_cli.integrations.opencode.docker_manager.httpx.get")
    def test_check_container_ready_timeout(self, mock_get):
        """Test container health check timeout."""
        mock_get.side_effect = Exception("Connection refused")

        manager = DockerManager(timeout=1)  # Short timeout for testing
        result = manager.check_container_ready(timeout=1)
        assert result is False

    @patch("specify_cli.integrations.opencode.docker_manager.subprocess.run")
    def test_get_container_logs(self, mock_run):
        """Test retrieving container logs."""
        mock_run.side_effect = [
            MagicMock(returncode=0),
            MagicMock(
                returncode=0,
                stdout="log line 1\nlog line 2",
            ),
        ]

        manager = DockerManager()
        logs = manager.get_container_logs(lines=50)
        assert "log line" in logs


class TestOpencodeIntegration:
    """Tests for OpenCode integration Docker support."""

    def test_split_opencode_slash_prompt(self):
        """Slash prompts map to OpenCode session command API fields."""
        assert OpencodeIntegration._split_opencode_slash_prompt("") == ("help", "")
        assert OpencodeIntegration._split_opencode_slash_prompt("/speckit.implement") == (
            "speckit.implement",
            "",
        )
        assert OpencodeIntegration._split_opencode_slash_prompt("/speckit.implement Phase 1") == (
            "speckit.implement",
            "Phase 1",
        )

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
                "http_url": "http://localhost:9000",
            },
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

    def test_opencode_http_command_name(self):
        """HTTP /session/.../command uses spec.* for core speckit.* commands."""
        assert OpencodeIntegration._opencode_http_command_name("speckit.implement") == "spec.implement"
        assert OpencodeIntegration._opencode_http_command_name("speckit.specify") == "spec.specify"
        assert OpencodeIntegration._opencode_http_command_name("speckit.taskstoissues") == (
            "speckit.taskstoissues"
        )

    @patch("httpx.Client")
    def test_call_docker_opencode_success(self, mock_client_class, tmp_path):
        """Test successful Docker OpenCode API call."""
        mock_inst = MagicMock()
        mock_inst.__enter__ = MagicMock(return_value=mock_inst)
        mock_inst.__exit__ = MagicMock(return_value=False)
        mock_inst.post.side_effect = [
            MagicMock(
                status_code=200,
                json=lambda: {
                    "id": "sess-test",
                    "title": "Specify CLI",
                    "projectID": "p",
                    "directory": "/workspace",
                    "version": "1",
                    "time": {"created": 0, "updated": 0},
                },
            ),
            MagicMock(
                status_code=200,
                json=lambda: {"info": {"role": "assistant"}, "parts": []},
            ),
        ]
        mock_client_class.return_value = mock_inst

        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        spec_dir = project_root / ".specify"
        spec_dir.mkdir()

        config_file = spec_dir / "opencode.json"
        with open(config_file, "w") as f:
            json.dump(
                {"mode": "docker", "docker": {"http_url": "http://localhost:9000"}},
                f,
            )

        result = integration._call_docker_opencode(
            "/speckit.specify hello",
            project_root=project_root,
        )

        assert result["exit_code"] == 0
        assert mock_inst.post.call_count == 2
        first_url = mock_inst.post.call_args_list[0][0][0]
        second_url = mock_inst.post.call_args_list[1][0][0]
        assert "/session" in first_url
        assert "/session/sess-test/command" in second_url
        cmd_body = mock_inst.post.call_args_list[1][1]["json"]
        assert cmd_body["command"] == "spec.specify"
        assert cmd_body["arguments"] == "hello"
        assert "assistant" in result["stdout"]

    @patch("httpx.Client")
    def test_call_docker_opencode_connection_error(self, mock_client_class, tmp_path):
        """Test Docker OpenCode API connection error."""
        import httpx

        mock_inst = MagicMock()
        mock_inst.__enter__ = MagicMock(return_value=mock_inst)
        mock_inst.__exit__ = MagicMock(return_value=False)
        mock_inst.post.side_effect = httpx.ConnectError("Connection failed")
        mock_client_class.return_value = mock_inst

        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        spec_dir = project_root / ".specify"
        spec_dir.mkdir()

        config_file = spec_dir / "opencode.json"
        with open(config_file, "w") as f:
            json.dump(
                {"mode": "docker", "docker": {"http_url": "http://localhost:9000"}},
                f,
            )

        result = integration._call_docker_opencode(
            "/speckit.specify hello",
            project_root=project_root,
        )

        assert result["exit_code"] == 1
        assert "Docker running" in result["stderr"] or "Failed to connect" in result["stderr"]

    def test_build_exec_args_docker_mode(self, tmp_path):
        """Test build_exec_args returns synthetic args in Docker mode."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        spec_dir = project_root / ".specify"
        spec_dir.mkdir()

        config_file = spec_dir / "opencode.json"
        with open(config_file, "w") as f:
            json.dump({"mode": "docker"}, f)

        args = integration.build_exec_args(
            "/spec.implement test", project_root=project_root
        )

        assert args is not None
        assert "--docker-mode" in args
        assert args[0] == "opencode"
        assert "/spec.implement test" in args

    def test_build_exec_args_local_mode(self, tmp_path):
        """Test build_exec_args returns local CLI args when not in Docker mode."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        # No config file = local mode
        args = integration.build_exec_args(
            "/spec.implement test", project_root=project_root
        )

        assert args is not None
        assert args[0] == "opencode"
        assert "run" in args
        assert "--docker-mode" not in args

    @patch.dict("os.environ", {"OPENCODE_MODE": "docker"})
    def test_build_exec_args_docker_mode_from_env(self, tmp_path):
        """Test build_exec_args detects Docker mode from env var without config file."""
        integration = OpencodeIntegration()
        project_root = tmp_path / "project"
        project_root.mkdir()

        # No config file, but env var set
        args = integration.build_exec_args(
            "/spec.implement test", project_root=project_root
        )

        assert args is not None
        assert "--docker-mode" in args

    def test_is_docker_mode_exec_args(self):
        """Test is_docker_mode_exec_args correctly detects Docker mode."""
        # Docker mode args
        docker_args = ["opencode", "--docker-mode", "/spec.test"]
        assert OpencodeIntegration.is_docker_mode_exec_args(docker_args) is True

        # Local mode args
        local_args = ["opencode", "run", "test"]
        assert OpencodeIntegration.is_docker_mode_exec_args(local_args) is False

        # None
        assert OpencodeIntegration.is_docker_mode_exec_args(None) is False

        # Empty list
        assert OpencodeIntegration.is_docker_mode_exec_args([]) is False

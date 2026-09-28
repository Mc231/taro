"""tools/run_integration.sh with flutter and patrol stubbed (06 §4)."""

from __future__ import annotations

import shutil
import stat
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "run_integration.sh"
STUB = """#!/usr/bin/env bash
echo "{name} $(basename "$PWD") $*" >> "$STUB_LOG"
exit "${{STUB_EXIT:-0}}"
"""


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    (root / "tools").mkdir(parents=True)
    shutil.copy(SCRIPT, root / "tools" / "run_integration.sh")
    (root / "apps" / "taro").mkdir(parents=True)
    return root


def _run(repo: Path, **env: str) -> tuple[int, str, list[str]]:
    bin_dir = repo.parent / "bin"
    bin_dir.mkdir(exist_ok=True)
    log = repo.parent / "calls.log"
    log.unlink(missing_ok=True)
    for name in ("flutter", "patrol"):
        stub = bin_dir / name
        stub.write_text(STUB.format(name=name))
        stub.chmod(stub.stat().st_mode | stat.S_IXUSR)
    full_env = {"PATH": "/usr/bin:/bin", "STUB_LOG": str(log), "TARO_FLUTTER": str(bin_dir / "flutter"),
                "TARO_PATROL": str(bin_dir / "patrol"), **env}
    proc = subprocess.run(["bash", str(repo / "tools" / "run_integration.sh")], env=full_env,
                          capture_output=True, text=True, check=False)
    calls = log.read_text().splitlines() if log.exists() else []
    return proc.returncode, proc.stdout + proc.stderr, calls


def _add(repo: Path, rel: str) -> None:
    path = repo / "apps" / "taro" / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("void main() {}")


def test_nothing_to_run(repo: Path) -> None:
    code, out, calls = _run(repo)
    assert code == 0
    assert "no integration tests yet" in out
    assert calls == []


def test_spikes_run_with_flutter_test_on_the_device(repo: Path) -> None:
    _add(repo, "integration_test/fts5_spike_test.dart")
    code, out, calls = _run(repo, TARO_DEVICE_ID="SIM-1", TARO_INTEGRATION_PLATFORM="ios")
    assert code == 0, out
    assert calls == ["flutter taro test integration_test --flavor dev "
                     "--dart-define-from-file=config/dev.json -d SIM-1"]
    assert "platform=ios device=SIM-1" in out


def test_patrol_flows_win_and_device_is_optional(repo: Path) -> None:
    _add(repo, "integration_test/fts5_spike_test.dart")
    _add(repo, "patrol_test/onboarding_test.dart")
    code, out, calls = _run(repo, TARO_INTEGRATION_PLATFORM="android")
    assert code == 0, out
    assert calls == ["patrol taro test --flavor dev --dart-define-from-file=config/dev.json"]


def test_failures_propagate(repo: Path) -> None:
    _add(repo, "integration_test/fts5_spike_test.dart")
    code, _, _ = _run(repo, STUB_EXIT="1")
    assert code == 1


def test_rejects_an_unknown_platform(repo: Path) -> None:
    code, out, _ = _run(repo, TARO_INTEGRATION_PLATFORM="web")
    assert code == 2
    assert "must be ios or android" in out

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any

import pytest

import golden_update
from golden_update import (
    UPDATE_COMMAND,
    golden_packages,
    host_machine,
    installed_flutter,
    main,
    pinned_flutter,
    reference_problems,
)

PUBSPEC = """name: ws
environment:
  sdk: ^3.9.0
  # QA14 pin
  flutter: 3.44.8

workspace:
  - apps/taro
"""


class FakeRun:
    """Records calls; answers flutter --version, sysctl and the update runs."""

    def __init__(self, flutter: str | None = "3.44.8", arm64: bool = True, fail_update: bool = False,
                 sysctl_missing: bool = False) -> None:
        self.flutter = flutter
        self.arm64 = arm64
        self.fail_update = fail_update
        self.sysctl_missing = sysctl_missing
        self.calls: list[tuple[list[str], Any]] = []

    def __call__(self, cmd: list[str], **kwargs: Any) -> subprocess.CompletedProcess[str]:
        self.calls.append((cmd, kwargs.get("cwd")))
        if cmd[:2] == ["flutter", "--version"]:
            if self.flutter is None:
                raise OSError("no flutter")
            return subprocess.CompletedProcess(cmd, 0, json.dumps({"frameworkVersion": self.flutter}), "")
        if cmd[0] == "sysctl":
            if self.sysctl_missing:
                raise OSError("no sysctl")
            return subprocess.CompletedProcess(cmd, 0, "1\n" if self.arm64 else "0\n", "")
        return subprocess.CompletedProcess(cmd, 1 if self.fail_update else 0, "", "")

    @property
    def updates(self) -> list[tuple[list[str], Any]]:
        return [c for c in self.calls if c[0] == list(UPDATE_COMMAND)]


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    (tmp_path / "docs" / "specs").mkdir(parents=True)
    (tmp_path / "pubspec.yaml").write_text(PUBSPEC)
    for pkg in ("packages/taro_ui", "apps/taro"):
        (tmp_path / pkg / "test" / "golden").mkdir(parents=True)
    (tmp_path / "packages" / "taro_core" / "test").mkdir(parents=True)
    return tmp_path


@pytest.fixture()
def on_mac(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(golden_update.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(golden_update.platform, "machine", lambda: "x86_64")  # Rosetta python
    monkeypatch.delenv("TARO_GOLDEN_FORCE_LOCAL", raising=False)


def test_pinned_flutter(repo: Path, tmp_path: Path) -> None:
    assert pinned_flutter(repo) == "3.44.8"
    (repo / "pubspec.yaml").write_text("name: x\nenvironment:\n  sdk: ^3.9.0\n")
    assert pinned_flutter(repo) is None


def test_pinned_flutter_of_this_repository() -> None:
    root = Path(golden_update.__file__).resolve().parents[1]
    assert pinned_flutter(root) is not None


def test_installed_flutter() -> None:
    assert installed_flutter(FakeRun()) == "3.44.8"
    assert installed_flutter(FakeRun(flutter=None)) is None

    def bad_json(cmd: list[str], **_: Any) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(cmd, 0, "not json", "")

    assert installed_flutter(bad_json) is None


def test_host_machine() -> None:
    assert host_machine("Darwin", FakeRun(arm64=True)) == "arm64"
    fallback = host_machine("Darwin", FakeRun(arm64=False))
    assert fallback == golden_update.platform.machine()
    assert host_machine("Darwin", FakeRun(sysctl_missing=True)) == golden_update.platform.machine()
    run = FakeRun()
    host_machine("Linux", run)
    assert run.calls == []


def test_reference_problems() -> None:
    assert reference_problems("Darwin", "arm64", "3.44.8", "3.44.8") == []
    problems = reference_problems("Linux", "x86_64", "3.40.0", "3.44.8")
    assert len(problems) == 2
    assert "Linux x86_64" in problems[0]
    assert "Flutter is 3.40.0, the pin is 3.44.8" in problems[1]
    assert "unavailable" in reference_problems("Darwin", "arm64", None, "3.44.8")[0]
    assert "no environment.flutter pin" in reference_problems("Darwin", "arm64", "3.44.8", None)[0]


def test_golden_packages(repo: Path) -> None:
    assert [p.relative_to(repo).as_posix() for p in golden_packages(repo)] == ["apps/taro", "packages/taro_ui"]


def test_updates_every_golden_package_on_the_reference(repo: Path, on_mac: None,
                                                       capsys: pytest.CaptureFixture[str]) -> None:
    run = FakeRun()
    assert main(["--root", str(repo)], run=run) == 0
    assert [cwd for _, cwd in run.updates] == [repo / "apps/taro", repo / "packages/taro_ui"]
    assert "WARNING" not in capsys.readouterr().out


def test_refuses_off_the_reference(repo: Path, on_mac: None, capsys: pytest.CaptureFixture[str]) -> None:
    run = FakeRun(arm64=False)
    assert main(["--root", str(repo)], run=run) == 1
    err = capsys.readouterr().err
    assert "refusing" in err and "--force-local" in err
    assert run.updates == []


def test_refuses_a_different_flutter(repo: Path, on_mac: None) -> None:
    run = FakeRun(flutter="3.45.0")
    assert main(["--root", str(repo)], run=run) == 1


@pytest.mark.parametrize("via_env", [False, True])
def test_force_local_runs_with_a_warning(repo: Path, on_mac: None, monkeypatch: pytest.MonkeyPatch,
                                         capsys: pytest.CaptureFixture[str], via_env: bool) -> None:
    run = FakeRun(arm64=False)
    args = ["--root", str(repo)]
    if via_env:
        monkeypatch.setenv("TARO_GOLDEN_FORCE_LOCAL", "1")
    else:
        args.append("--force-local")
    assert main(args, run=run) == 0
    assert "do not commit" in capsys.readouterr().out
    assert len(run.updates) == 2


def test_dry_run_and_failures(repo: Path, on_mac: None, capsys: pytest.CaptureFixture[str]) -> None:
    run = FakeRun()
    assert main(["--root", str(repo), "--dry-run"], run=run) == 0
    assert run.updates == []
    assert "packages/taro_ui: flutter test" in capsys.readouterr().out
    failing = FakeRun(fail_update=True)
    assert main(["--root", str(repo)], run=failing) == 1
    assert "FAILED in apps/taro" in capsys.readouterr().err


def test_no_golden_packages(repo: Path, on_mac: None, capsys: pytest.CaptureFixture[str]) -> None:
    for pkg in ("packages/taro_ui", "apps/taro"):
        (repo / pkg / "test" / "golden").rmdir()
    assert main(["--root", str(repo)], run=FakeRun()) == 0
    assert "no package has test/golden/" in capsys.readouterr().out


def test_runs_as_a_script_in_dry_run() -> None:
    script = Path(golden_update.__file__)
    proc = subprocess.run([sys.executable, str(script), "--dry-run", "--force-local"],
                          capture_output=True, text=True, check=False)
    assert proc.returncode == 0, proc.stderr
    assert "packages/taro_ui" in proc.stdout

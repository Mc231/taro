"""bump_version.sh and bump_worker_version.sh on temp copies (06 §10.1, Sprint 3.5)."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parents[1]
TODAY = "2026-10-01"

CHANGELOG = """# Changelog

Intro.

## [Unreleased]

### Added

- A thing.

## [0.1.0] - 2026-09-01

### Added

- The first thing.
"""

EMPTY_CHANGELOG = """# Changelog

## [Unreleased]

### Added

## [0.1.0] - 2026-09-01

- Old.
"""

PUBSPEC = """name: taro
publish_to: none
version: 0.1.0+7

environment:
  sdk: ^3.9.0
"""

SONAR = """sonar.projectKey=taro
sonar.projectVersion=0.1.0
sonar.sources=apps/taro/lib
"""

PACKAGE = """{
  "name": "taro-api",
  "version": "1.2.3",
  "private": true
}
"""

LOCK = """{
  "name": "taro-api",
  "version": "1.2.3",
  "lockfileVersion": 3,
  "packages": {
    "": {
      "name": "taro-api",
      "version": "1.2.3"
    },
    "node_modules/dep": {
      "version": "1.2.3"
    }
  }
}
"""


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    (root / "tools" / "lib").mkdir(parents=True)
    for name in ("bump_version.sh", "bump_worker_version.sh", "lib/release_common.sh"):
        shutil.copy(TOOLS / name, root / "tools" / name)
    (root / "apps" / "taro").mkdir(parents=True)
    (root / "apps" / "taro" / "pubspec.yaml").write_text(PUBSPEC)
    (root / "CHANGELOG.md").write_text(CHANGELOG)
    (root / "sonar-project.properties").write_text(SONAR)
    (root / "worker").mkdir()
    (root / "worker" / "package.json").write_text(PACKAGE)
    (root / "worker" / "package-lock.json").write_text(LOCK)
    (root / "worker" / "CHANGELOG.md").write_text(CHANGELOG)
    return root


def _run(repo: Path, script: str, *args: str) -> subprocess.CompletedProcess[str]:
    env = {**os.environ, "TARO_TODAY": TODAY}
    return subprocess.run(["bash", str(repo / "tools" / script), *args],
                          env=env, capture_output=True, text=True, check=False)


def _version(repo: Path) -> str:
    for line in (repo / "apps/taro/pubspec.yaml").read_text().splitlines():
        if line.startswith("version:"):
            return line.split(":", 1)[1].strip()
    raise AssertionError("no version line")


# --- app -------------------------------------------------------------------


@pytest.mark.parametrize(
    ("args", "expected"),
    [((), "0.1.1+8"), (("patch",), "0.1.1+8"), (("minor",), "0.2.0+8"), (("major",), "1.0.0+8")],
)
def test_app_bump_levels_always_add_one_build(repo: Path, args: tuple[str, ...], expected: str) -> None:
    proc = _run(repo, "bump_version.sh", *args)
    assert proc.returncode == 0, proc.stderr
    assert _version(repo) == expected
    semver = expected.split("+")[0]
    assert f"sonar.projectVersion={semver}\n" in (repo / "sonar-project.properties").read_text()
    changelog = (repo / "CHANGELOG.md").read_text()
    assert f"## [Unreleased]\n\n## [{semver}] - {TODAY}\n\n### Added\n\n- A thing." in changelog
    assert changelog.count("## [Unreleased]") == 1
    assert "## [0.1.0] - 2026-09-01" in changelog


def test_app_explicit_version(repo: Path) -> None:
    proc = _run(repo, "bump_version.sh", "--version", "2.0.0+20")
    assert proc.returncode == 0, proc.stderr
    assert _version(repo) == "2.0.0+20"


@pytest.mark.parametrize("value", ["2.0.0+7", "2.0.0+3"])
def test_app_explicit_version_must_raise_the_build(repo: Path, value: str) -> None:
    proc = _run(repo, "bump_version.sh", "--version", value)
    assert proc.returncode == 1
    assert "build number must increase" in proc.stderr
    assert _version(repo) == "0.1.0+7"


def test_app_dry_run_writes_nothing(repo: Path) -> None:
    before = {p: p.read_text() for p in repo.rglob("*") if p.is_file()}
    proc = _run(repo, "bump_version.sh", "minor", "--dry-run")
    assert proc.returncode == 0, proc.stderr
    assert "app: 0.1.0+7 -> 0.2.0+8" in proc.stdout
    assert "(dry-run: no files written)" in proc.stdout
    assert {p: p.read_text() for p in before} == before


def test_app_fails_on_empty_unreleased(repo: Path) -> None:
    (repo / "CHANGELOG.md").write_text(EMPTY_CHANGELOG)
    proc = _run(repo, "bump_version.sh")
    assert proc.returncode == 1
    assert "is empty" in proc.stderr
    assert _version(repo) == "0.1.0+7"


def test_app_fails_on_missing_unreleased(repo: Path) -> None:
    (repo / "CHANGELOG.md").write_text("# Changelog\n\n## [0.1.0] - 2026-09-01\n\n- Old.\n")
    assert _run(repo, "bump_version.sh").returncode == 1


def test_app_fails_when_the_release_heading_exists(repo: Path) -> None:
    (repo / "CHANGELOG.md").write_text(CHANGELOG + "\n## [0.1.1] - 2026-09-15\n\n- Dup.\n")
    proc = _run(repo, "bump_version.sh")
    assert proc.returncode == 1
    assert "already has a '## [0.1.1]'" in proc.stderr


def test_app_rejects_malformed_versions(repo: Path) -> None:
    proc = _run(repo, "bump_version.sh", "--version", "2.0")
    assert proc.returncode == 1
    assert "malformed version" in proc.stderr
    (repo / "apps/taro/pubspec.yaml").write_text(PUBSPEC.replace("0.1.0+7", "0.1.0"))
    assert _run(repo, "bump_version.sh").returncode == 1


def test_app_missing_files(repo: Path) -> None:
    (repo / "CHANGELOG.md").unlink()
    assert "CHANGELOG.md not found" in _run(repo, "bump_version.sh").stderr
    (repo / "apps/taro/pubspec.yaml").unlink()
    assert "pubspec.yaml not found" in _run(repo, "bump_version.sh").stderr


def test_app_without_sonar_file_warns(repo: Path) -> None:
    (repo / "sonar-project.properties").unlink()
    proc = _run(repo, "bump_version.sh")
    assert proc.returncode == 0, proc.stderr
    assert "skipping sonar.projectVersion" in proc.stderr
    assert not (repo / "sonar-project.properties").exists()


def test_app_adds_a_missing_sonar_version_line(repo: Path) -> None:
    (repo / "sonar-project.properties").write_text("sonar.projectKey=taro\n")
    assert _run(repo, "bump_version.sh").returncode == 0
    assert (repo / "sonar-project.properties").read_text().endswith("sonar.projectVersion=0.1.1\n")


@pytest.mark.parametrize("script", ["bump_version.sh", "bump_worker_version.sh"])
def test_arguments(repo: Path, script: str) -> None:
    proc = _run(repo, script, "--help")
    assert proc.returncode == 0
    assert "--dry-run" in proc.stdout
    assert _run(repo, script, "sideways").returncode == 2
    assert _run(repo, script, "--version").returncode == 2


# --- worker ----------------------------------------------------------------


@pytest.mark.parametrize(
    ("args", "expected"),
    [((), "1.2.4"), (("minor",), "1.3.0"), (("major",), "2.0.0"), (("--version", "1.10.0"), "1.10.0")],
)
def test_worker_bump(repo: Path, args: tuple[str, ...], expected: str) -> None:
    proc = _run(repo, "bump_worker_version.sh", *args)
    assert proc.returncode == 0, proc.stderr
    assert f'"version": "{expected}"' in (repo / "worker/package.json").read_text()
    lock = (repo / "worker/package-lock.json").read_text()
    assert lock.count(f'"version": "{expected}"') == 2
    assert lock.count('"version": "1.2.3"') == 1  # the dependency is untouched
    changelog = (repo / "worker/CHANGELOG.md").read_text()
    assert f"## [Unreleased]\n\n## [{expected}] - {TODAY}" in changelog


@pytest.mark.parametrize("value", ["1.2.3", "1.2.2", "0.9.9", "1.1.9"])
def test_worker_explicit_version_must_increase(repo: Path, value: str) -> None:
    proc = _run(repo, "bump_worker_version.sh", "--version", value)
    assert proc.returncode == 1
    assert "version must increase" in proc.stderr


def test_worker_rejects_malformed_explicit_version(repo: Path) -> None:
    proc = _run(repo, "bump_worker_version.sh", "--version", "v2")
    assert proc.returncode == 1
    assert "malformed version" in proc.stderr


def test_worker_dry_run_and_empty_changelog(repo: Path) -> None:
    proc = _run(repo, "bump_worker_version.sh", "--dry-run")
    assert proc.returncode == 0, proc.stderr
    assert "worker: 1.2.3 -> 1.2.4" in proc.stdout
    assert '"version": "1.2.3"' in (repo / "worker/package.json").read_text()
    (repo / "worker/CHANGELOG.md").write_text(EMPTY_CHANGELOG)
    proc = _run(repo, "bump_worker_version.sh")
    assert proc.returncode == 1
    assert "is empty" in proc.stderr


def test_worker_without_lockfile_and_missing_package(repo: Path) -> None:
    (repo / "worker/package-lock.json").unlink()
    assert _run(repo, "bump_worker_version.sh").returncode == 0
    (repo / "worker/package.json").unlink()
    proc = _run(repo, "bump_worker_version.sh")
    assert proc.returncode == 1
    assert "package.json not found" in proc.stderr


def test_worker_missing_changelog(repo: Path) -> None:
    (repo / "worker/CHANGELOG.md").unlink()
    assert "CHANGELOG.md not found" in _run(repo, "bump_worker_version.sh").stderr


@pytest.mark.parametrize("script", ["bump_version.sh", "bump_worker_version.sh", "lib/release_common.sh"])
def test_scripts_are_valid_bash(script: str) -> None:
    assert subprocess.run(["bash", "-n", str(TOOLS / script)], check=False).returncode == 0

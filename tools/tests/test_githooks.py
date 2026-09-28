"""The commit-msg and pre-push hooks in a throwaway git repository (06 §6.4)."""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parents[1]

CHECK_STUB = """import sys
text = open(sys.argv[1]).read()
sys.exit(0 if text.startswith("feat(") else 1)
"""

VERIFY_STUB = """#!/usr/bin/env bash
echo "verify $*" >> "$(dirname "$0")/../verify.log"
exit "${VERIFY_EXIT:-0}"
"""


def _git(repo: Path, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=repo, capture_output=True, text=True, check=False, env=env)


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    (root / "tools").mkdir(parents=True)
    shutil.copytree(TOOLS / "githooks", root / "tools" / "githooks")
    (root / "tools" / "check_commit_msg.py").write_text(CHECK_STUB)
    verify = root / "tools" / "verify.sh"
    verify.write_text(VERIFY_STUB)
    verify.chmod(verify.stat().st_mode | stat.S_IXUSR)
    _git(root, "init", "-q", "-b", "main")
    for key, value in (("user.name", "Test"), ("user.email", "t@example.com"),
                       ("core.hooksPath", "tools/githooks"), ("commit.gpgsign", "false")):
        _git(root, "config", key, value)
    (root / "a.txt").write_text("a")
    _git(root, "add", ".")
    return root


def test_hooks_are_executable_bash() -> None:
    for hook in ("commit-msg", "pre-push"):
        path = TOOLS / "githooks" / hook
        assert os.access(path, os.X_OK), hook
        assert subprocess.run(["bash", "-n", str(path)], check=False).returncode == 0


def test_commit_msg_rejects_and_accepts(repo: Path) -> None:
    bad = _git(repo, "commit", "-q", "-m", "wip")
    assert bad.returncode != 0
    good = _git(repo, "commit", "-q", "-m", "feat(taro): add a")
    assert good.returncode == 0, good.stderr


def test_pre_push_runs_verify_fast(repo: Path, tmp_path: Path) -> None:
    assert _git(repo, "commit", "-q", "-m", "feat(taro): add a").returncode == 0
    remote = tmp_path / "remote.git"
    subprocess.run(["git", "init", "-q", "--bare", str(remote)], check=True)
    _git(repo, "remote", "add", "origin", str(remote))
    assert _git(repo, "push", "-q", "origin", "main").returncode == 0
    assert (repo / "verify.log").read_text().strip() == "verify --fast"
    (repo / "b.txt").write_text("b")
    _git(repo, "add", ".")
    _git(repo, "commit", "-q", "-m", "feat(taro): add b")
    env = {**os.environ, "VERIFY_EXIT": "1"}
    assert _git(repo, "push", "-q", "origin", "main", env=env).returncode != 0

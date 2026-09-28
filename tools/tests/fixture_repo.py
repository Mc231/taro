"""Builds throwaway repository roots from ``tests/fixtures/<check>/<case>/``.

A fixture tree holds only the files a case is about. ``make_root`` copies it
into ``tmp_path``, adds the ``docs/specs`` marker, and copies the real spec
files a check parses (so fixtures never fork the specs).
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1]
REPO = TOOLS.parent
FIXTURES = TOOLS / "tests" / "fixtures"


def make_root(tmp_path: Path, check: str, case: str | None, specs: tuple[str, ...] = ()) -> Path:
    """A repo root at ``tmp_path/repo`` from a fixture case plus real specs."""
    root = tmp_path / "repo"
    if case is not None:
        shutil.copytree(FIXTURES / check / case, root)
    (root / "docs" / "specs").mkdir(parents=True, exist_ok=True)
    for spec in specs:
        target = root / "docs" / "specs" / spec
        if not target.exists():
            shutil.copy(REPO / "docs" / "specs" / spec, target)
    return root


def git(root: Path, *args: str) -> str:
    """Run git in ``root`` with a fixed identity; return stdout."""
    env_args = ["-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false"]
    return subprocess.run(
        ["git", *env_args, *args], cwd=root, check=True, capture_output=True, text=True
    ).stdout


def init_git(root: Path) -> None:
    """Initialise a repo with ``main`` as the default branch."""
    root.mkdir(parents=True, exist_ok=True)
    git(root, "init", "-q", "-b", "main")


def commit_all(root: Path, message: str) -> str:
    git(root, "add", "-A")
    git(root, "commit", "-q", "--allow-empty", "-m", message)
    return git(root, "rev-parse", "HEAD").strip()

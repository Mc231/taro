from pathlib import Path

import pytest

from taro_tools import REPO_MARKER, find_repo_root


def _make_repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    (root / REPO_MARKER).mkdir(parents=True)
    return root


def test_returns_start_when_it_is_the_root(tmp_path: Path) -> None:
    root = _make_repo(tmp_path)
    assert find_repo_root(root) == root.resolve()


def test_walks_up_from_a_nested_directory(tmp_path: Path) -> None:
    root = _make_repo(tmp_path)
    nested = root / "packages" / "taro_core" / "lib"
    nested.mkdir(parents=True)
    assert find_repo_root(nested) == root.resolve()


def test_starts_from_the_parent_of_a_file(tmp_path: Path) -> None:
    root = _make_repo(tmp_path)
    script = root / "tools" / "check_x.py"
    script.parent.mkdir(parents=True)
    script.write_text("")
    assert find_repo_root(script) == root.resolve()


def test_raises_outside_a_repository(tmp_path: Path) -> None:
    with pytest.raises(FileNotFoundError, match="no Taro repository root"):
        find_repo_root(tmp_path)


def test_finds_this_repository() -> None:
    root = find_repo_root(Path(__file__))
    assert (root / "docs" / "specs" / "00_DECISIONS.md").is_file()

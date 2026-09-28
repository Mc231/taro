from pathlib import Path

import pytest

import check_commit_msg as c
from fixture_repo import FIXTURES, REPO, commit_all, init_git

CASES = FIXTURES / "check_commit_msg"


def _files(case: str) -> list[Path]:
    return sorted((CASES / case).glob("*.txt"))


@pytest.mark.parametrize("path", _files("pass"), ids=lambda p: p.stem)
def test_pass_messages(path: Path) -> None:
    assert c.check_message(path.read_text(encoding="utf-8")) == []
    assert c.main([str(path)]) == 0


@pytest.mark.parametrize("path", _files("fail_subject"), ids=lambda p: p.stem)
def test_bad_subjects(path: Path) -> None:
    problems = c.check_message(path.read_text(encoding="utf-8"))
    assert problems
    assert c.main([str(path)]) == 1


@pytest.mark.parametrize("path", _files("fail_attribution"), ids=lambda p: p.stem)
def test_ai_attribution(path: Path) -> None:
    problems = c.check_message(path.read_text(encoding="utf-8"))
    assert any("AI attribution" in p.message for p in problems)


def test_subject_boundary_72_chars() -> None:
    assert c.check_message("feat: " + "x" * 72) == []
    assert c.check_message("feat: " + "x" * 73)


def test_message_flag_and_render(capsys: pytest.CaptureFixture[str]) -> None:
    assert c.main(["--message", "docs: fix typo"]) == 0
    assert c.main(["--message", "bad"]) == 1
    assert "not a conventional commit" in capsys.readouterr().err
    assert c.Problem("abc123", "x").render() == "abc123: x"
    assert c.Problem("", "x").render() == "x"


def test_range_and_all_over_a_git_repo(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    repo = tmp_path / "r"
    init_git(repo)
    base = commit_all(repo, "chore: init")
    commit_all(repo, "feat(tools): add check")
    assert c.main(["--range", f"{base}..HEAD", "--repo", str(repo)]) == 0
    commit_all(repo, "feat: x\n\nCo-Authored-By: Claude <noreply@anthropic.com>")
    assert c.main(["--range", f"{base}..HEAD", "--repo", str(repo)]) == 1
    assert c.main(["--all", "--repo", str(repo)]) == 1
    out = capsys.readouterr().err
    assert "AI attribution" in out


def test_bad_range_is_a_usage_error(tmp_path: Path) -> None:
    repo = tmp_path / "r"
    init_git(repo)
    commit_all(repo, "chore: init")
    assert c.main(["--range", "nope..HEAD", "--repo", str(repo)]) == 2


def test_missing_file_is_a_usage_error(tmp_path: Path) -> None:
    assert c.main([str(tmp_path / "missing.txt")]) == 2


def test_this_repository_history_is_clean() -> None:
    assert c.main(["--all", "--repo", str(REPO)]) == 0

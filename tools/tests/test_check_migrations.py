from pathlib import Path

import pytest

import check_migrations as c
from fixture_repo import REPO, commit_all, git, init_git, make_root

CHECK = "check_migrations"


def _rules(root: Path, base: str | None = None) -> list[str]:
    findings, _ = c.run(root, base)
    return sorted(f.rule for f in findings)


def test_pass(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    findings, notices = c.run(root, None)
    assert findings == []
    assert any("append-only rule not checked" in n for n in notices)
    assert c.main(["--root", str(root)]) == 0


def test_gap(tmp_path: Path) -> None:
    assert _rules(make_root(tmp_path, CHECK, "fail_gap")) == ["gap"]


def test_drop_without_marker(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "fail_drop")
    findings, _ = c.run(root, None)
    assert [(f.rule, f.line) for f in findings] == [("drop-without-marker", 2), ("drop-without-marker", 3)]
    assert c.main(["--root", str(root)]) == 1


def test_bad_names(tmp_path: Path) -> None:
    assert _rules(make_root(tmp_path, CHECK, "fail_name")) == ["name", "name"]


def test_duplicate_numbers(tmp_path: Path) -> None:
    assert _rules(make_root(tmp_path, CHECK, "fail_duplicate")) == ["duplicate"]


def test_strip_sql_comments_keeps_lines() -> None:
    sql = "a -- DROP TABLE x\n/* DROP\nCOLUMN */ 'it''s DROP TABLE'\nb"
    stripped = c.strip_sql_comments(sql)
    assert "DROP" not in stripped
    assert stripped.count("\n") == sql.count("\n")
    assert c.strip_sql_comments("x /* open") == "x " + " " * 7
    assert c.strip_sql_comments("'open") == "     "


def test_append_only_against_a_base(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    init_git(root)
    commit_all(root, "chore: init")
    git(root, "branch", "base")
    assert _rules(root, "base") == []
    (root / "worker/migrations/0004_new.sql").write_text("SELECT 1;\n")
    assert _rules(root, "base") == []
    (root / "worker/migrations/0002_add_trust.sql").write_text("ALTER TABLE installs ADD COLUMN x TEXT;\n")
    (root / "worker/migrations/0001_init.sql").unlink()
    assert _rules(root, "base") == ["append-only", "append-only", "gap"]
    assert c.check_changes([("R100", "worker/migrations/0003_a.sql"), ("A", "worker/migrations/0005.sql")])[0].message.startswith(
        "existing migration renamed"
    )


def test_default_base_and_unknown_base(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    init_git(root)
    commit_all(root, "chore: init")
    git(root, "update-ref", "refs/remotes/origin/main", "HEAD")
    findings, notices = c.run(root, None)
    assert findings == [] and not any("append-only" in n for n in notices)
    assert _rules(root, "no-such-ref") == ["base"]


def test_absent_and_empty_folder(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    assert c.run(root, None) == ([], ["worker/migrations/ not present yet; skipped"])
    (root / "worker/migrations").mkdir(parents=True)
    findings, notices = c.run(root, None)
    assert findings == [] and any("no migrations yet" in n for n in notices)


def test_real_repository_passes(capsys: pytest.CaptureFixture[str]) -> None:
    assert c.main(["--root", str(REPO)]) == 0

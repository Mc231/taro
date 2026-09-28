from pathlib import Path

import pytest

import check_changelog as c
from fixture_repo import REPO, commit_all, init_git, make_root

CHECK = "check_changelog"


def _rules(findings: list) -> list[str]:
    return sorted(f.rule for f in findings)


def test_pass(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    assert c.main(["--root", str(root)]) == 0
    assert c.main(["--root", str(root), "--version", "1.1.0+7"]) == 0
    assert c.main(["--root", str(root), "--version", "1.0.0", "--worker"]) == 0


def test_missing_unreleased(tmp_path: Path) -> None:
    findings, _ = c.run(make_root(tmp_path, CHECK, "fail_no_unreleased"), version=None, worker=False, rev_range=None)
    assert _rules(findings) == ["unreleased-missing"]


def test_bad_headings(tmp_path: Path) -> None:
    findings, _ = c.run(make_root(tmp_path, CHECK, "fail_bad_heading"), version=None, worker=False, rev_range=None)
    assert _rules(findings) == ["date", "heading", "heading", "heading"]


def test_bad_subsection(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "fail_subsection")
    findings, _ = c.run(root, version=None, worker=False, rev_range=None)
    assert _rules(findings) == ["subsection"]
    assert c.main(["--root", str(root)]) == 1


def test_order_and_duplicates(tmp_path: Path) -> None:
    findings, _ = c.run(make_root(tmp_path, CHECK, "fail_order"), version=None, worker=False, rev_range=None)
    assert _rules(findings) == ["duplicate", "duplicate", "order", "unreleased-order"]


def test_version_lookup(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    text = (root / "CHANGELOG.md").read_text()
    assert c.check_version(text, "1.0.0", "x") == []
    assert _rules(c.check_version(text, "2.0.0", "x")) == ["version-missing"]
    assert _rules(c.check_version(text, "0.9.0", "x")) == ["empty"]
    assert _rules(c.check_version(text, "1.0", "x")) == ["version"]
    assert _rules(c.check_version("## [1.0.0] - 2026-13-01\n- x\n", "1.0.0", "x")) == ["heading"]
    assert _rules(c.check_version("## [1.0.0]\n- x\n", "1.0.0", "x")) == ["heading"]
    assert c.main(["--root", str(root), "--version", "3.0.0"]) == 1


def test_missing_files(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    findings, notices = c.run(root, version="1.0.0", worker=True, rev_range=None)
    assert _rules(findings) == ["missing", "missing"]
    assert "not present yet" in notices[0]


def test_check_range_rules() -> None:
    code = ["apps/taro/lib/app.dart", "worker/src/app.ts"]
    assert c.check_range(code, ["docs: x", "chore(ci): y"]) == []
    findings = c.check_range(code, ["feat: x"])
    assert sorted(f.path for f in findings) == ["CHANGELOG.md", "worker/CHANGELOG.md"]
    assert c.check_range([*code, "CHANGELOG.md", "worker/CHANGELOG.md"], ["feat: x"]) == []
    assert c.check_range(["packages/taro_core/lib/a.dart"], ["Merge branch x"])[0].path == "CHANGELOG.md"
    assert c.check_range(["docs/x.md", "packages/taro_core/test/a.dart"], ["feat: x"]) == []
    assert c.check_range([], []) == []


def test_range_over_git(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    init_git(root)
    base = commit_all(root, "chore: init")
    (root / "worker" / "src").mkdir(parents=True)
    (root / "worker" / "src" / "a.ts").write_text("export {};\n")
    commit_all(root, "feat(worker): a")
    assert c.main(["--root", str(root), "--range", f"{base}..HEAD"]) == 1
    (root / "worker" / "CHANGELOG.md").write_text((root / "worker" / "CHANGELOG.md").read_text() + "\n")
    commit_all(root, "docs(worker): changelog")
    assert c.main(["--root", str(root), "--pr", f"{base}..HEAD"]) == 0
    assert c.main(["--root", str(root), "--range", "nope..HEAD"]) == 1
    assert "cannot read" in capsys.readouterr().out


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0

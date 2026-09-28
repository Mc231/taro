from pathlib import Path

import pytest

import check_skadnetwork as c
from fixture_repo import REPO, make_root

CHECK = "check_skadnetwork"


def _rules(tmp_path: Path, case: str, require: bool = False) -> list[str]:
    findings, _ = c.run(make_root(tmp_path, CHECK, case), require)
    return sorted(f.rule for f in findings)


def test_pass(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    assert c.run(root, True) == ([], ["3 SKAdNetwork ID(s) compared"])
    assert c.main(["--root", str(root), "--require"]) == 0


def test_no_items_is_skipped_unless_required(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "no_items")
    findings, notices = c.run(root, False)
    assert findings == [] and "comparison skipped" in notices[0]
    assert c.main(["--root", str(root), "--require"]) == 1


@pytest.mark.parametrize(
    ("case", "rules"),
    [
        ("fail_missing", ["missing"]),
        ("fail_unpinned", ["duplicate", "unpinned"]),
        ("fail_bad_pinned", ["duplicate", "format"]),
    ],
)
def test_failures(tmp_path: Path, case: str, rules: list[str]) -> None:
    assert _rules(tmp_path, case) == rules


@pytest.mark.parametrize("case", ["fail_malformed", "fail_items_shape"])
def test_malformed_plist(tmp_path: Path, case: str) -> None:
    assert c.main(["--root", str(make_root(tmp_path, CHECK, case))]) == 1


def test_plist_shapes() -> None:
    with pytest.raises(c.InputError):
        c.plist_ids([])
    with pytest.raises(c.InputError):
        c.plist_ids({"SKAdNetworkItems": "x"})


def test_missing_files(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    assert [f.rule for f in c.run(root, False)[0]] == ["missing"]
    (root / "tools").mkdir()
    (root / "tools/skadnetwork_ids.txt").write_text("# nothing\n")
    findings, notices = c.run(root, False)
    assert [f.rule for f in findings] == ["empty"] and "not present yet" in notices[0]
    assert sorted(f.rule for f in c.run(root, True)[0]) == ["empty", "missing"]


def test_pinned_list_in_repo_is_well_formed() -> None:
    ids, findings = c.parse_pinned((REPO / c.PINNED).read_text())
    assert findings == [] and "cstr6suwn9.skadnetwork" in ids and len(ids) == 49


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0

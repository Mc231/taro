from pathlib import Path

import pytest

import check_contract_fixtures as c
from fixture_repo import REPO, make_root

CHECK = "check_contract_fixtures"


def _rules(tmp_path: Path, case: str) -> list[str]:
    findings, _ = c.run(make_root(tmp_path, CHECK, case))
    return sorted(f.rule for f in findings)


def test_pass(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    findings, notices = c.run(root)
    assert findings == [] and notices == ["2 canonical fixture(s) compared"]
    assert c.main(["--root", str(root)]) == 0


@pytest.mark.parametrize(
    ("case", "rules"),
    [
        ("fail_drift", ["drift"]),
        ("fail_missing_copy", ["missing-copy"]),
        ("fail_orphan", ["orphan-copy"]),
        ("fail_invalid_json", ["invalid-json"]),
        ("fail_no_dart", ["missing"]),
        ("fail_no_worker", ["missing"]),
    ],
)
def test_failures(tmp_path: Path, case: str, rules: list[str]) -> None:
    assert _rules(tmp_path, case) == rules
    assert c.main(["--root", str(make_root(tmp_path / "again", CHECK, case))]) == 1


def test_absent_is_skipped(tmp_path: Path) -> None:
    findings, notices = c.run(make_root(tmp_path, CHECK, None))
    assert findings == [] and "not present yet" in notices[0]


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0

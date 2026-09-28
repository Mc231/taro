from pathlib import Path

import pytest

import check_retention as c
from fixture_repo import REPO, make_root

CHECK = "check_retention"
SPECS = ("03_BACKEND_WORKER.md",)


def _root(tmp_path: Path, case: str | None) -> Path:
    return make_root(tmp_path, CHECK, case, SPECS)


def _findings(tmp_path: Path, case: str) -> list:
    findings, _ = c.run(_root(tmp_path, case))
    return findings


def test_pass(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    assert c.run(root) == ([], [])
    assert c.main(["--root", str(root)]) == 0


def test_privacy_mismatch(tmp_path: Path) -> None:
    findings = _findings(tmp_path, "fail_privacy_mismatch")
    assert {(f.path, f.message.split(":")[0]) for f in findings} == {
        ("web/privacy.en.md", "logs"),
        ("web/privacy.en.md", "reading_metadata"),
        ("web/privacy.en.md", "rewards"),
    }


def test_consent_mismatch(tmp_path: Path) -> None:
    findings = _findings(tmp_path, "fail_consent_mismatch")
    assert sorted(f.message.split(":")[0] for f in findings) == ["question", "reports"]
    assert all(f.rule == "mismatch" for f in findings)


def test_missing_categories(tmp_path: Path) -> None:
    findings = _findings(tmp_path, "fail_missing_category")
    assert sorted((f.rule, f.message.split(" ")[4]) for f in findings) == [("missing", "ledger"), ("missing", "reports")]


def test_missing_retention_section(tmp_path: Path) -> None:
    assert [f.rule for f in _findings(tmp_path, "fail_no_section")] == ["section-missing"]


@pytest.mark.parametrize("case", ["fail_arb_malformed", "fail_arb_not_string"])
def test_bad_arb(tmp_path: Path, case: str) -> None:
    assert c.main(["--root", str(_root(tmp_path, case))]) == 1


def test_targets_not_present_yet(tmp_path: Path) -> None:
    findings, notices = c.run(_root(tmp_path, "no_consent_yet"))
    assert findings == [] and len(notices) == 2
    findings, notices = c.run(_root(tmp_path / "bare", None))
    assert findings == [] and len(notices) == 2


def test_source_periods_from_the_spec() -> None:
    periods = c.source_periods((REPO / c.BACKEND).read_text())
    assert periods["question"] == c.NOT_STORED
    assert periods["ai_output"] == "7 days" and periods["ip"] == "48 hours" and periods["ledger"] == "7 years"


@pytest.mark.parametrize(
    "text",
    [
        "# nothing",
        "## 13. Privacy & retention\n\nno table\n",
        "## 13. Privacy & retention\n\n| Data | Where | Retention |\n|---|---|---|\n| Logs | x | 7 days |\n",
        "## 13. Privacy & retention\n\n| Data | Where | Retention |\n|---|---|---|\n| **Question text** | kept | — |\n",
    ],
)
def test_source_parse_errors(text: str) -> None:
    with pytest.raises(c.InputError):
        c.source_periods(text)


def test_helpers() -> None:
    assert c.normalize("48", "h") == "48 hours"
    assert c.first_period("no numbers") is None
    assert c.stated_periods("Logs are kept.") == {}


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0

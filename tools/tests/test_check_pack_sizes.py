"""Tests for tools/store_copy/check_pack_sizes.py (05 Risks, CS12, 04 §4, RC3)."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path

import pytest
from fixture_tree import REPO, fail_cases, materialize

from store_copy import check_pack_sizes as cps
from taro_tools.checkkit import InputError
from taro_tools.store import ASO_PATH, CATALOG_PATH

CHECK = "check_pack_sizes"

EXPECTED: dict[str, set[str]] = {
    "fail_display_name_locale": {"pack_size"},
    "fail_display_name_no_number": {"pack_size"},
    "fail_display_name_arabic_digits": {"pack_size"},
    "fail_description": {"pack_size"},
    "fail_pack_missing": {"pack_missing"},
    "fail_store_only_consumable": {"pack_missing"},
    "fail_credits_missing": {"credits_missing"},
}
MALFORMED = {"fail_malformed_catalog", "fail_malformed_aso"}


def test_every_fixture_is_covered() -> None:
    assert set(fail_cases(CHECK)) == set(EXPECTED) | MALFORMED


def test_pass_tree_is_clean(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    assert cps.check(root) == ([], [])
    assert cps.main(["--root", str(root)]) == 0
    assert "check_pack_sizes: OK" in capsys.readouterr().out


@pytest.mark.parametrize("case", sorted(EXPECTED))
def test_fail_modes(case: str, tmp_path: Path) -> None:
    root = materialize(CHECK, case, tmp_path)
    findings, _ = cps.check(root)
    assert {f.rule for f in findings} == EXPECTED[case], [f.render() for f in findings]
    assert cps.main(["--root", str(root)]) == 1


@pytest.mark.parametrize("case", sorted(MALFORMED))
def test_malformed_inputs_fail(case: str, tmp_path: Path) -> None:
    root = materialize(CHECK, case, tmp_path)
    with pytest.raises(InputError):
        cps.check(root)
    assert cps.main(["--root", str(root)]) == 1


@pytest.mark.parametrize("missing", [CATALOG_PATH, ASO_PATH])
def test_absent_input_is_skipped(missing: str, tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    (root / missing).unlink()
    findings, notices = cps.check(root)
    assert findings == []
    assert notices == [f"{missing} not present yet; skipped"]


def test_numbers_reads_unicode_digits() -> None:
    assert cps.numbers("٣ قراءات") == [3]
    assert cps.numbers("10 Readings, 2 free") == [10, 2]
    assert cps.numbers("Readings") == []


def test_current_repository_passes() -> None:
    assert cps.check(REPO)[0] == []


def test_script_entry_point(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    monkeypatch.setattr(sys, "argv", ["check_pack_sizes.py", "--root", str(root)])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(REPO / "tools" / "store_copy" / "check_pack_sizes.py"), run_name="__main__")
    assert exit_info.value.code == 0

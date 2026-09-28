"""Tests for tools/check_iap_ids.py (06 §6.2, 04 §4, RC3)."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path

import pytest
from fixture_tree import REPO, fail_cases, materialize

import check_iap_ids as cii
from taro_tools.checkkit import InputError
from taro_tools.store import ASO_PATH, CATALOG_PATH, PRODUCTS_PATH, normalize_kind

CHECK = "check_iap_ids"

EXPECTED: dict[str, set[str]] = {
    "fail_id_format": {"id_format", "product_set", "sets_differ"},
    "fail_product_set_dart": {"product_set", "sets_differ"},
    "fail_extra_product_aso": {"product_set", "sets_differ"},
    "fail_kind": {"kind", "single_non_consumable", "kinds_differ"},
    "fail_second_non_consumable": {"kind", "single_non_consumable", "kinds_differ"},
    "fail_unknown_kind": {"kind"},
    "fail_display_name_credits": {"display_name_credits"},
    "fail_play_differs": {"product_set", "single_non_consumable", "sets_differ"},
}
MALFORMED = {
    "fail_catalog_no_object",
    "fail_catalog_no_entries",
    "fail_catalog_no_kind",
    "fail_catalog_unbalanced",
    "fail_dart_no_ids",
    "fail_dart_no_kind",
    "fail_dart_id_outside_call",
    "fail_aso_not_mapping",
    "fail_aso_iap_not_list",
    "fail_aso_iap_no_id",
    "fail_aso_bad_yaml",
    "fail_aso_section_not_mapping",
}


def test_every_fixture_is_covered() -> None:
    assert set(fail_cases(CHECK)) == set(EXPECTED) | MALFORMED


def test_pass_tree_is_clean(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    findings, notices = cii.check(root)
    assert findings == [] and notices == []
    assert cii.main(["--root", str(root)]) == 0
    assert "check_iap_ids: OK" in capsys.readouterr().out


@pytest.mark.parametrize("case", sorted(EXPECTED))
def test_fail_modes(case: str, tmp_path: Path) -> None:
    root = materialize(CHECK, case, tmp_path)
    findings, _ = cii.check(root)
    assert {f.rule for f in findings} == EXPECTED[case], [f.render() for f in findings]
    assert cii.main(["--root", str(root)]) == 1


@pytest.mark.parametrize("case", sorted(MALFORMED))
def test_malformed_inputs_fail(case: str, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, case, tmp_path)
    with pytest.raises(InputError):
        cii.check(root)
    assert cii.main(["--root", str(root)]) == 1
    assert "malformed input" in capsys.readouterr().out


def test_parsed_sources_agree(tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    catalog = cii.parse_catalog_ts((root / CATALOG_PATH).read_text(), CATALOG_PATH)
    assert catalog["com.vshyrochuk.taro.readings_10"].credits == 10
    assert catalog["com.vshyrochuk.taro.readings_5"].retired
    assert catalog["com.vshyrochuk.taro.remove_ads"].credits is None
    dart = cii.parse_taro_products((root / PRODUCTS_PATH).read_text(), PRODUCTS_PATH)
    assert {p.kind for p in dart.values()} == {"consumable", "non_consumable"}
    assert "commented.out" not in dart
    assert dart["com.vshyrochuk.taro.readings_3"].line == 4


@pytest.mark.parametrize("present", [(), (CATALOG_PATH,), (PRODUCTS_PATH, ASO_PATH)])
def test_absent_sources_are_skipped(present: tuple[str, ...], tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    for label in (CATALOG_PATH, PRODUCTS_PATH, ASO_PATH):
        if label not in present:
            (root / label).unlink()
    findings, notices = cii.check(root)
    assert findings == []
    assert sum("not present yet" in n for n in notices) == 3 - len(present)


def test_aso_without_play_list(tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    aso = root / ASO_PATH
    aso.write_text(aso.read_text().split("google_play:")[0] + "google_play:\n  iap_products: '*same_ids_as_app_store'\n")
    assert cii.check(root)[0] == []


def test_normalize_kind() -> None:
    assert normalize_kind("NON_CONSUMABLE") == "non_consumable"
    assert normalize_kind("nonConsumable") == "non_consumable"
    assert normalize_kind("non-consumable") == "non_consumable"
    assert normalize_kind("Consumable") == "consumable"
    assert normalize_kind("subscription") is None


def test_current_repository_passes() -> None:
    assert cii.check(REPO)[0] == []


def test_script_entry_point(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    monkeypatch.setattr(sys, "argv", ["check_iap_ids.py", "--root", str(root)])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(REPO / "tools" / "check_iap_ids.py"), run_name="__main__")
    assert exit_info.value.code == 0

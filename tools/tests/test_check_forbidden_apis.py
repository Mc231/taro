"""Tests for tools/check_forbidden_apis.py (06 §6.2, QA9, RC90)."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path

import pytest
from fixture_tree import REPO, fail_cases, materialize

import check_forbidden_apis as cfa
from taro_tools.checkkit import InputError

CHECK = "check_forbidden_apis"
REAL = ("tools/import_rules.yaml",)

# Every fail overlay and the rule ids it must produce (exactly).
EXPECTED: dict[str, set[str]] = {
    "fail_datetime_now": {"datetime_now"},
    "fail_datetime_now_interpolated": {"datetime_now"},
    "fail_random": {"random"},
    "fail_random_secure": {"random_secure"},
    "fail_uuid_v4": {"uuid_v4", "sdk_import"},
    "fail_print": {"print"},
    "fail_debug_print": {"debug_print"},
    "fail_sdk_import": {"sdk_import"},
    "fail_sdk_banned_everywhere": {"sdk_import"},
    "fail_sdk_glob": {"sdk_import"},
    "fail_edge_insets": {"non_directional"},
    "fail_alignment": {"non_directional"},
    "fail_text_align": {"non_directional"},
    "fail_positioned": {"non_directional"},
    "fail_raw_color": {"raw_visual_value"},
    "fail_font_size": {"raw_visual_value"},
    "fail_duration": {"raw_visual_value"},
    "fail_test_support_relative": {"test_support_import"},
    "fail_test_support_package": {"test_support_import"},
}
MALFORMED = {
    "fail_malformed_rules",
    "fail_rules_not_yaml",
    "fail_rules_unknown_api",
    "fail_rules_missing",
}


def test_every_fixture_is_covered() -> None:
    assert set(fail_cases(CHECK)) == set(EXPECTED) | MALFORMED


def test_pass_tree_is_clean(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    findings, notices = cfa.check(root)
    assert findings == []
    assert notices == []
    assert cfa.main(["--root", str(root)]) == 0
    assert "check_forbidden_apis: OK" in capsys.readouterr().out


@pytest.mark.parametrize("case", sorted(EXPECTED))
def test_fail_modes(case: str, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, case, tmp_path, REAL)
    findings, _ = cfa.check(root)
    assert {f.rule for f in findings} == EXPECTED[case]
    assert all(f.line > 0 for f in findings)
    assert cfa.main(["--root", str(root)]) == 1
    assert "FAILED" in capsys.readouterr().out


@pytest.mark.parametrize("case", sorted(MALFORMED))
def test_malformed_rules_fail(case: str, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, case, tmp_path, REAL)
    with pytest.raises(InputError):
        cfa.check(root)
    assert cfa.main(["--root", str(root)]) == 1
    assert "malformed input" in capsys.readouterr().out


def test_edge_insets_reports_the_call_line(tmp_path: Path) -> None:
    root = materialize(CHECK, "fail_edge_insets", tmp_path, REAL)
    (finding,) = cfa.check(root)[0]
    assert finding.path == "apps/taro/lib/features/journal/view/journal_tile.dart"
    assert finding.line == 3


def test_empty_repo_has_notice(tmp_path: Path) -> None:
    (tmp_path / "tools").mkdir()
    (tmp_path / "tools" / "import_rules.yaml").write_text((REPO / REAL[0]).read_text())
    findings, notices = cfa.check(tmp_path)
    assert findings == []
    assert "nothing to scan" in notices[0]


@pytest.mark.parametrize(
    ("data", "message"),
    [
        ([], "top level"),
        ({"sdk_packages": []}, "non-empty"),
        ({"sdk_packages": [{"allowed": []}]}, "package"),
        ({"sdk_packages": [{"package": "x", "allowed": "a"}]}, "list of strings"),
        ({"sdk_packages": [{"package": "x", "allowed": []}], "api_allowlist": []}, "mapping"),
    ],
)
def test_parse_rules_rejects_bad_shapes(data: object, message: str) -> None:
    with pytest.raises(InputError, match=message):
        cfa.parse_rules(data)


def test_sdk_rule_prefers_exact_then_glob() -> None:
    rules = cfa.parse_rules(
        {
            "sdk_packages": [
                {"package": "firebase_*", "allowed": []},
                {"package": "firebase_core", "allowed": ["a/**"]},
            ]
        }
    )
    assert rules.sdk_rule("firebase_core").allowed == ("a/**",)
    assert rules.sdk_rule("firebase_messaging").allowed == ()
    assert rules.sdk_rule("flutter") is None


def test_real_rules_cover_every_sdk_named_in_06() -> None:
    rules = cfa.load_rules(REPO)
    for package in (
        "google_mobile_ads",
        "in_app_purchase",
        "in_app_purchase_storekit",
        "in_app_purchase_android",
        "firebase_core",
        "firebase_analytics",
        "firebase_crashlytics",
        "firebase_messaging",
        "app_tracking_transparency",
        "flutter_secure_storage",
        "http",
        "dio",
        "taro_attestation",
    ):
        assert rules.sdk_rule(package) is not None, package


def test_check_source_ignores_dart_imports_and_unknown_packages() -> None:
    rules = cfa.load_rules(REPO)
    source = "import 'dart:async';\nimport 'package:collection/collection.dart';\n"
    assert cfa.check_source("apps/taro/lib/features/x/view/a.dart", source, rules) == []


def test_current_repository_passes() -> None:
    findings, _ = cfa.check(REPO)
    assert findings == []


def test_script_entry_point(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    monkeypatch.setattr(sys, "argv", ["check_forbidden_apis.py", "--root", str(root)])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(REPO / "tools" / "check_forbidden_apis.py"), run_name="__main__")
    assert exit_info.value.code == 0

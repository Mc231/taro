"""Tests for tools/check_l10n.py (06 §6.2, 02 §11, RC26, RC94)."""

from __future__ import annotations

import json
import runpy
import sys
from pathlib import Path

import pytest
from fixture_tree import REPO, fail_cases, materialize

import check_l10n as cl
from taro_tools.checkkit import LOCALES, InputError

CHECK = "check_l10n"
REAL = ("tools/l10n_untranslated_allowlist.yaml",)

EXPECTED: dict[str, set[str]] = {
    "fail_missing_locale": {"missing_locale"},
    "fail_key_parity": {"key_parity"},
    "fail_placeholder_name": {"placeholder_mismatch"},
    "fail_placeholder_type": {"placeholder_mismatch"},
    "fail_icu_select": {"icu_mismatch"},
    "fail_icu_plural_category": {"icu_mismatch"},
    "fail_icu_plural_no_other": {"icu_mismatch"},
    "fail_icu_plural_exact": {"icu_mismatch"},
    "fail_icu_not_in_en": {"icu_mismatch"},
    "fail_invalid_icu": {"invalid_icu"},
    "fail_invalid_icu_en": {"invalid_icu"},
    "fail_empty_value": {"empty_value"},
    "fail_missing_description": {"missing_description"},
    "fail_untranslated": {"untranslated"},
    "fail_locale_mismatch": {"locale_mismatch"},
    "fail_unsupported_locale": {"unsupported_locale"},
    "fail_literal": {"user_facing_literal"},
    "fail_store_limits": {"field_limit"},
    "fail_glossary_keys": {"glossary_keys"},
    "fail_stale_allowlist": {"stale_allowlist"},
}
MALFORMED = {
    "fail_malformed_arb",
    "fail_arb_message_not_string",
    "fail_arb_metadata_not_object",
    "fail_arb_top_level_list",
    "fail_malformed_aso",
    "fail_glossary_no_section",
    "fail_malformed_allowlist",
    "fail_allowlist_bad_locale",
    "fail_allowlist_locale_not_list",
    "fail_allowlist_locales_not_mapping",
    "fail_allowlist_not_mapping",
}


def test_every_fixture_is_covered() -> None:
    assert set(fail_cases(CHECK)) == set(EXPECTED) | MALFORMED


def test_pass_tree_is_clean(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    findings, notices = cl.check(root)
    assert findings == []
    assert any("deck content not checked" in n for n in notices)
    assert cl.main(["--root", str(root)]) == 0
    assert "check_l10n: OK" in capsys.readouterr().out


@pytest.mark.parametrize("case", sorted(EXPECTED))
def test_fail_modes(case: str, tmp_path: Path) -> None:
    root = materialize(CHECK, case, tmp_path, REAL)
    findings, _ = cl.check(root)
    assert {f.rule for f in findings} == EXPECTED[case], [f.render() for f in findings]
    assert cl.main(["--root", str(root)]) == 1


@pytest.mark.parametrize("case", sorted(MALFORMED))
def test_malformed_inputs_fail(case: str, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, case, tmp_path, REAL)
    with pytest.raises(InputError):
        cl.check(root)
    assert cl.main(["--root", str(root)]) == 1
    assert "malformed input" in capsys.readouterr().out


def test_literal_findings_point_at_lines(tmp_path: Path) -> None:
    root = materialize(CHECK, "fail_literal", tmp_path, REAL)
    findings, _ = cl.check(root)
    assert sorted(f.line for f in findings) == [5, 6, 7]


def test_glossary_keys_are_staged(tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    en_path = root / "apps/taro/lib/l10n/arb/app_en.arb"
    en = json.loads(en_path.read_text())
    findings, notices = cl.glossary_findings(root, {"appTitle": "Taro"}, require=False)
    assert findings == [] and "not enforced" in notices[0]
    findings, _ = cl.glossary_findings(root, {"appTitle": "Taro"}, require=True)
    assert findings and findings[0].rule == "glossary_keys"
    assert cl.glossary_findings(root, en, require=True) == ([], [])
    (root / "docs/specs/GLOSSARY.md").unlink()
    assert "not present" in cl.glossary_findings(root, en, require=False)[1][0]


def test_require_glossary_keys_flag(tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    for locale in LOCALES:
        path = root / f"apps/taro/lib/l10n/arb/app_{locale}.arb"
        data = json.loads(path.read_text())
        for key in ("failureNetwork", "safetyDeclinedHealth", "@failureNetwork", "@safetyDeclinedHealth"):
            data.pop(key, None)
        path.write_text(json.dumps(data, ensure_ascii=False))
    assert cl.main(["--root", str(root)]) == 0
    assert cl.main(["--root", str(root), "--require-glossary-keys"]) == 1


def test_missing_inputs_are_skipped(tmp_path: Path) -> None:
    findings, notices = cl.check(tmp_path)
    assert findings == []
    assert len(notices) == 4
    assert any("ARB checks skipped" in n for n in notices)


def test_allowlist_absent_means_empty(tmp_path: Path) -> None:
    allowlist = cl.load_allowlist(tmp_path)
    assert not allowlist.allows("de", "appTitle")


# --- deck content (built programmatically: 78 cards x 12 locales) ---------


def _deck_tree(root: Path) -> None:
    for locale in LOCALES:
        cards = root / cl.CONTENT_SOURCE / locale / "cards"
        cards.mkdir(parents=True)
        for card in cl.CARD_IDS:
            (cards / f"{card}.yaml").write_text(f"name: {card}\nkeywords: [a]\n")
        deck = root / cl.DECK_ASSETS
        deck.mkdir(parents=True, exist_ok=True)
        (deck / f"{locale}.json").write_text(json.dumps({"cards": {c: {"name": c} for c in cl.CARD_IDS}}))


def test_deck_complete(tmp_path: Path) -> None:
    _deck_tree(tmp_path)
    assert cl.deck_findings(tmp_path) == ([], [])
    assert len(cl.CARD_IDS) == 78


def test_deck_missing_card_and_locale(tmp_path: Path) -> None:
    _deck_tree(tmp_path)
    (tmp_path / cl.CONTENT_SOURCE / "de/cards/major_13.yaml").unlink()
    (tmp_path / cl.DECK_ASSETS / "uk.json").unlink()
    (tmp_path / cl.DECK_ASSETS / "fr.json").write_text(json.dumps(["major_00"]))
    findings, notices = cl.deck_findings(tmp_path)
    assert [f.rule for f in findings] == ["deck_missing_card"]
    assert any("de/cards: 1 of 78 cards not translated yet" in n for n in notices)
    assert any("uk.json not built" in n for n in notices)
    strict, _ = cl.deck_findings(tmp_path, require_all_locales=True)
    assert {f.rule for f in strict} == {"deck_missing_card", "deck_missing_locale"}
    assert len(strict) == 3


def test_deck_en_is_required(tmp_path: Path) -> None:
    _deck_tree(tmp_path)
    (tmp_path / cl.CONTENT_SOURCE / "en/cards/major_13.yaml").unlink()
    (tmp_path / cl.DECK_ASSETS / "en.json").unlink()
    findings, _ = cl.deck_findings(tmp_path)
    assert sorted(f.rule for f in findings) == ["deck_missing_card", "deck_missing_locale"]


def test_deck_require_all_locales_flag(tmp_path: Path) -> None:
    _deck_tree(tmp_path)
    (tmp_path / cl.CONTENT_SOURCE / "de/cards/major_13.yaml").unlink()
    assert cl.main(["--root", str(tmp_path)]) == 0
    assert cl.main(["--root", str(tmp_path), "--require-all-locales"]) == 1


def test_deck_empty_field_and_malformed_card(tmp_path: Path) -> None:
    _deck_tree(tmp_path)
    (tmp_path / cl.CONTENT_SOURCE / "ja/cards/cups_01.yaml").write_text("name: ''\nmeaning:\n")
    findings, _ = cl.deck_findings(tmp_path)
    assert [f.rule for f in findings] == ["deck_empty_field"]
    (tmp_path / cl.CONTENT_SOURCE / "ja/cards/cups_01.yaml").write_text("- not a mapping\n")
    with pytest.raises(InputError):
        cl.deck_findings(tmp_path)


def test_deck_source_without_build(tmp_path: Path) -> None:
    _deck_tree(tmp_path)
    for path in (tmp_path / cl.DECK_ASSETS).glob("*.json"):
        path.unlink()
    findings, notices = cl.deck_findings(tmp_path)
    assert findings == [] and "not built yet" in notices[0]


# --- ICU parser ------------------------------------------------------------


def test_parse_icu_nested() -> None:
    args = cl.parse_icu("{count, plural, =0{none} other{{count} of {total, select, a{A} other{B}}}}")
    assert cl.placeholder_names(args) == {"count", "total"}
    assert args[0].kind == "plural" and set(args[0].branches) == {"=0", "other"}


def test_parse_icu_number_format_is_simple() -> None:
    args = cl.parse_icu("{price, number, {currency}} left")
    assert [(a.name, a.kind) for a in args] == [("price", "simple")]


@pytest.mark.parametrize(
    "message",
    [
        "a } b",
        "{",
        "{name",
        "{, plural, other{x}}",
        "{n, plural}",
        "{n, plural, }",
        "{n, plural, other}",
        "{n, plural, other{x}",
        "{n, plural, other{x",
        "{n, number{x}}",
        "{n, number, {x}",
        "{n{",
    ],
)
def test_parse_icu_errors(message: str) -> None:
    with pytest.raises(cl.IcuError):
        cl.parse_icu(message)


def test_current_repository_passes() -> None:
    findings, _ = cl.check(REPO)
    assert findings == []


def test_script_entry_point(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    monkeypatch.setattr(sys, "argv", ["check_l10n.py", "--root", str(root)])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(REPO / "tools" / "check_l10n.py"), run_name="__main__")
    assert exit_info.value.code == 0

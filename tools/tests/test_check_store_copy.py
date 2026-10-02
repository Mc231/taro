"""Tests for tools/store_copy/check_store_copy.py (05 §3, §7, §8.1, §9.5; RC39, RC79, RC80)."""

from __future__ import annotations

import json
import runpy
import sys
from pathlib import Path

import pytest
from fixture_tree import REPO, fail_cases, materialize

from store_copy import check_store_copy as csc
from taro_tools.checkkit import LOCALES, InputError, load_yaml

CHECK = "check_store_copy"
REAL = (
    "tools/store_copy/banned_phrases.yaml",
    "tools/store_copy/required_sentences.yaml",
    "tools/store_copy/certainty_exemptions.yaml",
    *(f"worker/safety/lexicons/{loc}.json" for loc in LOCALES),
)

EXPECTED: dict[str, set[str]] = {
    "fail_banned_phrase_en": {"banned_phrase"},
    "fail_banned_phrase_de": {"banned_phrase"},
    "fail_banned_phrase_ja": {"banned_phrase"},
    "fail_banned_phrase_uk": {"banned_phrase"},
    "fail_banned_common": {"banned_phrase"},
    "fail_apple_android": {"apple_fields_no_android"},
    "fail_apple_android_iap": {"apple_fields_no_android"},
    "fail_play_apple": {"play_fields_no_apple", "banned_phrase"},
    "fail_both_platforms": {"apple_fields_no_android", "play_fields_no_apple"},
    "fail_name_free": {"name_subtitle_banned"},
    "fail_disclaimer": {"description_has_disclaimer"},
    "fail_disclaimer_play": {"description_has_disclaimer"},
    "fail_keywords_spaces": {"keywords"},
    "fail_keywords_duplicate": {"keywords"},
    "fail_keywords_name_repeat": {"keywords"},
    "fail_field_limit": {"field_limit"},
    "fail_review_notes_length": {"field_limit"},
    "fail_locales_missing": {"locales_present"},
    "fail_unknown_locale": {"locales_present"},
    "fail_iap_localized": {"iap_localized"},
    "fail_remove_ads_name": {"remove_banner_ads_name"},
    "fail_remove_ads_long": {"remove_banner_ads_name", "field_limit"},
    "fail_remove_ads_missing_locale": {"remove_banner_ads_name"},
    "fail_review_labels": {"review_notes_labels_exist"},
    "fail_review_no_block": {"review_notes_labels_exist"},
    "fail_review_no_arb": {"review_notes_labels_exist"},
    "fail_banned_review_notes": {"banned_phrase"},
    "fail_banned_screenshot": {"banned_phrase"},
    "fail_banned_arb": {"banned_phrase"},
    "fail_banned_whats_new": {"banned_phrase"},
    "fail_banned_content": {"banned_phrase"},
    "fail_banned_prompt_template": {"banned_phrase"},
    "fail_certainty_arb": {"certainty_phrase"},
    "fail_certainty_ja": {"certainty_phrase"},
    "fail_certainty_content": {"certainty_phrase"},
    "fail_subscription": {"no_subscriptions"},
}
MALFORMED = {
    "fail_malformed_banned",
    "fail_malformed_required",
    "fail_malformed_aso",
    "fail_malformed_content",
    "fail_banned_missing",
    "fail_malformed_certainty",
}


def test_every_fixture_is_covered() -> None:
    assert set(fail_cases(CHECK)) == set(EXPECTED) | MALFORMED


def test_pass_tree_is_clean(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    findings, notices = csc.check(root)
    assert findings == [] and notices == []
    assert csc.main(["--root", str(root)]) == 0
    assert "check_store_copy: OK" in capsys.readouterr().out


@pytest.mark.parametrize("case", sorted(EXPECTED))
def test_fail_modes(case: str, tmp_path: Path) -> None:
    root = materialize(CHECK, case, tmp_path, REAL)
    findings, _ = csc.check(root)
    assert {f.rule for f in findings} == EXPECTED[case], [f.render() for f in findings]
    assert csc.main(["--root", str(root)]) == 1


@pytest.mark.parametrize("case", sorted(MALFORMED))
def test_malformed_inputs_fail(case: str, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, case, tmp_path, REAL)
    with pytest.raises(InputError):
        csc.check(root)
    assert csc.main(["--root", str(root)]) == 1
    assert "malformed input" in capsys.readouterr().out


def test_missing_surfaces_are_skipped(tmp_path: Path) -> None:
    for rel in REAL[:2]:
        (tmp_path / rel).parent.mkdir(parents=True, exist_ok=True)
        (tmp_path / rel).write_text((REPO / rel).read_text())
    findings, notices = csc.check(tmp_path)
    assert findings == []
    assert len(notices) == 6
    assert any("certainty wording (1.1.6) not checked" in n for n in notices)


def _matcher() -> csc.Matcher:
    banned = csc.parse_banned(load_yaml(REPO / csc.BANNED_PATH))
    required = csc.parse_required(load_yaml(REPO / csc.REQUIRED_PATH))
    return csc.Matcher(banned, required)


@pytest.mark.parametrize(
    ("locale", "text", "hit"),
    [
        ("en", "A GUARANTEED answer", "guaranteed"),
        ("en", "Guarantees included", "guarantee*"),
        ("en", "Readings are 100% yours", "100%"),
        ("en", "Ｐｓｙｃｈｉｃ readings", "psychic*"),  # NFKC full-width
        ("en", "spirits   say so", "spirits say"),
        ("fr", "prédire l’avenir", "prédire l'avenir"),
        ("uk", "Передбачення майбутнього", "передбач* майбутн*"),
        ("ja", "必ず当たる", "当たる"),
        ("tr", "Kesinlikle doğru", "kesin*"),
    ],
)
def test_matcher_hits(locale: str, text: str, hit: str) -> None:
    assert hit in {phrase for _, phrase in _matcher().hits(text, locale, ["global"])}


@pytest.mark.parametrize(
    ("locale", "text"),
    [
        ("en", "Questions about health are declined."),  # heal != health
        ("en", "Spelling out every card's symbolism."),  # spell != spelling
        ("en", "They are not medical, legal, financial or psychological advice."),
        ("en", "It does not predict the future."),
        ("tr", "Büyük Arkana kartları"),  # büyü != büyük
        ("fr", "Sortir et réfléchir"),  # sort != sortir
        ("de", "Die Tageskarte und das Journal"),
    ],
)
def test_matcher_word_boundaries_and_exemptions(locale: str, text: str) -> None:
    assert _matcher().hits(text, locale, ["global"]) == []


def test_required_sentences_are_clean_in_their_own_locale() -> None:
    banned = csc.parse_banned(load_yaml(REPO / csc.BANNED_PATH))
    required = csc.parse_required(load_yaml(REPO / csc.REQUIRED_PATH))
    raw = csc.Matcher(banned, {loc: "\x00" for loc in LOCALES})
    for locale, sentence in required.items():
        assert raw.hits(sentence, locale, ["global", "apple_only", "play_only"]) == [], locale
    assert required["en"].startswith("Taro is for entertainment and self-reflection.")


def test_every_locale_has_seed_phrases() -> None:
    banned = csc.parse_banned(load_yaml(REPO / csc.BANNED_PATH))
    for locale in LOCALES:
        assert len(banned[locale].lists["global"].phrases) > 5, locale
    en = {p for p, _ in banned["en"].lists["global"].phrases}
    seed = {
        "accurate", "guaranteed", "100%", "real psychic", "predict your future",
        "know your future", "medical", "cure", "win the lottery", "free unlimited", "limited time",
    }
    assert seed <= en
    apple = {p for p, _ in banned["en"].lists["apple_only"].phrases}
    assert {"android", "google play", "play store"} <= apple


@pytest.mark.parametrize(
    ("data", "message"),
    [
        ([], "top level"),
        ({"locales": {}, "common": ["x"]}, "common must be a mapping"),
        ({"common": {}}, "locales must be a mapping"),
        ({"locales": {"xx": {}}}, "unknown locales"),
        ({"locales": {"en": {}}}, "missing locales"),
        ({"common": {"extra": []}, "locales": dict.fromkeys(LOCALES, {})}, "not a phrase list"),
        ({"locales": {**dict.fromkeys(LOCALES, {}), "de": []}}, "must be a mapping"),
        ({"locales": {**dict.fromkeys(LOCALES, {}), "de": {"odd": 1}}}, "not a known key"),
        ({"locales": {**dict.fromkeys(LOCALES, {}), "de": {"match": "fuzzy"}}}, "word or substring"),
        ({"locales": {**dict.fromkeys(LOCALES, {}), "de": {"global": [""]}}}, "non-empty strings"),
    ],
)
def test_parse_banned_rejects_bad_shapes(data: object, message: str) -> None:
    with pytest.raises(InputError, match=message):
        csc.parse_banned(data)


def test_parse_required_rejects_unknown_locale() -> None:
    sentences = {loc: "x" for loc in LOCALES} | {"zz": "y"}
    with pytest.raises(InputError, match="unknown locales"):
        csc.parse_required({"description_disclaimer": sentences})
    with pytest.raises(InputError, match="description_disclaimer"):
        csc.parse_required([])


def test_phrase_regex_rejects_empty() -> None:
    with pytest.raises(ValueError):
        csc.phrase_regex("   ", substring=False)


def test_locale_of_paths() -> None:
    assert csc.locale_of("apps/taro/store/whats_new/1.0.0/de.txt") == "de"
    assert csc.locale_of("apps/taro/store/whats_new/en-US.txt") == "en"
    assert csc.locale_of("worker/prompts/reading/v1/templates/share.ja.md") == "ja"
    assert csc.locale_of("apps/taro/content/source/glossary.yaml") == "en"


def test_how_to_review_block() -> None:
    notes = "INTRO\nx\nHOW TO REVIEW\n1. Tap \"A\".\nNEXT PART\nTap \"B\".\n"
    assert csc.how_to_review_block(notes) == '1. Tap "A".'
    assert csc.how_to_review_block("nothing here") is None


def test_review_labels_edge_cases() -> None:
    assert csc.review_label_findings({}, None) == []
    no_quotes = {"app_review_information": {"notes": "HOW TO REVIEW\n1. Launch.\n"}}
    assert csc.review_label_findings(no_quotes, None) == []


def test_current_repository_passes() -> None:
    findings, _ = csc.check(REPO)
    assert findings == []


def test_script_entry_point(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path, REAL)
    monkeypatch.setattr(sys, "argv", ["check_store_copy.py", "--root", str(root)])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(REPO / "tools" / "store_copy" / "check_store_copy.py"), run_name="__main__")
    assert exit_info.value.code == 0


# --------------------------------------------------------------------------
# Apple 1.1.6: certainty wording in ARB and deck text (APPLE_MATRIX row 1.1.6)


def _certainty(exemptions: object | None = None) -> dict[str, csc.CertaintyRules]:
    banned = csc.parse_banned(load_yaml(REPO / csc.BANNED_PATH))
    lexicons = {loc: json.loads((REPO / csc.LEXICON_DIR / f"{loc}.json").read_text()) for loc in LOCALES}
    if exemptions is None:
        exemptions = load_yaml(REPO / csc.CERTAINTY_EXEMPTIONS_PATH)
    return csc.parse_certainty(lexicons, exemptions, banned)


def test_1_1_6_no_arb_or_deck_text_states_certainty() -> None:
    findings, notices = csc.check(REPO)
    assert [f for f in findings if f.rule == "certainty_phrase"] == []
    assert not any("certainty wording" in n for n in notices)
    rules = _certainty()
    assert all(rules[loc].phrases.phrases for loc in LOCALES)


@pytest.mark.parametrize(
    ("locale", "text", "hit"),
    [
        ("en", "This will definitely work out.", "will definitely"),
        ("fr", "Cela arrivera a coup sur.", "à coup sûr"),
        ("ja", "願いは絶対に叶います", "絶対に"),
    ],
)
def test_certainty_hits(locale: str, text: str, hit: str) -> None:
    assert _certainty()[locale].hits(text) == [hit]


@pytest.mark.parametrize(
    ("locale", "text"),
    [
        ("en", "Write down what you know for certain and what you assume."),
        ("en", "Nothing here is guaranteed; notice what will happen if you rest."),
        ("ar", "أسوأ الاحتمالات"),
        ("ja", "が"),
    ],
)
def test_certainty_non_claims_are_exempt(locale: str, text: str) -> None:
    assert _certainty()[locale].hits(text) == []


def test_certainty_without_exemptions_flags_the_reviewed_span() -> None:
    rules = _certainty({})
    assert rules["en"].hits("what you know for certain") == ["for certain"]


def test_fold_keeps_non_latin_marks() -> None:
    assert csc.fold("Cafe\u0301  À") == "cafe a"
    assert csc.fold("か\u3099") == "が"


@pytest.mark.parametrize(
    ("exemptions", "lexicon", "message"),
    [
        ([], {"l3": {"certainty": []}}, "non_claims mapping"),
        ({"non_claims": {"xx": ["a"]}}, {"l3": {"certainty": []}}, "unknown locales"),
        ({}, {"l3": {"certainty": ["a"], "nonClaimSpans": ["("]}}, "bad nonClaimSpans"),
        ({}, {"l3": []}, "l3.certainty"),
        ({}, [], "l3.certainty"),
    ],
)
def test_parse_certainty_rejects_bad_shapes(exemptions: object, lexicon: object, message: str) -> None:
    banned = csc.parse_banned(load_yaml(REPO / csc.BANNED_PATH))
    with pytest.raises(InputError, match=message):
        csc.parse_certainty({"en": lexicon}, exemptions, banned)


def test_certainty_findings_skip_locales_without_a_lexicon() -> None:
    assert csc.certainty_findings({}, "x", "k", "for sure", "en") == []

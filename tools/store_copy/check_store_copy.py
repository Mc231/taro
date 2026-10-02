#!/usr/bin/env python3
"""Store-copy lint: banned phrases, disclaimers, keywords, limits, labels.

05 CS3, §3, §7, §8.1, §9.5; 06 §6.2; RC39, RC79, RC80. Rules:

* ``banned_phrase`` — a phrase of ``banned_phrases.yaml`` (per locale plus
  ``common``) appears in ``apps/taro/store/aso.yaml`` fields and review notes,
  ``apps/taro/store/whats_new/**``, the ARB files, deck content
  (``apps/taro/content/source/**``) or the Worker's user-visible prompt
  templates (``worker/prompts/**/templates/**``);
* ``apple_fields_no_android`` / ``play_fields_no_apple`` — a platform list hit
  in a field shown by the other store;
* ``name_subtitle_banned`` — e.g. "free" in the name, subtitle or Play title;
* ``description_has_disclaimer`` — a long description lacks the locale's
  ``required_sentences.yaml`` sentence in its first 3 lines;
* ``keywords`` — spaces, empty or duplicate entries, or a word repeated from
  the locale's name/subtitle;
* ``field_limit`` — store limits, including review notes ≤ 4000;
* ``locales_present`` / ``iap_localized`` — the 12 locales;
* ``remove_banner_ads_name`` — the ``remove_ads`` display name is
  "Remove Banner Ads" and ≤ 30 characters in all 12 locales (RC80);
* ``review_notes_labels_exist`` — every "quoted" label in the review notes'
  HOW TO REVIEW block is a value in ``app_en.arb`` (RC79);
* ``certainty_phrase`` — Apple 1.1.6: an ARB message or deck text uses the
  Worker's L3 certainty wording (``worker/safety/lexicons/<locale>.json``
  ``l3.certainty``, after its ``nonClaimSpans`` and the reviewed non-claim
  spans of ``certainty_exemptions.yaml`` are removed);
* ``no_subscriptions`` — Apple 3.1.2 / CS5: an ``aso.yaml`` IAP product is
  auto-renewable or a subscription.

Surfaces that do not exist yet are skipped with a notice; the two YAML rule
files must exist and be well-formed.
"""

from __future__ import annotations

import re
import sys
import unicodedata
from collections import Counter
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from taro_tools.checkkit import (
    LOCALES,
    Finding,
    InputError,
    base_parser,
    load_json,
    load_yaml,
    rel,
    resolve_root,
    run_check,
)
from taro_tools.store import (
    ARB_DIR,
    ASO_PATH,
    TextField,
    aso_iap_products,
    arb_messages,
    arb_path,
    field_limit_findings,
    iter_store_fields,
    load_arb,
    load_aso,
)

NAME = "check_store_copy"
BANNED_PATH = "tools/store_copy/banned_phrases.yaml"
REQUIRED_PATH = "tools/store_copy/required_sentences.yaml"
LEXICON_DIR = "worker/safety/lexicons"
CERTAINTY_EXEMPTIONS_PATH = "tools/store_copy/certainty_exemptions.yaml"
WHATS_NEW_DIR = "apps/taro/store/whats_new"
CONTENT_SOURCE = "apps/taro/content/source"
PROMPT_TEMPLATES = "worker/prompts"
REMOVE_ADS = "com.vshyrochuk.taro.remove_ads"
REMOVE_ADS_NAME = "Remove Banner Ads"
TEXT_SUFFIXES = {".txt", ".md", ".yaml", ".yml", ".json"}

_LISTS = ("global", "apple_only", "play_only", "name_subtitle")
_NAME_FIELDS = {"name", "subtitle", "title"}
_DESCRIPTION_FIELDS = {"description", "full_description"}


def normalize(text: str) -> str:
    """NFKC, case-folded, curly apostrophes as ``'``."""
    text = unicodedata.normalize("NFKC", text)
    return text.replace("’", "'").replace("‘", "'").casefold()


def phrase_regex(phrase: str, substring: bool) -> re.Pattern[str]:
    """Regex for one banned phrase (``*`` = stem, word boundaries)."""
    tokens = normalize(phrase).split()
    if not tokens:
        raise ValueError("empty phrase")
    if substring:
        return re.compile(r"\s*".join(re.escape(t.rstrip("*")) for t in tokens))
    parts = [re.escape(t.rstrip("*")) + (r"\w*" if t.endswith("*") else "") for t in tokens]
    tail = "" if tokens[-1].endswith("*") else r"(?!\w)"
    return re.compile(r"(?<!\w)" + r"\s+".join(parts) + tail)


@dataclass(frozen=True)
class PhraseList:
    """Compiled phrases of one list for one locale."""

    phrases: tuple[tuple[str, re.Pattern[str]], ...]

    def hits(self, text: str) -> list[str]:
        """Phrases that occur in the (already normalized) ``text``."""
        return [phrase for phrase, pattern in self.phrases if pattern.search(text)]


@dataclass(frozen=True)
class LocaleRules:
    """Everything the matcher needs for one locale."""

    lists: Mapping[str, PhraseList]
    allowed_contexts: tuple[str, ...]
    substring: bool = False


def _str_list(value: Any, where: str) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list) or not all(isinstance(v, str) and v.strip() for v in value):
        raise InputError(BANNED_PATH, f"{where} must be a list of non-empty strings")
    return value


def parse_banned(data: Any) -> dict[str, LocaleRules]:
    """Validate and compile ``banned_phrases.yaml``."""
    if not isinstance(data, dict):
        raise InputError(BANNED_PATH, "top level must be a mapping")
    common = data.get("common") or {}
    locales = data.get("locales")
    if not isinstance(common, dict):
        raise InputError(BANNED_PATH, "common must be a mapping")
    if not isinstance(locales, dict):
        raise InputError(BANNED_PATH, "locales must be a mapping")
    unknown = sorted(set(map(str, locales)) - set(LOCALES))
    if unknown:
        raise InputError(BANNED_PATH, f"unknown locales: {', '.join(unknown)}")
    missing = [loc for loc in LOCALES if loc not in locales]
    if missing:
        raise InputError(BANNED_PATH, f"missing locales: {', '.join(missing)}")
    for key in common:
        if key not in _LISTS:
            raise InputError(BANNED_PATH, f"common.{key} is not a phrase list")
    rules: dict[str, LocaleRules] = {}
    for locale in LOCALES:
        block = locales[locale]
        if not isinstance(block, dict):
            raise InputError(BANNED_PATH, f"locales.{locale} must be a mapping")
        for key in block:
            if key not in (*_LISTS, "match", "allowed_contexts"):
                raise InputError(BANNED_PATH, f"locales.{locale}.{key} is not a known key")
        match = block.get("match", "word")
        if match not in ("word", "substring"):
            raise InputError(BANNED_PATH, f"locales.{locale}.match must be word or substring")
        lists = {}
        for name in _LISTS:
            phrases = _str_list(common.get(name), f"common.{name}") + _str_list(
                block.get(name), f"locales.{locale}.{name}"
            )
            lists[name] = PhraseList(
                tuple((p, phrase_regex(p, match == "substring")) for p in phrases)
            )
        contexts = _str_list(block.get("allowed_contexts"), f"locales.{locale}.allowed_contexts")
        rules[locale] = LocaleRules(lists, tuple(normalize(c) for c in contexts), match == "substring")
    return rules


def parse_required(data: Any) -> dict[str, str]:
    """Validate ``required_sentences.yaml``: a disclaimer for all 12 locales."""
    if not isinstance(data, dict) or not isinstance(data.get("description_disclaimer"), dict):
        raise InputError(REQUIRED_PATH, "needs a description_disclaimer mapping")
    sentences = data["description_disclaimer"]
    missing = [loc for loc in LOCALES if not isinstance(sentences.get(loc), str) or not sentences[loc].strip()]
    if missing:
        raise InputError(REQUIRED_PATH, f"no disclaimer for: {', '.join(missing)}")
    unknown = sorted(set(map(str, sentences)) - set(LOCALES))
    if unknown:
        raise InputError(REQUIRED_PATH, f"unknown locales: {', '.join(unknown)}")
    return {loc: sentences[loc] for loc in LOCALES}


def _squash(text: str) -> str:
    return " ".join(normalize(text).split())


class Matcher:
    """Banned-phrase lookup with the exemptions applied."""

    def __init__(self, rules: Mapping[str, LocaleRules], required: Mapping[str, str]) -> None:
        self.rules = rules
        self.required = {loc: _squash(s) for loc, s in required.items()}

    def hits(self, text: str, locale: str, lists: Iterable[str]) -> list[tuple[str, str]]:
        """``(list, phrase)`` pairs found in ``text`` for ``locale``."""
        rules = self.rules[locale]
        clean = _squash(text)
        for span in (self.required[locale], *rules.allowed_contexts):
            clean = clean.replace(_squash(span), " ")
        return [(name, phrase) for name in lists for phrase in rules.lists[name].hits(clean)]


_RULE_OF_LIST = {
    "global": "banned_phrase",
    "apple_only": "apple_fields_no_android",
    "play_only": "play_fields_no_apple",
    "name_subtitle": "name_subtitle_banned",
}


def _lists_for(platform: str, field: str) -> list[str]:
    lists = ["global"]
    if platform in ("apple", "both"):
        lists.append("apple_only")
    if platform in ("play", "both"):
        lists.append("play_only")
    if field in _NAME_FIELDS:
        lists.append("name_subtitle")
    return lists


def text_findings(
    matcher: Matcher,
    path: str,
    where: str,
    text: str,
    locale: str,
    lists: Iterable[str],
) -> list[Finding]:
    """Banned-phrase findings for one text."""
    return [
        Finding(path, 0, _RULE_OF_LIST[name], f"{where} ({locale}): contains {phrase!r}")
        for name, phrase in matcher.hits(text, locale, lists)
    ]


# --------------------------------------------------------------------------
# certainty wording (Apple 1.1.6)


def fold(text: str) -> str:
    """``normalize`` plus Latin diacritics dropped (the Worker's ``foldText``)."""
    out: list[str] = []
    latin = False
    for ch in unicodedata.normalize("NFD", normalize(text)):
        if unicodedata.combining(ch):
            if not latin:
                out.append(ch)
            continue
        latin = unicodedata.name(ch, "").startswith("LATIN")
        out.append(ch)
    return " ".join(unicodedata.normalize("NFC", "".join(out)).split())


@dataclass(frozen=True)
class CertaintyRules:
    """Certainty phrases of one locale and the spans that are not claims."""

    phrases: PhraseList
    non_claims: tuple[re.Pattern[str], ...]
    exempt: tuple[str, ...]

    def hits(self, text: str) -> list[str]:
        """Certainty phrases used as claims in ``text``."""
        clean = fold(text)
        for span in self.exempt:
            clean = clean.replace(span, " ")
        for pattern in self.non_claims:
            clean = pattern.sub(" ", clean)
        return self.phrases.hits(clean)


def _lexicon_strings(data: Any, key: str, label: str) -> list[str]:
    l3 = data.get("l3") if isinstance(data, dict) else None
    value = l3.get(key, []) if isinstance(l3, dict) else None
    if not isinstance(value, list) or not all(isinstance(v, str) and v.strip() for v in value):
        raise InputError(label, f"l3.{key} must be a list of non-empty strings")
    return value


def parse_certainty(
    lexicons: Mapping[str, Any], exemptions: Any, rules: Mapping[str, LocaleRules]
) -> dict[str, CertaintyRules]:
    """Compile the L3 certainty lists with the reviewed exemptions."""
    if not isinstance(exemptions, dict) or not isinstance(exemptions.get("non_claims", {}), dict):
        raise InputError(CERTAINTY_EXEMPTIONS_PATH, "needs a non_claims mapping of locale to spans")
    spans = exemptions.get("non_claims", {})
    unknown = sorted(set(map(str, spans)) - set(LOCALES))
    if unknown:
        raise InputError(CERTAINTY_EXEMPTIONS_PATH, f"unknown locales: {', '.join(unknown)}")
    compiled: dict[str, CertaintyRules] = {}
    for locale, data in lexicons.items():
        label = f"{LEXICON_DIR}/{locale}.json"
        substring = rules[locale].substring
        phrases = PhraseList(
            tuple((p, phrase_regex(fold(p), substring)) for p in _lexicon_strings(data, "certainty", label))
        )
        try:
            non_claims = tuple(re.compile(s) for s in _lexicon_strings(data, "nonClaimSpans", label))
        except re.error as error:
            raise InputError(label, f"bad nonClaimSpans regex: {error}") from error
        exempt = tuple(fold(s) for s in _str_list(spans.get(locale), f"non_claims.{locale}"))
        compiled[locale] = CertaintyRules(phrases, non_claims, exempt)
    return compiled


def load_certainty(root: Path, rules: Mapping[str, LocaleRules]) -> dict[str, CertaintyRules] | None:
    """The certainty rules, or ``None`` before the Worker lexicons exist."""
    directory = root / LEXICON_DIR
    if not directory.is_dir():
        return None
    lexicons = {
        locale: load_json(directory / f"{locale}.json", f"{LEXICON_DIR}/{locale}.json")
        for locale in LOCALES
        if (directory / f"{locale}.json").is_file()
    }
    path = root / CERTAINTY_EXEMPTIONS_PATH
    exemptions = load_yaml(path, CERTAINTY_EXEMPTIONS_PATH) if path.is_file() else {}
    return parse_certainty(lexicons, exemptions, rules)


def certainty_findings(
    certainty: Mapping[str, CertaintyRules], path: str, where: str, text: str, locale: str
) -> list[Finding]:
    """``certainty_phrase`` findings for one in-app or deck text."""
    rules = certainty.get(locale)
    if rules is None:
        return []
    return [
        Finding(path, 0, "certainty_phrase", f"{where} ({locale}): states certainty with {phrase!r} (1.1.6)")
        for phrase in rules.hits(text)
    ]


# --------------------------------------------------------------------------
# aso.yaml rules


def _first_lines(text: str, count: int = 3) -> str:
    return " ".join([line for line in text.splitlines() if line.strip()][:count])


def _words(text: str) -> set[str]:
    return {w for w in re.split(r"[\W_]+", normalize(text)) if w}


def keyword_findings(fields: Sequence[TextField]) -> list[Finding]:
    """05 §8.1 rules 1–2 for ``localizations.<loc>.keywords``."""
    findings: list[Finding] = []
    by_locale: dict[str, dict[str, str]] = {}
    for f in fields:
        if f.key.startswith("localizations."):
            by_locale.setdefault(f.locale, {})[f.field] = f.text
    for locale, values in sorted(by_locale.items()):
        keywords = values.get("keywords")
        if keywords is None:
            continue
        key = f"localizations.{locale}.keywords"
        problems: list[str] = []
        if re.search(r"\s", keywords.strip()):
            problems.append("contains whitespace (use commas only)")
        entries = [normalize(k) for k in keywords.strip().split(",")]
        if any(not e.strip() for e in entries):
            problems.append("has an empty entry")
        dups = sorted(e for e, n in Counter(entries).items() if n > 1 and e.strip())
        if dups:
            problems.append(f"duplicates {dups}")
        name_words = _words(values.get("name", "")) | _words(values.get("subtitle", ""))
        repeated = sorted({e.strip() for e in entries} & name_words)
        if repeated:
            problems.append(f"repeats name/subtitle words {repeated}")
        findings += [Finding(ASO_PATH, 0, "keywords", f"{key} {p}") for p in problems]
    return findings


def disclaimer_findings(fields: Sequence[TextField], required: Mapping[str, str]) -> list[Finding]:
    """Every long description starts (first 3 lines) with its disclaimer."""
    findings = []
    for f in fields:
        if f.field in _DESCRIPTION_FIELDS and f.locale in required and not f.key.startswith(
            ("app_store.iap_products", "google_play.iap_products")
        ):
            if _squash(required[f.locale]) not in _squash(_first_lines(f.text)):
                findings.append(
                    Finding(
                        ASO_PATH,
                        0,
                        "description_has_disclaimer",
                        f"{f.key}: the first 3 lines lack the {f.locale} disclaimer sentence",
                    )
                )
    return findings


def locale_findings(aso: Mapping[str, Any]) -> list[Finding]:
    """All 12 locales in ``localizations``; no unknown locale anywhere."""
    findings: list[Finding] = []
    locs = aso.get("localizations") or {}
    missing = [loc for loc in LOCALES if loc not in locs]
    if missing:
        findings.append(
            Finding(ASO_PATH, 0, "locales_present", f"localizations lacks: {', '.join(missing)}")
        )
    return findings


def _unknown_locale_findings(fields: Sequence[TextField]) -> list[Finding]:
    bad = sorted({(f.key.rsplit(".", 1)[0], f.locale) for f in fields if f.locale not in LOCALES})
    return [
        Finding(ASO_PATH, 0, "locales_present", f"{key}: {locale!r} is not one of the 12 locales")
        for key, locale in bad
    ]


def iap_findings(aso: Mapping[str, Any]) -> list[Finding]:
    """IAP names in 12 locales (05 §8.1 rule 6) and RC80 for Remove Ads."""
    findings: list[Finding] = []
    for index, item in enumerate(aso_iap_products(aso, "app_store")):
        key = f"app_store.iap_products[{index}]"
        locs = item.get("localizations") or {}
        names = {"en": item.get("display_name")}
        names.update(
            {str(loc): (entry or {}).get("display_name") for loc, entry in locs.items() if isinstance(entry, dict)}
        )
        missing = [loc for loc in LOCALES if not isinstance(names.get(loc), str) or not names[loc].strip()]
        if item["product_id"] != REMOVE_ADS:
            if missing:
                findings.append(
                    Finding(ASO_PATH, 0, "iap_localized", f"{key} ({item['product_id']}) lacks display_name for: {', '.join(missing)}")
                )
            continue
        rule = "remove_banner_ads_name"
        if names["en"] != REMOVE_ADS_NAME:
            findings.append(Finding(ASO_PATH, 0, rule, f"{key}.display_name is {names['en']!r}, expected {REMOVE_ADS_NAME!r} (RC80)"))
        if missing:
            findings.append(Finding(ASO_PATH, 0, rule, f"{key} lacks a localized display_name for: {', '.join(missing)}"))
        for loc in LOCALES:
            name = names.get(loc)
            if isinstance(name, str) and len(name) > 30:
                findings.append(Finding(ASO_PATH, 0, rule, f"{key} {loc} display_name is {len(name)} characters (limit 30)"))
    return findings


_QUOTED = re.compile(r"[\"“]([^\"“”\n]+)[\"”]")
_HEADING = re.compile(r"^[A-Z][A-Z0-9 ()/&.,'-]+$")


def how_to_review_block(notes: str) -> str | None:
    """The text between the HOW TO REVIEW heading and the next heading."""
    lines = notes.splitlines()
    for index, line in enumerate(lines):
        if line.strip().upper().startswith("HOW TO REVIEW"):
            block = []
            for follow in lines[index + 1:]:
                if _HEADING.match(follow.strip()):
                    break
                block.append(follow)
            return "\n".join(block)
    return None


def review_label_findings(aso: Mapping[str, Any], en: Mapping[str, Any] | None) -> list[Finding]:
    """RC79: quoted HOW TO REVIEW labels exist verbatim in ``app_en.arb``."""
    review = aso.get("app_review_information") or {}
    notes = review.get("notes") if isinstance(review, dict) else None
    if not isinstance(notes, str) or not notes.strip():
        return []
    block = how_to_review_block(notes)
    rule = "review_notes_labels_exist"
    if block is None:
        return [Finding(ASO_PATH, 0, rule, "app_review_information.notes has no HOW TO REVIEW block")]
    labels = _QUOTED.findall(block)
    if not labels:
        return []
    if en is None:
        return [Finding(ASO_PATH, 0, rule, f"{arb_path('en')} is missing; cannot verify quoted labels")]
    values = set(arb_messages(en).values())
    return [
        Finding(ASO_PATH, 0, rule, f"quoted label {label!r} is not a value in {arb_path('en')}")
        for label in dict.fromkeys(labels)
        if label not in values
    ]


def aso_findings(
    aso: Mapping[str, Any], matcher: Matcher, required: Mapping[str, str], en: Mapping[str, Any] | None
) -> list[Finding]:
    """Every rule over ``aso.yaml``."""
    fields = iter_store_fields(aso)
    findings = _unknown_locale_findings(fields)
    for f in fields:
        if f.locale in LOCALES:
            lists = ["global"] if f.platform == "review" else _lists_for(f.platform, f.field)
            findings += text_findings(matcher, ASO_PATH, f.key, f.text, f.locale, lists)
    findings += field_limit_findings(fields)
    findings += keyword_findings(fields)
    findings += disclaimer_findings([f for f in fields if f.locale in LOCALES], required)
    findings += locale_findings(aso)
    findings += iap_findings(aso)
    findings += review_label_findings(aso, en)
    findings += subscription_findings(aso)
    return findings


def subscription_findings(aso: Mapping[str, Any]) -> list[Finding]:
    """Apple 3.1.2 / CS5: v1 sells no subscriptions (no auto-renewable products)."""
    return [
        Finding(ASO_PATH, 0, "no_subscriptions", f"{section}.iap_products {item['product_id']} is {kind!r} (CS5: no subscriptions in v1)")
        for section in ("app_store", "google_play")
        for item in aso_iap_products(aso, section)
        if any(word in (kind := str(item.get("type", ""))).upper() for word in ("AUTO_RENEW", "SUBSCRIPTION"))
    ]


# --------------------------------------------------------------------------
# Other surfaces


def locale_of(path: str) -> str:
    """The locale named by a path segment or ``name.<locale>.ext`` (else en)."""
    parts = re.split(r"[/._-]", path)
    for part in reversed(parts):
        if part in LOCALES:
            return part
    return "en"


def _yaml_strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return [s for item in value.values() for s in _yaml_strings(item)]
    if isinstance(value, list):
        return [s for item in value for s in _yaml_strings(item)]
    return []


def file_findings(
    matcher: Matcher,
    root: Path,
    files: Iterable[Path],
    lists: list[str],
    certainty: Mapping[str, CertaintyRules] | None = None,
) -> list[Finding]:
    """Banned phrases (and certainty wording, if given) in text/YAML files; the locale comes from the path."""
    findings: list[Finding] = []
    for path in files:
        label = rel(root, path)
        locale = locale_of(label)
        if path.suffix in (".yaml", ".yml"):
            texts = _yaml_strings(load_yaml(path, label))
        else:
            texts = [path.read_text(encoding="utf-8")]
        for text in texts:
            findings += text_findings(matcher, label, "text", text, locale, lists)
            if certainty is not None:
                findings += certainty_findings(certainty, label, "text", text, locale)
    return findings


def _text_files(directory: Path) -> list[Path]:
    return sorted(p for p in directory.rglob("*") if p.is_file() and p.suffix in TEXT_SUFFIXES)


def arb_findings(
    matcher: Matcher,
    arbs: Mapping[str, Mapping[str, Any]],
    certainty: Mapping[str, CertaintyRules] | None = None,
) -> list[Finding]:
    """Banned phrases and certainty wording in ARB message values (in-app text: global lists)."""
    findings: list[Finding] = []
    for locale, arb in arbs.items():
        for key, value in arb_messages(arb).items():
            findings += text_findings(matcher, arb_path(locale), key, value, locale, ["global"])
            if certainty is not None:
                findings += certainty_findings(certainty, arb_path(locale), key, value, locale)
    return findings


def check(root: Path) -> tuple[list[Finding], list[str]]:
    """Findings and notices for the repository at ``root``."""
    for label in (BANNED_PATH, REQUIRED_PATH):
        if not (root / label).is_file():
            raise InputError(label, "missing (the check cannot run without it)")
    required = parse_required(load_yaml(root / REQUIRED_PATH, REQUIRED_PATH))
    banned = parse_banned(load_yaml(root / BANNED_PATH, BANNED_PATH))
    matcher = Matcher(banned, required)
    findings: list[Finding] = []
    notices: list[str] = []
    certainty = load_certainty(root, banned)
    if certainty is None:
        notices.append(f"{LEXICON_DIR} not present yet; certainty wording (1.1.6) not checked")

    arbs: dict[str, dict[str, Any]] = {}
    if (root / ARB_DIR).is_dir():
        for locale in LOCALES:
            path = root / arb_path(locale)
            if path.is_file():
                arbs[locale] = load_arb(path, arb_path(locale))
        findings += arb_findings(matcher, arbs, certainty)
    else:
        notices.append(f"{ARB_DIR} not present yet; ARB copy not checked")

    aso = load_aso(root)
    if aso is None:
        notices.append(f"{ASO_PATH} not present yet; store listing rules skipped")
    else:
        findings += aso_findings(aso, matcher, required, arbs.get("en"))

    surfaces = (
        (WHATS_NEW_DIR, "*", ["global", "apple_only", "play_only"], None),
        (CONTENT_SOURCE, "*", ["global"], certainty),
        (PROMPT_TEMPLATES, "templates", ["global"], None),
    )
    for base, marker, lists, cert in surfaces:
        directory = root / base
        files = _text_files(directory) if directory.is_dir() else []
        if marker == "templates":
            files = [p for p in files if "templates" in p.relative_to(directory).parts]
        if not files:
            where = f"{base}/**/templates/**" if marker == "templates" else f"{base}/**"
            notices.append(f"{where} not present yet; skipped")
            continue
        findings += file_findings(matcher, root, files, lists, cert)
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    """CLI entry point."""
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: check(root))


if __name__ == "__main__":
    sys.exit(main())

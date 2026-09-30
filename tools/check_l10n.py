#!/usr/bin/env python3
"""Localization gate: ARB parity, literals, deck content and store limits.

06 §6.2 ``check_l10n.py`` (02 §11, RC26, RC94). The former
``tools/dart_tools/bin/check_arb.dart`` (02 §11) is folded into this script
(docs/phase3_notes/CHECKS.md). Fails when:

* an ARB file of the 12 locales is missing, malformed, has a key set that
  differs from ``app_en.arb`` or a ``@@locale`` that differs from its name;
* a placeholder name or declared type, or an ICU select branch, differs from
  ``en``; a plural lacks ``other``, drops an ``=N`` branch of ``en`` or uses a
  CLDR category the locale does not have;
* a value is empty; an ``en`` key lacks ``@key.description``;
* a non-``en`` value equals ``en`` and the key is not in
  ``tools/l10n_untranslated_allowlist.yaml`` and not marked
  ``"@key": {"x-translate": true}`` (a development-mode placeholder copied
  from ``en``, Phase 13; the markers are counted as notices, and
  ``--strict-translations`` (Phase 18) makes every marker a finding);
* a ``Text('…')`` / ``label: '…'`` / ``tooltip: '…'`` literal with a letter
  sits in a widget ``lib/`` file (debug-only folders excepted);
* deck content is missing an ``en`` card (source or build), a card file has
  an empty field, or a built locale lacks a card; untranslated locales are
  notices until Phase 18 (``--require-all-locales`` makes them findings);
* a store field in ``apps/taro/store/aso.yaml`` exceeds its limit;
* a ``failure*`` / ``safetyDeclined*`` key of GLOSSARY §5 / §5.2 is missing
  from ``app_en.arb`` (RC94; enforced once the first such key exists, or
  always with ``--require-glossary-keys``).

Inputs that do not exist yet are skipped with a notice.
"""

from __future__ import annotations

import re
import sys
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from taro_tools.checkkit import (
    LOCALES,
    Finding,
    InputError,
    base_parser,
    glob_match,
    line_of,
    load_json,
    load_yaml,
    mask_dart,
    rel,
    resolve_root,
    run_check,
)
from taro_tools.store import (
    ARB_DIR,
    arb_messages,
    arb_path,
    field_limit_findings,
    iter_store_fields,
    load_arb,
    load_aso,
)

NAME = "check_l10n"
ALLOWLIST_PATH = "tools/l10n_untranslated_allowlist.yaml"
GLOSSARY_PATH = "docs/specs/GLOSSARY.md"
CONTENT_SOURCE = "apps/taro/content/source"
DECK_ASSETS = "apps/taro/assets/deck"

# CLDR cardinal plural categories per supported locale.
PLURAL_CATEGORIES: dict[str, frozenset[str]] = {
    "en": frozenset({"one", "other"}),
    "ar": frozenset({"zero", "one", "two", "few", "many", "other"}),
    "de": frozenset({"one", "other"}),
    "es": frozenset({"one", "many", "other"}),
    "fr": frozenset({"one", "many", "other"}),
    "it": frozenset({"one", "many", "other"}),
    "ja": frozenset({"other"}),
    "ko": frozenset({"other"}),
    "nl": frozenset({"one", "other"}),
    "pt": frozenset({"one", "many", "other"}),
    "tr": frozenset({"one", "other"}),
    "uk": frozenset({"one", "few", "many", "other"}),
}

# Canonical card ids (RC1): major_00…major_21, <suit>_01…_14.
CARD_IDS: tuple[str, ...] = tuple(
    [f"major_{n:02d}" for n in range(22)]
    + [f"{suit}_{n:02d}" for suit in ("wands", "cups", "swords", "pentacles") for n in range(1, 15)]
)

LITERAL_SCOPE = ("apps/taro/lib/**", "packages/taro_ui/lib/**")
LITERAL_EXCEPT = (
    "apps/taro/lib/features/debug/**",
    "apps/taro/lib/l10n/generated/**",
    "**/*.g.dart",
    "**/*.freezed.dart",
    "**/*.gen.dart",
    "**/lib/src/tokens/generated/**",
)
_LITERAL = re.compile(
    r"""(?<![\w$])(?:Text\s*\(\s*|(?:label|tooltip)\s*:\s*)r?(['"])((?:\\.|(?!\1)[^\n])*)\1"""
)
_INTERPOLATION = re.compile(r"\$\{[^}]*\}|\$[A-Za-z_]\w*")
_LETTER = re.compile(r"[^\W\d_]")
_GLOSSARY_KEY = re.compile(r"`((?:failure|safetyDeclined)[A-Z]\w*)`")
X_TRANSLATE = "x-translate"


# --------------------------------------------------------------------------
# ICU message parsing


@dataclass
class IcuArg:
    """One ``{…}`` argument; ``branches`` for plural/select."""

    name: str
    kind: str
    branches: dict[str, list[IcuArg]] = field(default_factory=dict)


class IcuError(ValueError):
    """The message is not valid ICU."""


def _skip_ws(text: str, i: int) -> int:
    while i < len(text) and text[i].isspace():
        i += 1
    return i


def _parse_text(text: str, i: int, nested: bool) -> tuple[list[IcuArg], int]:
    args: list[IcuArg] = []
    while i < len(text):
        char = text[i]
        if char == "{":
            arg, i = _parse_arg(text, i)
            args.append(arg)
        elif char == "}":
            if nested:
                return args, i
            raise IcuError("unbalanced '}'")
        else:
            i += 1
    if nested:
        raise IcuError("unterminated branch")
    return args, i


def _read_until(text: str, i: int, stops: str) -> tuple[str, int]:
    start = i
    while i < len(text) and text[i] not in stops:
        i += 1
    if i >= len(text):
        raise IcuError("unterminated argument")
    return text[start:i].strip(), i


def _parse_arg(text: str, i: int) -> tuple[IcuArg, int]:
    name, i = _read_until(text, i + 1, ",}{")
    if text[i] == "{" or not name:
        raise IcuError("malformed argument name")
    if text[i] == "}":
        return IcuArg(name, "simple"), i + 1
    kind, i = _read_until(text, i + 1, ",}{")
    if kind not in ("plural", "select", "selectordinal"):
        if text[i] == "{":
            raise IcuError(f"unexpected '{{' after {kind!r}")
        # `{x, number, …}` style: keep as a simple placeholder.
        depth = 1
        while depth:
            i += 1
            if i >= len(text):
                raise IcuError("unterminated argument")
            depth += {"{": 1, "}": -1}.get(text[i], 0)
        return IcuArg(name, "simple"), i + 1
    if text[i] != ",":
        raise IcuError(f"{kind} without branches")
    arg = IcuArg(name, kind)
    i += 1
    while True:
        i = _skip_ws(text, i)
        if i >= len(text):
            raise IcuError("unterminated plural/select")
        if text[i] == "}":
            if not arg.branches:
                raise IcuError(f"{kind} without branches")
            return arg, i + 1
        start = i
        while i < len(text) and not text[i].isspace() and text[i] not in "{}":
            i += 1
        key = text[start:i]
        i = _skip_ws(text, i)
        if not key or i >= len(text) or text[i] != "{":
            raise IcuError(f"malformed {kind} branch")
        sub, i = _parse_text(text, i + 1, nested=True)
        arg.branches[key] = sub
        i += 1


def parse_icu(message: str) -> list[IcuArg]:
    """Top-level ICU arguments of ``message`` (raises :class:`IcuError`)."""
    args, _ = _parse_text(message, 0, nested=False)
    return args


def _walk(args: list[IcuArg]) -> list[IcuArg]:
    out: list[IcuArg] = []
    for arg in args:
        out.append(arg)
        for sub in arg.branches.values():
            out += _walk(sub)
    return out


def placeholder_names(args: list[IcuArg]) -> set[str]:
    """Every argument name used anywhere in the message."""
    return {arg.name for arg in _walk(args)}


# --------------------------------------------------------------------------
# ARB checks


def _placeholder_types(arb: Mapping[str, Any], key: str) -> dict[str, str]:
    meta = arb.get(f"@{key}")
    if not isinstance(meta, dict) or not isinstance(meta.get("placeholders"), dict):
        return {}
    return {
        name: str(spec.get("type"))
        for name, spec in meta["placeholders"].items()
        if isinstance(spec, dict) and spec.get("type") is not None
    }


def _compare_icu(
    locale: str, key: str, en_args: list[IcuArg], args: list[IcuArg], path: str
) -> list[Finding]:
    findings: list[Finding] = []
    en_names, names = placeholder_names(en_args), placeholder_names(args)
    if en_names != names:
        findings.append(
            Finding(
                path,
                0,
                "placeholder_mismatch",
                f"{key}: placeholders {sorted(names)} != en {sorted(en_names)}",
            )
        )
    en_by_name = {a.name: a for a in _walk(en_args) if a.kind != "simple"}
    for arg in _walk(args):
        if arg.kind == "simple":
            continue
        ref = en_by_name.get(arg.name)
        if ref is None or ref.kind != arg.kind:
            findings.append(
                Finding(path, 0, "icu_mismatch", f"{key}: {{{arg.name}, {arg.kind}}} is not in en")
            )
            continue
        keys = set(arg.branches)
        if arg.kind == "select":
            if keys != set(ref.branches):
                findings.append(
                    Finding(
                        path,
                        0,
                        "icu_mismatch",
                        f"{key}: select branches {sorted(keys)} != en {sorted(ref.branches)}",
                    )
                )
            continue
        exact = {k for k in ref.branches if k.startswith("=")}
        allowed = PLURAL_CATEGORIES[locale] | {k for k in keys if re.fullmatch(r"=\d+", k)}
        problems = []
        if "other" not in keys:
            problems.append("no 'other' branch")
        if exact - keys:
            problems.append(f"missing {sorted(exact - keys)} of en")
        if keys - allowed:
            problems.append(f"categories {sorted(keys - allowed)} not used by {locale}")
        if problems:
            findings.append(Finding(path, 0, "icu_mismatch", f"{key}: plural {'; '.join(problems)}"))
    return findings


@dataclass(frozen=True)
class Allowlist:
    """Keys whose translation may equal the English text."""

    keys: frozenset[str]
    per_locale: Mapping[str, frozenset[str]]

    def allows(self, locale: str, key: str) -> bool:
        return key in self.keys or key in self.per_locale.get(locale, frozenset())


def x_translate_keys(arb: Mapping[str, Any]) -> set[str]:
    """Keys marked ``"@key": {"x-translate": true}`` (awaiting translation)."""
    return {
        key[1:]
        for key, meta in arb.items()
        if key.startswith("@") and not key.startswith("@@") and isinstance(meta, dict) and meta.get(X_TRANSLATE) is True
    }


def load_allowlist(root: Path) -> Allowlist:
    """``tools/l10n_untranslated_allowlist.yaml`` (empty when absent)."""
    path = root / ALLOWLIST_PATH
    if not path.is_file():
        return Allowlist(frozenset(), {})
    data = load_yaml(path, ALLOWLIST_PATH) or {}
    if not isinstance(data, dict):
        raise InputError(ALLOWLIST_PATH, "top level must be a mapping")
    keys = data.get("keys") or []
    locales = data.get("locales") or {}
    if not isinstance(keys, list) or not all(isinstance(k, str) for k in keys):
        raise InputError(ALLOWLIST_PATH, "keys must be a list of strings")
    if not isinstance(locales, dict):
        raise InputError(ALLOWLIST_PATH, "locales must be a mapping")
    per: dict[str, frozenset[str]] = {}
    for locale, value in locales.items():
        if locale not in LOCALES or locale == "en":
            raise InputError(ALLOWLIST_PATH, f"locales.{locale} is not a translated locale")
        if not isinstance(value, list) or not all(isinstance(k, str) for k in value):
            raise InputError(ALLOWLIST_PATH, f"locales.{locale} must be a list of strings")
        per[locale] = frozenset(value)
    return Allowlist(frozenset(keys), per)


def check_arbs(
    arbs: Mapping[str, Mapping[str, Any]], allowlist: Allowlist, strict_translations: bool = False
) -> list[Finding]:
    """Parity, ICU, emptiness, description and untranslated-value findings.

    ``strict_translations`` (Phase 18) reports every ``x-translate`` marker;
    otherwise a marked key may keep the English text.
    """
    findings: list[Finding] = []
    en = arbs["en"]
    en_path = arb_path("en")
    en_messages = arb_messages(en)
    en_icu: dict[str, list[IcuArg]] = {}
    for key, value in en_messages.items():
        meta = en.get(f"@{key}")
        if not isinstance(meta, dict) or not str(meta.get("description") or "").strip():
            findings.append(Finding(en_path, 0, "missing_description", f"{key}: no @{key}.description"))
        try:
            en_icu[key] = parse_icu(value)
        except IcuError as exc:
            findings.append(Finding(en_path, 0, "invalid_icu", f"{key}: {exc}"))
    stale = (allowlist.keys | frozenset().union(*allowlist.per_locale.values())) - set(en_messages)
    for key in sorted(stale):
        findings.append(Finding(ALLOWLIST_PATH, 0, "stale_allowlist", f"{key} is not an en key"))

    for locale in LOCALES:
        arb = arbs[locale]
        path = arb_path(locale)
        declared = arb.get("@@locale")
        if declared != locale:
            findings.append(Finding(path, 0, "locale_mismatch", f"@@locale is {declared!r}, expected {locale!r}"))
        messages = arb_messages(arb)
        for key, value in messages.items():
            if not value.strip():
                findings.append(Finding(path, 0, "empty_value", f"{key} is empty"))
        if locale == "en":
            continue
        pending = x_translate_keys(arb)
        if strict_translations and pending:
            findings.append(
                Finding(
                    path,
                    0,
                    "x_translate",
                    f"{len(pending)} key(s) still marked {X_TRANSLATE}, e.g. {sorted(pending)[0]}",
                )
            )
        missing = sorted(set(en_messages) - set(messages))
        extra = sorted(set(messages) - set(en_messages))
        if missing:
            findings.append(Finding(path, 0, "key_parity", f"missing keys: {', '.join(missing)}"))
        if extra:
            findings.append(Finding(path, 0, "key_parity", f"keys not in en: {', '.join(extra)}"))
        for key in sorted(set(messages) & set(en_messages)):
            value = messages[key]
            if not value.strip():
                continue  # already reported as empty_value
            en_types = _placeholder_types(en, key)
            for name, kind in _placeholder_types(arb, key).items():
                if en_types.get(name) != kind:
                    findings.append(
                        Finding(
                            path,
                            0,
                            "placeholder_mismatch",
                            f"{key}: placeholder {name} type {kind!r} != en {en_types.get(name)!r}",
                        )
                    )
            if key in en_icu:
                try:
                    args = parse_icu(value)
                except IcuError as exc:
                    findings.append(Finding(path, 0, "invalid_icu", f"{key}: {exc}"))
                else:
                    findings += _compare_icu(locale, key, en_icu[key], args, path)
            text = _INTERPOLATION.sub("", value)
            if (
                value == en_messages[key]
                and _LETTER.search(re.sub(r"\{[^{}]*\}", "", text))
                and not allowlist.allows(locale, key)
                and key not in pending
            ):
                findings.append(
                    Finding(path, 0, "untranslated", f"{key} equals en ({value!r}); translate or allowlist it")
                )
    return findings


def load_arbs(root: Path) -> tuple[dict[str, dict[str, Any]], list[Finding]]:
    """Parsed ARB files by locale plus findings for missing/extra files."""
    arbs: dict[str, dict[str, Any]] = {}
    findings: list[Finding] = []
    directory = root / ARB_DIR
    for locale in LOCALES:
        path = directory / f"app_{locale}.arb"
        if path.is_file():
            arbs[locale] = load_arb(path, arb_path(locale))
        else:
            findings.append(Finding(arb_path(locale), 0, "missing_locale", "ARB file is missing"))
    for path in sorted(directory.glob("app_*.arb")):
        locale = path.stem[len("app_"):]
        if locale not in LOCALES:
            findings.append(Finding(rel(root, path), 0, "unsupported_locale", f"{locale} is not one of the 12 locales"))
    return arbs, findings


# --------------------------------------------------------------------------
# Literals, deck content, glossary


def literal_findings(path: str, source: str) -> list[Finding]:
    """User-facing string literals in widget code (06 §6.2 heuristic)."""
    code = mask_dart(source, mask_strings=False)
    findings = []
    for match in _LITERAL.finditer(code):
        body = _INTERPOLATION.sub("", match.group(2))
        if _LETTER.search(body):
            findings.append(
                Finding(
                    path,
                    line_of(source, match.start()),
                    "user_facing_literal",
                    f"string literal {match.group(0)!r} looks user-facing; use TaroLocalizations",
                )
            )
    return findings


def literal_files(root: Path) -> list[Path]:
    """Dart files in the literal-heuristic scope."""
    files = set()
    for base in ("apps/taro/lib", "packages/taro_ui/lib"):
        if (root / base).is_dir():
            files.update((root / base).rglob("*.dart"))
    return sorted(
        p
        for p in files
        if glob_match(rel(root, p), LITERAL_SCOPE) and not glob_match(rel(root, p), LITERAL_EXCEPT)
    )


def _strings(value: Any) -> set[str]:
    if isinstance(value, str):
        return {value}
    if isinstance(value, dict):
        out = set(map(str, value))
        for item in value.values():
            out |= _strings(item)
        return out
    if isinstance(value, list):
        return set().union(*map(_strings, value)) if value else set()
    return set()


def _card_fields(root: Path, locale: str, card: str) -> list[Finding] | None:
    """Findings of one card source file, or ``None`` when it is missing."""
    label = f"{CONTENT_SOURCE}/{locale}/cards/{card}.yaml"
    path = root / label
    if not path.is_file():
        return None
    data = load_yaml(path, label)
    if not isinstance(data, dict) or not data:
        raise InputError(label, "card source must be a non-empty mapping")
    empty = sorted(k for k, v in data.items() if v is None or (isinstance(v, str) and not v.strip()))
    if empty:
        return [Finding(label, 0, "deck_empty_field", f"empty fields: {', '.join(map(str, empty))}")]
    return []


def deck_findings(root: Path, require_all_locales: bool = False) -> tuple[list[Finding], list[str]]:
    """Deck content completeness (78 cards x 12 locales, RC26).

    ``en`` must be complete in the source and in the build. A missing
    translation (card file or built ``<locale>.json``) is only a notice until
    Phase 18 (``tools/content validate`` prints the staleness report);
    ``require_all_locales`` makes it a finding. A built locale file must
    always hold all 78 cards (``tools/content build`` writes only complete
    locales).
    """
    findings: list[Finding] = []
    notices: list[str] = []
    source = root / CONTENT_SOURCE
    if not source.is_dir():
        notices.append(f"{CONTENT_SOURCE} not present yet (Phase 5); deck content not checked")
    else:
        for locale in LOCALES:
            missing: list[str] = []
            for card in CARD_IDS:
                result = _card_fields(root, locale, card)
                if result is None:
                    missing.append(card)
                else:
                    findings += result
            if not missing:
                continue
            if locale == "en" or require_all_locales:
                findings += [
                    Finding(f"{CONTENT_SOURCE}/{locale}/cards/{card}.yaml", 0, "deck_missing_card", "card source file is missing")
                    for card in missing
                ]
            else:
                notices.append(f"{CONTENT_SOURCE}/{locale}/cards: {len(missing)} of {len(CARD_IDS)} cards not translated yet (Phase 18)")
    assets = root / DECK_ASSETS
    built = sorted(assets.glob("*.json")) if assets.is_dir() else []
    if not built:
        notices.append(f"{DECK_ASSETS}/*.json not built yet (Phase 5); built deck not checked")
        return findings, notices
    for locale in LOCALES:
        label = f"{DECK_ASSETS}/{locale}.json"
        path = root / label
        if not path.is_file():
            if locale == "en" or require_all_locales:
                findings.append(Finding(label, 0, "deck_missing_locale", "built deck texts are missing"))
            else:
                notices.append(f"{label} not built (locale incomplete until Phase 18)")
            continue
        strings = _strings(load_json(path, label))
        missing_cards = [card for card in CARD_IDS if card not in strings]
        if missing_cards:
            findings.append(
                Finding(label, 0, "deck_missing_card", f"{len(missing_cards)} card(s) missing, e.g. {missing_cards[0]}")
            )
    return findings, notices


def glossary_keys(root: Path) -> list[str] | None:
    """``failure*`` / ``safetyDeclined*`` ARB keys named in GLOSSARY §5–§5.2."""
    path = root / GLOSSARY_PATH
    if not path.is_file():
        return None
    text = path.read_text(encoding="utf-8")
    start = re.search(r"^## 5\.", text, re.MULTILINE)
    end = re.search(r"^## 6\.", text, re.MULTILINE)
    if not start:
        raise InputError(GLOSSARY_PATH, "no '## 5.' section")
    section = text[start.start(): end.start() if end else len(text)]
    return sorted(set(_GLOSSARY_KEY.findall(section)))


def glossary_findings(
    root: Path, en: Mapping[str, Any], require: bool
) -> tuple[list[Finding], list[str]]:
    """RC94: glossary-defined failure/refusal keys present in ``app_en.arb``."""
    keys = glossary_keys(root)
    if keys is None:
        return [], [f"{GLOSSARY_PATH} not present; RC94 keys not checked"]
    present = [k for k in keys if k in en]
    if not present and not require:
        return [], [
            f"none of the {len(keys)} GLOSSARY §5 failure*/safetyDeclined* keys is in "
            "app_en.arb yet; RC94 key check not enforced until the first one lands"
        ]
    missing = [k for k in keys if k not in en]
    if not missing:
        return [], []
    return [
        Finding(arb_path("en"), 0, "glossary_keys", f"missing GLOSSARY §5 keys: {', '.join(missing)}")
    ], []


# --------------------------------------------------------------------------


def x_translate_notices(arbs: Mapping[str, Mapping[str, Any]]) -> list[str]:
    """One notice per locale that still has ``x-translate`` markers."""
    notices = []
    for locale in LOCALES:
        count = len(x_translate_keys(arbs.get(locale, {})))
        if count and locale != "en":
            notices.append(f"{arb_path(locale)}: {count} key(s) marked {X_TRANSLATE} (translated in Phase 18)")
    return notices


def check(
    root: Path,
    require_glossary_keys: bool = False,
    require_all_locales: bool = False,
    strict_translations: bool = False,
) -> tuple[list[Finding], list[str]]:
    """Findings and notices for the repository at ``root``."""
    findings: list[Finding] = []
    notices: list[str] = []
    if (root / ARB_DIR).is_dir():
        arbs, file_findings = load_arbs(root)
        findings += file_findings
        if len(arbs) == len(LOCALES):
            findings += check_arbs(arbs, load_allowlist(root), strict_translations)
            if not strict_translations:
                notices += x_translate_notices(arbs)
        if "en" in arbs:
            extra, notes = glossary_findings(root, arbs["en"], require_glossary_keys)
            findings += extra
            notices += notes
    else:
        notices.append(f"{ARB_DIR} not present yet; ARB checks skipped")
    for path in literal_files(root):
        findings += literal_findings(rel(root, path), path.read_text(encoding="utf-8"))
    deck, notes = deck_findings(root, require_all_locales)
    findings += deck
    notices += notes
    aso = load_aso(root)
    if aso is None:
        notices.append("apps/taro/store/aso.yaml not present yet; store field limits not checked")
    else:
        findings += field_limit_findings(iter_store_fields(aso))
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    """CLI entry point."""
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument(
        "--require-glossary-keys",
        action="store_true",
        help="fail on missing GLOSSARY §5 keys even before the first one lands",
    )
    parser.add_argument(
        "--require-all-locales",
        action="store_true",
        help="fail on untranslated deck locales (Phase 18; default: notice only)",
    )
    parser.add_argument(
        "--strict-translations",
        action="store_true",
        help=f"fail on any {X_TRANSLATE} marker left in a non-en ARB (Phase 18)",
    )
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(
        NAME,
        lambda: check(root, args.require_glossary_keys, args.require_all_locales, args.strict_translations),
    )


if __name__ == "__main__":
    sys.exit(main())

"""Readers for the store and monetization inputs shared by several checks.

Paths are the canonical ones from 04 §4, 05 §8.1 and 02 §11: the App Store /
Play metadata ``apps/taro/store/aso.yaml``, the Worker ``PRODUCT_CATALOG`` in
``worker/src/monetization/catalog.ts``, the app's ``TaroProducts`` constant in
``packages/taro_core/lib/src/monetization/taro_products.dart`` and the ARB
files. Readers return ``None`` when a file is absent and raise
:class:`~taro_tools.checkkit.InputError` when it exists but is malformed.
"""

from __future__ import annotations

import re
from collections.abc import Iterator, Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from taro_tools.checkkit import (
    LOCALES,
    Finding,
    InputError,
    line_of,
    load_json,
    load_yaml,
    mask_dart,
)

__all__ = [
    "ARB_DIR",
    "ASO_PATH",
    "CATALOG_PATH",
    "EXPECTED_PRODUCTS",
    "PRODUCTS_PATH",
    "PRODUCT_ID_RE",
    "Product",
    "TextField",
    "aso_iap_products",
    "field_limit_findings",
    "iter_store_fields",
    "load_arb",
    "load_aso",
    "normalize_kind",
    "parse_catalog_ts",
    "parse_taro_products",
]

ASO_PATH = "apps/taro/store/aso.yaml"
CATALOG_PATH = "worker/src/monetization/catalog.ts"
PRODUCTS_PATH = "packages/taro_core/lib/src/monetization/taro_products.dart"
ARB_DIR = "apps/taro/lib/l10n/arb"

PRODUCT_ID_RE = re.compile(r"^com\.vshyrochuk\.taro\.[a-z0-9_]+$")

# 04 §4 / GLOSSARY §3 (RC3): the complete v1 catalogue and its kinds.
EXPECTED_PRODUCTS: dict[str, str] = {
    "com.vshyrochuk.taro.readings_3": "consumable",
    "com.vshyrochuk.taro.readings_10": "consumable",
    "com.vshyrochuk.taro.readings_30": "consumable",
    "com.vshyrochuk.taro.remove_ads": "non_consumable",
}

_KINDS = {
    "consumable": "consumable",
    "nonconsumable": "non_consumable",
    "non_consumable": "non_consumable",
}


def normalize_kind(raw: str) -> str | None:
    """Map ``consumable``/``nonConsumable``/``NON_CONSUMABLE``… to one spelling."""
    return _KINDS.get(raw.strip().lower().replace("-", "_"))


@dataclass(frozen=True)
class Product:
    """A product as declared by one source."""

    id: str
    kind: str | None
    line: int
    credits: int | None = None
    retired: bool = False


def _balanced(text: str, open_idx: int) -> int:
    """Index just past the bracket matching ``text[open_idx]``."""
    pairs = {"{": "}", "(": ")", "[": "]"}
    opener = text[open_idx]
    closer = pairs[opener]
    depth = 0
    for k in range(open_idx, len(text)):
        if text[k] == opener:
            depth += 1
        elif text[k] == closer:
            depth -= 1
            if depth == 0:
                return k + 1
    return -1


_CATALOG_START = re.compile(r"\bPRODUCT_CATALOG\b[^=\n]*=\s*\{")
_CATALOG_ENTRY = re.compile(r"""(['"])([^'"\n]+)\1\s*:\s*\{([^{}]*)\}""")


def parse_catalog_ts(text: str, label: str) -> dict[str, Product]:
    """Products of ``export const PRODUCT_CATALOG = { 'id': {kind, credits} }``."""
    start = _CATALOG_START.search(text)
    if not start:
        raise InputError(label, "no `PRODUCT_CATALOG = {` object literal found")
    open_idx = start.end() - 1
    end = _balanced(text, open_idx)
    if end < 0:
        raise InputError(label, "unbalanced braces in PRODUCT_CATALOG")
    products: dict[str, Product] = {}
    for entry in _CATALOG_ENTRY.finditer(text, open_idx, end):
        body = entry.group(3)
        kind = re.search(r"""\bkind\s*:\s*['"]([\w-]+)['"]""", body)
        if not kind:
            raise InputError(label, f"catalog entry {entry.group(2)!r} has no kind")
        credits = re.search(r"\bcredits\s*:\s*(\d+)", body)
        products[entry.group(2)] = Product(
            id=entry.group(2),
            kind=normalize_kind(kind.group(1)),
            line=line_of(text, entry.start()),
            credits=int(credits.group(1)) if credits else None,
            retired=bool(re.search(r"\bretired\s*:\s*true\b", body)),
        )
    if not products:
        raise InputError(label, "PRODUCT_CATALOG has no `'id': { kind: … }` entries")
    return products


def _enclosing_call(text: str, pos: int) -> tuple[int, int]:
    """Bounds of the innermost ``( … )`` around ``pos``."""
    depth = 0
    for k in range(pos, -1, -1):
        if text[k] == ")":
            depth += 1
        elif text[k] == "(":
            if depth == 0:
                return k, _balanced(text, k)
            depth -= 1
    return -1, -1


_DART_ID = re.compile(r"""\bid\s*:\s*(['"])([^'"\n]*)\1""")
_DART_KIND = re.compile(r"\bkind\s*:\s*(?:[\w]+\.)*(\w+)")


def parse_taro_products(text: str, label: str) -> dict[str, Product]:
    """Products of the Dart ``TaroProducts`` constant.

    Expected shape (one constructor call per product, named arguments):
    ``TaroProduct(id: 'com.vshyrochuk.taro.readings_3',
    kind: ProductKind.consumable, alias: 'pack_s')``.
    """
    code = mask_dart(text, mask_strings=False)
    products: dict[str, Product] = {}
    for match in _DART_ID.finditer(code):
        start, end = _enclosing_call(code, match.start())
        if start < 0 or end < 0:
            raise InputError(
                label, f"id {match.group(2)!r} is not inside a constructor call"
            )
        kind = _DART_KIND.search(code, start, end)
        if not kind:
            raise InputError(label, f"product {match.group(2)!r} has no kind:")
        products[match.group(2)] = Product(
            id=match.group(2),
            kind=normalize_kind(kind.group(1)),
            line=line_of(text, match.start()),
        )
    if not products:
        raise InputError(label, "no `id: '…'` product entries found")
    return products


def load_aso(root: Path) -> dict[str, Any] | None:
    """The parsed ``aso.yaml``; ``None`` when it does not exist yet."""
    path = root / ASO_PATH
    if not path.is_file():
        return None
    data = load_yaml(path, ASO_PATH)
    if not isinstance(data, dict):
        raise InputError(ASO_PATH, "top level must be a mapping")
    return data


def _mapping(value: Any, key: str) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise InputError(ASO_PATH, f"{key} must be a mapping")
    return value


def _sequence(value: Any, key: str) -> list[Any]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise InputError(ASO_PATH, f"{key} must be a list")
    return value


def aso_iap_products(aso: Mapping[str, Any], section: str = "app_store") -> list[dict[str, Any]]:
    """``<section>.iap_products`` entries, each checked to have a string id."""
    block = _mapping(aso.get(section), section)
    raw = block.get("iap_products")
    if raw is None or isinstance(raw, str):
        # A missing list, or the draft alias text `*same_ids_as_app_store`.
        return []
    items = _sequence(raw, f"{section}.iap_products")
    out: list[dict[str, Any]] = []
    for index, item in enumerate(items):
        key = f"{section}.iap_products[{index}]"
        if not isinstance(item, dict) or not isinstance(item.get("product_id"), str):
            raise InputError(ASO_PATH, f"{key} needs a string product_id")
        out.append(item)
    return out


@dataclass(frozen=True)
class TextField:
    """One user-visible text in ``aso.yaml``.

    ``platform`` is ``apple`` (App Store fields), ``play`` (Play fields),
    ``both`` (shown on both stores) or ``review`` (App Review notes, read by
    reviewers only).
    """

    key: str
    locale: str
    platform: str
    field: str
    text: str
    limit: int | None


def _text(value: Any, key: str) -> str | None:
    if value is None:
        return None
    if isinstance(value, (dict, list)):
        raise InputError(ASO_PATH, f"{key} must be text")
    return str(value)


# Store limits (05 §8.1 rules 1 and 6, §7; 06 §6.2).
_LOCALIZATION_LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "whats_new": 4000,
}
_PLAY_LIMITS = {"title": 30, "short_description": 80, "full_description": 4000}
_IAP_LIMITS = {"display_name": 30, "description": 45}


def _fields(
    block: Mapping[str, Any],
    prefix: str,
    limits: Mapping[str, int | None],
    locale: str,
    platform: str,
) -> Iterator[TextField]:
    for name, limit in limits.items():
        key = f"{prefix}.{name}" if prefix else name
        text = _text(block.get(name), key)
        if text is not None:
            yield TextField(key, locale, platform, name, text, limit)


def _iap_fields(aso: Mapping[str, Any], section: str, platform: str) -> Iterator[TextField]:
    for index, item in enumerate(aso_iap_products(aso, section)):
        prefix = f"{section}.iap_products[{index}]"
        yield from _fields(item, prefix, _IAP_LIMITS, "en", platform)
        yield from _fields(item, prefix, {"review_notes": 4000}, "en", "review")
        locs = _mapping(item.get("localizations"), f"{prefix}.localizations")
        for locale, entry in locs.items():
            key = f"{prefix}.localizations.{locale}"
            yield from _fields(_mapping(entry, key), key, _IAP_LIMITS, str(locale), platform)


def _screenshot_fields(aso: Mapping[str, Any]) -> Iterator[TextField]:
    shots = _mapping(aso.get("store_screenshots"), "store_screenshots")

    def items(value: Any, key: str, locale: str) -> Iterator[TextField]:
        for index, item in enumerate(_sequence(value, key)):
            item_key = f"{key}[{index}]"
            if isinstance(item, dict):
                yield from _fields(
                    item, item_key, {"headline": None, "subtext": None}, locale, "both"
                )
            else:
                text = _text(item, item_key)
                if text is not None:
                    yield TextField(item_key, locale, "both", "caption", text, None)

    yield from items(shots.get("screenshots"), "store_screenshots.screenshots", "en")
    translations = _mapping(shots.get("translations"), "store_screenshots.translations")
    for locale, value in translations.items():
        yield from items(value, f"store_screenshots.translations.{locale}", str(locale))


def iter_store_fields(aso: Mapping[str, Any]) -> list[TextField]:
    """Every user-visible text of ``aso.yaml`` with its locale, platform, limit."""
    out: list[TextField] = []
    out += _fields(
        aso,
        "",
        {"short_description": 80, "full_description": 4000},
        "en",
        "play",
    )
    out += _fields(aso, "", {"whats_new": 4000}, "en", "both")
    keywords = aso.get("keywords")
    if keywords is not None:
        words = _sequence(keywords, "keywords")
        out.append(
            TextField("keywords", "en", "both", "keywords_list", ", ".join(map(str, words)), None)
        )
    review = _mapping(aso.get("app_review_information"), "app_review_information")
    out += _fields(review, "app_review_information", {"notes": 4000}, "en", "review")
    app_store = _mapping(aso.get("app_store"), "app_store")
    out += _fields(app_store, "app_store", {"name": 30}, "en", "apple")
    out += _iap_fields(aso, "app_store", "apple")
    play = _mapping(aso.get("google_play"), "google_play")
    out += _fields(play, "google_play", _PLAY_LIMITS, "en", "play")
    play_locs = _mapping(play.get("localizations"), "google_play.localizations")
    for locale, entry in play_locs.items():
        key = f"google_play.localizations.{locale}"
        out += _fields(_mapping(entry, key), key, _PLAY_LIMITS, str(locale), "play")
    out += _iap_fields(aso, "google_play", "play")
    locs = _mapping(aso.get("localizations"), "localizations")
    for locale, entry in locs.items():
        key = f"localizations.{locale}"
        out += _fields(_mapping(entry, key), key, _LOCALIZATION_LIMITS, str(locale), "apple")
    out += _screenshot_fields(aso)
    return out


def field_limit_findings(fields: list[TextField], rule: str = "field_limit") -> list[Finding]:
    """Store fields longer than their limit (Python ``len()``, 05 §8.1 rule 1)."""
    return [
        Finding(
            ASO_PATH,
            0,
            rule,
            f"{f.key} is {len(f.text)} characters (limit {f.limit})",
        )
        for f in fields
        if f.limit is not None and len(f.text.rstrip("\n")) > f.limit
    ]


def load_arb(path: Path, label: str) -> dict[str, Any]:
    """A parsed ARB file: a JSON object whose message values are strings."""
    data = load_json(path, label)
    if not isinstance(data, dict):
        raise InputError(label, "top level must be a JSON object")
    for key, value in data.items():
        if not key.startswith("@") and not isinstance(value, str):
            raise InputError(label, f"message {key!r} must be a string")
        if key.startswith("@") and not key.startswith("@@") and not isinstance(value, dict):
            raise InputError(label, f"metadata {key!r} must be an object")
    return data


def arb_messages(arb: Mapping[str, Any]) -> dict[str, str]:
    """The message entries of an ARB (no ``@`` metadata)."""
    return {k: v for k, v in arb.items() if not k.startswith("@")}


def arb_path(locale: str) -> str:
    """Repository path of the ARB file for ``locale``."""
    return f"{ARB_DIR}/app_{locale}.arb"


__all__ += ["arb_messages", "arb_path", "LOCALES"]

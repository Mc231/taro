#!/usr/bin/env python3
"""Pack display names in aso.yaml state the credits of the Worker catalog.

05 Risks / CS12, 04 §4 (RC3): credits live only in
``worker/src/monetization/catalog.ts``; the store names ("3 Readings") and
descriptions ("Adds 3 AI tarot readings.") of every consumable, in every
locale of ``apps/taro/store/aso.yaml``, must state exactly that number.

Fails when a catalog consumable has no store product (or the reverse), a
display name does not contain exactly its credit count, or a description
mentions a different number. Skips with a notice while either file is absent.
"""

from __future__ import annotations

import re
import sys
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any

from taro_tools.checkkit import Finding, base_parser, resolve_root, run_check
from taro_tools.store import (
    ASO_PATH,
    CATALOG_PATH,
    Product,
    aso_iap_products,
    load_aso,
    parse_catalog_ts,
)

NAME = "check_pack_sizes"
_NUMBER = re.compile(r"\d+")  # Unicode digits too (e.g. Arabic-Indic)


def numbers(text: str) -> list[int]:
    """Every integer written in ``text``."""
    return [int(n) for n in _NUMBER.findall(text)]


def _texts(item: Mapping[str, Any], field: str) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    if isinstance(item.get(field), str):
        out.append(("en", item[field]))
    locs = item.get("localizations") or {}
    if isinstance(locs, dict):
        for locale, entry in locs.items():
            if isinstance(entry, dict) and isinstance(entry.get(field), str):
                out.append((str(locale), entry[field]))
    return out


def pack_findings(aso: Mapping[str, Any], catalog: Mapping[str, Product]) -> list[Finding]:
    """Compare every consumable's store texts with its catalog credits."""
    findings: list[Finding] = []
    consumables = {
        pid: p for pid, p in catalog.items() if p.kind == "consumable" and not p.retired
    }
    items = {item["product_id"]: item for item in aso_iap_products(aso, "app_store")}
    for pid, product in sorted(consumables.items()):
        if product.credits is None:
            findings.append(Finding(CATALOG_PATH, product.line, "credits_missing", f"{pid} has no credits"))
            continue
        item = items.get(pid)
        if item is None:
            findings.append(Finding(ASO_PATH, 0, "pack_missing", f"{pid} is in the catalog but not in app_store.iap_products"))
            continue
        for locale, name in _texts(item, "display_name"):
            if numbers(name) != [product.credits]:
                findings.append(
                    Finding(ASO_PATH, 0, "pack_size", f"{pid} {locale} display_name {name!r} does not state {product.credits}")
                )
        for locale, text in _texts(item, "description"):
            wrong = [n for n in numbers(text) if n != product.credits]
            if wrong:
                findings.append(
                    Finding(ASO_PATH, 0, "pack_size", f"{pid} {locale} description {text!r} mentions {wrong}, catalog says {product.credits}")
                )
    for pid, item in sorted(items.items()):
        kind = str(item.get("type", "")).upper()
        if kind == "CONSUMABLE" and pid not in consumables:
            findings.append(Finding(ASO_PATH, 0, "pack_missing", f"{pid} is a store consumable with no catalog credits"))
    return findings


def check(root: Path) -> tuple[list[Finding], list[str]]:
    """Findings and notices for the repository at ``root``."""
    notices = []
    catalog_path = root / CATALOG_PATH
    catalog = (
        parse_catalog_ts(catalog_path.read_text(encoding="utf-8"), CATALOG_PATH)
        if catalog_path.is_file()
        else None
    )
    aso = load_aso(root)
    if catalog is None:
        notices.append(f"{CATALOG_PATH} not present yet; skipped")
    if aso is None:
        notices.append(f"{ASO_PATH} not present yet; skipped")
    if catalog is None or aso is None:
        return [], notices
    return pack_findings(aso, catalog), notices


def main(argv: Sequence[str] | None = None) -> int:
    """CLI entry point."""
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: check(root))


if __name__ == "__main__":
    sys.exit(main())

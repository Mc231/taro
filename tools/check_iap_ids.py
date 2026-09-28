#!/usr/bin/env python3
"""IAP product IDs agree across the app, the Worker catalog and aso.yaml.

06 §6.2 ``check_iap_ids.py`` (04 §4, RC3). Sources:

* app ``TaroProducts`` — ``packages/taro_core/lib/src/monetization/taro_products.dart``
* Worker ``PRODUCT_CATALOG`` — ``worker/src/monetization/catalog.ts``
* store metadata — ``apps/taro/store/aso.yaml`` ``app_store.iap_products``
  (and ``google_play.iap_products`` when it is a list)

Fails when an ID is not ``^com\\.vshyrochuk\\.taro\\.[a-z0-9_]+$``, a source's
active set is not exactly ``readings_3``, ``readings_10``, ``readings_30``,
``remove_ads``, the sets or kinds differ between sources, Remove Ads is not the
single non-consumable, or a consumable's display name ("N Readings") disagrees
with its catalog credits. Absent sources are skipped with a notice; the
cross-source comparison runs over the sources that exist.
"""

from __future__ import annotations

import re
import sys
from collections.abc import Mapping, Sequence
from pathlib import Path

from taro_tools.checkkit import (
    Finding,
    base_parser,
    resolve_root,
    run_check,
)
from taro_tools.store import (
    ASO_PATH,
    CATALOG_PATH,
    EXPECTED_PRODUCTS,
    PRODUCT_ID_RE,
    PRODUCTS_PATH,
    Product,
    aso_iap_products,
    load_aso,
    normalize_kind,
    parse_catalog_ts,
    parse_taro_products,
)

NAME = "check_iap_ids"
REMOVE_ADS = "com.vshyrochuk.taro.remove_ads"


def aso_products(aso: Mapping[str, object], section: str) -> dict[str, Product]:
    """Products of ``<section>.iap_products`` keyed by ID."""
    out: dict[str, Product] = {}
    for item in aso_iap_products(aso, section):
        kind = item.get("type")
        out[item["product_id"]] = Product(
            id=item["product_id"],
            kind=normalize_kind(kind) if isinstance(kind, str) else None,
            line=0,
        )
    return out


def source_findings(label: str, products: Mapping[str, Product]) -> list[Finding]:
    """Per-source rules: ID shape, exact set, kinds, single non-consumable."""
    findings: list[Finding] = []
    active = {pid: p for pid, p in products.items() if not p.retired}
    for pid, product in sorted(products.items()):
        if not PRODUCT_ID_RE.match(pid):
            findings.append(
                Finding(label, product.line, "id_format", f"{pid!r} is not com.vshyrochuk.taro.<suffix>")
            )
        if product.kind is None:
            findings.append(Finding(label, product.line, "kind", f"{pid}: unknown product kind"))
    missing = sorted(set(EXPECTED_PRODUCTS) - set(active))
    extra = sorted(set(active) - set(EXPECTED_PRODUCTS))
    if missing:
        findings.append(Finding(label, 0, "product_set", f"missing products: {', '.join(missing)}"))
    if extra:
        findings.append(Finding(label, 0, "product_set", f"unexpected products: {', '.join(extra)}"))
    for pid, product in sorted(active.items()):
        expected = EXPECTED_PRODUCTS.get(pid)
        if expected and product.kind and product.kind != expected:
            findings.append(
                Finding(label, product.line, "kind", f"{pid} is {product.kind}, expected {expected}")
            )
    non_consumables = sorted(pid for pid, p in active.items() if p.kind == "non_consumable")
    if non_consumables != [REMOVE_ADS]:
        findings.append(
            Finding(
                label,
                0,
                "single_non_consumable",
                f"non-consumables are {non_consumables or 'none'}; only {REMOVE_ADS} may be (RC3)",
            )
        )
    return findings


def cross_findings(sources: Mapping[str, Mapping[str, Product]]) -> list[Finding]:
    """The active ID sets and kinds agree between every pair of sources."""
    findings: list[Finding] = []
    labels = sorted(sources)
    for i, left in enumerate(labels):
        for right in labels[i + 1:]:
            a = {k: v for k, v in sources[left].items() if not v.retired}
            b = {k: v for k, v in sources[right].items() if not v.retired}
            only_a = sorted(set(a) - set(b))
            only_b = sorted(set(b) - set(a))
            if only_a or only_b:
                findings.append(
                    Finding(
                        left,
                        0,
                        "sets_differ",
                        f"vs {right}: only here {only_a or '[]'}, only there {only_b or '[]'}",
                    )
                )
            for pid in sorted(set(a) & set(b)):
                if a[pid].kind and b[pid].kind and a[pid].kind != b[pid].kind:
                    findings.append(
                        Finding(
                            left,
                            a[pid].line,
                            "kinds_differ",
                            f"{pid} is {a[pid].kind} here and {b[pid].kind} in {right}",
                        )
                    )
    return findings


_COUNT = re.compile(r"\d+")


def display_name_findings(aso: Mapping[str, object], catalog: Mapping[str, Product]) -> list[Finding]:
    """A consumable's en display name states its catalog credits (04 §4)."""
    findings: list[Finding] = []
    for item in aso_iap_products(aso, "app_store"):
        product = catalog.get(item["product_id"])
        if product is None or product.kind != "consumable" or product.credits is None:
            continue
        name = str(item.get("display_name") or "")
        counts = [int(n) for n in _COUNT.findall(name)]
        if counts != [product.credits]:
            findings.append(
                Finding(
                    ASO_PATH,
                    0,
                    "display_name_credits",
                    f"{product.id} display_name {name!r} does not state {product.credits} credits",
                )
            )
    return findings


def check(root: Path) -> tuple[list[Finding], list[str]]:
    """Findings and notices for the repository at ``root``."""
    notices: list[str] = []
    sources: dict[str, dict[str, Product]] = {}
    for label, parser in ((PRODUCTS_PATH, parse_taro_products), (CATALOG_PATH, parse_catalog_ts)):
        path = root / label
        if path.is_file():
            sources[label] = parser(path.read_text(encoding="utf-8"), label)
        else:
            notices.append(f"{label} not present yet; skipped")
    aso = load_aso(root)
    if aso is None:
        notices.append(f"{ASO_PATH} not present yet; skipped")
    else:
        sources[f"{ASO_PATH} (app_store)"] = aso_products(aso, "app_store")
        play = aso_products(aso, "google_play")
        if play:
            sources[f"{ASO_PATH} (google_play)"] = play
    findings: list[Finding] = []
    for label, products in sources.items():
        findings += source_findings(label, products)
    findings += cross_findings(sources)
    if aso is not None and CATALOG_PATH in sources:
        findings += display_name_findings(aso, sources[CATALOG_PATH])
    if len(sources) < 2:
        notices.append(f"{len(sources)} of 3 product sources present; nothing to cross-check yet")
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    """CLI entry point."""
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: check(root))


if __name__ == "__main__":
    sys.exit(main())

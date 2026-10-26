#!/usr/bin/env python3
"""Glossary drift gate (06 §6.2, Phase 1 Sprint 1.2, RC94).

``docs/specs/GLOSSARY.md`` is the source of spelling for every canonical ID.
This check parses its tables and compares them with the generator inputs and
code constants that use the same IDs. Each comparison runs only once its
code or input exists (otherwise it prints a "not present yet" note), so the
check grows with the codebase:

====================  ==========================================================
Glossary section      Compared with
====================  ==========================================================
§1 card IDs           ``apps/taro/content/source/glossary.yaml`` (IDs + ``en``
                      names), ``apps/taro/assets/deck/deck_meta.json``
§2 spreads            ``apps/taro/assets/deck/spreads.json``; the
                      ``ai.maxTokensBySpread`` default
§3 product IDs        ``worker/src/monetization/catalog.ts``,
                      ``TaroProducts`` (``taro_products.dart``)
§4 endpoints          routes in ``worker/src/routes/*.ts`` and the committed
                      ``worker/openapi/openapi.json`` (subset: not all built)
§5 error codes        the Worker ``ErrorCode`` declaration; ``Failure``
                      subtypes in ``taro_core``; ``RefusalCategory``; and the
                      ``failure*`` / ``safetyDeclined*`` keys in
                      ``app_en.arb`` once those types exist
§6.1/§13 Worker env   ``worker/wrangler.toml`` (environments, Worker and D1
                      names, bindings, vars) and ``worker/src/env.ts``
§8 config keys        ``worker/config/remote_config.default.json`` (equal),
                      ``worker/src/config/schema.ts`` (subset)
§10 screens           route literals in ``apps/taro/lib/routing/routes.dart``
§12 secure keys       ``apps/taro/lib/data/secure/keys.dart``
§14.1 packages        ``pubspec.yaml`` names, paths and taro dependencies;
                      ``worker/package.json`` name
§15 identifiers       locales vs the ARB files; bundle IDs vs the iOS
                      xcconfigs and Android flavors; flavors, API hosts, web
                      host, legal URLs and support e-mail vs
                      ``apps/taro/config/*.json``
====================  ==========================================================
"""

from __future__ import annotations

import json
import re
import sys
import tomllib
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from check_remote_config import flatten, glossary_keys
from taro_tools.checkkit import (
    Finding,
    InputError,
    base_parser,
    load_json,
    load_yaml,
    mask_dart,
    rel,
    resolve_root,
    run_check,
)
from taro_tools.markdown import Table, backticks, parse_tables, section

NAME = "check_glossary"
GLOSSARY = "docs/specs/GLOSSARY.md"
CARD_RE = re.compile(r"^(major_(0\d|1\d|2[01])|(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$")
CARDISH_RE = re.compile(r"^(major|wands|cups|swords|pentacles)_\d+$")
PRODUCT_RE = re.compile(r"com\.vshyrochuk\.taro\.[a-z0-9_]+")
UPPER_SNAKE = re.compile(r"""['"]([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+|[A-Z]{3,})['"]""")

Findings = list[Finding]
Notices = list[str]


# --------------------------------------------------------------------------
# Glossary model
# --------------------------------------------------------------------------


@dataclass
class Glossary:
    """The canonical IDs parsed from GLOSSARY.md."""

    cards: dict[str, str] = field(default_factory=dict)
    spreads: dict[str, list[str]] = field(default_factory=dict)
    max_tokens: dict[str, int] = field(default_factory=dict)
    products: set[str] = field(default_factory=set)
    endpoints: set[tuple[str, str]] = field(default_factory=set)
    error_codes: set[str] = field(default_factory=set)
    failures: dict[str, str] = field(default_factory=dict)
    refusals: dict[str, str] = field(default_factory=dict)
    config_keys: set[str] = field(default_factory=set)
    screens: dict[str, str] = field(default_factory=dict)
    secure_keys: set[str] = field(default_factory=set)
    bindings: dict[str, str] = field(default_factory=dict)
    environments: dict[str, dict[str, str]] = field(default_factory=dict)
    worker_names: set[str] = field(default_factory=set)
    packages: dict[str, dict[str, Any]] = field(default_factory=dict)
    identifiers: dict[str, str] = field(default_factory=dict)
    public_defaults: dict[str, str] = field(default_factory=dict)


def _section(text: str, title: str) -> str:
    body = section(text, title)
    if body is None:
        raise InputError(GLOSSARY, f"no section '{title}'")
    return body


def _table(body: str, first_column: str, title: str) -> Table:
    for table in parse_tables(body):
        if table.header and table.header[0] == first_column:
            return table
    raise InputError(GLOSSARY, f"section '{title}' has no table starting with '{first_column}'")


def _first_tick(cell: str) -> str:
    ticks = backticks(cell)
    return ticks[0] if ticks else ""


def _titled_table(text: str, title: str, first_column: str) -> Table:
    """The table starting with ``first_column`` in section ``title``."""
    return _table(_section(text, title), first_column, title)


def _parse_cards_and_spreads(text: str, g: Glossary) -> None:
    """§1 card IDs, §2 spreads with positions and token budgets."""
    for row in _titled_table(text, "1. Card IDs", "#").rows:
        g.cards[_first_tick(row.get("cardId", ""))] = row.get("English name (en)", "").strip()
    for row in _titled_table(text, "2. Spread IDs", "spreadId").rows:
        spread = _first_tick(row.get("spreadId", ""))
        tokens = row.get("ai.maxTokensBySpread", "").strip()
        if tokens.isdigit():
            g.max_tokens[spread] = int(tokens)
        if spread != "*":
            g.spreads[spread] = backticks(row.get("positionIds (in order)", ""))


def _parse_products_and_endpoints(text: str, g: Glossary) -> None:
    """§3 product IDs and §4 endpoints."""
    products = _titled_table(text, "3. Product IDs", "Product ID")
    g.products = {_first_tick(cell) for cell in products.column("Product ID")}
    for cell in _titled_table(text, "4. Endpoints", "#").column("Method + path"):
        method, _, path = _first_tick(cell).partition(" ")
        g.endpoints.add((method.upper(), path))


def _parse_code_rows(table: Table, g: Glossary) -> None:
    """§5 ``HTTP | code`` rows: error codes and the Failure → ARB key they map to."""
    for row in table.rows:
        code = _first_tick(row.get("code", ""))
        if code:
            g.error_codes.add(code)
        failure, key = _first_tick(row.get("Failure (02 §3)", "")), _first_tick(row.get("ARB key", ""))
        if failure.endswith("Failure") and key:
            g.failures[failure] = key


def _parse_refusal_rows(table: Table, g: Glossary) -> None:
    """§5.2 refusal categories → ARB key."""
    for row in table.rows:
        dart, key = _first_tick(row.get("Dart RefusalCategory", "")), _first_tick(row.get("messageKey / ARB key", ""))
        if dart:
            g.refusals[dart] = key


def _parse_errors(text: str, g: Glossary) -> None:
    """§5 error codes, Failure subtypes and refusal categories."""
    for table in parse_tables(_section(text, "5. Error codes")):
        if table.header[:2] == ["HTTP", "code"]:
            _parse_code_rows(table, g)
        elif table.header[:1] == ["Failure"]:
            for row in table.rows:
                g.failures[_first_tick(row.get("Failure", ""))] = _first_tick(row.get("ARB key", ""))
        elif table.header[:1] == ["Wire category"]:
            _parse_refusal_rows(table, g)
    if not g.error_codes or not g.failures or not g.refusals:
        raise InputError(GLOSSARY, "§5 tables (codes, Failure, refusal categories) not found")


def _parse_client(text: str, g: Glossary) -> None:
    """§8 config keys and public defaults, §10 screens, §12 secure-storage keys."""
    g.config_keys = glossary_keys(text)
    for row in _titled_table(text, "8.1 Public", "Key").rows:
        for key in backticks(row.get("Key", "")):
            g.public_defaults[key] = row.get("Default", "")
    for row in _titled_table(text, "10. Screens", "ID").rows:
        g.screens[row.get("ID", "").strip()] = _first_tick(row.get("Route", ""))
    secure = _titled_table(text, "12. Secure-storage keys", "Key")
    g.secure_keys = {_first_tick(cell) for cell in secure.column("Key")}


_ENV_SECTION = "6.1 KV, bindings"


def _parse_worker(text: str, g: Glossary) -> None:
    """§6.1 bindings and environments, §13 Worker secrets and vars."""
    env_body = _section(text, _ENV_SECTION)
    for row in _table(env_body, "Name", _ENV_SECTION).rows:
        g.bindings[_first_tick(row.get("Name", ""))] = row.get("Kind", "")
    for row in _table(env_body, "Environment (ENVIRONMENT)", _ENV_SECTION).rows:
        name = _first_tick(row.get("Environment (ENVIRONMENT)", ""))
        g.environments[name] = {
            "worker": _first_tick(row.get("Worker name", "")),
            "d1": _first_tick(row.get("D1", "")),
            "host": _first_tick(row.get("Host", "")),
        }
    for cell in _titled_table(text, "13. Worker secrets and vars", "Name").column("Name"):
        g.worker_names.update(backticks(cell))


def _parse_repo(text: str, g: Glossary) -> None:
    """§14.1 monorepo packages and §15 other identifiers."""
    for row in _titled_table(text, "14.1 Monorepo packages", "Package").rows:
        g.packages[_first_tick(row.get("Package", ""))] = {
            "path": _first_tick(row.get("Path", "")).rstrip("/"),
            "deps": set(backticks(row.get("May depend on (taro)", ""))),
        }
    for row in _titled_table(text, "15. Other canonical identifiers", "Item").rows:
        g.identifiers[row.get("Item", "").strip()] = row.get("Value", "")


def parse_glossary(text: str) -> Glossary:
    """Parse every table this check uses; a missing table is an InputError."""
    g = Glossary()
    _parse_cards_and_spreads(text, g)
    _parse_products_and_endpoints(text, g)
    _parse_errors(text, g)
    _parse_client(text, g)
    _parse_worker(text, g)
    _parse_repo(text, g)
    return g


def check_self(g: Glossary) -> Findings:
    """Internal consistency of the glossary tables."""
    findings: Findings = []
    bad = sorted(card for card in g.cards if not CARD_RE.match(card))
    if len(g.cards) != 78 or bad:
        findings.append(Finding(GLOSSARY, 0, "cards", f"§1 must list 78 valid card IDs (got {len(g.cards)}; invalid: {bad})"))
    for product in sorted(g.products):
        if not PRODUCT_RE.fullmatch(product):
            findings.append(Finding(GLOSSARY, 0, "products", f"§3 product ID {product!r} is not com.vshyrochuk.taro.<id>"))
    for spread in g.spreads:
        if spread not in g.max_tokens:
            findings.append(Finding(GLOSSARY, 0, "spreads", f"§2 spread {spread} has no ai.maxTokensBySpread value"))
    return findings


# --------------------------------------------------------------------------
# Comparisons (each returns findings and "not present yet" notes)
# --------------------------------------------------------------------------


def _set_diff(label: str, rule: str, what: str, actual: Iterable[str], canonical: Iterable[str], *, subset: bool = False) -> Findings:
    actual_set, canonical_set = set(actual), set(canonical)
    findings = [
        Finding(label, 0, rule, f"{what} {value!r} is not in {GLOSSARY}")
        for value in sorted(actual_set - canonical_set)
    ]
    if not subset:
        findings += [
            Finding(label, 0, rule, f"{what} {value!r} from {GLOSSARY} is missing")
            for value in sorted(canonical_set - actual_set)
        ]
    return findings


def _compare_card_names(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    """Authored ``glossary.yaml`` card IDs and English names."""
    source = root / "apps/taro/content/source/glossary.yaml"
    label = rel(root, source)
    if not source.is_file():
        return [], [f"{label} not present yet; card names not compared"]
    data = load_yaml(source, label)
    entries = data.get("cards", data) if isinstance(data, dict) else None
    if not isinstance(entries, dict):
        raise InputError(label, "expected a mapping of cardId → names")
    cards = {k: v for k, v in entries.items() if isinstance(k, str) and CARDISH_RE.match(k)}
    findings = _set_diff(label, "cards", "card ID", cards, g.cards)
    for card, names in sorted(cards.items()):
        english = names.get("en") if isinstance(names, dict) else names
        if card in g.cards and english != g.cards[card]:
            findings.append(Finding(label, 0, "card-name", f"{card} en name {english!r} != glossary {g.cards[card]!r}"))
    return findings, []


def _compare_deck_meta(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    """Generated ``deck_meta.json`` card IDs."""
    meta = root / "apps/taro/assets/deck/deck_meta.json"
    label = rel(root, meta)
    if not meta.is_file():
        return [], [f"{label} not present yet; card IDs not compared"]
    data = load_json(meta, label)
    items = data.get("cards", []) if isinstance(data, dict) else data
    ids = [i.get("id") or i.get("cardId") for i in items if isinstance(i, dict)]
    return _set_diff(label, "cards", "card ID", [i for i in ids if isinstance(i, str)], g.cards), []


def compare_cards(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings, notices = _compare_card_names(root, g)
    meta_findings, meta_notices = _compare_deck_meta(root, g)
    return findings + meta_findings, notices + meta_notices


def _position_ids(positions: Any) -> list[str]:
    out: list[str] = []
    for position in positions if isinstance(positions, list) else []:
        if isinstance(position, str):
            out.append(position)
        elif isinstance(position, dict):
            out.append(str(position.get("id") or position.get("positionId")))
    return out


def compare_spreads(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    path = root / "apps/taro/assets/deck/spreads.json"
    label = rel(root, path)
    if path.is_file():
        data = load_json(path, label)
        items = data.get("spreads", []) if isinstance(data, dict) else data
        spreads = {
            str(i.get("id") or i.get("spreadId")): _position_ids(i.get("positions"))
            for i in items if isinstance(i, dict)
        }
        findings += _set_diff(label, "spreads", "spread ID", spreads, g.spreads)
        for spread, positions in sorted(spreads.items()):
            if spread in g.spreads and positions != g.spreads[spread]:
                findings.append(
                    Finding(label, 0, "positions", f"{spread} positions {positions} != glossary {g.spreads[spread]} (order matters)")
                )
    else:
        notices.append(f"{label} not present yet; spreads not compared")
    return findings, notices


def compare_products(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    sources = [root / "worker/src/monetization/catalog.ts"]
    core = root / "packages/taro_core/lib"
    sources += sorted(core.rglob("taro_products.dart")) if core.is_dir() else []
    if len(sources) == 1:
        notices.append("TaroProducts (taro_products.dart) not present yet; not compared")
    for path in sources:
        label = rel(root, path)
        if not path.is_file():
            notices.append(f"{label} not present yet; products not compared")
            continue
        found = set(PRODUCT_RE.findall(path.read_text(encoding="utf-8")))
        findings += _set_diff(label, "products", "product ID", found, g.products)
    return findings, notices


_ROUTE_CALL = re.compile(r"createRoute\(\s*\{")
_ROUTE_METHOD = re.compile(r"\bmethod\s*:\s*['\"](\w+)['\"]")
_ROUTE_PATH = re.compile(r"\bpath\s*:\s*['\"]([^'\"]+)['\"]")
_HONO_ROUTE = re.compile(r"\.(get|post|put|delete|patch)\(\s*['\"](/[^'\"]*)['\"]")


def _normalize_path(path: str) -> str:
    return re.sub(r":(\w+)", r"{\1}", path)


def ts_routes(source: str) -> set[tuple[str, str]]:
    """``(METHOD, /path)`` pairs declared with ``createRoute`` or ``app.<verb>()``."""
    routes: set[tuple[str, str]] = set()
    for match in _ROUTE_CALL.finditer(source):
        depth, end = 0, len(source)
        for index in range(match.end() - 1, len(source)):
            depth += {"{": 1, "}": -1}.get(source[index], 0)
            if depth == 0:
                end = index
                break
        block = source[match.end() : end]
        method, path = _ROUTE_METHOD.search(block), _ROUTE_PATH.search(block)
        if method and path:
            routes.add((method.group(1).upper(), _normalize_path(path.group(1))))
    for verb, path in _HONO_ROUTE.findall(source):
        routes.add((verb.upper(), _normalize_path(path)))
    return routes


def compare_endpoints(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    routes_dir = root / "worker/src/routes"
    canonical = {f"{m} {p}" for m, p in g.endpoints}
    if routes_dir.is_dir():
        for path in sorted(routes_dir.rglob("*.ts")):
            found = {f"{m} {p}" for m, p in ts_routes(path.read_text(encoding="utf-8"))}
            findings += _set_diff(rel(root, path), "endpoint", "route", found, canonical, subset=True)
    else:
        notices.append("worker/src/routes/ not present yet; endpoints not compared")
    openapi = root / "worker/openapi/openapi.json"
    label = rel(root, openapi)
    if openapi.is_file():
        data = load_json(openapi, label)
        paths = data.get("paths", {}) if isinstance(data, dict) else {}
        found = {
            f"{method.upper()} {path}"
            for path, ops in paths.items() if isinstance(ops, dict)
            for method in ops if method in ("get", "post", "put", "delete", "patch")
        }
        findings += _set_diff(label, "endpoint", "operation", found, canonical, subset=True)
    else:
        notices.append(f"{label} not present yet; not compared")
    return findings, notices


def _files_declaring(base: Path, pattern: re.Pattern[str], suffix: str) -> list[Path]:
    if not base.is_dir():
        return []
    return [p for p in sorted(base.rglob(f"*{suffix}")) if pattern.search(p.read_text(encoding="utf-8"))]


_ERROR_DECL = re.compile(r"\b(?:type|enum|const)\s+(?:ErrorCode|ERROR_CODES)\b")
_FAILURE_CLASS = re.compile(r"\b((?:(?:abstract|sealed|base|final|interface)\s+)*)class\s+(\w+Failure)\b")
_REFUSAL_ENUM = re.compile(r"\benum\s+RefusalCategory\s*\{([^}]*)\}")


def _split_top_level(text: str) -> list[str]:
    """Splits enum values on commas outside parentheses (constructor args)."""
    parts: list[str] = []
    depth = 0
    current: list[str] = []
    for char in text:
        depth += (char == "(") - (char == ")")
        if char == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
    parts.append("".join(current))
    return parts


_ARB_EN = "apps/taro/lib/l10n/arb/app_en.arb"
_CORE_LIB = "packages/taro_core/lib"


def _compare_error_codes(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    """Worker ``ErrorCode`` declarations against §5 codes."""
    worker_files = _files_declaring(root / "worker/src", _ERROR_DECL, ".ts")
    if not worker_files:
        return [], ["Worker ErrorCode declaration not present yet; error codes not compared"]
    findings: Findings = []
    expected = g.error_codes - {"PURCHASE_PENDING"}
    for path in worker_files:
        codes = set(UPPER_SNAKE.findall(path.read_text(encoding="utf-8")))
        findings += _set_diff(rel(root, path), "error-code", "error code", codes - {"PURCHASE_PENDING"}, expected)
    return findings, []


def _english_arb(root: Path) -> dict[str, Any]:
    """``app_en.arb`` as a mapping (empty when absent or not an object)."""
    arb_path = root / _ARB_EN
    if not arb_path.is_file():
        return {}
    data = load_json(arb_path, rel(root, arb_path))
    return data if isinstance(data, dict) else {}


def _compare_failures(root: Path, g: Glossary, arb: Mapping[str, Any]) -> tuple[Findings, Notices]:
    """Concrete ``Failure`` subtypes and their ARB keys."""
    failure_files = _files_declaring(root / _CORE_LIB, _FAILURE_CLASS, ".dart")
    if not failure_files:
        return [], ["Failure subtypes not present yet in taro_core; failure* ARB keys not required"]
    classes: set[str] = set()
    for path in failure_files:
        masked = mask_dart(path.read_text(encoding="utf-8"))
        classes |= {
            name for modifiers, name in _FAILURE_CLASS.findall(masked)
            if "abstract" not in modifiers.split() and "sealed" not in modifiers.split()
        }
    findings = _set_diff(rel(root, failure_files[0]), "failure", "Failure subtype", classes, g.failures)
    for key in sorted(set(g.failures.values()) - set(arb)):
        findings.append(Finding(_ARB_EN, 0, "arb-key", f"Failure ARB key {key!r} (GLOSSARY §5, RC94) is missing"))
    return findings, []


def _compare_refusals(root: Path, g: Glossary, arb: Mapping[str, Any]) -> tuple[Findings, Notices]:
    """``RefusalCategory`` values and their ``safetyDeclined*`` ARB keys."""
    refusal_files = _files_declaring(root / _CORE_LIB, _REFUSAL_ENUM, ".dart")
    if not refusal_files:
        return [], ["RefusalCategory not present yet in taro_core; safetyDeclined* ARB keys not required"]
    body = _REFUSAL_ENUM.search(mask_dart(refusal_files[0].read_text(encoding="utf-8")))
    # Enum values end at the first `;`; members (constructor, fields) follow.
    head = body.group(1).split(";")[0] if body else ""
    values = {v.strip().split("(")[0] for v in _split_top_level(head) if v.strip()}
    findings = _set_diff(rel(root, refusal_files[0]), "refusal", "RefusalCategory value", values, g.refusals)
    keys = {k for k in g.refusals.values() if k.startswith("safetyDeclined")}
    for key in sorted(keys - set(arb)):
        findings.append(Finding(_ARB_EN, 0, "arb-key", f"refusal ARB key {key!r} (GLOSSARY §5.2, RC94) is missing"))
    return findings, []


def compare_errors(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    arb = _english_arb(root)
    findings: Findings = []
    notices: Notices = []
    for found, notes in (
        _compare_error_codes(root, g),
        _compare_failures(root, g, arb),
        _compare_refusals(root, g, arb),
    ):
        findings += found
        notices += notes
    return findings, notices


def compare_config(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    defaults = root / "worker/config/remote_config.default.json"
    label = rel(root, defaults)
    if defaults.is_file():
        data = load_json(defaults, label)
        flat = flatten(data if isinstance(data, dict) else {}, g.config_keys)
        canonical = {k for k in g.config_keys if "[]" not in k}
        findings += _set_diff(label, "config-key", "config key", flat, canonical)
        tokens = flat.get("ai.maxTokensBySpread")
        if isinstance(tokens, dict) and tokens != g.max_tokens:
            findings.append(Finding(label, 0, "max-tokens", f"ai.maxTokensBySpread {tokens} != GLOSSARY §2 {g.max_tokens}"))
    else:
        notices.append(f"{label} not present yet; config keys not compared")
    schema = root / "worker/src/config/schema.ts"
    label = rel(root, schema)
    if schema.is_file():
        found = set(re.findall(r"['\"]([a-z]+(?:\.[A-Za-z0-9]+)+)['\"]", schema.read_text(encoding="utf-8")))
        allowed = g.config_keys | {k.replace("[]", "") for k in g.config_keys}
        findings += _set_diff(label, "config-key", "config key", found, allowed, subset=True)
    else:
        notices.append(f"{label} not present yet; not compared")
    return findings, notices


def _route_variants(route: str) -> set[str]:
    route = route.split("?", 1)[0]
    optional = re.match(r"^(.*)\[(.*)\]$", route)
    return {optional.group(1), optional.group(1) + optional.group(2)} if optional else {route}


def compare_screens(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    path = root / "apps/taro/lib/routing/routes.dart"
    label = rel(root, path)
    if not path.is_file():
        return [], [f"{label} not present yet; routes not compared"]
    canonical: set[str] = set()
    for route in g.screens.values():
        if route.startswith("/"):
            canonical |= _route_variants(route)
    found = {
        literal.split("?", 1)[0]
        for literal in re.findall(r"['\"](/[^'\"$]*)['\"]", path.read_text(encoding="utf-8"))
    }
    return _set_diff(label, "route", "route", found, canonical, subset=True), []


def compare_secure_keys(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    path = root / "apps/taro/lib/data/secure/keys.dart"
    label = rel(root, path)
    if not path.is_file():
        return [], [f"{label} not present yet; secure-storage keys not compared"]
    found = set(re.findall(r"['\"](taro\.[a-z_]+)['\"]", path.read_text(encoding="utf-8")))
    return _set_diff(label, "secure-key", "secure-storage key", found, g.secure_keys), []


def _toml_bindings(env: Mapping[str, Any]) -> set[str]:
    items = (
        item
        for value in env.values() if isinstance(value, list)
        for item in value if isinstance(item, dict)
    )
    names = (item.get("binding") or item.get("name") for item in items)
    return {name for name in names if isinstance(name, str)}


def compare_worker_env(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    path = root / "worker/wrangler.toml"
    label = rel(root, path)
    if not path.is_file():
        return [], [f"{label} not present yet; Worker environments not compared"]
    try:
        config = tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as exc:
        raise InputError(label, f"invalid TOML: {exc}") from exc
    findings: Findings = []
    envs = config.get("env", {})
    envs = envs if isinstance(envs, dict) else {}
    findings += _set_diff(label, "environment", "[env.*] environment", envs, g.environments)
    for var in config.get("vars", {}) or {}:
        if var not in g.worker_names:
            findings.append(Finding(label, 0, "var", f"[vars] {var!r} is not a GLOSSARY §13 name"))
    for name, env in sorted(envs.items()):
        if isinstance(env, dict) and name in g.environments:
            findings += _check_toml_env(label, name, env, g)
    env_ts = root / "worker/src/env.ts"
    if env_ts.is_file():
        fields = set(re.findall(r"\breadonly\s+([A-Z][A-Z0-9_]*)\??\s*:", env_ts.read_text(encoding="utf-8")))
        findings += _set_diff(rel(root, env_ts), "env-field", "Env field", fields, set(g.bindings) | g.worker_names, subset=True)
    return findings, []


def _check_toml_env(label: str, name: str, env: Mapping[str, Any], g: Glossary) -> Findings:
    """One ``[env.<name>]`` block against its §6.1 row."""
    findings: Findings = []
    expected = g.environments[name]
    if expected["worker"].startswith("taro-") and env.get("name") != expected["worker"]:
        findings.append(Finding(label, 0, "worker-name", f"[env.{name}] name {env.get('name')!r} != {expected['worker']!r}"))
    if expected["d1"].startswith("taro-"):
        d1 = [d.get("database_name") for d in env.get("d1_databases", []) if isinstance(d, dict)]
        if expected["d1"] not in d1:
            findings.append(Finding(label, 0, "d1", f"[env.{name}] D1 {d1} does not include {expected['d1']!r}"))
    findings += [
        Finding(label, 0, "binding", f"[env.{name}] {m}")
        for m in (f.message for f in _set_diff(label, "binding", "binding", _toml_bindings(env), g.bindings))
    ]
    findings += _check_toml_env_vars(label, name, env.get("vars", {}) or {}, g)
    for dataset in env.get("analytics_engine_datasets", []):
        names = backticks(g.bindings.get(str(dataset.get("binding")), ""))
        if names and dataset.get("dataset") not in names:
            findings.append(Finding(label, 0, "dataset", f"[env.{name}] dataset {dataset.get('dataset')!r} != {names[0]!r}"))
    return findings


def _check_toml_env_vars(label: str, name: str, variables: Mapping[str, Any], g: Glossary) -> Findings:
    """``[env.<name>.vars]``: only §13 names, and ``ENVIRONMENT`` matches."""
    findings = [
        Finding(label, 0, "var", f"[env.{name}.vars] {var!r} is not a GLOSSARY §13 name")
        for var in variables
        if var not in g.worker_names
    ]
    if variables.get("ENVIRONMENT") != name:
        findings.append(Finding(label, 0, "var", f"[env.{name}.vars] ENVIRONMENT = {variables.get('ENVIRONMENT')!r}, expected {name!r}"))
    return findings


def _pubspec(path: Path, label: str) -> dict[str, Any]:
    data = load_yaml(path, label)
    if not isinstance(data, dict):
        raise InputError(label, "pubspec is not a mapping")
    return data


_WORKER_PACKAGE_JSON = "worker/package.json"


def _check_pubspec(root: Path, pubspec: Path, g: Glossary, by_path: Mapping[str, str]) -> Findings:
    """One pubspec's name and taro dependencies against §14.1."""
    label = rel(root, pubspec)
    directory = rel(root, pubspec.parent)
    data = _pubspec(pubspec, label)
    actual = str(data.get("name"))
    if directory not in by_path:
        return [Finding(label, 0, "package", f"package {actual!r} at {directory}/ is not in GLOSSARY §14.1")]
    findings: Findings = []
    expected = by_path[directory]
    if actual != expected:
        findings.append(Finding(label, 0, "package-name", f"name {actual!r} != GLOSSARY §14.1 {expected!r} for {directory}/"))
    taro_names = {name for name in g.packages if name.startswith("taro") and name != "taro-api"}
    deps = data.get("dependencies") or {}
    allowed = g.packages[expected]["deps"]
    for dep in sorted(d for d in deps if d in taro_names and d not in allowed):
        findings.append(Finding(label, 0, "package-dep", f"{expected} may not depend on {dep} (GLOSSARY §14.1)"))
    return findings


def _check_worker_package(root: Path, worker: str | None) -> Findings:
    """``worker/package.json`` name against §14.1."""
    package_json = root / _WORKER_PACKAGE_JSON
    if not package_json.is_file() or not worker:
        return []
    data = load_json(package_json, _WORKER_PACKAGE_JSON)
    if isinstance(data, dict) and data.get("name") != worker:
        return [Finding(_WORKER_PACKAGE_JSON, 0, "package-name", f"name {data.get('name')!r} != {worker!r}")]
    return []


def compare_packages(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    by_path = {info["path"]: name for name, info in g.packages.items()}
    candidates = sorted(root.glob("apps/*/pubspec.yaml")) + sorted(root.glob("packages/*/pubspec.yaml"))
    candidates += [p for p in [root / "tools/dart_tools/pubspec.yaml"] if p.is_file()]
    for pubspec in candidates:
        findings += _check_pubspec(root, pubspec, g, by_path)
    worker = next((n for n, info in g.packages.items() if info["path"] == "worker"), None)
    findings += _check_worker_package(root, worker)
    for name, info in sorted(g.packages.items()):
        target = root / info["path"]
        manifest = "package.json" if name == worker else "pubspec.yaml"
        if info["path"] and not (target / manifest).is_file():
            findings.append(
                Finding(GLOSSARY, 0, "package-path", f"§14.1 {name}: {info['path']}/{manifest} does not exist")
            )
    return findings, []


def _xcconfig_bundle(path: Path) -> str | None:
    match = re.search(r"^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(\S+)", path.read_text(encoding="utf-8"), re.MULTILINE)
    return match.group(1) if match else None


def android_bundles(gradle: str) -> dict[str, str]:
    """Flavor → applicationId from a ``build.gradle(.kts)``."""
    base = re.search(r"applicationId\s*=?\s*['\"]([^'\"]+)['\"]", gradle)
    if not base:
        return {}
    bundles: dict[str, str] = {}
    for match in re.finditer(r"create\(\s*['\"](\w+)['\"]\s*\)\s*\{", gradle):
        depth, end = 0, len(gradle)
        for index in range(match.end() - 1, len(gradle)):
            depth += {"{": 1, "}": -1}.get(gradle[index], 0)
            if depth == 0:
                end = index
                break
        suffix = re.search(r"applicationIdSuffix\s*=?\s*['\"]([^'\"]+)['\"]", gradle[match.end() : end])
        bundles[match.group(1)] = base.group(1) + (suffix.group(1) if suffix else "")
    return bundles


def _compare_locales(root: Path, ids: Mapping[str, str]) -> tuple[Findings, Notices]:
    """ARB files against the §15 locale list."""
    locales = [x.strip() for x in _first_tick(ids.get("Locales", "")).split(",") if x.strip()]
    arb_dir = root / "apps/taro/lib/l10n/arb"
    if not arb_dir.is_dir():
        return [], ["apps/taro/lib/l10n/arb/ not present yet; locales not compared"]
    found = {p.stem.removeprefix("app_") for p in arb_dir.glob("app_*.arb")}
    return _set_diff(rel(root, arb_dir), "locale", "ARB locale", found, locales), []


def _glossary_bundles(cell: str) -> dict[str, str]:
    """Flavor → bundle ID from the §15 ``Bundle / applicationId`` cell."""
    bundles: dict[str, str] = {}
    for part in cell.split(";"):
        flavor = re.match(r"\s*(\w+)", part)
        value = next((t for t in backticks(part) if t.startswith("com.")), None)
        if flavor and value:
            bundles[flavor.group(1)] = value
    return bundles


def _compare_ios_bundles(root: Path, bundles: Mapping[str, str]) -> tuple[Findings, Notices]:
    """``PRODUCT_BUNDLE_IDENTIFIER`` per flavor xcconfig."""
    findings: Findings = []
    notices: Notices = []
    for flavor, expected in sorted(bundles.items()):
        xcconfig = root / f"apps/taro/ios/Config/{flavor.capitalize()}.xcconfig"
        if not xcconfig.is_file():
            notices.append(f"{rel(root, xcconfig)} not present yet; iOS {flavor} bundle ID not compared")
            continue
        actual = _xcconfig_bundle(xcconfig)
        if actual != expected:
            findings.append(Finding(rel(root, xcconfig), 0, "bundle-id", f"{actual!r} != GLOSSARY §15 {expected!r}"))
    return findings, notices


def _compare_android_bundles(root: Path, bundles: Mapping[str, str]) -> tuple[Findings, Notices]:
    """``applicationId`` per Gradle flavor."""
    findings: Findings = []
    notices: Notices = []
    gradle = next((p for p in (root / "apps/taro/android/app/build.gradle.kts", root / "apps/taro/android/app/build.gradle") if p.is_file()), None)
    if gradle is None:
        return findings, notices
    android = android_bundles(gradle.read_text(encoding="utf-8"))
    for flavor, expected in sorted(bundles.items()):
        if flavor not in android:
            notices.append(f"Android flavor {flavor} not present yet; applicationId not compared")
        elif android[flavor] != expected:
            findings.append(Finding(rel(root, gradle), 0, "bundle-id", f"{flavor} applicationId {android[flavor]!r} != {expected!r}"))
    return findings, notices


def _compare_flavor_files(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    """``apps/taro/config/*.json`` against the §15 flavors."""
    flavor_cell = g.identifiers.get("Flavors / build configs", "")
    flavors = [t for t in backticks(flavor_cell) if "/" not in t]
    files_token = next((t for t in backticks(flavor_cell) if "{" in t), "")
    files_match = re.match(r"^(.*)\{([^}]*)\}(.*)$", files_token)
    expected_files = {f"{files_match.group(1)}{s.strip()}{files_match.group(3)}" for s in files_match.group(2).split(",")} if files_match else set()
    config_dir = root / "apps/taro/config"
    if not config_dir.is_dir():
        return [], ["apps/taro/config/ not present yet; flavors not compared"]
    present = {rel(root, p) for p in config_dir.glob("*.json")}
    findings = _set_diff(rel(root, config_dir), "flavor-config", "flavor config file", present, expected_files, subset=True)
    notices = [f"{missing} not present yet (GLOSSARY §15 flavor config)" for missing in sorted(expected_files - present)]
    findings += _check_flavor_configs(root, sorted(present & expected_files), g, flavors)
    return findings, notices


def compare_identifiers(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    bundles = _glossary_bundles(g.identifiers.get("Bundle / applicationId", ""))
    for found, notes in (
        _compare_locales(root, g.identifiers),
        _compare_ios_bundles(root, bundles),
        _compare_android_bundles(root, bundles),
        _compare_flavor_files(root, g),
    ):
        findings += found
        notices += notes
    return findings, notices


def _host(url: str) -> str:
    return urlparse(url).hostname or ""


def _check_flavor_configs(root: Path, files: Sequence[str], g: Glossary, flavors: Sequence[str]) -> Findings:
    findings: Findings = []
    ids = g.identifiers
    web_host = _first_tick(ids.get("Web host", ""))
    api_hosts = {m.group(2): m.group(1) for m in re.finditer(r"`([^`]+)`\s*\((prod|staging)\)", ids.get("API hosts", ""))}
    public = {k: _first_tick(v) for k, v in g.public_defaults.items()}
    for relative in files:
        data = load_json(root / relative, relative)
        if not isinstance(data, dict):
            raise InputError(relative, "flavor config is not an object")
        flavor = data.get("flavor")
        if flavor not in flavors:
            findings.append(Finding(relative, 0, "flavor", f"flavor {flavor!r} is not one of {list(flavors)}"))
        findings += _check_api_base_url(relative, data, g, api_hosts)
        checks = (
            ("privacyPolicyUrl", public.get("legal.privacyUrl")),
            ("termsUrl", public.get("legal.termsUrl")),
            ("supportEmail", public.get("support.email")),
            ("universalLinkHost", web_host),
        )
        for key, expected in checks:
            if expected and key in data and data[key] != expected:
                findings.append(Finding(relative, 0, key, f"{key} {data[key]!r} != GLOSSARY {expected!r}"))
    return findings


def _check_api_base_url(relative: str, data: Mapping[str, Any], g: Glossary, api_hosts: Mapping[str, str]) -> Findings:
    """``apiBaseUrl`` host per §15 API hosts; dev must equal the §6.1 host."""
    findings: Findings = []
    flavor = data.get("flavor")
    api = data.get("apiBaseUrl", "")
    if flavor in api_hosts and _host(api) != api_hosts[flavor]:
        findings.append(Finding(relative, 0, "api-host", f"apiBaseUrl host {_host(api)!r} != GLOSSARY {api_hosts[flavor]!r}"))
    dev_host = g.environments.get(str(flavor), {}).get("host", "")
    if flavor == "dev" and dev_host.startswith("http") and api != dev_host:
        findings.append(Finding(relative, 0, "api-host", f"apiBaseUrl {api!r} != GLOSSARY {dev_host!r}"))
    return findings


COMPARISONS = (
    compare_cards,
    compare_spreads,
    compare_products,
    compare_endpoints,
    compare_errors,
    compare_config,
    compare_screens,
    compare_secure_keys,
    compare_worker_env,
    compare_packages,
    compare_identifiers,
)


def run(root: Path) -> tuple[Findings, Notices]:
    glossary_path = root / GLOSSARY
    if not glossary_path.is_file():
        raise InputError(GLOSSARY, "file not found")
    g = parse_glossary(glossary_path.read_text(encoding="utf-8"))
    findings = check_self(g)
    notices: Notices = []
    for compare in COMPARISONS:
        found, notes = compare(root, g)
        findings += found
        notices += notes
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--quiet", action="store_true", help="hide 'not present yet' notes")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)

    def body() -> tuple[Findings, Notices]:
        findings, notices = run(root)
        return findings, [] if args.quiet else notices

    return run_check(NAME, body)


if __name__ == "__main__":
    sys.exit(main())

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


def parse_glossary(text: str) -> Glossary:
    """Parse every table this check uses; a missing table is an InputError."""
    g = Glossary()
    cards = _table(_section(text, "1. Card IDs"), "#", "1. Card IDs")
    for row in cards.rows:
        g.cards[_first_tick(row.get("cardId", ""))] = row.get("English name (en)", "").strip()

    spreads = _table(_section(text, "2. Spread IDs"), "spreadId", "2. Spread IDs")
    for row in spreads.rows:
        spread = _first_tick(row.get("spreadId", ""))
        tokens = row.get("ai.maxTokensBySpread", "").strip()
        if tokens.isdigit():
            g.max_tokens[spread] = int(tokens)
        if spread != "*":
            g.spreads[spread] = backticks(row.get("positionIds (in order)", ""))

    products = _table(_section(text, "3. Product IDs"), "Product ID", "3. Product IDs")
    g.products = {_first_tick(cell) for cell in products.column("Product ID")}

    endpoints = _table(_section(text, "4. Endpoints"), "#", "4. Endpoints")
    for cell in endpoints.column("Method + path"):
        method, _, path = _first_tick(cell).partition(" ")
        g.endpoints.add((method.upper(), path))

    errors_body = _section(text, "5. Error codes")
    for table in parse_tables(errors_body):
        if table.header[:2] == ["HTTP", "code"]:
            for row in table.rows:
                code = _first_tick(row.get("code", ""))
                if code:
                    g.error_codes.add(code)
                failure, key = _first_tick(row.get("Failure (02 §3)", "")), _first_tick(row.get("ARB key", ""))
                if failure.endswith("Failure") and key:
                    g.failures[failure] = key
        elif table.header[:1] == ["Failure"]:
            for row in table.rows:
                g.failures[_first_tick(row.get("Failure", ""))] = _first_tick(row.get("ARB key", ""))
        elif table.header[:1] == ["Wire category"]:
            for row in table.rows:
                dart, key = _first_tick(row.get("Dart RefusalCategory", "")), _first_tick(row.get("messageKey / ARB key", ""))
                if dart:
                    g.refusals[dart] = key
    if not g.error_codes or not g.failures or not g.refusals:
        raise InputError(GLOSSARY, "§5 tables (codes, Failure, refusal categories) not found")

    g.config_keys = glossary_keys(text)
    public = _table(_section(text, "8.1 Public"), "Key", "8.1 Public")
    for row in public.rows:
        for key in backticks(row.get("Key", "")):
            g.public_defaults[key] = row.get("Default", "")

    screens = _table(_section(text, "10. Screens"), "ID", "10. Screens")
    for row in screens.rows:
        g.screens[row.get("ID", "").strip()] = _first_tick(row.get("Route", ""))

    secure = _table(_section(text, "12. Secure-storage keys"), "Key", "12. Secure-storage keys")
    g.secure_keys = {_first_tick(cell) for cell in secure.column("Key")}

    env_body = _section(text, "6.1 KV, bindings")
    bindings = _table(env_body, "Name", "6.1 KV, bindings")
    for row in bindings.rows:
        g.bindings[_first_tick(row.get("Name", ""))] = row.get("Kind", "")
    envs = _table(env_body, "Environment (ENVIRONMENT)", "6.1 KV, bindings")
    for row in envs.rows:
        name = _first_tick(row.get("Environment (ENVIRONMENT)", ""))
        g.environments[name] = {
            "worker": _first_tick(row.get("Worker name", "")),
            "d1": _first_tick(row.get("D1", "")),
            "host": _first_tick(row.get("Host", "")),
        }
    names = _table(_section(text, "13. Worker secrets and vars"), "Name", "13. Worker secrets and vars")
    for cell in names.column("Name"):
        g.worker_names.update(backticks(cell))

    packages = _table(_section(text, "14.1 Monorepo packages"), "Package", "14.1 Monorepo packages")
    for row in packages.rows:
        g.packages[_first_tick(row.get("Package", ""))] = {
            "path": _first_tick(row.get("Path", "")).rstrip("/"),
            "deps": set(backticks(row.get("May depend on (taro)", ""))),
        }

    ids = _table(_section(text, "15. Other canonical identifiers"), "Item", "15. Other canonical identifiers")
    for row in ids.rows:
        g.identifiers[row.get("Item", "").strip()] = row.get("Value", "")
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


def compare_cards(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    source = root / "apps/taro/content/source/glossary.yaml"
    label = rel(root, source)
    if source.is_file():
        data = load_yaml(source, label)
        entries = data.get("cards", data) if isinstance(data, dict) else None
        if not isinstance(entries, dict):
            raise InputError(label, "expected a mapping of cardId → names")
        cards = {k: v for k, v in entries.items() if isinstance(k, str) and CARDISH_RE.match(k)}
        findings += _set_diff(label, "cards", "card ID", cards, g.cards)
        for card, names in sorted(cards.items()):
            english = names.get("en") if isinstance(names, dict) else names
            if card in g.cards and english != g.cards[card]:
                findings.append(Finding(label, 0, "card-name", f"{card} en name {english!r} != glossary {g.cards[card]!r}"))
    else:
        notices.append(f"{label} not present yet; card names not compared")
    meta = root / "apps/taro/assets/deck/deck_meta.json"
    label = rel(root, meta)
    if meta.is_file():
        data = load_json(meta, label)
        items = data.get("cards", []) if isinstance(data, dict) else data
        ids = [i.get("id") or i.get("cardId") for i in items if isinstance(i, dict)]
        findings += _set_diff(label, "cards", "card ID", [i for i in ids if isinstance(i, str)], g.cards)
    else:
        notices.append(f"{label} not present yet; card IDs not compared")
    return findings, notices


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


def compare_errors(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    worker_files = _files_declaring(root / "worker/src", _ERROR_DECL, ".ts")
    if worker_files:
        for path in worker_files:
            codes = set(UPPER_SNAKE.findall(path.read_text(encoding="utf-8")))
            expected = g.error_codes - {"PURCHASE_PENDING"}
            findings += _set_diff(rel(root, path), "error-code", "error code", codes - {"PURCHASE_PENDING"}, expected)
    else:
        notices.append("Worker ErrorCode declaration not present yet; error codes not compared")

    arb_path = root / "apps/taro/lib/l10n/arb/app_en.arb"
    arb: dict[str, Any] = {}
    if arb_path.is_file():
        data = load_json(arb_path, rel(root, arb_path))
        arb = data if isinstance(data, dict) else {}
    core = root / "packages/taro_core/lib"
    failure_files = _files_declaring(core, _FAILURE_CLASS, ".dart")
    if failure_files:
        classes: set[str] = set()
        for path in failure_files:
            masked = mask_dart(path.read_text(encoding="utf-8"))
            classes |= {
                name for modifiers, name in _FAILURE_CLASS.findall(masked)
                if "abstract" not in modifiers.split() and "sealed" not in modifiers.split()
            }
        findings += _set_diff(rel(root, failure_files[0]), "failure", "Failure subtype", classes, g.failures)
        for key in sorted(set(g.failures.values()) - set(arb)):
            findings.append(Finding(rel(root, arb_path), 0, "arb-key", f"Failure ARB key {key!r} (GLOSSARY §5, RC94) is missing"))
    else:
        notices.append("Failure subtypes not present yet in taro_core; failure* ARB keys not required")
    refusal_files = _files_declaring(core, _REFUSAL_ENUM, ".dart")
    if refusal_files:
        body = _REFUSAL_ENUM.search(mask_dart(refusal_files[0].read_text(encoding="utf-8")))
        values = {v.strip().split("(")[0] for v in body.group(1).replace(";", ",").split(",") if v.strip()} if body else set()
        findings += _set_diff(rel(root, refusal_files[0]), "refusal", "RefusalCategory value", values, g.refusals)
        keys = {k for k in g.refusals.values() if k.startswith("safetyDeclined")}
        for key in sorted(keys - set(arb)):
            findings.append(Finding(rel(root, arb_path), 0, "arb-key", f"refusal ARB key {key!r} (GLOSSARY §5.2, RC94) is missing"))
    else:
        notices.append("RefusalCategory not present yet in taro_core; safetyDeclined* ARB keys not required")
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
    names: set[str] = set()
    for value in env.values():
        if isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    name = item.get("binding") or item.get("name")
                    if isinstance(name, str):
                        names.add(name)
    return names


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
    allowed_vars = g.worker_names
    for var in config.get("vars", {}) or {}:
        if var not in allowed_vars:
            findings.append(Finding(label, 0, "var", f"[vars] {var!r} is not a GLOSSARY §13 name"))
    for name, env in sorted(envs.items()):
        if not isinstance(env, dict) or name not in g.environments:
            continue
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
        variables = env.get("vars", {}) or {}
        for var, value in variables.items():
            if var not in allowed_vars:
                findings.append(Finding(label, 0, "var", f"[env.{name}.vars] {var!r} is not a GLOSSARY §13 name"))
        if variables.get("ENVIRONMENT") != name:
            findings.append(Finding(label, 0, "var", f"[env.{name}.vars] ENVIRONMENT = {variables.get('ENVIRONMENT')!r}, expected {name!r}"))
        for dataset in env.get("analytics_engine_datasets", []):
            kind = g.bindings.get(str(dataset.get("binding")), "")
            names = backticks(kind)
            if names and dataset.get("dataset") not in names:
                findings.append(Finding(label, 0, "dataset", f"[env.{name}] dataset {dataset.get('dataset')!r} != {names[0]!r}"))
    env_ts = root / "worker/src/env.ts"
    if env_ts.is_file():
        fields = set(re.findall(r"\breadonly\s+([A-Z][A-Z0-9_]*)\??\s*:", env_ts.read_text(encoding="utf-8")))
        findings += _set_diff(rel(root, env_ts), "env-field", "Env field", fields, set(g.bindings) | allowed_vars, subset=True)
    return findings, []


def _pubspec(path: Path, label: str) -> dict[str, Any]:
    data = load_yaml(path, label)
    if not isinstance(data, dict):
        raise InputError(label, "pubspec is not a mapping")
    return data


def compare_packages(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    by_path = {info["path"]: name for name, info in g.packages.items()}
    candidates = sorted(root.glob("apps/*/pubspec.yaml")) + sorted(root.glob("packages/*/pubspec.yaml"))
    candidates += [p for p in [root / "tools/dart_tools/pubspec.yaml"] if p.is_file()]
    taro_names = {name for name in g.packages if name.startswith("taro") and name != "taro-api"}
    for pubspec in candidates:
        label = rel(root, pubspec)
        directory = rel(root, pubspec.parent)
        data = _pubspec(pubspec, label)
        actual = str(data.get("name"))
        if directory not in by_path:
            findings.append(Finding(label, 0, "package", f"package {actual!r} at {directory}/ is not in GLOSSARY §14.1"))
            continue
        expected = by_path[directory]
        if actual != expected:
            findings.append(Finding(label, 0, "package-name", f"name {actual!r} != GLOSSARY §14.1 {expected!r} for {directory}/"))
        deps = data.get("dependencies") or {}
        allowed = g.packages[expected]["deps"]
        for dep in sorted(d for d in deps if d in taro_names and d not in allowed):
            findings.append(Finding(label, 0, "package-dep", f"{expected} may not depend on {dep} (GLOSSARY §14.1)"))
    package_json = root / "worker/package.json"
    worker = next((n for n, info in g.packages.items() if info["path"] == "worker"), None)
    if package_json.is_file() and worker:
        data = load_json(package_json, "worker/package.json")
        if isinstance(data, dict) and data.get("name") != worker:
            findings.append(Finding("worker/package.json", 0, "package-name", f"name {data.get('name')!r} != {worker!r}"))
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


def compare_identifiers(root: Path, g: Glossary) -> tuple[Findings, Notices]:
    findings: Findings = []
    notices: Notices = []
    ids = g.identifiers

    locales = [x.strip() for x in _first_tick(ids.get("Locales", "")).split(",") if x.strip()]
    arb_dir = root / "apps/taro/lib/l10n/arb"
    if arb_dir.is_dir():
        found = {p.stem.removeprefix("app_") for p in arb_dir.glob("app_*.arb")}
        findings += _set_diff(rel(root, arb_dir), "locale", "ARB locale", found, locales)
    else:
        notices.append("apps/taro/lib/l10n/arb/ not present yet; locales not compared")

    bundle_cell = ids.get("Bundle / applicationId", "")
    bundles: dict[str, str] = {}
    for part in bundle_cell.split(";"):
        flavor = re.match(r"\s*(\w+)", part)
        value = next((t for t in backticks(part) if t.startswith("com.")), None)
        if flavor and value:
            bundles[flavor.group(1)] = value
    for flavor, expected in sorted(bundles.items()):
        xcconfig = root / f"apps/taro/ios/Config/{flavor.capitalize()}.xcconfig"
        if xcconfig.is_file():
            actual = _xcconfig_bundle(xcconfig)
            if actual != expected:
                findings.append(Finding(rel(root, xcconfig), 0, "bundle-id", f"{actual!r} != GLOSSARY §15 {expected!r}"))
        else:
            notices.append(f"{rel(root, xcconfig)} not present yet; iOS {flavor} bundle ID not compared")
    gradle = next((p for p in (root / "apps/taro/android/app/build.gradle.kts", root / "apps/taro/android/app/build.gradle") if p.is_file()), None)
    if gradle is not None:
        android = android_bundles(gradle.read_text(encoding="utf-8"))
        for flavor, expected in sorted(bundles.items()):
            if flavor in android and android[flavor] != expected:
                findings.append(Finding(rel(root, gradle), 0, "bundle-id", f"{flavor} applicationId {android[flavor]!r} != {expected!r}"))
            elif flavor not in android:
                notices.append(f"Android flavor {flavor} not present yet; applicationId not compared")

    flavor_cell = ids.get("Flavors / build configs", "")
    flavors = [t for t in backticks(flavor_cell) if "/" not in t]
    files_token = next((t for t in backticks(flavor_cell) if "{" in t), "")
    files_match = re.match(r"^(.*)\{([^}]*)\}(.*)$", files_token)
    expected_files = {f"{files_match.group(1)}{s.strip()}{files_match.group(3)}" for s in files_match.group(2).split(",")} if files_match else set()
    config_dir = root / "apps/taro/config"
    if config_dir.is_dir():
        present = {rel(root, p) for p in config_dir.glob("*.json")}
        findings += _set_diff(rel(root, config_dir), "flavor-config", "flavor config file", present, expected_files, subset=True)
        for missing in sorted(expected_files - present):
            notices.append(f"{missing} not present yet (GLOSSARY §15 flavor config)")
        findings += _check_flavor_configs(root, sorted(present & expected_files), g, flavors)
    else:
        notices.append("apps/taro/config/ not present yet; flavors not compared")
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
        api = data.get("apiBaseUrl", "")
        if flavor in api_hosts and _host(api) != api_hosts[flavor]:
            findings.append(Finding(relative, 0, "api-host", f"apiBaseUrl host {_host(api)!r} != GLOSSARY {api_hosts[flavor]!r}"))
        dev_host = g.environments.get(str(flavor), {}).get("host", "")
        if flavor == "dev" and dev_host.startswith("http") and api != dev_host:
            findings.append(Finding(relative, 0, "api-host", f"apiBaseUrl {api!r} != GLOSSARY {dev_host!r}"))
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

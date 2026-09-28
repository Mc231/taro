#!/usr/bin/env python3
"""Remote-config defaults gate (06 §6.2, 03 §8, 02 §9.4, RC8, RC62).

``worker/config/remote_config.default.json`` (the one defaults file) must:

* validate against the JSON Schema exported from the zod schema
  (``worker/config/remote_config.schema.json``);
* give a default to every key the client reads (02 §9.4);
* hold no key outside the 03 §8.2 key set (spelled in GLOSSARY §8), e.g. a
  per-spread cost key (RC62).

The defaults file may hold the keys flat (``"readings.enabled": true``),
nested (``{"readings": {"enabled": true}}``) or split into ``public`` /
``server`` documents; ``version`` and ``$schema`` are ignored. Skips (exit 0)
while the defaults file does not exist.
"""

from __future__ import annotations

import re
import sys
from collections.abc import Iterable, Mapping, Sequence
from pathlib import Path
from typing import Any

from jsonschema import exceptions as schema_exceptions
from jsonschema import validators

from taro_tools.checkkit import Finding, InputError, base_parser, load_json, resolve_root, run_check
from taro_tools.markdown import backticks, parse_tables, section

NAME = "check_remote_config"
DEFAULTS = "worker/config/remote_config.default.json"
SCHEMA = "worker/config/remote_config.schema.json"
GLOSSARY = "docs/specs/GLOSSARY.md"
ARCHITECTURE = "docs/specs/02_ARCHITECTURE.md"
META_KEYS = frozenset({"version", "$schema"})
SECTIONS = ("public", "server")

_KEY = re.compile(r"^[a-z][A-Za-z0-9]*(\.[A-Za-z0-9{},]+|\[\])+$")
_BRACES = re.compile(r"^(?P<head>.*)\.\{(?P<alts>[^}]+)\}$")


def expand_key(token: str) -> list[str]:
    """``app.minVersion.{ios,android}`` → two keys; ``store.packs[]`` → ``store.packs``."""
    token = token.strip()
    match = _BRACES.match(token)
    keys = [f"{match.group('head')}.{alt.strip()}" for alt in match.group("alts").split(",")] if match else [token]
    return [key.removesuffix("[]") for key in keys]


def glossary_keys(glossary: str) -> set[str]:
    """Every remote-config key named in GLOSSARY §8 (``store.packs[].x`` kept as is)."""
    body = section(glossary, "8. Remote-config keys")
    if body is None:
        raise InputError(GLOSSARY, "no '## 8. Remote-config keys' section")
    keys: set[str] = set()
    for table in parse_tables(body):
        if not table.header or table.header[0] != "Key":
            continue
        for cell in table.column("Key"):
            for token in backticks(cell):
                if _KEY.match(token):
                    keys.update(expand_key(token))
    if not keys:
        raise InputError(GLOSSARY, "§8 lists no remote-config keys")
    return keys


def client_keys(architecture: str) -> set[str]:
    """Keys the client reads with a default, from the 02 §9.4 paragraph."""
    body = section(architecture, "9.4 Remote config keys consumed by the client")
    if body is None:
        raise InputError(ARCHITECTURE, "no '### 9.4 Remote config keys consumed by the client' section")
    paragraph = next((p for p in body.split("\n\n") if "·" in p), None)
    if paragraph is None:
        raise InputError(ARCHITECTURE, "§9.4 has no '·'-separated key list")
    keys: set[str] = set()
    for piece in paragraph.split("·"):
        piece = re.sub(r"\[[^\]]*\]|\([^)]*\)", "", piece)  # drop defaults and notes
        piece = re.split(r"\.\s+[A-Z]", piece, maxsplit=1)[0]  # stop at the next sentence
        for token in backticks(piece):
            if "." in token:
                keys.update(expand_key(token))
    return keys


def flatten(document: Mapping[str, Any], known: Iterable[str]) -> dict[str, Any]:
    """Dotted key → value; recursion stops at known keys (maps and lists stay values)."""
    known_set = set(known)
    parts: list[Mapping[str, Any]] = []
    if any(isinstance(document.get(s), Mapping) for s in SECTIONS):
        parts = [document[s] for s in SECTIONS if isinstance(document.get(s), Mapping)]
        extra = [k for k in document if k not in SECTIONS and k not in META_KEYS]
        if extra:
            parts.append({k: document[k] for k in extra})
    else:
        parts = [document]
    flat: dict[str, Any] = {}

    def visit(node: Mapping[str, Any], prefix: str) -> None:
        for key, value in node.items():
            if not prefix and key in META_KEYS:
                continue
            dotted = f"{prefix}.{key}" if prefix else str(key)
            if isinstance(value, Mapping) and dotted not in known_set and value:
                visit(value, dotted)
            else:
                flat[dotted] = value

    for part in parts:
        visit(part, "")
    return flat


def check_keys(flat: Mapping[str, Any], allowed: set[str], client: set[str]) -> list[Finding]:
    """Unknown keys and client keys without a default."""
    findings: list[Finding] = []
    for key in sorted(flat):
        if key not in allowed:
            findings.append(
                Finding(DEFAULTS, 0, "unknown-key",
                        f"{key!r} is not a 03 §8.2 key (GLOSSARY §8); no per-spread cost or ad-hoc keys (RC62)")
            )
    for key in sorted(client - set(flat)):
        findings.append(Finding(DEFAULTS, 0, "missing-default", f"client-read key {key!r} (02 §9.4) has no default"))
    for key in sorted(client - allowed):
        findings.append(Finding(ARCHITECTURE, 0, "spec-drift", f"02 §9.4 key {key!r} is not in GLOSSARY §8"))
    return findings


def check_schema(defaults: Any, schema: Any) -> list[Finding]:
    """JSON-Schema validation findings (the schema itself must be valid too)."""
    try:
        validator_cls = validators.validator_for(schema)
        validator_cls.check_schema(schema)
    except schema_exceptions.SchemaError as exc:
        return [Finding(SCHEMA, 0, "invalid-schema", exc.message)]
    validator = validator_cls(schema)
    findings: list[Finding] = []
    for error in sorted(validator.iter_errors(defaults), key=lambda e: list(e.absolute_path)):
        where = "/".join(str(p) for p in error.absolute_path) or "(root)"
        findings.append(Finding(DEFAULTS, 0, "schema", f"{where}: {error.message}"))
    return findings


def run(root: Path) -> tuple[list[Finding], list[str]]:
    defaults_path = root / DEFAULTS
    if not defaults_path.is_file():
        return [], [f"{DEFAULTS} not present yet; skipped"]
    defaults = load_json(defaults_path, DEFAULTS)
    if not isinstance(defaults, dict):
        raise InputError(DEFAULTS, "top level must be an object")
    allowed = glossary_keys((root / GLOSSARY).read_text(encoding="utf-8"))
    client = client_keys((root / ARCHITECTURE).read_text(encoding="utf-8"))
    findings = check_keys(flatten(defaults, allowed), allowed, client)
    schema_path = root / SCHEMA
    if schema_path.is_file():
        findings += check_schema(defaults, load_json(schema_path, SCHEMA))
    else:
        findings.append(Finding(SCHEMA, 0, "schema-missing", "export the zod schema as JSON Schema before this check"))
    return findings, []


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root))


if __name__ == "__main__":
    sys.exit(main())

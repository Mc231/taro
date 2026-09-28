#!/usr/bin/env python3
"""Worker prod-environment gate (06 §6.2, 03 BE20, RC86).

Fails when ``worker/wrangler.toml`` ``[env.prod]`` defines any test-only
switch: ``ALLOW_DEBUG_ATTESTATION``, ``AI_PROVIDER`` or
``DEBUG_ATTESTATION_TOKEN``, as a var, as any other key, or named as a string
value (e.g. a required-secrets list). Also fails when ``[env.prod]`` is
missing, since then nothing proves prod is clean. Runs in ``ci`` and in
``worker-deploy.yml`` before a prod deploy.
"""

from __future__ import annotations

import sys
import tomllib
from collections.abc import Iterator, Sequence
from pathlib import Path
from typing import Any

from taro_tools.checkkit import (
    Finding,
    InputError,
    base_parser,
    resolve_root,
    run_check,
)

NAME = "check_worker_env"
WRANGLER = "worker/wrangler.toml"
TEST_ONLY_VARS = ("ALLOW_DEBUG_ATTESTATION", "AI_PROVIDER", "DEBUG_ATTESTATION_TOKEN")


def _walk(node: Any, path: str) -> Iterator[tuple[str, str | None, Any]]:
    """Yield ``(dotted path, key, value)`` for every key and list item."""
    if isinstance(node, dict):
        for key, value in node.items():
            child = f"{path}.{key}"
            yield child, key, value
            yield from _walk(value, child)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            child = f"{path}[{index}]"
            yield child, None, value
            yield from _walk(value, child)


def check_config(config: dict[str, Any], label: str = WRANGLER) -> list[Finding]:
    """Findings for a parsed ``wrangler.toml``."""
    prod = config.get("env", {}).get("prod") if isinstance(config.get("env"), dict) else None
    if not isinstance(prod, dict):
        return [Finding(label, 0, "prod-missing", "no [env.prod] table; prod cannot be verified")]
    findings: list[Finding] = []
    for path, key, value in _walk(prod, "env.prod"):
        if key in TEST_ONLY_VARS:
            findings.append(
                Finding(label, 0, "test-only-var", f"{path} is set; test-only vars are dev/staging only (RC86)")
            )
        elif isinstance(value, str) and value in TEST_ONLY_VARS:
            findings.append(
                Finding(label, 0, "test-only-var", f"{path} names {value}; test-only vars are dev/staging only (RC86)")
            )
    return findings


def load_wrangler(path: Path, label: str = WRANGLER) -> dict[str, Any]:
    """Parse ``wrangler.toml``; malformed TOML is an :class:`InputError`."""
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except (tomllib.TOMLDecodeError, UnicodeDecodeError) as exc:
        raise InputError(label, f"invalid TOML: {exc}") from exc


def run(root: Path) -> tuple[list[Finding], list[str]]:
    path = root / WRANGLER
    if not path.is_file():
        return [], [f"{WRANGLER} not present yet; skipped"]
    return check_config(load_wrangler(path)), []


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root))


if __name__ == "__main__":
    sys.exit(main())

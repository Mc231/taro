#!/usr/bin/env python3
"""Client–Worker contract fixture drift gate (06 QA15, RC38, RC95).

The Worker tests export canonical request/response JSON to
``worker/test/contract/fixtures/``; ``melos run contract:sync`` copies them to
``apps/taro/test/contract/fixtures/`` for the Dart API-client tests. Fails
when the two trees differ: a file on one side only, different bytes, or a
fixture that is not valid JSON. Skips (exit 0) while neither tree exists.
"""

from __future__ import annotations

import json
import sys
from collections.abc import Mapping, Sequence
from pathlib import Path

from taro_tools.checkkit import Finding, base_parser, resolve_root, run_check

NAME = "check_contract_fixtures"
WORKER_DIR = "worker/test/contract/fixtures"
DART_DIR = "apps/taro/test/contract/fixtures"
SYNC_HINT = "run `melos run contract:sync`"


def read_tree(folder: Path) -> dict[str, bytes]:
    """Relative POSIX path → bytes for every file under ``folder`` (dotfiles skipped)."""
    tree: dict[str, bytes] = {}
    for path in sorted(folder.rglob("*")):
        relative = path.relative_to(folder)
        if path.is_file() and not any(part.startswith(".") for part in relative.parts):
            tree[relative.as_posix()] = path.read_bytes()
    return tree


def compare(worker: Mapping[str, bytes], dart: Mapping[str, bytes]) -> list[Finding]:
    """Drift and validity findings between the canonical and the copied tree."""
    findings: list[Finding] = []
    for name in sorted(set(worker) | set(dart)):
        if name not in dart:
            findings.append(Finding(f"{DART_DIR}/{name}", 0, "missing-copy", f"not copied from {WORKER_DIR}; {SYNC_HINT}"))
        elif name not in worker:
            findings.append(
                Finding(f"{DART_DIR}/{name}", 0, "orphan-copy", f"no canonical fixture in {WORKER_DIR}; {SYNC_HINT}")
            )
        elif worker[name] != dart[name]:
            findings.append(Finding(f"{DART_DIR}/{name}", 0, "drift", f"differs from {WORKER_DIR}/{name}; {SYNC_HINT}"))
    for name, data in sorted(worker.items()):
        if name.endswith(".json"):
            try:
                json.loads(data.decode("utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError) as exc:
                findings.append(Finding(f"{WORKER_DIR}/{name}", 0, "invalid-json", str(exc)))
    return findings


def run(root: Path) -> tuple[list[Finding], list[str]]:
    worker_dir, dart_dir = root / WORKER_DIR, root / DART_DIR
    if not worker_dir.is_dir() and not dart_dir.is_dir():
        return [], [f"{WORKER_DIR}/ and {DART_DIR}/ not present yet; skipped"]
    if not worker_dir.is_dir():
        return [Finding(WORKER_DIR, 0, "missing", f"canonical fixtures missing while {DART_DIR}/ exists")], []
    if not dart_dir.is_dir():
        return [Finding(DART_DIR, 0, "missing", f"Dart copies missing; {SYNC_HINT}")], []
    worker, dart = read_tree(worker_dir), read_tree(dart_dir)
    return compare(worker, dart), [f"{len(worker)} canonical fixture(s) compared"]


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root))


if __name__ == "__main__":
    sys.exit(main())

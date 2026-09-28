#!/usr/bin/env python3
"""SKAdNetwork declaration gate (05 §1 technical declarations, 06 §6.2).

The iOS ``Info.plist`` ``SKAdNetworkItems`` must equal the pinned Google
AdMob list in ``tools/skadnetwork_ids.txt`` (case-insensitive, order ignored,
no duplicates). The pinned list itself must be well formed
(``<id>.skadnetwork``). While ``Info.plist`` has no ``SKAdNetworkItems`` yet
(AdMob lands in Phase 12) the comparison is skipped with a note, unless
``--require`` is given (release builds).
"""

from __future__ import annotations

import plistlib
import re
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Any

from taro_tools.checkkit import Finding, InputError, base_parser, resolve_root, run_check

NAME = "check_skadnetwork"
PINNED = "tools/skadnetwork_ids.txt"
INFO_PLIST = "apps/taro/ios/Runner/Info.plist"
_ID = re.compile(r"^[a-z0-9]+\.skadnetwork$")


def parse_pinned(text: str, label: str = PINNED) -> tuple[list[str], list[Finding]]:
    """IDs from the pinned list (``#`` comments and blanks ignored) plus format findings."""
    ids: list[str] = []
    findings: list[Finding] = []
    seen: set[str] = set()
    for number, raw in enumerate(text.splitlines(), start=1):
        line = raw.split("#", 1)[0].strip().lower()
        if not line:
            continue
        if not _ID.match(line):
            findings.append(Finding(label, number, "format", f"{line!r} is not '<id>.skadnetwork'"))
        elif line in seen:
            findings.append(Finding(label, number, "duplicate", f"{line} listed twice"))
        else:
            ids.append(line)
        seen.add(line)
    if not ids and not findings:
        findings.append(Finding(label, 0, "empty", "no SKAdNetwork IDs pinned"))
    return ids, findings


def plist_ids(data: Any, label: str = INFO_PLIST) -> list[str] | None:
    """``SKAdNetworkIdentifier`` values (lower-cased), ``None`` when the key is absent."""
    if not isinstance(data, dict):
        raise InputError(label, "top level is not a dictionary")
    if "SKAdNetworkItems" not in data:
        return None
    items = data["SKAdNetworkItems"]
    if not isinstance(items, list):
        raise InputError(label, "SKAdNetworkItems is not an array")
    ids: list[str] = []
    for index, item in enumerate(items):
        value = item.get("SKAdNetworkIdentifier") if isinstance(item, dict) else None
        if not isinstance(value, str):
            raise InputError(label, f"SKAdNetworkItems[{index}] has no SKAdNetworkIdentifier string")
        ids.append(value.strip().lower())
    return ids


def compare(pinned: Sequence[str], declared: Sequence[str], label: str = INFO_PLIST) -> list[Finding]:
    """Differences between the pinned list and the declared items."""
    findings: list[Finding] = []
    seen: set[str] = set()
    for value in declared:
        if value in seen:
            findings.append(Finding(label, 0, "duplicate", f"{value} declared twice"))
        seen.add(value)
    for value in sorted(set(pinned) - seen):
        findings.append(Finding(label, 0, "missing", f"{value} is pinned in {PINNED} but not declared"))
    for value in sorted(seen - set(pinned)):
        findings.append(Finding(label, 0, "unpinned", f"{value} is declared but not in {PINNED}"))
    return findings


def load_plist(path: Path, label: str = INFO_PLIST) -> Any:
    try:
        with path.open("rb") as handle:
            return plistlib.load(handle)
    except Exception as exc:  # plistlib raises InvalidFileException, ValueError, ExpatError…
        raise InputError(label, f"invalid plist: {exc}") from exc


def run(root: Path, require: bool) -> tuple[list[Finding], list[str]]:
    pinned_path, plist_path = root / PINNED, root / INFO_PLIST
    if not pinned_path.is_file():
        return [Finding(PINNED, 0, "missing", "pinned SKAdNetwork list not found")], []
    pinned, findings = parse_pinned(pinned_path.read_text(encoding="utf-8"))
    if not plist_path.is_file():
        if require:
            return findings + [Finding(INFO_PLIST, 0, "missing", "Info.plist not found")], []
        return findings, [f"{INFO_PLIST} not present yet; skipped"]
    declared = plist_ids(load_plist(plist_path))
    if declared is None:
        if require:
            return findings + [Finding(INFO_PLIST, 0, "not-declared", "no SKAdNetworkItems (required for AdMob)")], []
        return findings, [f"{INFO_PLIST} has no SKAdNetworkItems yet (AdMob, Phase 12); comparison skipped"]
    return findings + compare(pinned, declared), [f"{len(declared)} SKAdNetwork ID(s) compared"]


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--require", action="store_true", help="fail when Info.plist declares no SKAdNetworkItems")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root, args.require))


if __name__ == "__main__":
    sys.exit(main())

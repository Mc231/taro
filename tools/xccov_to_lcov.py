#!/usr/bin/env python3
"""Converts Xcode ``xccov`` JSON to lcov (06 §5.2; RC40, unit ``taro_attestation_ios``).

Two inputs are understood:

* ``xcrun xccov view --archive --json <xcresult>``: ``{"/abs/File.swift":
  [{"line": 1, "isExecutable": true, "executionCount": 3}, ...]}``. Gives
  per-line ``DA`` records.
* ``xcrun xccov view --report --json <xcresult>``: ``{"targets": [{"files":
  [{"path", "executableLines", "coveredLines", "functions": [...]}]}]}``.
  Gives ``FN``/``FNDA`` records, and ``LF``/``LH`` when no archive is given.

Paths are resolved (CocoaPods ``.symlinks`` point at the plugin sources)
and written repo-relative; ``--include`` globs keep only the plugin's files.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections.abc import Sequence
from pathlib import Path

from taro_tools import find_repo_root


def _glob_to_regex(glob: str) -> re.Pattern[str]:
    out = ["^"]
    i = 0
    while i < len(glob):
        if glob.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif glob.startswith("**", i):
            out.append(".*")
            i += 2
        else:
            c = glob[i]
            out.append("[^/]*" if c == "*" else "[^/]" if c == "?" else re.escape(c))
            i += 1
    out.append("$")
    return re.compile("".join(out))


def repo_relative(path: str, repo_root: Path) -> str:
    """Resolves symlinks and returns the path relative to ``repo_root``."""
    real = Path(os.path.realpath(path))
    try:
        return real.relative_to(Path(os.path.realpath(repo_root))).as_posix()
    except ValueError:
        return real.as_posix()


def _included(rel: str, include: Sequence[re.Pattern[str]]) -> bool:
    return not include or any(r.match(rel) for r in include)


def convert(
    report: dict | None,
    archive: dict | None,
    repo_root: Path,
    include: Sequence[str] = (),
) -> str:
    """Builds the lcov text from an xccov report and/or archive JSON."""
    if report is None and archive is None:
        raise ValueError("need an xccov report or archive")
    patterns = [_glob_to_regex(g) for g in include]
    records: dict[str, dict] = {}

    for raw_path, lines in (archive or {}).items():
        rel = repo_relative(raw_path, repo_root)
        if not _included(rel, patterns):
            continue
        entry = records.setdefault(rel, {"lines": {}, "functions": [], "lf": 0, "lh": 0})
        for item in lines:
            if not item.get("isExecutable"):
                continue
            number = int(item["line"])
            hits = int(item.get("executionCount") or 0)
            entry["lines"][number] = max(entry["lines"].get(number, 0), hits)

    for target in (report or {}).get("targets", []):
        for file in target.get("files", []):
            rel = repo_relative(file["path"], repo_root)
            if not _included(rel, patterns):
                continue
            entry = records.setdefault(rel, {"lines": {}, "functions": [], "lf": 0, "lh": 0})
            entry["lf"] = max(entry["lf"], int(file.get("executableLines", 0)))
            entry["lh"] = max(entry["lh"], int(file.get("coveredLines", 0)))
            for fn in file.get("functions", []):
                entry["functions"].append(
                    (int(fn.get("lineNumber", 0)), fn["name"], int(fn.get("executionCount", 0)))
                )

    out: list[str] = []
    for rel in sorted(records):
        entry = records[rel]
        out.append("TN:")
        out.append(f"SF:{rel}")
        functions = sorted(set(entry["functions"]))
        for line, name, _ in functions:
            out.append(f"FN:{line},{name}")
        for _, name, count in functions:
            out.append(f"FNDA:{count},{name}")
        if functions:
            out.append(f"FNF:{len(functions)}")
            out.append(f"FNH:{sum(1 for f in functions if f[2] > 0)}")
        lines = entry["lines"]
        for number in sorted(lines):
            out.append(f"DA:{number},{lines[number]}")
        if lines:
            out.append(f"LF:{len(lines)}")
            out.append(f"LH:{sum(1 for h in lines.values() if h > 0)}")
        else:
            out.append(f"LF:{entry['lf']}")
            out.append(f"LH:{entry['lh']}")
        out.append("end_of_record")
    return "\n".join(out) + ("\n" if out else "")


def _load(path: Path | None) -> dict | None:
    if path is None:
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def main(argv: Sequence[str] | None = None) -> int:
    """Command-line entry point."""
    parser = argparse.ArgumentParser(description="xccov JSON -> lcov")
    parser.add_argument("--report", type=Path, help="xccov view --report --json output")
    parser.add_argument("--archive", type=Path, help="xccov view --archive --json output")
    parser.add_argument("--include", action="append", default=[], help="repo-relative glob to keep")
    parser.add_argument("--repo-root", type=Path, help="repository root (default: auto-detected)")
    parser.add_argument("-o", "--output", type=Path, required=True, help="lcov file to write")
    args = parser.parse_args(argv)
    repo_root = args.repo_root or find_repo_root(Path(__file__))
    try:
        text = convert(_load(args.report), _load(args.archive), repo_root, args.include)
    except (OSError, ValueError, KeyError) as error:
        print(f"xccov_to_lcov: {error}", file=sys.stderr)
        return 1
    if not text:
        print("xccov_to_lcov: no file matched --include", file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"xccov_to_lcov: wrote {args.output} ({text.count('end_of_record')} file(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())

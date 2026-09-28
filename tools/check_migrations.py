#!/usr/bin/env python3
"""D1 migration gate (06 §6.2, 03 §4 migration rules).

``worker/migrations/NNNN_<snake_name>.sql`` files are forward-only:

* names match ``^\\d{4}_[a-z0-9_]+\\.sql$`` and numbers run 0001, 0002, … with
  no gap and no duplicate;
* an existing migration is never modified, deleted or renamed (append-only):
  compared with ``--base <ref>`` (default ``origin/main`` when it exists;
  without a base only the other rules run);
* ``DROP TABLE`` / ``DROP COLUMN`` needs a ``-- contract-phase: <ticket>``
  marker in the same file (expand → deploy → contract keeps a Worker
  rollback safe).
"""

from __future__ import annotations

import re
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path

from taro_tools.checkkit import Finding, base_parser, line_of, resolve_root, run_check

NAME = "check_migrations"
MIGRATIONS = "worker/migrations"
DEFAULT_BASE = "origin/main"

_NAME = re.compile(r"^(\d{4})_[a-z0-9_]+\.sql$")
_MARKER = re.compile(r"--\s*contract-phase:\s*\S+", re.IGNORECASE)
_DROP = re.compile(r"\bDROP\s+(TABLE|COLUMN)\b", re.IGNORECASE)


def strip_sql_comments(sql: str) -> str:
    """Blank ``--`` and ``/* */`` comments and string literals, keeping lines."""
    out: list[str] = []
    i, n = 0, len(sql)
    while i < n:
        if sql.startswith("--", i):
            end = sql.find("\n", i)
            end = n if end < 0 else end
            out.append(" " * (end - i))
            i = end
        elif sql.startswith("/*", i):
            end = sql.find("*/", i + 2)
            end = n if end < 0 else end + 2
            out.append("".join(c if c == "\n" else " " for c in sql[i:end]))
            i = end
        elif sql[i] == "'":
            end = i + 1
            while end < n:
                if sql[end] == "'" and sql.startswith("''", end):
                    end += 2
                    continue
                if sql[end] == "'":
                    end += 1
                    break
                end += 1
            out.append("".join(c if c == "\n" else " " for c in sql[i:end]))
            i = end
        else:
            out.append(sql[i])
            i += 1
    return "".join(out)


def check_names(names: Sequence[str]) -> list[Finding]:
    """Naming, numbering and gap findings for the migration file names."""
    findings: list[Finding] = []
    numbers: dict[int, str] = {}
    for name in sorted(names):
        label = f"{MIGRATIONS}/{name}"
        match = _NAME.match(name)
        if not match:
            findings.append(Finding(label, 0, "name", "migration file must be named NNNN_snake_case.sql"))
            continue
        number = int(match.group(1))
        if number in numbers:
            findings.append(Finding(label, 0, "duplicate", f"number {number:04d} already used by {numbers[number]}"))
            continue
        numbers[number] = name
    expected = 1
    for number in sorted(numbers):
        if number != expected:
            findings.append(
                Finding(f"{MIGRATIONS}/{numbers[number]}", 0, "gap",
                        f"expected {expected:04d}, found {number:04d} (numbering must have no gaps)")
            )
        expected = number + 1
    return findings


def check_drops(name: str, sql: str) -> list[Finding]:
    """``DROP TABLE``/``DROP COLUMN`` without a contract-phase marker."""
    if _MARKER.search(sql):
        return []
    code = strip_sql_comments(sql)
    return [
        Finding(f"{MIGRATIONS}/{name}", line_of(code, m.start()), "drop-without-marker",
                f"{m.group(0).upper()} needs a '-- contract-phase: <ticket>' marker (expand/contract)")
        for m in _DROP.finditer(code)
    ]


def check_changes(changes: Sequence[tuple[str, str]]) -> list[Finding]:
    """Findings for ``git diff --name-status`` rows touching existing migrations."""
    findings: list[Finding] = []
    verbs = {"M": "modified", "D": "deleted", "R": "renamed", "T": "changed type", "C": "copied"}
    for status, path in changes:
        kind = status[:1]
        if kind in ("M", "D", "R", "T"):
            findings.append(
                Finding(path, 0, "append-only", f"existing migration {verbs[kind]}; add a new migration instead")
            )
    return findings


def git_changes(root: Path, base: str) -> list[tuple[str, str]] | None:
    """Name-status rows for ``worker/migrations`` since ``base`` (``None`` if no such ref)."""
    try:
        subprocess.run(
            ["git", "rev-parse", "--verify", "--quiet", f"{base}^{{commit}}"],
            cwd=root, check=True, capture_output=True, text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    out = subprocess.run(
        ["git", "diff", "--name-status", base, "--", MIGRATIONS],
        cwd=root, check=True, capture_output=True, text=True,
    ).stdout
    rows: list[tuple[str, str]] = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            rows.append((parts[0], parts[1]))
    return rows


def run(root: Path, base: str | None) -> tuple[list[Finding], list[str]]:
    folder = root / MIGRATIONS
    if not folder.is_dir():
        return [], [f"{MIGRATIONS}/ not present yet; skipped"]
    notices: list[str] = []
    files = sorted(p for p in folder.iterdir() if p.is_file() and not p.name.startswith("."))
    findings = check_names([p.name for p in files])
    for path in files:
        if path.suffix == ".sql":
            findings += check_drops(path.name, path.read_text(encoding="utf-8"))
    ref = base or DEFAULT_BASE
    changes = git_changes(root, ref)
    if changes is None:
        if base is not None:
            findings.append(Finding("git", 0, "base", f"base ref {base!r} not found"))
        else:
            notices.append(f"no {DEFAULT_BASE} ref; append-only rule not checked (pass --base)")
    else:
        findings += check_changes(changes)
    if not files:
        notices.append(f"{MIGRATIONS}/ has no migrations yet")
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--base", default=None, help=f"git ref to compare with (default {DEFAULT_BASE} if present)")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root, args.base))


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Print the implementation state of every phase (Phase 3 Sprint 3.5).

Reads ``docs/phases/PHASE_*.md``: the ``# Phase N: Title`` heading, the first
``**Status:**`` line and the ``- [ ]`` / ``- [x]`` task checkboxes, then
prints one row per phase and the current phase (the lowest-numbered phase
that is not complete). Ported from ``quiz_apps/tools/phase_state.py``; Taro
keeps the state in the phase docs themselves instead of a YAML side file, so
there is nothing to write.

Usage::

    tools/phase_state.py                 # table
    tools/phase_state.py --status in_progress
    tools/phase_state.py --json
    tools/phase_state.py --phase 3
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Sequence
from dataclasses import asdict, dataclass
from pathlib import Path

if __package__ in (None, ""):  # run as a script: make taro_tools importable
    sys.path.insert(0, str(Path(__file__).resolve().parent))

from taro_tools import find_repo_root  # noqa: E402

PHASES_DIR = Path("docs") / "phases"
STATUSES = ("done", "in_progress", "blocked", "not_started", "unknown")

_HEADING = re.compile(r"^#\s+Phase\s+(\d+)\s*:\s*(.+?)\s*$", re.MULTILINE)
_STATUS = re.compile(r"^\*\*Status:\*\*\s*(.+?)\s*$", re.MULTILINE)
_BOX = re.compile(r"^\s*[-*]\s+\[([ xX])\]", re.MULTILINE)
_FILE = re.compile(r"PHASE_(\d+)_.*\.md$")

# Emoji or leading words → normalized status, checked in order.
_STATUS_RULES: tuple[tuple[str, str], ...] = (
    ("✅", "done"),
    ("complete", "done"),
    ("done", "done"),
    ("⛔", "blocked"),
    ("blocked", "blocked"),
    ("🟡", "in_progress"),
    ("🚧", "in_progress"),
    ("🔄", "in_progress"),
    ("in progress", "in_progress"),
    ("⬜", "not_started"),
    ("not started", "not_started"),
)


@dataclass(frozen=True)
class PhaseState:
    """One phase as read from its doc."""

    number: int
    title: str
    status: str
    detail: str
    tasks_done: int
    tasks_total: int
    path: str


def normalize_status(raw: str) -> tuple[str, str]:
    """``(status, detail)`` for the text after ``**Status:**``.

    ``detail`` is the text after the status words, e.g. the completion date.
    """
    lowered = raw.lower()
    status = "unknown"
    for needle, value in _STATUS_RULES:
        if needle in lowered:
            status = value
            break
    detail = re.sub(r"^[^\w(]*", "", raw)  # drop the leading emoji
    detail = re.sub(
        r"^(complete|completed|done|blocked|in progress|not started)\b[.:]?\s*",
        "",
        detail,
        flags=re.IGNORECASE,
    )
    return status, detail.strip()


def parse_phase(path: Path, text: str) -> PhaseState:
    """Parse one phase doc. Missing parts become ``unknown`` / file-derived values."""
    heading = _HEADING.search(text)
    file_number = _FILE.search(path.name)
    if heading:
        number, title = int(heading.group(1)), heading.group(2)
    else:
        number = int(file_number.group(1)) if file_number else 0
        title = path.stem
    status_line = _STATUS.search(text)
    status, detail = (
        normalize_status(status_line.group(1)) if status_line else ("unknown", "no **Status:** line")
    )
    boxes = _BOX.findall(text)
    done = sum(1 for mark in boxes if mark in "xX")
    return PhaseState(number, title, status, detail, done, len(boxes), path.name)


def read_phases(root: Path) -> list[PhaseState]:
    """Every ``PHASE_*.md`` under ``root/docs/phases``, sorted by phase number."""
    folder = root / PHASES_DIR
    phases = [
        parse_phase(path, path.read_text(encoding="utf-8"))
        for path in folder.glob("PHASE_*.md")
    ]
    return sorted(phases, key=lambda p: (p.number, p.path))


def current_phase(phases: Sequence[PhaseState]) -> PhaseState | None:
    """The lowest-numbered phase that is not done (``None`` when all are)."""
    return next((p for p in phases if p.status != "done"), None)


def _shorten(text: str, width: int) -> str:
    return text if len(text) <= width else text[: width - 1] + "…"


def render_table(
    phases: Sequence[PhaseState], current: PhaseState | None, width: int = 60
) -> str:
    """A fixed-width text table plus the ``current`` phase line."""
    header = f"{'#':>2}  {'phase':<44}  {'status':<11}  {'tasks':>7}  detail"
    lines = [header, "-" * len(header)]
    for p in phases:
        tasks = f"{p.tasks_done}/{p.tasks_total}"
        lines.append(
            f"{p.number:>2}  {_shorten(p.title, 44):<44}  {p.status:<11}  {tasks:>7}  "
            f"{_shorten(p.detail, width)}".rstrip()
        )
    lines.append("")
    if current is None:
        lines.append("current: all phases done")
    else:
        lines.append(f"current: Phase {current.number} ({current.title}), {current.status}")
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="phase_state", description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=None, help="repository root (default: auto-detected)")
    parser.add_argument("--json", action="store_true", help="print JSON instead of a table")
    parser.add_argument("--status", choices=STATUSES, help="only phases with this status")
    parser.add_argument("--phase", type=int, help="only this phase number")
    args = parser.parse_args(argv)

    root = args.root.resolve() if args.root else find_repo_root(Path(__file__))
    phases = read_phases(root)
    if not phases:
        print(f"phase_state: no PHASE_*.md under {root / PHASES_DIR}", file=sys.stderr)
        return 1
    shown = [
        p for p in phases
        if (args.status is None or p.status == args.status)
        and (args.phase is None or p.number == args.phase)
    ]
    if args.phase is not None and not shown:
        print(f"phase_state: no phase {args.phase}", file=sys.stderr)
        return 1
    current = current_phase(phases)
    if args.json:
        print(json.dumps(
            {"current": current.number if current else None, "phases": [asdict(p) for p in shown]},
            ensure_ascii=False,
            indent=2,
        ))
    else:
        print(render_table(shown, current))
    return 0


if __name__ == "__main__":
    sys.exit(main())

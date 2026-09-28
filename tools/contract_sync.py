#!/usr/bin/env python3
"""Copy the Worker contract fixtures into the app tests (06 QA15, RC38, RC95).

``worker/test/contract/fixtures/`` is canonical; this mirrors it into
``apps/taro/test/contract/fixtures/`` (new and changed files are copied,
files that no longer exist upstream are removed, dotfiles are ignored).
``tools/check_contract_fixtures.py`` fails CI when the two trees drift.
``melos run contract:sync [--dry-run]`` calls this script.
"""

from __future__ import annotations

import argparse
import shutil
import sys
from collections.abc import Sequence
from pathlib import Path

if __package__ in (None, ""):  # run as a script: make taro_tools importable
    sys.path.insert(0, str(Path(__file__).resolve().parent))

from taro_tools import find_repo_root  # noqa: E402

SOURCE = Path("worker/test/contract/fixtures")
TARGET = Path("apps/taro/test/contract/fixtures")


def _files(folder: Path) -> dict[str, Path]:
    if not folder.is_dir():
        return {}
    return {
        path.relative_to(folder).as_posix(): path
        for path in sorted(folder.rglob("*"))
        if path.is_file() and not any(p.startswith(".") for p in path.relative_to(folder).parts)
    }


def plan(source: Path, target: Path) -> tuple[list[str], list[str]]:
    """``(copy, remove)``: relative paths to copy (new or changed) and to delete."""
    src, dst = _files(source), _files(target)
    copy = [name for name, path in src.items()
            if name not in dst or dst[name].read_bytes() != path.read_bytes()]
    remove = sorted(set(dst) - set(src))
    return copy, remove


def sync(source: Path, target: Path, dry_run: bool = False) -> tuple[list[str], list[str]]:
    """Mirror ``source`` into ``target``; returns what was (or would be) changed."""
    copy, remove = plan(source, target)
    if not dry_run:
        for name in copy:
            destination = target / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source / name, destination)
        for name in remove:
            (target / name).unlink()
        for folder in sorted((p for p in target.rglob("*") if p.is_dir()), reverse=True):
            if not any(folder.iterdir()):
                folder.rmdir()
    return copy, remove


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="contract_sync", description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=None, help="repository root (default: auto-detected)")
    parser.add_argument("--dry-run", action="store_true", help="print the changes without writing")
    args = parser.parse_args(argv)
    root = args.root.resolve() if args.root else find_repo_root(Path(__file__))
    source, target = root / SOURCE, root / TARGET
    if not source.is_dir():
        print(f"contract_sync: {SOURCE} does not exist yet; nothing to sync")
        return 0
    copy, remove = sync(source, target, dry_run=args.dry_run)
    verb = "would " if args.dry_run else ""
    for name in copy:
        print(f"contract_sync: {verb}copy {name}")
    for name in remove:
        print(f"contract_sync: {verb}remove {name}")
    print(f"contract_sync: {len(copy)} copied, {len(remove)} removed ({SOURCE} -> {TARGET})")
    return 0


if __name__ == "__main__":
    sys.exit(main())

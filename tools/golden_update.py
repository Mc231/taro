#!/usr/bin/env python3
"""Regenerate golden files, only on the reference platform (06 QA8, §3).

The reference platform is **macOS on Apple silicon (Darwin arm64) with the
Flutter version pinned in the root ``pubspec.yaml``**: the self-hosted
``macos`` Gitea runner, and any developer Mac of the same kind (both render
byte-identical goldens with the pinned engine). Anywhere else the command
refuses to run unless given ``--force-local`` (or ``TARO_GOLDEN_FORCE_LOCAL=1``);
files produced that way are for local iteration and are never committed.

For each package with a ``test/golden/`` folder it runs
``flutter test --no-pub --tags golden --update-goldens``.
``melos run golden:update [--force-local] [--dry-run]`` calls this script.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import re
import subprocess
import sys
from collections.abc import Callable, Sequence
from pathlib import Path

if __package__ in (None, ""):  # run as a script: make taro_tools importable
    sys.path.insert(0, str(Path(__file__).resolve().parent))

from taro_tools import find_repo_root  # noqa: E402

REFERENCE_SYSTEM = "Darwin"
REFERENCE_MACHINE = "arm64"
FORCE_ENV = "TARO_GOLDEN_FORCE_LOCAL"
UPDATE_COMMAND = ("flutter", "test", "--no-pub", "--tags", "golden", "--update-goldens")

Runner = Callable[..., subprocess.CompletedProcess[str]]

_FLUTTER_PIN = re.compile(r"^environment:\s*$(?:\n[ \t]+.*$)*?\n[ \t]+flutter:\s*['\"]?([0-9][^'\"\s]*)",
                          re.MULTILINE)


def pinned_flutter(root: Path) -> str | None:
    """The ``environment.flutter`` pin of the root ``pubspec.yaml`` (QA14)."""
    match = _FLUTTER_PIN.search((root / "pubspec.yaml").read_text(encoding="utf-8"))
    return match.group(1) if match else None


def installed_flutter(run: Runner) -> str | None:
    """``frameworkVersion`` from ``flutter --version --machine`` (None if unavailable)."""
    try:
        proc = run(["flutter", "--version", "--machine"], capture_output=True, text=True, check=True)
        return str(json.loads(proc.stdout)["frameworkVersion"])
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError):
        return None


def host_machine(system: str, run: Runner) -> str:
    """The hardware architecture; on macOS ``arm64`` even under Rosetta.

    A Python built for x86_64 reports ``x86_64`` from ``platform.machine()``
    on Apple silicon, so macOS asks ``sysctl hw.optional.arm64`` instead.
    """
    if system == "Darwin":
        try:
            proc = run(["sysctl", "-n", "hw.optional.arm64"], capture_output=True, text=True, check=False)
        except OSError:
            proc = None
        if proc is not None and proc.stdout.strip() == "1":
            return "arm64"
    return platform.machine()


def reference_problems(system: str, machine: str, flutter: str | None, pinned: str | None) -> list[str]:
    """Why this host is not the reference platform (empty when it is)."""
    problems: list[str] = []
    if (system, machine) != (REFERENCE_SYSTEM, REFERENCE_MACHINE):
        problems.append(f"host is {system} {machine}, the reference is {REFERENCE_SYSTEM} {REFERENCE_MACHINE}")
    if pinned is None:
        problems.append("no environment.flutter pin in the root pubspec.yaml")
    elif flutter != pinned:
        problems.append(f"Flutter is {flutter or 'unavailable'}, the pin is {pinned}")
    return problems


def golden_packages(root: Path) -> list[Path]:
    """Package roots (under ``apps/`` and ``packages/``) that have ``test/golden/``."""
    return sorted(
        golden.parent.parent
        for pattern in ("apps/*/test/golden", "packages/*/test/golden")
        for golden in root.glob(pattern)
        if golden.is_dir()
    )


def main(argv: Sequence[str] | None = None, run: Runner = subprocess.run) -> int:
    parser = argparse.ArgumentParser(prog="golden_update", description=__doc__.splitlines()[0])
    parser.add_argument("--force-local", action="store_true",
                        help="run off the reference platform (output must not be committed)")
    parser.add_argument("--dry-run", action="store_true", help="print the plan only")
    parser.add_argument("--root", type=Path, default=None, help="repository root (default: auto-detected)")
    args = parser.parse_args(argv)
    root = args.root.resolve() if args.root else find_repo_root(Path(__file__))
    force = args.force_local or os.environ.get(FORCE_ENV) == "1"

    system = platform.system()
    problems = reference_problems(system, host_machine(system, run), installed_flutter(run), pinned_flutter(root))
    if problems and not force:
        print("golden_update: refusing to update goldens off the reference platform:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        print("Use the golden.yml workflow (update: true), or pass --force-local for local-only files "
              "that are never committed.", file=sys.stderr)
        return 1
    if problems:
        print("golden_update: WARNING --force-local off the reference platform; do not commit the result.")

    packages = golden_packages(root)
    if not packages:
        print("golden_update: no package has test/golden/")
        return 0
    for package in packages:
        where = package.relative_to(root).as_posix()
        print(f"golden_update: {where}: {' '.join(UPDATE_COMMAND)}")
        if args.dry_run:
            continue
        if run(list(UPDATE_COMMAND), cwd=package, check=False).returncode != 0:
            print(f"golden_update: FAILED in {where}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

"""Fixture trees for the repository checks (06 Testing strategy).

``tools/tests/fixtures/<check>/pass/`` is a minimal repository that passes.
Each ``fail_<mode>/`` is an overlay applied on top of a copy of ``pass/``: its
files replace or add files, and an empty file named ``<name>.delete`` removes
``<name>`` (file or folder). That keeps every failure mode to the one file
that breaks it.
"""

from __future__ import annotations

import shutil
from collections.abc import Iterable
from pathlib import Path

FIXTURES = Path(__file__).parent / "fixtures"
REPO = Path(__file__).resolve().parents[2]
DELETE_SUFFIX = ".delete"


def fail_cases(check: str) -> list[str]:
    """Names of the ``fail_*`` overlays of ``check``."""
    return sorted(p.name for p in (FIXTURES / check).iterdir() if p.name.startswith("fail_"))


def materialize(check: str, case: str, dest: Path, real: Iterable[str] = ()) -> Path:
    """Build the fixture repository for ``case`` under ``dest``.

    ``real`` lists repository files (e.g. the rule YAMLs) copied in first, so
    the tests exercise the committed configuration; fixtures may override them.
    """
    root = dest / f"{check}-{case}"
    root.mkdir(parents=True)
    (root / "docs" / "specs").mkdir(parents=True, exist_ok=True)
    for rel in real:
        target = root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO / rel, target)
    shutil.copytree(FIXTURES / check / "pass", root, dirs_exist_ok=True)
    if case != "pass":
        overlay = FIXTURES / check / case
        for source in sorted(overlay.rglob("*")):
            if source.is_dir():
                continue
            target = root / source.relative_to(overlay)
            if source.name.endswith(DELETE_SUFFIX):
                victim = target.with_name(source.name[: -len(DELETE_SUFFIX)])
                if victim.is_dir():
                    shutil.rmtree(victim)
                else:
                    victim.unlink()
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    return root

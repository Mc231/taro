"""Shared helpers for the Taro repository checks in ``tools/``.

The ``check_*.py`` scripts added in Phase 3 (06 §6.2) import from here, so
repository discovery lives in one tested place.
"""

from pathlib import Path

__all__ = ["REPO_MARKER", "find_repo_root"]

# A directory is the repository root when it contains this path.
REPO_MARKER = Path("docs") / "specs"


def find_repo_root(start: Path) -> Path:
    """Return the nearest ancestor of ``start`` (inclusive) holding ``docs/specs``.

    Raises ``FileNotFoundError`` when no ancestor is the Taro repository root.
    """
    current = start.resolve()
    if current.is_file():
        current = current.parent
    for candidate in (current, *current.parents):
        if (candidate / REPO_MARKER).is_dir():
            return candidate
    raise FileNotFoundError(f"no Taro repository root above {start}")

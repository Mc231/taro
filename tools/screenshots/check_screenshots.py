#!/usr/bin/env python3
"""Store screenshot inputs are valid (05 §9.4, Phase 20.2; run by verify.sh).

``screenshots.py lint`` (the fixtures: 12 locales, wire shape, no Death /
Devil / Tower in frames 1–3; the ``store_screenshots`` captions) and
``screenshots.py fixtures --check`` (the generated Dart fixture file is in
sync with ``apps/taro/test/fixtures/store_readings/``).
"""

from __future__ import annotations

import sys
from collections.abc import Sequence
from pathlib import Path

# Run as a script, this folder shadows the `screenshots` package.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from screenshots.screenshots import main as screenshots_main  # noqa: E402


def main(argv: Sequence[str] | None = None) -> int:
    """Runs both checks; ``--root`` is passed through."""
    args = list(argv if argv is not None else sys.argv[1:])
    lint = screenshots_main([*args, "lint"])
    fresh = screenshots_main([*args, "fixtures", "--check"])
    return 1 if lint or fresh else 0


if __name__ == "__main__":
    sys.exit(main())

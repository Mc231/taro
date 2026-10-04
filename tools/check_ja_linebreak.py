#!/usr/bin/env python3
"""Japanese line-break gate: ja ARB strings carry U+2060 word joiners.

Japanese has no spaces, so Flutter may break a line between any two
characters and leaves one- or two-character orphans ("相談窓 / 口",
"くださ / い。"; BUG-18, V2-02). Every ja message therefore joins, with
U+2060 WORD JOINER:

* katakana words ("リーディング") and kanji compounds ("相談窓口");
* kanji with up to three following hiragana ("受け取る", "地域では"), a
  one-kana okurigana between kanji (not a particle), and a katakana word
  with up to two following hiragana ("カードを");
* a character with the closing punctuation after it;
* the last five characters of every sentence ("できません。"), so the last
  line is never an orphan.

Joins already in the ARB (hand-placed, BUG-18) are kept. Native keys
(``ns…``, e.g. ``nsUserTrackingUsageDescription``) are drawn by the OS from
``InfoPlist.strings``, which must equal the ARB value (check_manifests), so
they carry no joiners. Fails when a
message lacks a join these rules add; ``--fix`` rewrites ``app_ja.arb``.
Skips (exit 0) while the file does not exist.
"""

from __future__ import annotations

import json
import re
import sys
from collections.abc import Sequence
from pathlib import Path

from taro_tools.checkkit import Finding, base_parser, line_of, resolve_root, run_check
from taro_tools.store import arb_path, load_arb

NAME = "check_ja_linebreak"
WJ = "⁠"
ARB = arb_path("ja")
TAIL = 5
MAX_OKURIGANA = 3
CLOSING = "。、！？」』）〕】…"
SENTENCE_END = "。！？"
# Particles: a break may follow them, so they never join two kanji.
PARTICLES = "はがをにでとのもへや"
NATIVE_KEY = re.compile(r"^ns[A-Z]")


def kind(ch: str) -> str | None:
    """``K`` kanji, ``T`` katakana, ``H`` hiragana, ``P`` closing mark, else None."""
    code = ord(ch) if len(ch) == 1 else -1
    if ch in CLOSING:
        return "P"
    if 0x4E00 <= code <= 0x9FFF or 0x3400 <= code <= 0x4DBF or ch == "々":
        return "K"
    if 0x30A1 <= code <= 0x30FA or ch == "ー":
        return "T"
    if 0x3041 <= code <= 0x309F:
        return "H"
    return None


def _run(kinds: list[str | None], i: int, step: int) -> int:
    """Length of the hiragana run through ``i`` in direction ``step``."""
    n = 0
    while 0 <= i < len(kinds) and kinds[i] == "H":
        n, i = n + 1, i + step
    return n


def _pair_joins(chars: list[str], kinds: list[str | None]) -> set[int]:
    """Indices ``i`` where ``i - 1`` and ``i`` are one word."""
    joins: set[int] = set()
    for i in range(1, len(kinds)):
        a, b = kinds[i - 1], kinds[i]
        if a is None or b is None:
            continue
        same_word = a == b and a in "KT"
        okurigana = a == "K" and b == "H" and _run(kinds, i, 1) <= MAX_OKURIGANA
        between = a == "H" and b == "K" and i >= 2 and kinds[i - 2] == "K" and chars[i - 1] not in PARTICLES
        after_katakana = a == "T" and b == "H" and _run(kinds, i, 1) <= 2
        if same_word or okurigana or between or after_katakana or b == "P":
            joins.add(i)
    return joins


def _tail_joins(chars: list[str], kinds: list[str | None]) -> set[int]:
    """Joins inside the last ``TAIL`` characters of each sentence."""
    joins: set[int] = set()
    n = len(chars)
    for end in range(n):
        if kinds[end] is None:
            continue
        if end < n - 1 and kinds[end + 1] is not None and chars[end] not in SENTENCE_END:
            continue
        last = end
        while last > 0 and kinds[last] == "P":
            last -= 1
        first = last
        while first > 0 and last - first + 1 < TAIL and kinds[first - 1] not in (None, "P"):
            first -= 1
        joins.update(range(first + 1, end + 1))
    return joins


def join_ja(text: str) -> str:
    """``text`` with the word joiners of the module rules added."""
    chars: list[str] = []
    joins: set[int] = set()
    for ch in text:
        if ch == WJ:
            if chars:
                joins.add(len(chars))
            continue
        chars.append(ch)
    kinds = [kind(ch) for ch in chars]
    joins |= _pair_joins(chars, kinds) | _tail_joins(chars, kinds)
    return "".join((WJ if i in joins and i > 0 else "") + ch for i, ch in enumerate(chars))


def dump_arb(data: dict[str, object]) -> str:
    """The ARB text as the repository writes it (joiners as ``\\u2060``)."""
    return json.dumps(data, ensure_ascii=False, indent=2).replace(WJ, "\\u2060") + "\n"


def _fixed(key: str, value: object) -> object:
    """[value] as the gate wants it: joined, or joiner-free for native keys."""
    if key.startswith("@") or not isinstance(value, str):
        return value
    return value.replace(WJ, "") if NATIVE_KEY.match(key) else join_ja(value)


def run(root: Path, fix: bool = False) -> tuple[list[Finding], list[str]]:
    path = root / ARB
    if not path.is_file():
        return [], [f"{ARB} not present yet; skipped"]
    arb = load_arb(path, ARB)
    text = path.read_text(encoding="utf-8")
    fixed = {k: _fixed(k, v) for k, v in arb.items()}
    findings = [
        Finding(ARB, line_of(text, text.find(f'"{key}"')), "ja-linebreak", f"{key}: word joiners not as the rules want; run with --fix")
        for key, value in arb.items()
        if fixed[key] != value
    ]
    if fix and findings:
        path.write_text(dump_arb(fixed), encoding="utf-8")
        return [], [f"{len(findings)} ja message(s) fixed"]
    count = sum(1 for k in arb if not k.startswith("@"))
    return findings, [f"{count} ja message(s) checked"]


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--fix", action="store_true", help="add the missing joiners to app_ja.arb")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root, fix=args.fix))


if __name__ == "__main__":
    sys.exit(main())

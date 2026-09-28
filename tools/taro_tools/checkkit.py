"""Shared plumbing for the ``tools/check_*.py`` repository checks (06 §6.2).

Every check is ``main(argv) -> int`` over pure functions that return
:class:`Finding` lists. This module holds what they share: the locale list,
input loading that turns malformed files into :class:`InputError`, glob
matching with ``**``, a Dart comment/string masker and the report printer.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any, TextIO

from ruamel.yaml import YAML
from ruamel.yaml.error import YAMLError

from taro_tools import find_repo_root

__all__ = [
    "LOCALES",
    "Finding",
    "InputError",
    "base_parser",
    "emit",
    "glob_match",
    "line_of",
    "load_json",
    "load_yaml",
    "mask_dart",
    "rel",
    "resolve_root",
    "run_check",
]

# The 12 supported locales (02 §11), `en` first (the template).
LOCALES: tuple[str, ...] = (
    "en", "ar", "de", "es", "fr", "it", "ja", "ko", "nl", "pt", "tr", "uk",
)


class InputError(Exception):
    """An input file exists but cannot be used (bad syntax or shape)."""

    def __init__(self, path: str, message: str) -> None:
        super().__init__(f"{path}: {message}")
        self.path = path
        self.message = message


@dataclass(frozen=True, order=True)
class Finding:
    """One violation, rendered as ``path[:line]: [rule] message``."""

    path: str
    line: int
    rule: str
    message: str

    def render(self) -> str:
        where = f"{self.path}:{self.line}" if self.line else self.path
        return f"{where}: [{self.rule}] {self.message}"


def rel(root: Path, path: Path) -> str:
    """``path`` relative to ``root`` in POSIX form (``path`` itself if outside)."""
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def load_yaml(path: Path, label: str | None = None) -> Any:
    """Parse a YAML file (safe loader, duplicate keys rejected)."""
    name = label or path.as_posix()
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        raise InputError(name, f"not UTF-8 ({exc.reason})") from exc
    try:
        return YAML(typ="safe", pure=True).load(text)
    except YAMLError as exc:
        raise InputError(name, f"invalid YAML: {exc}".splitlines()[0]) from exc


def load_json(path: Path, label: str | None = None) -> Any:
    """Parse a JSON file."""
    name = label or path.as_posix()
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except UnicodeDecodeError as exc:
        raise InputError(name, f"not UTF-8 ({exc.reason})") from exc
    except json.JSONDecodeError as exc:
        raise InputError(name, f"invalid JSON: {exc}") from exc


@lru_cache(maxsize=512)
def _glob_regex(pattern: str) -> re.Pattern[str]:
    out: list[str] = []
    i = 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    return re.compile("".join(out) + r"\Z")


def glob_match(path: str, patterns: Iterable[str]) -> bool:
    """True when the POSIX ``path`` matches any glob (``**`` spans folders)."""
    return any(_glob_regex(p).match(path) for p in patterns)


def line_of(text: str, offset: int) -> int:
    """1-based line number of ``offset`` in ``text``."""
    return text.count("\n", 0, offset) + 1


def _blank(chars: list[str], start: int, end: int) -> None:
    for k in range(start, min(end, len(chars))):
        if chars[k] != "\n":
            chars[k] = " "


def mask_dart(source: str, *, mask_strings: bool = True) -> str:
    """Blank Dart comments (and string contents) keeping offsets and lines.

    With ``mask_strings`` the quotes stay but the text between them becomes
    spaces, except the code inside ``${...}`` interpolations. Nested block
    comments, raw strings and triple-quoted strings are handled.
    """
    chars = list(source)
    n = len(source)
    # Each frame: ["code", brace_depth] or ["str", quote, triple, raw].
    stack: list[list[Any]] = [["code", 0]]
    i = 0
    while i < n:
        top = stack[-1]
        if top[0] == "code":
            if source.startswith("//", i):
                end = source.find("\n", i)
                end = n if end < 0 else end
                _blank(chars, i, end)
                i = end
                continue
            if source.startswith("/*", i):
                depth, j = 1, i + 2
                while j < n and depth:
                    if source.startswith("/*", j):
                        depth, j = depth + 1, j + 2
                    elif source.startswith("*/", j):
                        depth, j = depth - 1, j + 2
                    else:
                        j += 1
                _blank(chars, i, j)
                i = j
                continue
            start = i
            raw = False
            prev = source[i - 1] if i else ""
            if (
                source[i] in "rR"
                and i + 1 < n
                and source[i + 1] in "'\""
                and not (prev.isalnum() or prev in "_$")
            ):
                raw = True
                start = i + 1
            if source[start] in "'\"":
                quote = source[start]
                triple = source.startswith(quote * 3, start)
                stack.append(["str", quote, triple, raw])
                i = start + (3 if triple else 1)
                continue
            if source[i] == "{":
                top[1] += 1
            elif source[i] == "}":
                if top[1] == 0 and len(stack) > 1:
                    stack.pop()
                    i += 1
                    continue
                top[1] -= 1
            i += 1
            continue
        _, quote, triple, raw = top
        close = quote * 3 if triple else quote
        if source.startswith(close, i):
            stack.pop()
            i += len(close)
            continue
        char = source[i]
        if not raw and char == "\\":
            if mask_strings:
                _blank(chars, i, i + 2)
            i += 2
            continue
        if not raw and source.startswith("${", i):
            stack.append(["code", 0])
            i += 2
            continue
        if char == "\n" and not triple:
            stack.pop()  # unterminated single-line string: recover
            i += 1
            continue
        if mask_strings and char != "\n":
            chars[i] = " "
        i += 1
    return "".join(chars)


def base_parser(prog: str, description: str) -> argparse.ArgumentParser:
    """An argument parser with the shared ``--root`` option."""
    parser = argparse.ArgumentParser(prog=prog, description=description)
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="repository root (default: the repository holding this script)",
    )
    return parser


def resolve_root(root: Path | None, script: str) -> Path:
    """``root`` if given, else the repository that contains ``script``."""
    return root.resolve() if root is not None else find_repo_root(Path(script))


def emit(
    name: str,
    findings: Sequence[Finding],
    notices: Sequence[str] = (),
    out: TextIO | None = None,
) -> int:
    """Print notices and findings; return the exit code (1 on findings)."""
    stream = out or sys.stdout
    for notice in notices:
        print(f"{name}: note: {notice}", file=stream)
    for finding in sorted(findings):
        print(finding.render(), file=stream)
    if findings:
        print(f"{name}: FAILED ({len(findings)} finding(s))", file=stream)
        return 1
    print(f"{name}: OK", file=stream)
    return 0


def run_check(name: str, body: Any) -> int:
    """Run ``body() -> (findings, notices)``; malformed inputs exit 1."""
    try:
        findings, notices = body()
    except InputError as exc:
        print(f"{name}: malformed input: {exc}", file=sys.stdout)
        print(f"{name}: FAILED (malformed input)", file=sys.stdout)
        return 1
    return emit(name, findings, notices)

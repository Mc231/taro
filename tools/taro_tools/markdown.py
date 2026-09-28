"""Minimal Markdown readers for the spec-driven checks (06 §6.2).

The specs and ``docs/*.md`` references hold their canonical data in headed
sections and pipe tables. These helpers cut a section out of a document and
turn its tables into rows, without a Markdown dependency.
"""

from __future__ import annotations

import re

__all__ = ["Table", "backticks", "parse_tables", "section", "split_cells"]

_HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
_SEPARATOR = re.compile(r"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$")
_BACKTICK = re.compile(r"`([^`]+)`")


def section(text: str, title: str) -> str | None:
    """Body of the first heading whose text starts with ``title``.

    The body runs to the next heading of the same or a higher level, so
    subsections are included. Returns ``None`` when no heading matches.
    """
    lines = text.splitlines()
    for index, line in enumerate(lines):
        match = _HEADING.match(line)
        if not match or not match.group(2).startswith(title):
            continue
        level = len(match.group(1))
        body: list[str] = []
        for following in lines[index + 1 :]:
            nested = _HEADING.match(following)
            if nested and len(nested.group(1)) <= level:
                break
            body.append(following)
        return "\n".join(body)
    return None


def split_cells(line: str) -> list[str]:
    """Cells of one pipe-table row; ``\\|`` and pipes inside backticks stay."""
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    cells: list[str] = []
    current: list[str] = []
    in_code = False
    i = 0
    while i < len(body):
        char = body[i]
        if char == "\\" and i + 1 < len(body) and body[i + 1] == "|":
            current.append("|")
            i += 2
            continue
        if char == "`":
            in_code = not in_code
        if char == "|" and not in_code:
            cells.append("".join(current).strip())
            current = []
        else:
            current.append(char)
        i += 1
    cells.append("".join(current).strip())
    return cells


class Table:
    """One pipe table: ``header`` cells and ``rows`` as header→cell dicts."""

    def __init__(self, header: list[str], rows: list[dict[str, str]], line: int):
        self.header = header
        self.rows = rows
        self.line = line

    def column(self, name: str) -> list[str]:
        """Cells of the column ``name`` (empty strings where a row is short)."""
        return [row.get(name, "") for row in self.rows]


def parse_tables(text: str) -> list[Table]:
    """Every pipe table in ``text`` (a header row followed by ``---`` cells)."""
    lines = text.splitlines()
    tables: list[Table] = []
    index = 0
    while index < len(lines) - 1:
        line = lines[index]
        if line.lstrip().startswith("|") and _SEPARATOR.match(lines[index + 1].strip()):
            header = [re.sub(r"[`*]", "", cell) for cell in split_cells(line)]
            rows: list[dict[str, str]] = []
            cursor = index + 2
            while cursor < len(lines) and lines[cursor].lstrip().startswith("|"):
                cells = split_cells(lines[cursor])
                rows.append(dict(zip(header, cells, strict=False)))
                cursor += 1
            tables.append(Table(header, rows, index + 1))
            index = cursor
            continue
        index += 1
    return tables


def backticks(text: str) -> list[str]:
    """The contents of every ```code``` span in ``text``, in order."""
    return _BACKTICK.findall(text)

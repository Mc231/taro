#!/usr/bin/env python3
"""Analytics event catalogue gate (06 §6.2, 01 §15, 04 §14, PR18).

Compares the sealed event classes in code with ``docs/ANALYTICS_EVENTS.md``:

* every event class in code is documented, every documented event exists, and
  each event's parameter set is identical on both sides;
* names are ``snake_case`` and ≤ 40 characters, with ≤ 25 parameters (01 §15);
* no event class has a free-form ``String`` field: a ``String``/``String?``
  field must carry an enum annotation (an annotation whose name contains
  ``Enum``, e.g. ``@AnalyticsEnum([...])``), because params are enums, ints or
  bools only (PR18).

Code conventions (Phase 4, ``TaroAnalyticsEvent``): an event is a concrete
class under ``packages/taro_core/lib`` or ``apps/taro/lib`` whose body sets
``eventName`` (or ``name``) to a string literal (``String get eventName =>
'x';`` or ``final eventName = 'x';``) and whose ``parameters`` (or ``params``)
getter returns a map literal with string keys.

Doc conventions: pipe tables with an ``Event`` column (one or more
backticked names) and a ``Params``/``Parameters`` column listing
``\\`param\\` (type)`` entries separated by commas; ``–`` means none.

Skips (exit 0) while neither the catalogue nor any event class exists.
"""

from __future__ import annotations

import re
import sys
from collections.abc import Iterable, Sequence
from dataclasses import dataclass, field
from pathlib import Path

from taro_tools.checkkit import Finding, base_parser, line_of, mask_dart, rel, resolve_root, run_check
from taro_tools.markdown import backticks, parse_tables

NAME = "check_analytics_events"
DOC = "docs/ANALYTICS_EVENTS.md"
CODE_DIRS = ("packages/taro_core/lib", "apps/taro/lib")
GENERATED = (".g.dart", ".freezed.dart", ".gen.dart")
MAX_NAME = 40
MAX_PARAMS = 25

_SNAKE = re.compile(r"^[a-z][a-z0-9]*(_[a-z0-9]+)*$")
_CLASS = re.compile(r"\b((?:(?:abstract|sealed|base|final|interface|mixin)\s+)*)class\s+(\w+)[^{;]*\{")
_EVENT_NAME = re.compile(r"\b(?:eventName|name)\s*(?:=>|=)\s*(['\"])")
_PARAMS = re.compile(r"\b(?:parameters|params)\s*(=>|\{)")
_STRING_FIELD = re.compile(
    r"((?:@\w+(?:\.\w+)?(?:\([^;]*?\))?\s+)*)(?:final\s+|late\s+)*String\??\s+(\w+)\s*[;=]"
)


@dataclass
class Event:
    """An event as seen on one side (code or doc)."""

    name: str
    params: list[str]
    where: str
    line: int
    string_fields: list[tuple[str, int]] = field(default_factory=list)


def _match_close(masked: str, open_index: int) -> int:
    """Index just past the bracket matching ``masked[open_index]``."""
    pairs = {"{": "}", "(": ")", "[": "]"}
    depth = 0
    for index in range(open_index, len(masked)):
        char = masked[index]
        if char in pairs:
            depth += 1
        elif char in pairs.values():
            depth -= 1
            if depth == 0:
                return index + 1
    return len(masked)


def _depth(masked: str, end: int) -> int:
    """Bracket depth at ``end`` relative to the start of ``masked``."""
    text = masked[:end]
    return sum(text.count(c) for c in "{([") - sum(text.count(c) for c in "})]")


def _literal(source: str, masked: str, quote_index: int) -> str:
    quote = masked[quote_index]
    close = masked.find(quote, quote_index + 1)
    return source[quote_index + 1 : close if close >= 0 else len(source)]


def _expression_end(masked: str, start: int) -> int:
    """End of an ``=>`` expression: the ``;`` at bracket depth 0."""
    depth = 0
    for index in range(start, len(masked)):
        char = masked[index]
        if char in "{([":
            depth += 1
        elif char in "})]":
            depth -= 1
        elif char == ";" and depth == 0:
            return index
    return len(masked)


def _map_keys(source: str, masked: str, start: int, end: int) -> list[str]:
    """String keys of map literals in ``[start, end)`` (``'k': …`` after ``{``, ``,`` or ``)``)."""
    keys: list[str] = []
    index = start
    while index < end:
        char = masked[index]
        if char in "'\"":
            close = masked.find(char, index + 1)
            if close < 0 or close >= end:
                break
            before = masked[start:index].rstrip()
            after = masked[close + 1 : end].lstrip()
            if after.startswith(":") and before[-1:] in ("{", ",", ")"):
                keys.append(source[index + 1 : close])
            index = close + 1
            continue
        index += 1
    return keys


def dart_events(source: str, where: str) -> list[Event]:
    """Concrete event classes declared in one Dart file."""
    masked = mask_dart(source)
    events: list[Event] = []
    for match in _CLASS.finditer(masked):
        modifiers = match.group(1).split()
        if "abstract" in modifiers or "sealed" in modifiers or "mixin" in modifiers:
            continue
        open_index = match.end() - 1
        close = _match_close(masked, open_index)
        body_start, body_end = open_index + 1, close - 1
        body = masked[body_start:body_end]
        name_match = _EVENT_NAME.search(body)
        if not name_match:
            continue
        name = _literal(source, masked, body_start + name_match.start(1))
        params: list[str] = []
        params_match = _PARAMS.search(body)
        if params_match:
            p_start = body_start + params_match.end()
            if params_match.group(1) == "=>":
                p_end = _expression_end(masked, p_start)
            else:
                p_end = _match_close(masked, p_start - 1)
            params = _map_keys(source, masked, p_start, p_end)
        string_fields = [
            (m.group(2), line_of(source, body_start + m.start(2)))
            for m in _STRING_FIELD.finditer(body)
            if _depth(body, m.start()) == 0
            and m.group(2) not in ("eventName", "name")
            and not re.search(r"@\w*enum", m.group(1), re.IGNORECASE)
        ]
        events.append(Event(name, params, where, line_of(source, match.start(2)), string_fields))
    return events


def _split_params(cell: str) -> list[str]:
    """Top-level comma-separated segments of a params cell."""
    segments: list[str] = []
    depth = 0
    current: list[str] = []
    for char in cell:
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        if char == "," and depth == 0:
            segments.append("".join(current))
            current = []
        else:
            current.append(char)
    segments.append("".join(current))
    return segments


def doc_events(text: str, where: str = DOC) -> list[Event]:
    """Events documented in the catalogue tables."""
    events: list[Event] = []
    for table in parse_tables(text):
        if "Event" not in table.header:
            continue
        params_column = next(
            (h for h in table.header if h.split(" ")[0] in ("Params", "Parameters")), None
        )
        for offset, row in enumerate(table.rows, start=2):
            names = backticks(row.get("Event", ""))
            params: list[str] = []
            if params_column:
                for segment in _split_params(row.get(params_column, "")):
                    tokens = backticks(segment.strip())
                    if tokens and segment.strip().startswith("`"):
                        params.append(tokens[0].rstrip("?"))
            for name in names:
                events.append(Event(name, list(params), where, table.line + offset))
    return events


def check_rules(events: Iterable[Event]) -> list[Finding]:
    """Naming, size and free-String findings for one side."""
    findings: list[Finding] = []
    for event in events:
        if not _SNAKE.match(event.name) or len(event.name) > MAX_NAME:
            findings.append(Finding(event.where, event.line, "name", f"{event.name!r} must be snake_case, ≤ {MAX_NAME} chars"))
        if len(event.params) > MAX_PARAMS:
            findings.append(Finding(event.where, event.line, "params", f"{event.name} has {len(event.params)} params (> {MAX_PARAMS})"))
        for param in event.params:
            if not _SNAKE.match(param):
                findings.append(Finding(event.where, event.line, "param-name", f"{event.name}.{param} must be snake_case"))
        for field_name, line in event.string_fields:
            findings.append(
                Finding(event.where, line, "free-string",
                        f"{event.name}.{field_name} is a String without an enum annotation (PR18: enums, ints, bools only)")
            )
    return findings


def _index(events: Iterable[Event], side: str) -> tuple[dict[str, Event], list[Finding]]:
    index: dict[str, Event] = {}
    findings: list[Finding] = []
    for event in events:
        if event.name in index:
            first = index[event.name]
            findings.append(
                Finding(event.where, event.line, "duplicate", f"{side} event {event.name} already at {first.where}:{first.line}")
            )
        else:
            index[event.name] = event
    return index, findings


def compare(code: Sequence[Event], doc: Sequence[Event]) -> list[Finding]:
    """Set and parameter differences between code and the catalogue."""
    code_index, findings = _index(code, "code")
    doc_index, doc_dupes = _index(doc, "documented")
    findings += doc_dupes
    for name in sorted(set(code_index) - set(doc_index)):
        event = code_index[name]
        findings.append(Finding(event.where, event.line, "undocumented", f"event {name} is missing from {DOC}"))
    for name in sorted(set(doc_index) - set(code_index)):
        event = doc_index[name]
        findings.append(Finding(event.where, event.line, "not-in-code", f"documented event {name} has no event class"))
    for name in sorted(set(code_index) & set(doc_index)):
        in_code, in_doc = set(code_index[name].params), set(doc_index[name].params)
        if in_code != in_doc:
            detail = []
            if in_code - in_doc:
                detail.append(f"only in code: {', '.join(sorted(in_code - in_doc))}")
            if in_doc - in_code:
                detail.append(f"only in doc: {', '.join(sorted(in_doc - in_code))}")
            event = doc_index[name]
            findings.append(Finding(event.where, event.line, "params-differ", f"{name} params differ ({'; '.join(detail)})"))
    return findings


def code_events(root: Path, dirs: Sequence[str] = CODE_DIRS) -> list[Event]:
    events: list[Event] = []
    for directory in dirs:
        base = root / directory
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*.dart")):
            if path.name.endswith(GENERATED) or "/generated/" in path.as_posix():
                continue
            source = path.read_text(encoding="utf-8")
            if "Event" in source:
                events += dart_events(source, rel(root, path))
    return events


def run(root: Path) -> tuple[list[Finding], list[str]]:
    code = code_events(root)
    doc_path = root / DOC
    if not doc_path.is_file():
        if not code:
            return [], [f"{DOC} and analytics event classes not present yet; skipped"]
        return check_rules(code) + [Finding(DOC, 0, "missing", f"{len(code)} event class(es) exist but the catalogue does not")], []
    doc = doc_events(doc_path.read_text(encoding="utf-8"))
    findings = check_rules(code) + check_rules(doc) + compare(code, doc)
    return findings, [f"{len(code)} event class(es), {len(doc)} documented event(s)"]


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root))


if __name__ == "__main__":
    sys.exit(main())

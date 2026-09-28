#!/usr/bin/env python3
"""Retention-period consistency gate (06 §6.2, RC69).

03 §13 is the single source of retention periods. The privacy policy
(``web/privacy.en.md`` §Retention) and the AI consent copy (ARB
``aiConsentBody`` in ``app_en.arb``) must state the same periods.

Each data category is found by keyword: in 03 §13 by its table row, in the
other texts by the clause (split on ``;``, ``.`` and new lines) that names it.
The first period in that clause (``7 days``, ``13 months``, ``48 h`` …) must
equal the 03 period; "never/not stored" categories must say so. The privacy
policy must cover every category marked ``policy``; the consent copy must
cover every category marked ``consent``; any other category a text mentions
is compared too. Targets that do not exist yet are skipped (exit 0).
"""

from __future__ import annotations

import json
import re
import sys
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path

from taro_tools.checkkit import Finding, InputError, base_parser, resolve_root, run_check
from taro_tools.markdown import parse_tables, section

NAME = "check_retention"
BACKEND = "docs/specs/03_BACKEND_WORKER.md"
PRIVACY = "web/privacy.en.md"
ARB = "apps/taro/lib/l10n/arb/app_en.arb"
NOT_STORED = "not stored"

_PERIOD = re.compile(
    r"(\d+)\s*(h|hours?|days?|months?|years?)\b", re.IGNORECASE
)
_NOT_STORED = re.compile(r"\b(never|not)\s+(be\s+)?stored\b", re.IGNORECASE)
_UNITS = {"h": "hours", "hour": "hours", "hours": "hours", "day": "days", "days": "days",
          "month": "months", "months": "months", "year": "years", "years": "years"}


@dataclass(frozen=True)
class Category:
    """A retention category: its 03 §13 row keyword and its keyword in prose."""

    key: str
    row: str  # regex matched against the 03 §13 "Data" cell
    prose: str  # regex matched against a privacy/consent clause
    policy: bool  # the privacy policy must state it
    consent: bool  # the AI consent copy must state it


CATEGORIES: tuple[Category, ...] = (
    Category("question", r"^\*{0,2}question text", r"\bquestion\b", True, True),
    Category("ai_output", r"^\*{0,2}ai output", r"reading text|your reading is kept|reading is kept", True, True),
    Category("reports", r"^reported reading", r"\breport", True, True),
    Category("ledger", r"^ledger", r"\bledger|\bpurchases\b", True, False),
    Category("reading_metadata", r"^reading metadata", r"reading metadata", True, False),
    Category("rewards", r"^reward intents", r"reward", True, False),
    Category("daily_usage", r"^daily usage", r"daily usage", True, False),
    Category("device_counters", r"^device free/rewarded counters", r"device counters|device-key", True, False),
    Category("logs", r"^logs\b", r"\blogs\b", True, False),
    Category("inactive_installs", r"^install uuid", r"inactive install", True, False),
    Category("ip", r"^ip address", r"\bip address", False, False),
)


def normalize(amount: str, unit: str) -> str:
    """``48 h`` → ``48 hours``; ``1 day`` → ``1 days`` (a stable comparison key)."""
    return f"{int(amount)} {_UNITS[unit.lower()]}"


def first_period(text: str) -> str | None:
    match = _PERIOD.search(text)
    return normalize(match.group(1), match.group(2)) if match else None


def source_periods(backend: str) -> dict[str, str]:
    """Category → period (or ``not stored``) from the 03 §13 table."""
    body = section(backend, "13. Privacy & retention")
    if body is None:
        raise InputError(BACKEND, "no '## 13. Privacy & retention' section")
    table = next((t for t in parse_tables(body) if t.header[:1] == ["Data"]), None)
    if table is None:
        raise InputError(BACKEND, "§13 has no 'Data | Where | Retention' table")
    periods: dict[str, str] = {}
    for category in CATEGORIES:
        row = next(
            (r for r in table.rows if re.search(category.row, r.get("Data", ""), re.IGNORECASE)), None
        )
        if row is None:
            raise InputError(BACKEND, f"§13 has no row for {category.key}")
        period = first_period(row.get("Retention", ""))
        if period is None and _NOT_STORED.search(f"{row.get('Data', '')} {row.get('Where', '')}"):
            period = NOT_STORED
        if period is None:
            raise InputError(BACKEND, f"§13 row for {category.key} states no period")
        periods[category.key] = period
    return periods


def clauses(text: str) -> list[str]:
    """Clauses of prose: split on ``;``, sentence ends and new lines."""
    return [c.strip() for c in re.split(r";|\.\s|\n", text) if c.strip()]


def stated_periods(text: str) -> dict[str, str]:
    """Category → the period a prose text states for it (first clause that names it)."""
    stated: dict[str, str] = {}
    for clause in clauses(text):
        for category in CATEGORIES:
            if category.key in stated or not re.search(category.prose, clause, re.IGNORECASE):
                continue
            if _NOT_STORED.search(clause):
                stated[category.key] = NOT_STORED
            else:
                period = first_period(clause)
                if period is not None:
                    stated[category.key] = period
    return stated


def compare(
    source: Mapping[str, str], stated: Mapping[str, str], label: str, required: Sequence[str]
) -> list[Finding]:
    """Findings for one target text against the 03 §13 periods."""
    findings: list[Finding] = []
    for key in required:
        if key not in stated:
            findings.append(Finding(label, 0, "missing", f"states no retention for {key} (03 §13: {source[key]})"))
    for key, value in sorted(stated.items()):
        if value != source[key]:
            findings.append(Finding(label, 0, "mismatch", f"{key}: states {value}, 03 §13 says {source[key]}"))
    return findings


def consent_body(arb_text: str) -> str | None:
    """The ``aiConsentBody`` value of ``app_en.arb`` (``None`` when absent)."""
    try:
        data = json.loads(arb_text)
    except json.JSONDecodeError as exc:
        raise InputError(ARB, f"invalid JSON: {exc}") from exc
    value = data.get("aiConsentBody") if isinstance(data, dict) else None
    if value is not None and not isinstance(value, str):
        raise InputError(ARB, "aiConsentBody is not a string")
    return value


def run(root: Path) -> tuple[list[Finding], list[str]]:
    source = source_periods((root / BACKEND).read_text(encoding="utf-8"))
    findings: list[Finding] = []
    notices: list[str] = []
    privacy_path = root / PRIVACY
    if privacy_path.is_file():
        retention = section(privacy_path.read_text(encoding="utf-8"), "Retention")
        if retention is None:
            findings.append(Finding(PRIVACY, 0, "section-missing", "no 'Retention' heading"))
        else:
            required = [c.key for c in CATEGORIES if c.policy]
            findings += compare(source, stated_periods(retention), PRIVACY, required)
    else:
        notices.append(f"{PRIVACY} not present yet; skipped")
    arb_path = root / ARB
    body = consent_body(arb_path.read_text(encoding="utf-8")) if arb_path.is_file() else None
    if body is None:
        notices.append(f"aiConsentBody not present yet in {ARB}; skipped")
    else:
        required = [c.key for c in CATEGORIES if c.consent]
        findings += compare(source, stated_periods(body), f"{ARB} (aiConsentBody)", required)
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root))


if __name__ == "__main__":
    sys.exit(main())

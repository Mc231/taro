#!/usr/bin/env python3
"""Per-unit coverage gate (06 QA1-QA4, §5.1; RC16, RC40, RC95).

Units: ``taro_core``, ``taro_ui``, ``taro_attestation`` (every
``packages/*`` with ``lib/``), ``taro_attestation_ios``,
``taro_attestation_android`` (RC40), ``apps/taro``, ``dart_tools``
(``tools/dart_tools``, 06 Testing strategy), ``worker`` and ``tools``.

The gate fails on a missing report, a non-excluded source file missing from
its report (QA4), a unit below 90.0 % lines (QA1), a file below 70.0 %
(QA2), a coverage pragma in a source file (QA3), the Worker below 85 %
branches (QA7), and, with ``--verify-sonar``, drift between
``tools/coverage_exclusions.txt`` and ``sonar.coverage.exclusions``.

It writes ``coverage/merged/lcov.info`` (repo-relative paths, for SonarQube)
and ``coverage/summary.md`` (the CI job summary).
"""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass, field
from pathlib import Path

from taro_tools import find_repo_root

UNIT_THRESHOLD = 90.0
FILE_THRESHOLD = 70.0
WORKER_BRANCH_THRESHOLD = 85.0
WORST_FILES = 10

EXCLUSIONS_PATH = "tools/coverage_exclusions.txt"
SONAR_PATH = "sonar-project.properties"
SONAR_KEY = "sonar.coverage.exclusions"
MERGED_LCOV = "coverage/merged/lcov.info"
SUMMARY_MD = "coverage/summary.md"

# QA3 pragmas, only when they sit in a comment. The literals are split so
# this file does not trip its own scan.
_PRAGMA_WORDS = (
    "coverage" + r":ignore-[a-z]+",
    "istanbul" + r"\s+ignore",
    "c8" + r"\s+ignore",
    "pragma" + r":\s*no\s+cover",
)
PRAGMA_RE = re.compile(
    r"(?://|/\*|#|\*).*?(" + "|".join(_PRAGMA_WORDS) + ")", re.IGNORECASE
)

# Directories never walked when listing tools/ Python sources (mirrors the
# pyproject coverage `omit`).
_TOOLS_SKIP_DIRS = {".venv", "build", "dart_tools", "__pycache__", "coverage"}
_DEFAULT_SKIP_DIRS = {"build", ".dart_tool", "node_modules", "coverage"}


# --------------------------------------------------------------------------
# Globs and exclusions
# --------------------------------------------------------------------------


def glob_to_regex(glob: str) -> re.Pattern[str]:
    """Anchored regex for a repo-relative glob.

    ``**/`` matches zero or more whole segments, a trailing ``**`` matches
    everything below, ``*`` and ``?`` stay inside one segment. Same rules as
    ``tools/dart_tools/lib/src/coverage_exclusions.dart``.
    """
    out = ["^"]
    i = 0
    while i < len(glob):
        c = glob[i]
        if glob.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
            continue
        if glob.startswith("**", i):
            out.append(".*")
            i += 2
            continue
        if c == "*":
            out.append("[^/]*")
        elif c == "?":
            out.append("[^/]")
        else:
            out.append(re.escape(c))
        i += 1
    out.append("$")
    return re.compile("".join(out))


def parse_exclusions(text: str) -> list[str]:
    """Patterns of the exclusion file: one per line, ``#`` comments."""
    patterns = []
    for raw in text.splitlines():
        line = raw.strip()
        if line and not line.startswith("#"):
            patterns.append(line)
    return patterns


@dataclass
class Exclusions:
    """The parsed exclusion list with compiled matchers."""

    patterns: list[str]
    _regexes: list[re.Pattern[str]] = field(init=False, repr=False)

    def __post_init__(self) -> None:
        self._regexes = [glob_to_regex(p) for p in self.patterns]

    def matches(self, path: str) -> bool:
        """Whether the repo-relative ``path`` is excluded."""
        return any(r.match(path) for r in self._regexes)


# --------------------------------------------------------------------------
# Report readers
# --------------------------------------------------------------------------


@dataclass
class FileCov:
    """Line coverage of one file. ``lines`` maps line number to hits."""

    path: str
    lines: dict[int, int] = field(default_factory=dict)
    found_override: int | None = None
    hit_override: int | None = None

    @property
    def found(self) -> int:
        if self.lines:
            return len(self.lines)
        return self.found_override or 0

    @property
    def hit(self) -> int:
        if self.lines:
            return sum(1 for h in self.lines.values() if h > 0)
        return self.hit_override or 0

    @property
    def pct(self) -> float:
        return 100.0 if self.found == 0 else 100.0 * self.hit / self.found

    def merge(self, other: FileCov) -> None:
        """Adds ``other``'s hits (the same file seen in two records)."""
        for line, hits in other.lines.items():
            self.lines[line] = self.lines.get(line, 0) + hits
        if not other.lines:
            self.found_override = max(self.found_override or 0, other.found)
            self.hit_override = max(self.hit_override or 0, other.hit)


def _repo_relative(raw: str, repo_root: Path, base: str) -> str:
    """Maps a report path to a forward-slash repo-relative path.

    Absolute paths are made relative to ``repo_root``; relative ones are
    taken relative to the unit directory ``base``.
    """
    raw = raw.replace("\\", "/")
    path = Path(raw)
    if path.is_absolute():
        try:
            return path.resolve().relative_to(repo_root.resolve()).as_posix()
        except ValueError:
            # Produced on another machine (CI artifact): re-anchor on the unit dir.
            marker = f"/{base}/" if base not in ("", ".") else ""
            index = raw.rfind(marker) if marker else -1
            return f"{base}/{raw[index + len(marker):]}" if index >= 0 else path.as_posix()
    joined = f"{base}/{raw}" if base not in ("", ".") else raw
    parts: list[str] = []
    for part in joined.split("/"):
        if part in ("", "."):
            continue
        if part == ".." and parts:
            parts.pop()
            continue
        parts.append(part)
    return "/".join(parts)


def parse_lcov(text: str, repo_root: Path, base: str) -> dict[str, FileCov]:
    """Reads an lcov tracefile into repo-relative :class:`FileCov` records."""
    files: dict[str, FileCov] = {}
    current: FileCov | None = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("SF:"):
            current = FileCov(_repo_relative(line[3:], repo_root, base))
        elif current is None:
            continue
        elif line.startswith("DA:"):
            fields = line[3:].split(",")
            number, hits = int(fields[0]), int(float(fields[1]))
            current.lines[number] = max(current.lines.get(number, 0), hits)
        elif line.startswith("LF:"):
            current.found_override = int(line[3:])
        elif line.startswith("LH:"):
            current.hit_override = int(line[3:])
        elif line == "end_of_record":
            if current.path in files:
                files[current.path].merge(current)
            else:
                files[current.path] = current
            current = None
    return files


def parse_coverage_py_json(data: dict, repo_root: Path, base: str) -> dict[str, FileCov]:
    """Reads ``coverage json`` output (statement coverage per line)."""
    files: dict[str, FileCov] = {}
    for raw, entry in data.get("files", {}).items():
        path = _repo_relative(raw, repo_root, base)
        cov = FileCov(path)
        for number in entry.get("executed_lines", []):
            cov.lines[int(number)] = 1
        for number in entry.get("missing_lines", []):
            cov.lines.setdefault(int(number), 0)
        if not cov.lines:
            summary = entry.get("summary", {})
            cov.found_override = int(summary.get("num_statements", 0))
            cov.hit_override = int(summary.get("covered_lines", 0))
        files[path] = cov
    return files


# --------------------------------------------------------------------------
# Units
# --------------------------------------------------------------------------


@dataclass
class Unit:
    """A coverage unit: where its report is and which files it must cover."""

    name: str
    root: str
    kind: str  # "lcov" | "worker" | "tools"
    reports: list[str]
    sources: list[str]
    lcov_base: str = ""


def discover_units(repo_root: Path) -> list[Unit]:
    """The units of 06 QA1 (RC40, RC95), in a stable order."""
    units: list[Unit] = []
    packages = repo_root / "packages"
    if packages.is_dir():
        for pubspec in sorted(packages.glob("*/pubspec.yaml")):
            pkg = pubspec.parent
            if not (pkg / "lib").is_dir():
                continue
            root = pkg.relative_to(repo_root).as_posix()
            units.append(_dart_unit(pkg.name, root))
    for name, root in (("apps/taro", "apps/taro"), ("dart_tools", "tools/dart_tools")):
        if (repo_root / root / "pubspec.yaml").is_file():
            units.append(_dart_unit(name, root))
    attestation = "packages/taro_attestation"
    if (repo_root / attestation / "ios").is_dir():
        units.append(
            Unit(
                name="taro_attestation_ios",
                root=f"{attestation}/ios",
                kind="lcov",
                reports=[f"{attestation}/coverage/ios/lcov.info"],
                sources=[f"{attestation}/ios/*/Sources/**/*.swift", f"{attestation}/ios/Classes/**/*.swift"],
            )
        )
    if (repo_root / attestation / "android").is_dir():
        units.append(
            Unit(
                name="taro_attestation_android",
                root=f"{attestation}/android",
                kind="lcov",
                reports=[f"{attestation}/coverage/android/lcov.info"],
                sources=[
                    f"{attestation}/android/src/main/**/*.kt",
                    f"{attestation}/android/src/main/**/*.java",
                ],
            )
        )
    if (repo_root / "worker" / "package.json").is_file():
        units.append(
            Unit(
                name="worker",
                root="worker",
                kind="worker",
                reports=["worker/coverage/lcov.info", "worker/coverage/coverage-summary.json"],
                sources=[
                    "worker/src/**/*.ts",
                    "worker/scripts/**/*.ts",
                    "worker/evals/lib/**/*.ts",
                ],
                lcov_base="worker",
            )
        )
    if (repo_root / "tools" / "pyproject.toml").is_file():
        units.append(
            Unit(
                name="tools",
                root="tools",
                kind="tools",
                reports=["tools/coverage/coverage.json"],
                sources=["tools/**/*.py"],
                lcov_base="tools",
            )
        )
    return units


def _dart_unit(name: str, root: str) -> Unit:
    return Unit(
        name=name,
        root=root,
        kind="lcov",
        reports=[f"{root}/coverage/lcov.filtered.info"],
        sources=[f"{root}/lib/**/*.dart"],
        lcov_base=root,
    )


def list_sources(repo_root: Path, unit: Unit, exclusions: Exclusions) -> list[str]:
    """Non-excluded source files of ``unit`` (repo-relative, sorted).

    Each source glob is walked from its wildcard-free prefix; symlinked
    directories (CocoaPods ``.symlinks``) and build/tool dirs are skipped.
    """
    skip = _TOOLS_SKIP_DIRS if unit.kind == "tools" else _DEFAULT_SKIP_DIRS
    found: set[str] = set()
    for glob in unit.sources:
        regex = glob_to_regex(glob)
        base = repo_root / _static_prefix(glob)
        if not base.is_dir():
            continue
        for path in _walk(base, skip):
            rel = path.relative_to(repo_root).as_posix()
            if not regex.match(rel) or exclusions.matches(rel):
                continue
            if unit.kind == "tools" and not _has_statements(path):
                continue  # coverage.py skip_empty drops these from the report.
            found.add(rel)
    return sorted(found)


def _static_prefix(glob: str) -> str:
    """The leading path segments of ``glob`` that hold no wildcard."""
    parts = []
    for part in glob.split("/")[:-1]:
        if any(c in part for c in "*?"):
            break
        parts.append(part)
    return "/".join(parts)


def _walk(base: Path, skip: set[str]) -> Iterable[Path]:
    for child in sorted(base.iterdir()):
        if child.is_symlink():
            continue
        if child.is_dir():
            if child.name in skip or child.name.endswith(".egg-info"):
                continue
            yield from _walk(child, skip)
        elif child.is_file():
            yield child


def _has_statements(path: Path) -> bool:
    """Whether a Python file has a statement besides its docstring."""
    try:
        body = ast.parse(path.read_text(encoding="utf-8")).body
    except SyntaxError:
        return True
    if body and isinstance(body[0], ast.Expr) and isinstance(getattr(body[0], "value", None), ast.Constant):
        body = body[1:]
    return bool(body)


_COMMENT_RE = re.compile(r"/\*.*?\*/|//[^\n]*", re.DOTALL)
_DART_DIRECTIVE_RE = re.compile(r"^(library|import|export|part)\b")
_TS_DECLARATION_RE = re.compile(
    r"^(export\s+)?(default\s+)?(declare\s|type\s|interface\s|import\s|export\s*[{*])"
)


def has_executable_code(path: Path) -> bool:
    """Whether a Dart or TypeScript file can produce coverage lines.

    Dart files holding only directives (barrels) and TypeScript files
    holding only imports, re-exports and type declarations produce no lines,
    so the Dart VM and istanbul leave them out of the report; they are not
    QA4 misses. Every other file (and any other language) counts.
    """
    suffix = path.suffix
    if suffix not in (".dart", ".ts"):
        return True
    text = _COMMENT_RE.sub("", path.read_text(encoding="utf-8", errors="replace"))
    statements = _top_level_statements(text)
    if suffix == ".dart":
        return any(not _DART_DIRECTIVE_RE.match(st) for st in statements)
    return any(not _TS_DECLARATION_RE.match(st) for st in statements)


def _top_level_statements(text: str) -> list[str]:
    """Splits source into top-level statements (``;`` or a closing ``}`` at depth 0)."""
    statements: list[str] = []
    current: list[str] = []
    depth = 0
    quote = ""
    for index, char in enumerate(text):
        current.append(char)
        if quote:
            if char == quote:
                quote = ""
            continue
        if char in "'\"`":
            quote = char
        elif char in "{([":
            depth += 1
        elif char in "})]":
            depth -= 1
            # `export { a } from './a';` continues after its brace.
            rest = text[index + 1 :].lstrip()
            if depth == 0 and char == "}" and not rest.startswith(("from", ";", ",", ")")):
                statements.append("".join(current))
                current = []
        elif char == ";" and depth == 0:
            statements.append("".join(current))
            current = []
    statements.append("".join(current))
    return [st.strip() for st in statements if st.strip() and st.strip() != ";"]


# --------------------------------------------------------------------------
# Evaluation
# --------------------------------------------------------------------------


@dataclass
class UnitResult:
    """Outcome of one unit."""

    name: str
    files: dict[str, FileCov] = field(default_factory=dict)
    failures: list[str] = field(default_factory=list)
    report_missing: bool = False
    branch_pct: float | None = None

    @property
    def found(self) -> int:
        return sum(f.found for f in self.files.values())

    @property
    def hit(self) -> int:
        return sum(f.hit for f in self.files.values())

    @property
    def pct(self) -> float:
        return 100.0 if self.found == 0 else 100.0 * self.hit / self.found

    @property
    def ok(self) -> bool:
        return not self.failures


def scan_pragmas(repo_root: Path, paths: Iterable[str]) -> list[str]:
    """``path:line`` of every banned coverage pragma (QA3)."""
    hits = []
    for rel in paths:
        try:
            text = (repo_root / rel).read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for number, line in enumerate(text.splitlines(), start=1):
            match = PRAGMA_RE.search(line)
            if match:
                hits.append(f"{rel}:{number}: {match.group(1)}")
    return hits


def read_unit_report(repo_root: Path, unit: Unit) -> tuple[dict[str, FileCov], float | None]:
    """Reads a unit's report(s). Raises ``FileNotFoundError`` when missing."""
    for rel in unit.reports:
        if not (repo_root / rel).is_file():
            raise FileNotFoundError(rel)
    first = (repo_root / unit.reports[0]).read_text(encoding="utf-8")
    if unit.kind == "tools":
        return parse_coverage_py_json(json.loads(first), repo_root, unit.lcov_base), None
    files = parse_lcov(first, repo_root, unit.lcov_base)
    branch_pct = None
    if unit.kind == "worker":
        summary = json.loads((repo_root / unit.reports[1]).read_text(encoding="utf-8"))
        branch_pct = float(summary.get("total", {}).get("branches", {}).get("pct", 0.0))
    return files, branch_pct


def evaluate_unit(
    repo_root: Path,
    unit: Unit,
    exclusions: Exclusions,
    unit_threshold: float = UNIT_THRESHOLD,
    file_threshold: float = FILE_THRESHOLD,
) -> UnitResult:
    """Applies QA1-QA4 (and QA7 branches for the Worker) to one unit."""
    result = UnitResult(unit.name)
    sources = list_sources(repo_root, unit, exclusions)
    for hit in scan_pragmas(repo_root, sources):
        result.failures.append(f"coverage pragma (QA3): {hit}")

    try:
        files, branch_pct = read_unit_report(repo_root, unit)
    except FileNotFoundError as missing:
        result.report_missing = True
        result.failures.insert(0, f"missing report: {missing.args[0]}")
        return result
    except (ValueError, KeyError) as error:
        result.report_missing = True
        result.failures.insert(0, f"unreadable report {unit.reports[0]}: {error}")
        return result

    result.files = {p: f for p, f in files.items() if not exclusions.matches(p)}
    result.branch_pct = branch_pct

    for rel in sources:
        if rel not in result.files and has_executable_code(repo_root / rel):
            result.failures.append(f"file missing from report (QA4): {rel}")
    if result.pct < unit_threshold:
        result.failures.append(f"unit line coverage {result.pct:.2f} % < {unit_threshold:.1f} % (QA1)")
    for path, cov in sorted(result.files.items()):
        if cov.pct < file_threshold:
            result.failures.append(f"file {path} {cov.pct:.2f} % < {file_threshold:.1f} % (QA2)")
    if branch_pct is not None and branch_pct < WORKER_BRANCH_THRESHOLD:
        result.failures.append(f"branch coverage {branch_pct:.2f} % < {WORKER_BRANCH_THRESHOLD:.1f} % (QA7)")
    return result


def parse_properties(text: str) -> dict[str, str]:
    """Minimal Java ``.properties`` reader (comments, ``=``/``:``, ``\\`` continuations)."""
    props: dict[str, str] = {}
    logical: list[str] = []
    pending = ""
    for raw in text.splitlines():
        line = raw.strip() if not pending else raw.lstrip()
        if not pending and (not line or line[0] in "#!"):
            continue
        if line.endswith("\\") and not line.endswith("\\\\"):
            pending += line[:-1]
            continue
        logical.append(pending + line)
        pending = ""
    if pending:
        logical.append(pending)
    for line in logical:
        match = re.match(r"([^=:\s]+)\s*[=:\s]\s*(.*)$", line)
        if match:
            props[match.group(1)] = match.group(2).strip()
    return props


def verify_sonar(repo_root: Path, exclusions: Exclusions) -> tuple[list[str], list[str]]:
    """Compares ``sonar.coverage.exclusions`` with the exclusion list.

    Returns ``(failures, notes)``. A missing properties file is a note, not a
    failure: Sprint 3.2 creates it.
    """
    path = repo_root / SONAR_PATH
    if not path.is_file():
        return [], [f"{SONAR_PATH} not found: Sonar exclusion drift not checked (--verify-sonar)."]
    props = parse_properties(path.read_text(encoding="utf-8"))
    if SONAR_KEY not in props:
        return [f"{SONAR_PATH} has no {SONAR_KEY}"], []
    sonar = [p.strip() for p in props[SONAR_KEY].split(",") if p.strip()]
    ours = set(exclusions.patterns)
    theirs = set(sonar)
    failures = []
    for pattern in sorted(ours - theirs):
        failures.append(f"Sonar drift: {pattern} is in {EXCLUSIONS_PATH} but not in {SONAR_KEY}")
    for pattern in sorted(theirs - ours):
        failures.append(f"Sonar drift: {pattern} is in {SONAR_KEY} but not in {EXCLUSIONS_PATH}")
    return failures, []


# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------


def render_merged_lcov(results: Sequence[UnitResult]) -> str:
    """One lcov tracefile of every unit with repo-relative ``SF:`` paths."""
    out = []
    for result in results:
        for path in sorted(result.files):
            cov = result.files[path]
            out.append(f"SF:{path}")
            for line in sorted(cov.lines):
                out.append(f"DA:{line},{cov.lines[line]}")
            out.append(f"LF:{cov.found}")
            out.append(f"LH:{cov.hit}")
            out.append("end_of_record")
    return "\n".join(out) + ("\n" if out else "")


def worst_files(results: Sequence[UnitResult], limit: int = WORST_FILES) -> list[tuple[str, FileCov]]:
    """The ``limit`` least-covered files (below 100 %) of the failing units."""
    candidates = [
        (r.name, f) for r in results if not r.ok for f in r.files.values() if f.pct < 100.0
    ]
    candidates.sort(key=lambda item: (item[1].pct, item[1].path))
    return candidates[:limit]


def _pct(result: UnitResult) -> str:
    return "n/a" if result.report_missing else f"{result.pct:.2f} %"


def render_summary(
    results: Sequence[UnitResult],
    global_failures: Sequence[str],
    notes: Sequence[str],
    unit_threshold: float,
) -> str:
    """Markdown summary: a table per unit, failures and the worst files."""
    passed = all(r.ok for r in results) and not global_failures
    lines = [
        "# Coverage",
        "",
        f"Gate: every unit >= {unit_threshold:.1f} % lines, every file >= {FILE_THRESHOLD:.1f} % "
        f"(06 QA1, QA2). Result: **{'PASS' if passed else 'FAIL'}**.",
        "",
        "| Unit | Files | Lines | Covered | Line % | Status |",
        "|---|---:|---:|---:|---:|---|",
    ]
    for r in results:
        status = "ok" if r.ok else f"FAIL ({len(r.failures)})"
        extra = f" (branches {r.branch_pct:.2f} %)" if r.branch_pct is not None else ""
        lines.append(f"| {r.name} | {len(r.files)} | {r.found} | {r.hit} | {_pct(r)}{extra} | {status} |")
    found = sum(r.found for r in results)
    hit = sum(r.hit for r in results)
    merged = 100.0 if found == 0 else 100.0 * hit / found
    lines += [
        f"| merged (reported, not gated) | {sum(len(r.files) for r in results)} | {found} | {hit} "
        f"| {merged:.2f} % | - |",
        "",
    ]
    failing = [r for r in results if not r.ok]
    if failing or global_failures:
        lines += ["## Failures", ""]
        for r in failing:
            lines += [f"- **{r.name}**: {f}" for f in r.failures]
        lines += [f"- {f}" for f in global_failures]
        lines.append("")
    worst = worst_files(results)
    if worst:
        lines += ["## Worst files", "", "| Unit | File | Lines | Line % |", "|---|---|---:|---:|"]
        lines += [f"| {u} | {f.path} | {f.hit}/{f.found} | {f.pct:.2f} % |" for u, f in worst]
        lines.append("")
    if notes:
        lines += ["## Notes", ""]
        lines += [f"- {n}" for n in notes]
        lines.append("")
    return "\n".join(lines)


def to_json(results: Sequence[UnitResult], global_failures: Sequence[str], notes: Sequence[str]) -> dict:
    """Machine-readable result for ``--json``."""
    return {
        "ok": all(r.ok for r in results) and not global_failures,
        "units": [
            {
                "name": r.name,
                "ok": r.ok,
                "report_missing": r.report_missing,
                "lines_found": r.found,
                "lines_hit": r.hit,
                "line_pct": None if r.report_missing else round(r.pct, 2),
                "branch_pct": r.branch_pct,
                "failures": r.failures,
                "files": {p: round(f.pct, 2) for p, f in sorted(r.files.items())},
            }
            for r in results
        ],
        "failures": list(global_failures),
        "notes": list(notes),
    }


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------


def run(
    repo_root: Path,
    unit_names: Sequence[str] | None = None,
    unit_threshold: float = UNIT_THRESHOLD,
    check_sonar: bool = False,
    emit: Callable[[str], None] = print,
    as_json: bool = False,
) -> int:
    """Evaluates the units and writes the outputs. Returns the exit code."""
    exclusions_file = repo_root / EXCLUSIONS_PATH
    if not exclusions_file.is_file():
        emit(f"check_coverage: {EXCLUSIONS_PATH} not found")
        return 2
    exclusions = Exclusions(parse_exclusions(exclusions_file.read_text(encoding="utf-8")))

    units = discover_units(repo_root)
    if unit_names:
        known = {u.name: u for u in units}
        unknown = [n for n in unit_names if n not in known]
        if unknown:
            emit(f"check_coverage: unknown unit(s): {', '.join(unknown)}; known: {', '.join(known)}")
            return 2
        units = [known[n] for n in unit_names]

    results = [evaluate_unit(repo_root, u, exclusions, unit_threshold) for u in units]
    global_failures: list[str] = []
    notes: list[str] = []
    if check_sonar:
        sonar_failures, sonar_notes = verify_sonar(repo_root, exclusions)
        global_failures += sonar_failures
        notes += sonar_notes

    merged = repo_root / MERGED_LCOV
    merged.parent.mkdir(parents=True, exist_ok=True)
    merged.write_text(render_merged_lcov(results), encoding="utf-8")
    summary = render_summary(results, global_failures, notes, unit_threshold)
    (repo_root / SUMMARY_MD).write_text(summary, encoding="utf-8")

    ok = all(r.ok for r in results) and not global_failures
    emit(json.dumps(to_json(results, global_failures, notes), indent=2) if as_json else summary)
    return 0 if ok else 1


def main(argv: Sequence[str] | None = None) -> int:
    """Command-line entry point."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--unit", action="append", help="check only this unit (repeatable)")
    parser.add_argument("--json", action="store_true", help="print the result as JSON")
    parser.add_argument(
        "--threshold",
        type=float,
        default=UNIT_THRESHOLD,
        help="unit line threshold (tests only; CI passes no value)",
    )
    parser.add_argument(
        "--verify-sonar",
        action="store_true",
        help=f"fail when {SONAR_PATH} {SONAR_KEY} differs from {EXCLUSIONS_PATH}",
    )
    parser.add_argument("--repo-root", type=Path, help="repository root (default: auto-detected)")
    args = parser.parse_args(argv)
    repo_root = args.repo_root or find_repo_root(Path(__file__))
    return run(
        repo_root,
        unit_names=args.unit,
        unit_threshold=args.threshold,
        check_sonar=args.verify_sonar,
        as_json=args.json,
    )


if __name__ == "__main__":
    sys.exit(main())

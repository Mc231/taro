#!/usr/bin/env python3
"""CHANGELOG gate (06 QA13, §10.2; Keep a Changelog 1.1.0).

Always validates the structure of the root ``CHANGELOG.md`` (app and packages)
and ``worker/CHANGELOG.md``: a ``## [Unreleased]`` section exists, every other
release heading is ``## [X.Y.Z] - YYYY-MM-DD`` with a real date, versions are
unique and newest first, and subsections are only Added, Changed, Deprecated,
Removed, Fixed and Security.

``--version X.Y.Z[+B]`` (deploy workflows): the file (``--worker`` selects
``worker/CHANGELOG.md``) must have a non-empty ``## [X.Y.Z] - YYYY-MM-DD``
section; the build number is ignored.

``--pr [<base>..<head>]`` / ``--range <base>..<head>`` (``ci`` on the pushed
range; default ``origin/main..HEAD``): a range that touches ``lib/`` or
``src/`` code must also change the matching CHANGELOG (``worker/src`` →
``worker/CHANGELOG.md``; ``apps/*/lib`` and ``packages/*/lib`` →
``CHANGELOG.md``), unless every commit in it is typed ``test``, ``docs``,
``refactor``, ``ci`` or ``chore``.
"""

from __future__ import annotations

import datetime as dt
import re
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

from taro_tools.checkkit import Finding, base_parser, resolve_root, run_check

NAME = "check_changelog"
APP_CHANGELOG = "CHANGELOG.md"
WORKER_CHANGELOG = "worker/CHANGELOG.md"
SUBSECTIONS = ("Added", "Changed", "Deprecated", "Removed", "Fixed", "Security")
EXEMPT_TYPES = ("test", "docs", "refactor", "ci", "chore")

_RELEASE = re.compile(r"^## \[(?P<name>[^\]]+)\](?P<rest>.*)$")
_VERSION = re.compile(r"^\d+\.\d+\.\d+$")
_DATED = re.compile(r"^ - (\d{4}-\d{2}-\d{2})$")
_SUBSECTION = re.compile(r"^### (.*?)\s*$")
_TYPE = re.compile(r"^(\w+)(\([^)]*\))?!?:")


@dataclass
class Release:
    """One ``## [...]`` section."""

    name: str
    line: int
    date: str | None
    body: list[str]

    def has_entries(self) -> bool:
        return any(line.strip().startswith(("-", "*")) for line in self.body)


def parse_releases(text: str) -> list[Release]:
    """Every ``## [...]`` section of a changelog, in file order."""
    releases: list[Release] = []
    for number, line in enumerate(text.splitlines(), start=1):
        match = _RELEASE.match(line)
        if match:
            dated = _DATED.match(match.group("rest"))
            releases.append(
                Release(match.group("name"), number, dated.group(1) if dated else None, [])
            )
        elif line.startswith("## "):
            releases.append(Release(line[3:].strip(), number, None, []))
        elif releases:
            releases[-1].body.append(line)
    return releases


def _valid_date(value: str) -> bool:
    try:
        dt.date.fromisoformat(value)
    except ValueError:
        return False
    return True


def _version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def check_structure(text: str, label: str) -> list[Finding]:
    """Keep a Changelog structure findings for one file."""
    findings: list[Finding] = []
    releases = parse_releases(text)
    names = [release.name for release in releases]
    if "Unreleased" not in names:
        findings.append(Finding(label, 0, "unreleased-missing", "no '## [Unreleased]' section"))
    elif names.index("Unreleased") != 0:
        findings.append(
            Finding(label, releases[names.index("Unreleased")].line, "unreleased-order",
                    "'## [Unreleased]' must be the first section")
        )
    seen: dict[str, int] = {}
    versions: list[tuple[str, int]] = []
    unreleased_seen = False
    for release in releases:
        if release.name == "Unreleased":
            if unreleased_seen:
                findings.append(Finding(label, release.line, "duplicate", "second '## [Unreleased]' section"))
            unreleased_seen = True
        elif not _VERSION.match(release.name) or release.date is None:
            findings.append(
                Finding(label, release.line, "heading",
                        f"release heading must be '## [X.Y.Z] - YYYY-MM-DD', got '## [{release.name}]…'")
            )
        elif not _valid_date(release.date):
            findings.append(Finding(label, release.line, "date", f"invalid date {release.date}"))
        else:
            if release.name in seen:
                findings.append(
                    Finding(label, release.line, "duplicate", f"version {release.name} already at line {seen[release.name]}")
                )
            seen[release.name] = release.line
            versions.append((release.name, release.line))
        for offset, line in enumerate(release.body, start=1):
            sub = _SUBSECTION.match(line)
            if sub and sub.group(1) not in SUBSECTIONS:
                findings.append(
                    Finding(label, release.line + offset, "subsection",
                            f"'### {sub.group(1)}' is not one of {', '.join(SUBSECTIONS)}")
                )
    for (newer, _), (older, line) in zip(versions, versions[1:], strict=False):
        if _version_key(newer) <= _version_key(older):
            findings.append(Finding(label, line, "order", f"{older} listed below {newer}; newest first"))
    return findings


def check_version(text: str, version: str, label: str) -> list[Finding]:
    """The shipped ``version`` (build suffix ignored) has a dated, non-empty section."""
    plain = version.split("+", 1)[0]
    if not _VERSION.match(plain):
        return [Finding(label, 0, "version", f"--version must be X.Y.Z[+B], got {version!r}")]
    for release in parse_releases(text):
        if release.name == plain:
            if release.date is None or not _valid_date(release.date):
                return [Finding(label, release.line, "heading", f"section for {plain} has no valid ' - YYYY-MM-DD' date")]
            if not release.has_entries():
                return [Finding(label, release.line, "empty", f"section for {plain} has no entries")]
            return []
    return [Finding(label, 0, "version-missing", f"no '## [{plain}] - YYYY-MM-DD' section for the version being shipped")]


def _is_app_code(path: str) -> bool:
    parts = path.split("/")
    return len(parts) > 3 and parts[0] in ("apps", "packages") and parts[2] == "lib"


def _is_worker_code(path: str) -> bool:
    return path.startswith("worker/src/")


def check_range(changed: Sequence[str], subjects: Sequence[str]) -> list[Finding]:
    """Code changes in a range need a CHANGELOG change, unless all commits are exempt."""
    types = [m.group(1) if (m := _TYPE.match(s)) else "" for s in subjects]
    if subjects and all(t in EXEMPT_TYPES for t in types):
        return []
    findings: list[Finding] = []
    changed_set = set(changed)
    app_code = sorted(p for p in changed if _is_app_code(p))
    worker_code = sorted(p for p in changed if _is_worker_code(p))
    if app_code and APP_CHANGELOG not in changed_set:
        findings.append(
            Finding(APP_CHANGELOG, 0, "not-updated",
                    f"range changes app/package code ({app_code[0]}, …) but not {APP_CHANGELOG} "
                    f"(allowed only when every commit is {'/'.join(EXEMPT_TYPES)})")
        )
    if worker_code and WORKER_CHANGELOG not in changed_set:
        findings.append(
            Finding(WORKER_CHANGELOG, 0, "not-updated",
                    f"range changes Worker code ({worker_code[0]}, …) but not {WORKER_CHANGELOG} "
                    f"(allowed only when every commit is {'/'.join(EXEMPT_TYPES)})")
        )
    return findings


def _git(root: Path, args: Sequence[str]) -> list[str]:
    out = subprocess.run(
        ["git", *args], cwd=root, check=True, capture_output=True, text=True
    ).stdout
    return [line for line in out.splitlines() if line.strip()]


def run(root: Path, *, version: str | None, worker: bool, rev_range: str | None) -> tuple[list[Finding], list[str]]:
    findings: list[Finding] = []
    notices: list[str] = []
    texts: dict[str, str] = {}
    for label in (APP_CHANGELOG, WORKER_CHANGELOG):
        path = root / label
        if path.is_file():
            texts[label] = path.read_text(encoding="utf-8")
            findings += check_structure(texts[label], label)
        elif label == APP_CHANGELOG:
            findings.append(Finding(label, 0, "missing", "file not found"))
        else:
            notices.append(f"{label} not present yet; skipped")
    if version is not None:
        label = WORKER_CHANGELOG if worker else APP_CHANGELOG
        if label in texts:
            findings += check_version(texts[label], version, label)
        elif label == WORKER_CHANGELOG:
            findings.append(Finding(label, 0, "missing", "file not found"))
    if rev_range is not None:
        try:
            changed = _git(root, ["diff", "--name-only", rev_range])
            subjects = _git(root, ["log", "--format=%s", rev_range])
        except (OSError, subprocess.CalledProcessError) as exc:
            detail = getattr(exc, "stderr", "") or str(exc)
            findings.append(Finding("git", 0, "range", f"cannot read {rev_range}: {detail.strip()}"))
        else:
            findings += check_range(changed, subjects)
            notices.append(f"range {rev_range}: {len(subjects)} commit(s), {len(changed)} file(s)")
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--version", help="version being shipped (X.Y.Z or X.Y.Z+B)")
    parser.add_argument("--worker", action="store_true", help="--version applies to worker/CHANGELOG.md")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--pr", nargs="?", const="origin/main..HEAD", default=None,
                      metavar="RANGE", help="PR/push range check (default origin/main..HEAD)")
    mode.add_argument("--range", dest="rev_range", metavar="RANGE", help="same as --pr RANGE")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    rev_range = args.rev_range or args.pr
    return run_check(NAME, lambda: run(root, version=args.version, worker=args.worker, rev_range=rev_range))


if __name__ == "__main__":
    sys.exit(main())

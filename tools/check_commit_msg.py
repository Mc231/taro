#!/usr/bin/env python3
"""Commit-message gate (06 QA12, §10.3).

Fails when the subject is not a conventional commit::

    ^(feat|fix|docs|test|refactor|perf|build|ci|chore|revert)(\\([a-z0-9_-]+\\))?!?: .{1,72}$

or when the message carries AI attribution: a ``Co-Authored-By:`` trailer
naming Claude, Anthropic or any other AI; a ``Generated with`` line; the words
``Claude Code``; a ``Claude-Session:`` trailer or a ``claude.ai/code`` link;
the robot emoji; or ``noreply@anthropic.com``. Talking about the product's AI
*feature* ("feat(reading): add AI consent screen") is allowed.

Git's own merge subjects (``Merge branch …``, ``Merge pull request …``,
``Merge remote-tracking branch …``) are accepted, since the pull-mirror can
contain them. ``fixup!``/``squash!`` subjects are rejected.

Usage::

    check_commit_msg.py <file>                # commit-msg hook (.git/COMMIT_EDITMSG)
    check_commit_msg.py --message "<text>"
    check_commit_msg.py --range <base>..<head>   # CI over a pushed range
    check_commit_msg.py --all                 # every commit reachable from HEAD
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

TYPES = ("feat", "fix", "docs", "test", "refactor", "perf", "build", "ci", "chore", "revert")

SUBJECT_RE = re.compile(
    r"^(" + "|".join(TYPES) + r")(\([a-z0-9_-]+\))?!?: .{1,72}$"
)
MERGE_RE = re.compile(r"^Merge (branch|pull request|remote-tracking branch|tag) ")

# Names that make a Co-Authored-By trailer an AI attribution.
_AI_NAMES = (
    r"claude|anthropic|openai|chatgpt|gpt(-?\d[\w.]*)?|copilot|gemini|bard|codex|"
    r"cursor|devin|aider|codeium|windsurf|tabnine|llm|ai|bot|assistant|agent"
)
_CO_AUTHOR = re.compile(
    r"^\s*co-authored-by:.*\b(" + _AI_NAMES + r")\b.*$", re.IGNORECASE | re.MULTILINE
)
_MARKERS: tuple[tuple[re.Pattern[str], str], ...] = (
    (_CO_AUTHOR, "Co-Authored-By trailer naming an AI"),
    (
        re.compile(r"^\W*generated with\b", re.IGNORECASE | re.MULTILINE),
        "'Generated with' attribution line",
    ),
    (
        re.compile(r"generated (with|by) \[?(" + _AI_NAMES + r")\b", re.IGNORECASE),
        "'Generated with/by <AI>' attribution",
    ),
    (re.compile(r"claude code", re.IGNORECASE), "'Claude Code' attribution"),
    (re.compile(r"^\s*claude-session:", re.IGNORECASE | re.MULTILINE), "Claude-Session trailer"),
    (re.compile(r"claude\.ai/code", re.IGNORECASE), "claude.ai/code link"),
    (re.compile("\U0001f916"), "robot emoji attribution marker"),
    (re.compile(r"noreply@anthropic\.com", re.IGNORECASE), "noreply@anthropic.com"),
)


@dataclass(frozen=True)
class Problem:
    """One reason a message is rejected."""

    commit: str
    message: str

    def render(self) -> str:
        return f"{self.commit}: {self.message}" if self.commit else self.message


def clean_message(raw: str) -> str:
    """Drop git comment lines and everything below the scissors line."""
    kept: list[str] = []
    for line in raw.splitlines():
        if line.startswith("# ------------------------ >8"):
            break
        if line.startswith("#"):
            continue
        kept.append(line.rstrip())
    return "\n".join(kept).strip("\n")


def check_message(raw: str, commit: str = "") -> list[Problem]:
    """All problems with one commit message (empty when it is acceptable)."""
    message = clean_message(raw)
    if not message.strip():
        return [Problem(commit, "empty commit message")]
    problems: list[Problem] = []
    subject = message.splitlines()[0]
    if not (SUBJECT_RE.match(subject) or MERGE_RE.match(subject)):
        problems.append(
            Problem(
                commit,
                f"subject is not a conventional commit (type(scope)?: summary, "
                f"≤ 72 chars after ': '): {subject!r}",
            )
        )
    for pattern, label in _MARKERS:
        match = pattern.search(message)
        if match:
            problems.append(Problem(commit, f"AI attribution is not allowed ({label}): {match.group(0).strip()!r}"))
    return problems


def _git(args: Sequence[str], cwd: Path | None) -> str:
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    ).stdout


def commits_in(rev_args: Sequence[str], cwd: Path | None = None) -> list[tuple[str, str]]:
    """``(short sha, message)`` for each commit selected by ``git log`` args."""
    out = _git(["log", "--format=%h%x1f%B%x1e", *rev_args], cwd)
    commits: list[tuple[str, str]] = []
    for record in out.split("\x1e"):
        record = record.strip("\n")
        if not record:
            continue
        sha, _, body = record.partition("\x1f")
        commits.append((sha, body))
    return commits


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="check_commit_msg", description=__doc__.splitlines()[0])
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("file", nargs="?", type=Path, help="commit message file (commit-msg hook)")
    group.add_argument("--message", help="check this message text")
    group.add_argument("--range", dest="rev_range", metavar="RANGE", help="check every commit in <base>..<head>")
    group.add_argument("--all", action="store_true", help="check every commit reachable from HEAD")
    parser.add_argument("--repo", type=Path, default=None, help="git repository (default: cwd)")
    args = parser.parse_args(argv)

    problems: list[Problem] = []
    checked = 0
    try:
        if args.file is not None:
            problems = check_message(args.file.read_text(encoding="utf-8"))
            checked = 1
        elif args.message is not None:
            problems = check_message(args.message)
            checked = 1
        else:
            rev = ["HEAD"] if args.all else [args.rev_range]
            for sha, body in commits_in(rev, args.repo):
                checked += 1
                problems.extend(check_message(body, sha))
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = getattr(exc, "stderr", "") or str(exc)
        print(f"check_commit_msg: cannot read commits: {detail.strip()}", file=sys.stderr)
        return 2

    for problem in problems:
        print(problem.render(), file=sys.stderr)
    if problems:
        print(f"check_commit_msg: FAILED ({len(problems)} problem(s) in {checked} message(s))", file=sys.stderr)
        return 1
    print(f"check_commit_msg: OK ({checked} message(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Every URL in aso.yaml and the ARB files is well-formed and returns 200.

05 CS10, §9.6. Collects ``http(s)://`` URLs from every string of
``apps/taro/store/aso.yaml`` and every ARB message. ``--offline`` (PRs)
checks the syntax only: ``https``, a dotted host, no placeholder text such as
``XXXX`` or ``<…>``. The default (weekly in ``nightly.yml``) also requests each
URL (HEAD, then GET when HEAD is refused) and fails unless the final response
after redirects is 200. Keys listed in ``SKIP_KEYS`` hold documentation-only
URLs that are not fetchable pages (the AdMob SSV callback, 05 §8.1).
"""

from __future__ import annotations

import re
import sys
import urllib.error
import urllib.request
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

from taro_tools.checkkit import (
    LOCALES,
    Finding,
    base_parser,
    resolve_root,
    run_check,
)
from taro_tools.store import ARB_DIR, ASO_PATH, arb_messages, arb_path, load_arb, load_aso

NAME = "check_urls"
SKIP_KEYS = frozenset({"ssv_callback_url"})
_URL = re.compile(r"https?://[^\s\"'<>()\[\]{}`]+")
_PLACEHOLDER = re.compile(r"XXXX|\.\.\.|<|>|%7B|%7D", re.IGNORECASE)
TIMEOUT = 15.0

Fetch = Callable[[str], int]


@dataclass(frozen=True)
class UrlRef:
    """A URL and where it was found."""

    url: str
    path: str
    where: str


def urls_in(text: str) -> list[str]:
    """URLs in ``text`` without trailing sentence punctuation."""
    return [m.group(0).rstrip(".,;:!?") for m in _URL.finditer(text)]


def _walk(value: Any, key: str) -> list[tuple[str, str]]:
    if isinstance(value, str):
        return [(key, value)]
    if isinstance(value, dict):
        return [pair for k, v in value.items() for pair in _walk(v, f"{key}.{k}" if key else str(k))]
    if isinstance(value, list):
        return [pair for i, v in enumerate(value) for pair in _walk(v, f"{key}[{i}]")]
    return []


def collect(aso: Mapping[str, Any] | None, arbs: Mapping[str, Mapping[str, Any]]) -> list[UrlRef]:
    """Every URL reference in the inputs (skip-listed keys excluded)."""
    refs: list[UrlRef] = []
    if aso is not None:
        for key, text in _walk(aso, ""):
            leaf = re.sub(r"(\[\d+\])+$", "", key).rsplit(".", 1)[-1]
            if leaf in SKIP_KEYS:
                continue
            refs += [UrlRef(url, ASO_PATH, key) for url in urls_in(text)]
    for locale, arb in arbs.items():
        for key, text in arb_messages(arb).items():
            refs += [UrlRef(url, arb_path(locale), key) for url in urls_in(text)]
    return refs


def syntax_problem(url: str) -> str | None:
    """Why ``url`` is not a publishable URL, or ``None``."""
    parts = urlsplit(url)
    if parts.scheme != "https":
        return "must use https"
    host = parts.hostname or ""
    if "." not in host or host.startswith(".") or host.endswith("."):
        return f"host {host!r} is not a public domain"
    if _PLACEHOLDER.search(url):
        return "contains placeholder text"
    return None


def _status(url: str, method: str) -> int:
    request = urllib.request.Request(url, method=method, headers={"User-Agent": "taro-check-urls/1"})
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:  # noqa: S310 - https only
        return int(response.status)


def default_fetch(url: str) -> int:
    """HTTP status after redirects (HEAD, falling back to GET when refused)."""
    try:
        return _status(url, "HEAD")
    except urllib.error.HTTPError as exc:
        if exc.code not in (403, 405, 501):
            return int(exc.code)
    try:
        return _status(url, "GET")
    except urllib.error.HTTPError as exc:
        return int(exc.code)


def check_refs(refs: Sequence[UrlRef], offline: bool, fetch: Fetch) -> list[Finding]:
    """Syntax findings, plus one fetch per distinct URL unless offline."""
    findings: list[Finding] = []
    fetched: dict[str, str | None] = {}
    for ref in refs:
        problem = syntax_problem(ref.url)
        if problem is None and not offline:
            if ref.url not in fetched:
                try:
                    status = fetch(ref.url)
                    fetched[ref.url] = None if status == 200 else f"returned HTTP {status}"
                except (urllib.error.URLError, OSError, ValueError) as exc:
                    fetched[ref.url] = f"request failed: {exc}"
            problem = fetched[ref.url]
        if problem:
            findings.append(Finding(ref.path, 0, "url", f"{ref.where}: {ref.url} {problem}"))
    return findings


def check(root: Path, offline: bool, fetch: Fetch = default_fetch) -> tuple[list[Finding], list[str]]:
    """Findings and notices for the repository at ``root``."""
    notices: list[str] = []
    aso = load_aso(root)
    if aso is None:
        notices.append(f"{ASO_PATH} not present yet; its URLs not checked")
    arbs: dict[str, dict[str, Any]] = {}
    if (root / ARB_DIR).is_dir():
        for locale in LOCALES:
            path = root / arb_path(locale)
            if path.is_file():
                arbs[locale] = load_arb(path, arb_path(locale))
    else:
        notices.append(f"{ARB_DIR} not present yet; ARB URLs not checked")
    refs = collect(aso, arbs)
    distinct = len({r.url for r in refs})
    mode = "offline (syntax only)" if offline else "online"
    notices.append(f"{distinct} distinct URL(s) found; mode {mode}")
    return check_refs(refs, offline, fetch), notices


def main(argv: Sequence[str] | None = None, fetch: Fetch = default_fetch) -> int:
    """CLI entry point."""
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--offline", action="store_true", help="check syntax only (no network)")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: check(root, args.offline, fetch))


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Install-size report: iOS download <= 60 MB, Android per-ABI <= 40 MB.

01 §16 / 02 §17 (Phase 18 Sprint 18.1), run by ``nightly.yml``. Estimates
from the release build outputs, 1 MB = 1,000,000 bytes:

* **iOS**: the compressed size of the ``.ipa`` (``--ipa``; default the first
  ``apps/taro/build/ios/ipa/*.ipa``). Without an ``.ipa`` the
  ``Runner.app`` of ``flutter build ios --no-codesign``
  (``apps/taro/build/ios/iphoneos/Runner.app``) is deflated in memory. App
  Store thinning makes the real download smaller, so this is an upper bound.
* **Android**: per ABI of the ``.aab`` (``--aab``; default the first
  ``apps/taro/build/app/outputs/bundle/*/*.aab``): the compressed size of
  every entry except ``META-INF/``, ``BUNDLE-METADATA/`` and the native
  libraries of the other ABIs (the per-ABI split Play serves).

A missing build is skipped with a note (``--require`` makes it a finding).
``--report FILE`` appends a Markdown table (for ``$GITHUB_STEP_SUMMARY``).
"""

from __future__ import annotations

import sys
import zipfile
import zlib
from collections.abc import Sequence
from pathlib import Path

from taro_tools.checkkit import Finding, InputError, base_parser, rel, resolve_root, run_check

NAME = "check_install_size"
IOS_MAX_MB = 60.0
ANDROID_MAX_MB = 40.0
MB = 1_000_000
IPA_GLOB = "apps/taro/build/ios/ipa/*.ipa"
APP_DIR = "apps/taro/build/ios/iphoneos/Runner.app"
AAB_GLOB = "apps/taro/build/app/outputs/bundle/*/*.aab"
_SKIP_PREFIXES = ("META-INF/", "BUNDLE-METADATA/")

Row = tuple[str, str, int, float]  # platform, variant, bytes, limit MB


def _first(root: Path, pattern: str) -> Path | None:
    found = sorted(root.glob(pattern))
    return found[0] if found else None


def _abi_of(name: str) -> str | None:
    """The ABI of a ``<module>/lib/<abi>/...`` entry, else ``None``."""
    parts = name.split("/")
    if len(parts) >= 4 and parts[1] == "lib":
        return parts[2]
    return None


def aab_split_sizes(path: Path) -> dict[str, int]:
    """Estimated download bytes per ABI (``universal`` without native code)."""
    try:
        with zipfile.ZipFile(path) as bundle:
            infos = [i for i in bundle.infolist() if not i.is_dir()]
    except (zipfile.BadZipFile, OSError) as exc:
        raise InputError(str(path), f"not a readable bundle ({exc})") from exc
    infos = [i for i in infos if not i.filename.startswith(_SKIP_PREFIXES)]
    abis = sorted({abi for i in infos if (abi := _abi_of(i.filename))})
    if not abis:
        return {"universal": sum(i.compress_size for i in infos)}
    return {
        abi: sum(i.compress_size for i in infos if _abi_of(i.filename) in (None, abi))
        for abi in abis
    }


def ipa_size(path: Path) -> int:
    """Compressed bytes of an ``.ipa``."""
    try:
        with zipfile.ZipFile(path) as ipa:
            return sum(i.compress_size for i in ipa.infolist())
    except (zipfile.BadZipFile, OSError) as exc:
        raise InputError(str(path), f"not a readable ipa ({exc})") from exc


def app_dir_size(path: Path) -> int:
    """Deflated bytes of every file under an ``.app`` folder."""
    return sum(
        len(zlib.compress(f.read_bytes(), 6)) for f in sorted(path.rglob("*")) if f.is_file()
    )


def measure(
    root: Path, ipa: Path | None, aab: Path | None, require: bool
) -> tuple[list[Row], list[Finding], list[str]]:
    """Sizes of the builds found, plus missing-build findings or notices."""
    rows: list[Row] = []
    findings: list[Finding] = []
    notices: list[str] = []

    def missing(platform: str, what: str) -> None:
        if require:
            findings.append(Finding(what, 0, "missing", f"no {platform} release build"))
        else:
            notices.append(f"no {platform} release build ({what}); skipped")

    ios = ipa or _first(root, IPA_GLOB)
    if ios is not None:
        rows.append(("iOS", rel(root, ios), ipa_size(ios), IOS_MAX_MB))
    elif (root / APP_DIR).is_dir():
        rows.append(("iOS", f"{APP_DIR} (deflated)", app_dir_size(root / APP_DIR), IOS_MAX_MB))
    else:
        missing("iOS", f"{IPA_GLOB} or {APP_DIR}")

    android = aab or _first(root, AAB_GLOB)
    if android is not None:
        for abi, size in aab_split_sizes(android).items():
            rows.append(("Android", abi, size, ANDROID_MAX_MB))
    else:
        missing("Android", AAB_GLOB)
    return rows, findings, notices


def report(rows: Sequence[Row]) -> str:
    """The Markdown table of [rows]."""
    lines = [
        "### Install size (01 §16, 02 §17)",
        "",
        "| Platform | Build | Size (MB) | Limit (MB) | |",
        "|---|---|---|---|---|",
    ]
    for platform, variant, size, limit in rows:
        ok = "ok" if size <= limit * MB else "**over**"
        lines.append(f"| {platform} | {variant} | {size / MB:.2f} | {limit:g} | {ok} |")
    if not rows:
        lines.append("| - | no release build | - | - | skipped |")
    return "\n".join(lines) + "\n"


def run(
    root: Path,
    *,
    ipa: Path | None = None,
    aab: Path | None = None,
    require: bool = False,
    report_path: Path | None = None,
) -> tuple[list[Finding], list[str]]:
    rows, findings, notices = measure(root, ipa, aab, require)
    for platform, variant, size, limit in rows:
        notices.append(f"{platform} {variant}: {size / MB:.2f} MB (limit {limit:g} MB)")
        if size > limit * MB:
            findings.append(
                Finding(variant, 0, "over-budget", f"{platform} {size / MB:.2f} MB > {limit:g} MB")
            )
    if report_path is not None:
        with report_path.open("a", encoding="utf-8") as out:
            out.write(report(rows))
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--ipa", type=Path, default=None, help="the .ipa to measure")
    parser.add_argument("--aab", type=Path, default=None, help="the .aab to measure")
    parser.add_argument("--require", action="store_true", help="fail when a build is missing")
    parser.add_argument("--report", type=Path, default=None, help="append a Markdown table here")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(
        NAME,
        lambda: run(root, ipa=args.ipa, aab=args.aab, require=args.require, report_path=args.report),
    )


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Converts a JaCoCo XML report to lcov (06 §5.2; RC40, unit ``taro_attestation_android``).

JaCoCo lists ``<package name="com/x"><sourcefile name="A.kt"><line nr=".."
mi=".." ci=".." mb=".." cb=".."/>``. A line is covered when it has at least
one covered instruction (``ci > 0``). Source files are located under the
``--source-root`` directories (first match wins) and written repo-relative.
"""

from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from collections.abc import Sequence
from pathlib import Path

from taro_tools import find_repo_root


def _locate(package: str, name: str, source_roots: Sequence[str], repo_root: Path) -> str:
    candidates = [f"{root.rstrip('/')}/{package}/{name}".replace("//", "/") for root in source_roots]
    for candidate in candidates:
        if (repo_root / candidate).is_file():
            return candidate
    return candidates[0] if candidates else f"{package}/{name}"


def convert(xml_text: str, source_roots: Sequence[str], repo_root: Path) -> str:
    """Builds the lcov text from JaCoCo XML."""
    root = ET.fromstring(xml_text)
    if root.tag != "report":
        raise ValueError(f"not a JaCoCo report (root <{root.tag}>)")
    out: list[str] = []
    for package in root.iter("package"):
        package_name = package.get("name", "")
        for source in package.findall("sourcefile"):
            path = _locate(package_name, source.get("name", ""), source_roots, repo_root)
            lines = []
            branches = []
            for line in source.findall("line"):
                number = int(line.get("nr", "0"))
                covered = int(line.get("ci", "0"))
                lines.append((number, 1 if covered > 0 else 0))
                mb, cb = int(line.get("mb", "0")), int(line.get("cb", "0"))
                if mb + cb:
                    branches.append((number, mb, cb))
            out.append("TN:")
            out.append(f"SF:{path}")
            for number, mb, cb in branches:
                for index in range(cb + mb):
                    taken = "1" if index < cb else "0"
                    out.append(f"BRDA:{number},0,{index},{taken}")
            if branches:
                out.append(f"BRF:{sum(mb + cb for _, mb, cb in branches)}")
                out.append(f"BRH:{sum(cb for _, _, cb in branches)}")
            for number, hits in lines:
                out.append(f"DA:{number},{hits}")
            out.append(f"LF:{len(lines)}")
            out.append(f"LH:{sum(1 for _, h in lines if h)}")
            out.append("end_of_record")
    return "\n".join(out) + ("\n" if out else "")


def main(argv: Sequence[str] | None = None) -> int:
    """Command-line entry point."""
    parser = argparse.ArgumentParser(description="JaCoCo XML -> lcov")
    parser.add_argument("report", type=Path, help="jacoco.xml")
    parser.add_argument(
        "--source-root",
        action="append",
        default=[],
        help="repo-relative source root holding the package directories (repeatable)",
    )
    parser.add_argument("--repo-root", type=Path, help="repository root (default: auto-detected)")
    parser.add_argument("-o", "--output", type=Path, required=True, help="lcov file to write")
    args = parser.parse_args(argv)
    repo_root = args.repo_root or find_repo_root(Path(__file__))
    try:
        text = convert(args.report.read_text(encoding="utf-8"), args.source_root, repo_root)
    except (OSError, ValueError, ET.ParseError) as error:
        print(f"jacoco_to_lcov: {error}", file=sys.stderr)
        return 1
    if not text:
        print("jacoco_to_lcov: the report has no source files", file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"jacoco_to_lcov: wrote {args.output} ({text.count('end_of_record')} file(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Ban non-deterministic, SDK, non-directional and raw visual APIs in ``lib/``.

06 §6.2 / QA9 / RC41 / RC90 / 02 §11. Scans ``apps/taro/lib`` and every
``packages/*/lib`` (generated files excluded) and reports ``file:line``:

* ``DateTime.now(``, ``Random(``, ``Random.secure(``, ``Uuid().v4(``,
  ``print(``, ``debugPrint(`` outside the adapter files listed under
  ``api_allowlist`` in ``tools/import_rules.yaml``;
* ``package:<sdk>/`` imports outside the adapter directories of
  ``sdk_packages`` in ``tools/import_rules.yaml``;
* non-directional layout APIs (``EdgeInsets.only(left:/right:``,
  ``Alignment.*Left/Right``, ``TextAlign.left/right``, ``Positioned(left:``);
* raw visual values (``Color(0x``, ``fontSize:``, ``Duration(milliseconds:``)
  in UI code only (RC90);
* test support (``test/fakes/``, ``test/contracts/``, ``test/helpers/``)
  imported from ``lib/``.

Comments and string contents are ignored (interpolated code is scanned).
"""

from __future__ import annotations

import fnmatch
import posixpath
import re
import sys
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from taro_tools.checkkit import (
    Finding,
    InputError,
    base_parser,
    glob_match,
    line_of,
    load_yaml,
    mask_dart,
    rel,
    resolve_root,
    run_check,
)

NAME = "check_forbidden_apis"
RULES_PATH = "tools/import_rules.yaml"

SCAN_ROOTS = ("apps/taro/lib", "packages/*/lib")

# Generated code (06 §6.1 analyzer excludes).
GENERATED = (
    "**/*.g.dart",
    "**/*.freezed.dart",
    "**/*.gen.dart",
    "apps/taro/lib/l10n/generated/**",
    "**/lib/src/tokens/generated/**",
    "**/firebase_options_*.dart",
)

# UI code for the raw-visual-value rule (06 §6.2, RC90).
UI_SCOPE = (
    "packages/taro_ui/lib/**",
    "apps/taro/lib/features/**/view/**",
    "apps/taro/lib/common/**",
)
UI_SCOPE_EXCEPT = (
    "packages/taro_ui/lib/src/tokens/**",
    "packages/taro_ui/lib/src/motion/**",
)

CALL_RULES: tuple[tuple[str, re.Pattern[str], str], ...] = (
    ("datetime_now", re.compile(r"(?<![\w$])DateTime\s*\.\s*now\s*\("), "DateTime.now( — use the Clock port"),
    ("random_secure", re.compile(r"(?<![\w$])Random\s*\.\s*secure\s*\("), "Random.secure( — use the RandomSource port"),
    ("random", re.compile(r"(?<![\w$])Random\s*\("), "Random( — use the RandomSource port"),
    ("uuid_v4", re.compile(r"(?<![\w$])Uuid\s*\(\s*\)\s*\.\s*v4\s*\("), "Uuid().v4( — use the IdGenerator port"),
    ("print", re.compile(r"(?<![\w$.])print\s*\("), "print( — use the Logger port"),
    ("debug_print", re.compile(r"(?<![\w$.])debugPrint\s*\("), "debugPrint( — use the Logger port"),
)

DIRECTIONAL_SIMPLE: tuple[tuple[re.Pattern[str], str], ...] = (
    (
        re.compile(r"(?<![\w$])Alignment\s*\.\s*(?:top|center|bottom)(?:Left|Right)\b"),
        "Alignment.*Left/Right — use AlignmentDirectional",
    ),
    (
        re.compile(r"(?<![\w$])TextAlign\s*\.\s*(?:left|right)\b"),
        "TextAlign.left/right — use TextAlign.start/end",
    ),
)
DIRECTIONAL_CALLS: tuple[tuple[re.Pattern[str], str], ...] = (
    (
        re.compile(r"(?<![\w$])EdgeInsets\s*\.\s*only\s*\("),
        "EdgeInsets.only(left:/right: — use EdgeInsetsDirectional.only(start:/end:",
    ),
    (
        re.compile(r"(?<![\w$.])Positioned(?:\s*\.\s*fill)?\s*\("),
        "Positioned(left:/right: — use PositionedDirectional(start:/end:",
    ),
)
_LEFT_RIGHT_ARG = re.compile(r"(?<![\w$])(?:left|right)\s*:")

RAW_VISUAL: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"(?<![\w$])Color\s*\(\s*0x"), "Color(0x — use a design token"),
    (re.compile(r"(?<![\w$])fontSize\s*:"), "fontSize: — use a token text style"),
    (
        re.compile(r"(?<![\w$])Duration\s*\(\s*milliseconds\s*:"),
        "Duration(milliseconds: — use TaroMotion / a named constant",
    ),
)

_DIRECTIVE = re.compile(r"^[ \t]*(?:import|export)\b[^;]*;", re.MULTILINE)
_URI = re.compile(r"""(['"])([^'"\n]+)\1""")
_TEST_SUPPORT = re.compile(r"(?:^|/)test/(?:fakes|contracts|helpers)/")


@dataclass(frozen=True)
class SdkRule:
    """Where ``package:<package>/`` may be imported."""

    package: str
    allowed: tuple[str, ...]


@dataclass(frozen=True)
class Rules:
    """The parsed ``tools/import_rules.yaml``."""

    sdk: tuple[SdkRule, ...]
    api_allowlist: Mapping[str, tuple[str, ...]]

    def sdk_rule(self, package: str) -> SdkRule | None:
        """The exact rule for ``package``, else the first matching glob rule."""
        for rule in self.sdk:
            if rule.package == package:
                return rule
        for rule in self.sdk:
            if any(c in rule.package for c in "*?[") and fnmatch.fnmatchcase(package, rule.package):
                return rule
        return None


def _str_list(value: Any, where: str) -> tuple[str, ...]:
    if not isinstance(value, list) or not all(isinstance(v, str) for v in value):
        raise InputError(RULES_PATH, f"{where} must be a list of strings")
    return tuple(value)


def parse_rules(data: Any) -> Rules:
    """Validate the shape of ``import_rules.yaml``."""
    if not isinstance(data, dict):
        raise InputError(RULES_PATH, "top level must be a mapping")
    packages = data.get("sdk_packages")
    if not isinstance(packages, list) or not packages:
        raise InputError(RULES_PATH, "sdk_packages must be a non-empty list")
    sdk: list[SdkRule] = []
    for index, item in enumerate(packages):
        where = f"sdk_packages[{index}]"
        if not isinstance(item, dict) or not isinstance(item.get("package"), str):
            raise InputError(RULES_PATH, f"{where} needs a string `package`")
        sdk.append(SdkRule(item["package"], _str_list(item.get("allowed"), f"{where}.allowed")))
    allow = data.get("api_allowlist", {})
    if not isinstance(allow, dict):
        raise InputError(RULES_PATH, "api_allowlist must be a mapping")
    known = {rule_id for rule_id, _, _ in CALL_RULES}
    api: dict[str, tuple[str, ...]] = {}
    for key, value in allow.items():
        if key not in known:
            raise InputError(RULES_PATH, f"api_allowlist has unknown rule {key!r}")
        api[key] = _str_list(value, f"api_allowlist.{key}")
    return Rules(tuple(sdk), api)


def load_rules(root: Path) -> Rules:
    """Read and validate the rules file (it must exist)."""
    path = root / RULES_PATH
    if not path.is_file():
        raise InputError(RULES_PATH, "missing (the check cannot run without it)")
    return parse_rules(load_yaml(path, RULES_PATH))


def _top_level_args(code: str, open_idx: int) -> str:
    """The text between ``(`` at ``open_idx`` and its ``)``, nested parts blanked."""
    depth = 0
    out: list[str] = []
    for k in range(open_idx, len(code)):
        char = code[k]
        if char in "([{":
            depth += 1
            if depth == 1:
                continue
        elif char in ")]}":
            depth -= 1
            if depth == 0:
                break
        out.append(char if depth == 1 else " ")
    return "".join(out)


def _imports(source: str) -> list[tuple[int, str]]:
    """``(offset, uri)`` for every URI in an import/export directive."""
    code = mask_dart(source, mask_strings=False)
    found: list[tuple[int, str]] = []
    for directive in _DIRECTIVE.finditer(code):
        for uri in _URI.finditer(code, directive.start(), directive.end()):
            found.append((uri.start(), uri.group(2)))
    return found


def check_source(path: str, source: str, rules: Rules) -> list[Finding]:
    """All findings for one Dart file at repository path ``path``."""
    findings: list[Finding] = []
    code = mask_dart(source)

    def add(offset: int, rule: str, message: str) -> None:
        findings.append(Finding(path, line_of(source, offset), rule, message))

    for rule_id, pattern, message in CALL_RULES:
        if glob_match(path, rules.api_allowlist.get(rule_id, ())):
            continue
        for match in pattern.finditer(code):
            add(match.start(), rule_id, message)

    for offset, uri in _imports(source):
        if uri.startswith("package:"):
            package = uri[len("package:"):].split("/", 1)[0]
            rule = rules.sdk_rule(package)
            if rule is not None and not glob_match(path, rule.allowed):
                where = ", ".join(rule.allowed) or "nowhere"
                add(offset, "sdk_import", f"package:{package} is allowed only in {where}")
            target = uri
        elif uri.startswith("dart:"):
            continue
        else:
            target = posixpath.normpath(posixpath.join(posixpath.dirname(path), uri))
        if _TEST_SUPPORT.search(target):
            add(offset, "test_support_import", f"lib/ imports test support {uri!r}")

    for pattern, message in DIRECTIONAL_SIMPLE:
        for match in pattern.finditer(code):
            add(match.start(), "non_directional", message)
    for pattern, message in DIRECTIONAL_CALLS:
        for match in pattern.finditer(code):
            if _LEFT_RIGHT_ARG.search(_top_level_args(code, match.end() - 1)):
                add(match.start(), "non_directional", message)

    if glob_match(path, UI_SCOPE) and not glob_match(path, UI_SCOPE_EXCEPT):
        for pattern, message in RAW_VISUAL:
            for match in pattern.finditer(code):
                add(match.start(), "raw_visual_value", message)
    return findings


def dart_files(root: Path) -> list[Path]:
    """Non-generated ``.dart`` files under the scan roots."""
    files: set[Path] = set()
    for pattern in SCAN_ROOTS:
        for lib in root.glob(pattern):
            if lib.is_dir():
                files.update(p for p in lib.rglob("*.dart") if p.is_file())
    return sorted(p for p in files if not glob_match(rel(root, p), GENERATED))


def check(root: Path) -> tuple[list[Finding], list[str]]:
    """Findings and notices for the repository at ``root``."""
    rules = load_rules(root)
    files = dart_files(root)
    notices: list[str] = []
    if not files:
        notices.append("no Dart lib/ files present yet; nothing to scan")
    findings: list[Finding] = []
    for file in files:
        findings += check_source(rel(root, file), file.read_text(encoding="utf-8"), rules)
    return findings, notices


def main(argv: Sequence[str] | None = None) -> int:
    """CLI entry point."""
    parser = base_parser(NAME, __doc__.splitlines()[0])
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: check(root))


if __name__ == "__main__":
    sys.exit(main())

"""Tests for taro_tools/checkkit.py (shared plumbing of the repo checks)."""

from __future__ import annotations

import io
from pathlib import Path

import pytest

from taro_tools.checkkit import (
    Finding,
    InputError,
    emit,
    glob_match,
    line_of,
    load_json,
    load_yaml,
    mask_dart,
    rel,
    resolve_root,
    run_check,
)
from fixture_tree import REPO


def test_finding_render() -> None:
    assert Finding("a.dart", 3, "rule", "msg").render() == "a.dart:3: [rule] msg"
    assert Finding("a.yaml", 0, "rule", "msg").render() == "a.yaml: [rule] msg"


def test_rel_inside_and_outside(tmp_path: Path) -> None:
    assert rel(tmp_path, tmp_path / "a" / "b.txt") == "a/b.txt"
    assert rel(tmp_path / "x", Path("/elsewhere/file")) == "/elsewhere/file"


def test_loaders_reject_bad_input(tmp_path: Path) -> None:
    binary = tmp_path / "bin.yaml"
    binary.write_bytes(b"\xff\xfe\x00")
    with pytest.raises(InputError, match="not UTF-8"):
        load_yaml(binary)
    with pytest.raises(InputError, match="not UTF-8"):
        load_json(binary)
    dup = tmp_path / "dup.yaml"
    dup.write_text("a: 1\na: 2\n")
    with pytest.raises(InputError, match="invalid YAML"):
        load_yaml(dup, "dup.yaml")
    bad = tmp_path / "bad.json"
    bad.write_text("{")
    with pytest.raises(InputError, match="invalid JSON"):
        load_json(bad)


@pytest.mark.parametrize(
    ("path", "patterns", "expected"),
    [
        ("apps/taro/lib/services/ads/x.dart", ["apps/taro/lib/services/ads/**"], True),
        ("apps/taro/lib/services/x.dart", ["apps/taro/lib/services/**/x.dart"], True),
        ("apps/taro/lib/features/a/view/b/c.dart", ["apps/taro/lib/features/**/view/**"], True),
        ("apps/taro/lib/features/a/controller/c.dart", ["apps/taro/lib/features/**/view/**"], False),
        ("a/b.g.dart", ["**/*.g.dart"], True),
        ("a/b.dart", ["a/?.dart"], True),
        ("a/bc.dart", ["a/?.dart"], False),
        ("a/b/c.dart", ["a/*.dart"], False),
    ],
)
def test_glob_match(path: str, patterns: list[str], expected: bool) -> None:
    assert glob_match(path, patterns) is expected


def test_line_of() -> None:
    assert line_of("a\nb\nc", 0) == 1
    assert line_of("a\nb\nc", 4) == 3


def test_mask_dart_blanks_comments_and_strings() -> None:
    source = "a('x\\'y'); // c\n/* b /* n */ */ r'\\n' \"\"\"t\nu\"\"\" '${f(1)} \\$g'\n"
    masked = mask_dart(source)
    assert len(masked) == len(source)
    assert masked.count("\n") == source.count("\n")
    assert "c" not in masked.split("\n")[0].split(";")[1]
    assert "f(1)" in masked
    assert "t" not in masked.split("\n")[1] and "u" not in masked.split("\n")[2].split("'")[0]


def test_mask_dart_keeps_strings_when_asked() -> None:
    assert mask_dart("x('hi'); // no", mask_strings=False) == "x('hi');      "


def test_mask_dart_recovers_from_unterminated_string() -> None:
    masked = mask_dart("a = 'open\nprint(1);\n")
    assert "print(1);" in masked


def test_mask_dart_braces_in_code() -> None:
    source = "void f() { if (x) { y(); } }\n'${ {1: 2}[1] }'"
    assert mask_dart(source).startswith("void f() { if (x) { y(); } }")
    assert "{1: 2}[1]" in mask_dart(source)


def test_emit_and_run_check() -> None:
    out = io.StringIO()
    assert emit("x", [Finding("p", 1, "r", "m")], ["n"], out) == 1
    text = out.getvalue()
    assert "x: note: n" in text and "p:1: [r] m" in text and "FAILED (1 finding(s))" in text
    out = io.StringIO()
    assert emit("x", [], [], out) == 0 and "x: OK" in out.getvalue()


def test_run_check_reports_malformed(capsys: pytest.CaptureFixture[str]) -> None:
    def body() -> tuple[list[Finding], list[str]]:
        raise InputError("f.yaml", "broken")

    assert run_check("x", body) == 1
    assert "malformed input: f.yaml: broken" in capsys.readouterr().out
    assert run_check("x", lambda: ([], [])) == 0


def test_resolve_root(tmp_path: Path) -> None:
    assert resolve_root(tmp_path, __file__) == tmp_path.resolve()
    assert resolve_root(None, __file__) == REPO

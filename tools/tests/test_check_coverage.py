"""Tests for tools/check_coverage.py (06 §5.1, Testing strategy).

The fixture repo ``fixtures/check_coverage/pass`` passes; each
``fail_*`` directory is an overlay copied on top of it that reproduces one
failure mode.
"""

from __future__ import annotations

import json
import runpy
import shutil
import sys
from pathlib import Path

import pytest

import check_coverage as cc

FIXTURES = Path(__file__).parent / "fixtures" / "check_coverage"
TOOLS = Path(__file__).resolve().parents[1]


def make_repo(tmp_path: Path, *overlays: str) -> Path:
    repo = tmp_path / "repo"
    shutil.copytree(FIXTURES / "pass", repo)
    for overlay in overlays:
        shutil.copytree(FIXTURES / overlay, repo, dirs_exist_ok=True)
    return repo


def run(repo: Path, *args: str) -> tuple[int, str]:
    lines: list[str] = []
    code = cc.run(repo, emit=lines.append, **_kwargs(args))
    return code, "\n".join(lines)


def _kwargs(args: tuple[str, ...]) -> dict:
    kwargs: dict = {}
    if "--verify-sonar" in args:
        kwargs["check_sonar"] = True
    if "--json" in args:
        kwargs["as_json"] = True
    return kwargs


def result_of(repo: Path, unit: str) -> cc.UnitResult:
    exclusions = cc.Exclusions(
        cc.parse_exclusions((repo / cc.EXCLUSIONS_PATH).read_text(encoding="utf-8"))
    )
    units = {u.name: u for u in cc.discover_units(repo)}
    return cc.evaluate_unit(repo, units[unit], exclusions)


# --------------------------------------------------------------------------
# Globs, exclusions, parsers
# --------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("glob", "path", "expected"),
    [
        ("**/test/**", "test/a.dart", True),
        ("**/test/**", "packages/x/test/a/b.dart", True),
        ("**/test/**", "packages/x/lib/contest/a.dart", False),
        ("**/*.g.dart", "a.g.dart", True),
        ("**/*.g.dart", "lib/src/a.g.dart", True),
        ("apps/taro/lib/main_*.dart", "apps/taro/lib/main_dev.dart", True),
        ("apps/taro/lib/main_*.dart", "apps/taro/lib/x/main_dev.dart", False),
        ("worker/src/generated/**", "worker/src/generated/deck/en.ts", True),
        ("a/?.ts", "a/b.ts", True),
        ("a/?.ts", "a/bc.ts", False),
        ("a.b", "axb", False),
        ("**", "anything/at/all", True),
    ],
)
def test_glob_to_regex(glob: str, path: str, expected: bool) -> None:
    assert bool(cc.glob_to_regex(glob).match(path)) is expected


def test_parse_exclusions_skips_comments_and_blanks() -> None:
    assert cc.parse_exclusions("# c\n\n  a/**  \n#x\nb\n") == ["a/**", "b"]


def test_real_exclusion_list_is_exactly_06_5_3() -> None:
    patterns = cc.parse_exclusions((TOOLS / "coverage_exclusions.txt").read_text(encoding="utf-8"))
    assert patterns == [
        "apps/taro/lib/l10n/generated/**",
        "packages/taro_ui/lib/src/tokens/generated/**",
        "**/*.g.dart",
        "**/*.freezed.dart",
        "**/*.gen.dart",
        "**/generated_plugin_registrant.dart",
        "**/GeneratedPluginRegistrant.*",
        "**/firebase_options_*.dart",
        "apps/taro/lib/main_*.dart",
        "worker/src/generated/**",
        "**/*.d.ts",
        "worker/worker-configuration.d.ts",
        "**/test/**",
        "**/integration_test/**",
        "worker/test/**",
        "tools/tests/**",
        "worker/evals/cases/**",
        "worker/evals/safety/**",
    ]
    text = (TOOLS / "coverage_exclusions.txt").read_text(encoding="utf-8").splitlines()
    for index, line in enumerate(text):
        if line and not line.startswith("#"):
            assert text[index - 1].startswith("# "), f"no reason comment above {line}"


def test_repo_relative_paths(tmp_path: Path) -> None:
    root = tmp_path
    assert cc._repo_relative(str(root / "worker/src/a.ts"), root, "worker") == "worker/src/a.ts"
    assert cc._repo_relative("/elsewhere/a.ts", root, "worker") == "/elsewhere/a.ts"
    assert cc._repo_relative("/runner/work/taro/worker/src/a.ts", root, "worker") == "worker/src/a.ts"
    assert cc._repo_relative("/elsewhere/a.ts", root, "") == "/elsewhere/a.ts"
    assert cc._repo_relative("lib/./x/../a.dart", root, "apps/taro") == "apps/taro/lib/a.dart"
    assert cc._repo_relative("a\\b.py", root, ".") == "a/b.py"
    assert cc._repo_relative("../a.py", root, "") == "../a.py"


def test_parse_lcov_merges_records_and_falls_back_to_lf_lh(tmp_path: Path) -> None:
    text = "\n".join(
        [
            "TN:",
            "DA:1,1",  # before any SF: ignored
            "SF:lib/a.dart",
            "DA:1,0,checksum",
            "DA:2,3",
            "end_of_record",
            "SF:lib/a.dart",
            "DA:1,2",
            "end_of_record",
            "SF:lib/b.dart",
            "LF:4",
            "LH:1",
            "end_of_record",
            "SF:lib/b.dart",
            "LF:4",
            "LH:3",
            "end_of_record",
            "SF:lib/empty.dart",
            "end_of_record",
        ]
    )
    files = cc.parse_lcov(text, tmp_path, "pkg")
    a, b, empty = files["pkg/lib/a.dart"], files["pkg/lib/b.dart"], files["pkg/lib/empty.dart"]
    assert (a.found, a.hit, a.pct) == (2, 2, 100.0)
    assert (b.found, b.hit, b.pct) == (4, 3, 75.0)
    assert (empty.found, empty.hit, empty.pct) == (0, 0, 100.0)


def test_parse_coverage_py_json_uses_summary_without_line_lists(tmp_path: Path) -> None:
    data = {"files": {"a.py": {"summary": {"num_statements": 4, "covered_lines": 2}}}}
    cov = cc.parse_coverage_py_json(data, tmp_path, "tools")["tools/a.py"]
    assert (cov.found, cov.hit) == (4, 2)


def test_parse_properties_handles_continuations_and_separators() -> None:
    props = cc.parse_properties(
        "# comment\n! bang\n\na=1\nb : two\nc three\nd=x,\\\n   y,\\\n   z\ne=trailing\\"
    )
    assert props == {"a": "1", "b": "two", "c": "three", "d": "x,y,z", "e": "trailing"}


def test_has_statements(tmp_path: Path) -> None:
    doc_only = tmp_path / "a.py"
    doc_only.write_text('"""Doc."""\n')
    code = tmp_path / "b.py"
    code.write_text('"""Doc."""\nX = 1\n')
    broken = tmp_path / "c.py"
    broken.write_text("def (:\n")
    assert not cc._has_statements(doc_only)
    assert cc._has_statements(code)
    assert cc._has_statements(broken)


def test_scan_pragmas_only_in_comments(tmp_path: Path) -> None:
    (tmp_path / "a.ts").write_text(
        "/* istanbul ignore next */\nconst s = 'c8 ignore';\n// c8 ignore next\n"
    )
    (tmp_path / "b.py").write_text("x = 1  # pragma: no cover\n")
    (tmp_path / "c.dart").write_text("// coverage:ignore-start\n")
    hits = cc.scan_pragmas(tmp_path, ["a.ts", "b.py", "c.dart", "missing.dart"])
    assert hits == [
        "a.ts:1: istanbul ignore",
        "a.ts:3: c8 ignore",
        "b.py:1: pragma: no cover",
        "c.dart:1: coverage:ignore-start",
    ]


# --------------------------------------------------------------------------
# Units and failure modes
# --------------------------------------------------------------------------


def test_discover_units(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    assert [u.name for u in cc.discover_units(repo)] == [
        "taro_attestation",
        "taro_core",
        "apps/taro",
        "dart_tools",
        "taro_attestation_ios",
        "taro_attestation_android",
        "worker",
        "tools",
    ]


def test_discover_units_in_an_empty_repo(tmp_path: Path) -> None:
    assert cc.discover_units(tmp_path) == []


def test_list_sources_respects_exclusions_and_skips(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    (repo / "tools/.venv/lib").mkdir(parents=True)
    (repo / "tools/.venv/lib/site.py").write_text("x = 1\n")
    (repo / "tools/x.egg-info").mkdir()
    (repo / "tools/x.egg-info/y.py").write_text("x = 1\n")
    exclusions = cc.Exclusions(cc.parse_exclusions((repo / cc.EXCLUSIONS_PATH).read_text()))
    units = {u.name: u for u in cc.discover_units(repo)}
    assert cc.list_sources(repo, units["tools"], exclusions) == ["tools/check_x.py"]
    assert cc.list_sources(repo, units["taro_core"], exclusions) == [
        "packages/taro_core/lib/barrel.dart",
        "packages/taro_core/lib/taro_core.dart",
    ]
    assert cc.list_sources(repo, units["worker"], exclusions) == [
        "worker/scripts/seed.ts",
        "worker/src/app.ts",
        "worker/src/env.ts",
    ]
    assert cc.list_sources(repo, units["taro_attestation_ios"], exclusions) == [
        "packages/taro_attestation/ios/taro_attestation/Sources/taro_attestation/Plugin.swift"
    ]
    gone = cc.Unit("gone", "nowhere", "lcov", [], ["nowhere/**"])
    assert cc.list_sources(repo, gone, exclusions) == []


def test_pass_fixture_passes_and_writes_outputs(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    code, out = run(repo, "--verify-sonar")
    assert code == 0, out
    assert "Result: **PASS**" in out
    assert "| apps/taro | 1 | 10 | 9 | 90.00 % | ok |" in out
    assert "(branches 90.00 %)" in out
    merged = (repo / cc.MERGED_LCOV).read_text()
    assert "SF:apps/taro/lib/app.dart\n" in merged
    assert "SF:worker/src/app.ts\n" in merged
    assert "SF:tools/check_x.py\n" in merged
    assert "model.g.dart" not in merged  # excluded, although in the report
    assert "tools/tests/helper.py" not in merged
    assert (repo / cc.SUMMARY_MD).read_text() == out
    assert "Worst files" not in out  # nothing failing


def test_unit_below_90(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_unit_below_90")
    result = result_of(repo, "taro_core")
    assert result.failures == ["unit line coverage 80.00 % < 90.0 % (QA1)"]
    code, out = run(repo)
    assert code == 1
    assert "Result: **FAIL**" in out
    assert "## Worst files" in out
    assert "| taro_core | packages/taro_core/lib/taro_core.dart | 8/10 | 80.00 % |" in out


def test_file_below_70(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_file_below_70")
    result = result_of(repo, "worker")
    assert result.failures == ["file worker/src/extra.ts 50.00 % < 70.0 % (QA2)"]
    assert result.pct > 90


def test_missing_file(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_missing_file")
    result = result_of(repo, "apps/taro")
    assert result.failures == ["file missing from report (QA4): apps/taro/lib/untested.dart"]


def test_missing_report(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_missing_report")
    result = result_of(repo, "taro_ui")
    assert result.report_missing
    assert result.failures == ["missing report: packages/taro_ui/coverage/lcov.filtered.info"]
    code, out = run(repo, "--json")
    assert code == 1
    data = json.loads(out)
    ui = next(u for u in data["units"] if u["name"] == "taro_ui")
    assert ui["line_pct"] is None and not ui["ok"]
    assert "| taro_ui | 0 | 0 | 0 | n/a | FAIL (1) |" in (repo / cc.SUMMARY_MD).read_text()


@pytest.mark.parametrize(
    ("unit", "report"),
    [
        ("taro_attestation_ios", "packages/taro_attestation/coverage/ios/lcov.info"),
        ("taro_attestation_android", "packages/taro_attestation/coverage/android/lcov.info"),
        ("worker", "worker/coverage/coverage-summary.json"),
        ("tools", "tools/coverage/coverage.json"),
    ],
)
def test_missing_native_worker_and_tools_reports(tmp_path: Path, unit: str, report: str) -> None:
    repo = make_repo(tmp_path)
    (repo / report).unlink()
    assert result_of(repo, unit).failures == [f"missing report: {report}"]


def test_unreadable_report(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    (repo / "tools/coverage/coverage.json").write_text("{not json")
    failures = result_of(repo, "tools").failures
    assert len(failures) == 1 and failures[0].startswith("unreadable report tools/coverage/coverage.json")


def test_pragmas(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_pragma")
    assert result_of(repo, "taro_core").failures == [
        "coverage pragma (QA3): packages/taro_core/lib/taro_core.dart:2: coverage:ignore-line"
    ]
    assert result_of(repo, "tools").failures == [
        "coverage pragma (QA3): tools/check_x.py:1: pragma: no cover"
    ]


def test_worker_branches_below_85(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_worker_branches")
    assert result_of(repo, "worker").failures == ["branch coverage 80.00 % < 85.0 % (QA7)"]


def test_sonar_drift(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_sonar_drift")
    assert run(repo)[0] == 0  # drift is only checked with --verify-sonar
    code, out = run(repo, "--verify-sonar")
    assert code == 1
    assert (
        "Sonar drift: tools/tests/** is in tools/coverage_exclusions.txt "
        "but not in sonar.coverage.exclusions" in out
    )
    assert (
        "Sonar drift: **/*.mocks.dart is in sonar.coverage.exclusions "
        "but not in tools/coverage_exclusions.txt" in out
    )


def test_sonar_file_absent_is_a_note(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    (repo / cc.SONAR_PATH).unlink()
    code, out = run(repo, "--verify-sonar")
    assert code == 0
    assert "## Notes" in out
    assert "sonar-project.properties not found" in out


def test_sonar_key_absent_fails(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    (repo / cc.SONAR_PATH).write_text("sonar.projectKey=taro\n")
    code, out = run(repo, "--verify-sonar")
    assert code == 1
    assert "sonar-project.properties has no sonar.coverage.exclusions" in out


# --------------------------------------------------------------------------
# run() and main()
# --------------------------------------------------------------------------


def test_unit_selection_and_threshold(tmp_path: Path) -> None:
    repo = make_repo(tmp_path, "fail_unit_below_90")
    lines: list[str] = []
    assert cc.run(repo, unit_names=["taro_core"], unit_threshold=80.0, emit=lines.append) == 0
    assert "| taro_core |" in lines[0] and "| worker |" not in lines[0]


def test_unknown_unit_is_a_usage_error(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    lines: list[str] = []
    assert cc.run(repo, unit_names=["nope"], emit=lines.append) == 2
    assert "unknown unit(s): nope" in lines[0]


def test_missing_exclusion_list_is_a_usage_error(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    (repo / cc.EXCLUSIONS_PATH).unlink()
    lines: list[str] = []
    assert cc.run(repo, emit=lines.append) == 2
    assert "not found" in lines[0]


def test_empty_results_render() -> None:
    assert cc.render_merged_lcov([]) == ""
    summary = cc.render_summary([], ["global"], [], 90.0)
    assert "| merged (reported, not gated) | 0 | 0 | 0 | 100.00 % | - |" in summary
    assert "- global" in summary


def test_main_json_and_flags(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    repo = make_repo(tmp_path, "fail_unit_below_90")
    code = cc.main(["--repo-root", str(repo), "--unit", "taro_core", "--json", "--threshold", "75"])
    assert code == 0
    data = json.loads(capsys.readouterr().out)
    assert data["ok"] is True
    assert data["units"][0]["files"] == {"packages/taro_core/lib/taro_core.dart": 80.0}


def test_main_finds_the_repo_root(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    repo = make_repo(tmp_path)
    monkeypatch.setattr(cc, "find_repo_root", lambda _start: repo)
    assert cc.main(["--verify-sonar"]) == 0
    assert "Result: **PASS**" in capsys.readouterr().out


def test_script_entry_point(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    repo = make_repo(tmp_path)
    monkeypatch.setattr(sys, "argv", ["check_coverage.py", "--repo-root", str(repo)])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(TOOLS / "check_coverage.py"), run_name="__main__")
    assert exit_info.value.code == 0


# --------------------------------------------------------------------------
# Files without executable code (barrels, type-only modules)
# --------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("name", "source", "expected"),
    [
        ("a.dart", "/// Doc.\nlibrary;\n\nexport 'src/a.dart';\nimport 'b.dart';\npart 'c.dart';\n", False),
        ("b.dart", "library;\nexport 'a.dart';\nint x() => 1;\n", True),
        ("c.ts", "import type { A } from './a';\nexport type B = 'x;y' | \"}\";\nexport interface C { a: string; b: { c: A } }\n", False),
        ("d.ts", "declare const x: number;\nexport * from './a';\nexport { b } from './b';\n", False),
        ("e.ts", "/* c */ export const a = 1;\n", True),
        ("f.ts", "export interface I { a: string }\nexport function f() { return 1; }\n", True),
        (
            "union.ts",
            "export type R =\n  { readonly ok: true } | F;\nexport type N =\n  | { a: 1 }\n  | { b: 2 };\n"
            "export type I = { a: 1 } & { b: 2 };\n",
            False,
        ),
        ("g.swift", "", True),
        # Dart type-only declarations: interfaces, plain enums, freezed unions.
        (
            "port.dart",
            "/// Doc.\nabstract interface class Logger {\n  void info(String m, {Object? error});\n"
            "  Logger child(String name);\n  bool get on;\n}\ntypedef Cb = void Function();\n",
            False,
        ),
        (
            "enum.dart",
            "enum A { x, y }\nenum B {\n  x('x'),\n  y('y;{');\n\n  const B(this.wire);\n\n  final String wire;\n}\n",
            False,
        ),
        (
            "union.dart",
            "part 'u.freezed.dart';\n@freezed\nsealed class U with _$U {\n"
            "  const factory U.a({@Default(3) int n, Map<String, int>? m}) = UA;\n"
            "  @Implements<X>()\n  const factory U.b() = UB;\n}\n",
            False,
        ),
        ("ctor.dart", "class S implements C {\n  const S();\n}\n", True),
        ("named_ctor.dart", "@freezed\nabstract class U with _$U {\n  const U._();\n  const factory U() = _U;\n}\n", True),
        ("getter.dart", "abstract class G {\n  int get x => 1;\n}\n", True),
        ("field.dart", "class F {\n  final int x = 1;\n}\n", True),
        ("enum_init.dart", "enum E {\n  a(1);\n\n  const E(this.v) : assert(v > 0);\n\n  final int v;\n}\n", True),
        ("enum_static.dart", "enum E {\n  a;\n\n  static const all = [a];\n}\n", True),
        ("function.dart", "@visibleForTesting\nint f() {\n  return 1;\n}\n", True),
        ("extension.dart", "extension type Id(String v) {}\n", True),
        ("unterminated.dart", "abstract class A {\n  void f();\n", True),
    ],
)
def test_has_executable_code(tmp_path: Path, name: str, source: str, expected: bool) -> None:
    path = tmp_path / name
    path.write_text(source)
    assert cc.has_executable_code(path) is expected


def test_static_prefix() -> None:
    assert cc._static_prefix("worker/src/**/*.ts") == "worker/src"
    assert cc._static_prefix("packages/x/ios/*/Sources/**/*.swift") == "packages/x/ios"
    assert cc._static_prefix("**/*.py") == ""


def test_symlinked_directories_are_not_walked(tmp_path: Path) -> None:
    repo = make_repo(tmp_path)
    link = repo / "packages/taro_core/lib/loop"
    link.symlink_to(repo / "packages/taro_core", target_is_directory=True)
    exclusions = cc.Exclusions(cc.parse_exclusions((repo / cc.EXCLUSIONS_PATH).read_text()))
    units = {u.name: u for u in cc.discover_units(repo)}
    assert cc.list_sources(repo, units["taro_core"], exclusions) == [
        "packages/taro_core/lib/barrel.dart",
        "packages/taro_core/lib/taro_core.dart",
    ]

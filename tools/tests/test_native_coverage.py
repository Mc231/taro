"""Tests for tools/xccov_to_lcov.py and tools/jacoco_to_lcov.py (06 §5.2, RC40)."""

from __future__ import annotations

import json
import runpy
import sys
from pathlib import Path

import pytest

import check_coverage as cc
import jacoco_to_lcov
import xccov_to_lcov

FIXTURES = Path(__file__).parent / "fixtures" / "native_coverage"
TOOLS = Path(__file__).resolve().parents[1]
SWIFT = "packages/taro_attestation/ios/taro_attestation/Sources/taro_attestation/TaroAttestationPlugin.swift"
KOTLIN = "packages/taro_attestation/android/src/main/kotlin/com/vshyrochuk/taro_attestation/TaroAttestationPlugin.kt"


def fixture_json(name: str, repo: Path) -> Path:
    """Copies an xccov fixture with ``REPO`` replaced by ``repo``."""
    text = (FIXTURES / name).read_text(encoding="utf-8").replace("REPO", str(repo))
    out = repo.parent / name
    out.write_text(text, encoding="utf-8")
    return out


@pytest.fixture
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    (root / SWIFT).parent.mkdir(parents=True)
    (root / SWIFT).write_text("// swift\n")
    (root / KOTLIN).parent.mkdir(parents=True)
    (root / KOTLIN).write_text("// kotlin\n")
    return root


# --------------------------------------------------------------------------
# xccov
# --------------------------------------------------------------------------


def test_xccov_archive_and_report(repo: Path) -> None:
    report = json.loads(fixture_json("xccov_report.json", repo).read_text())
    archive = json.loads(fixture_json("xccov_archive.json", repo).read_text())
    text = xccov_to_lcov.convert(report, archive, repo, ["packages/taro_attestation/ios/**"])
    assert text == "\n".join(
        [
            "TN:",
            f"SF:{SWIFT}",
            "FN:5,static TaroAttestationPlugin.register(with:)",
            "FN:11,TaroAttestationPlugin.handle(_:result:)",
            "FNDA:1,static TaroAttestationPlugin.register(with:)",
            "FNDA:0,TaroAttestationPlugin.handle(_:result:)",
            "FNF:2",
            "FNH:1",
            "DA:5,1",
            "DA:6,2",
            "DA:11,0",
            "DA:12,0",
            "LF:4",
            "LH:2",
            "end_of_record",
            "",
        ]
    )
    parsed = cc.parse_lcov(text, repo, "")[SWIFT]
    assert (parsed.found, parsed.hit) == (4, 2)


def test_xccov_report_only_uses_lf_lh(repo: Path) -> None:
    report = json.loads(fixture_json("xccov_report.json", repo).read_text())
    text = xccov_to_lcov.convert(report, None, repo)
    assert "SF:packages/taro_attestation/example/ios/Runner/AppDelegate.swift" in text
    assert "LF:13\nLH:12\n" in text
    assert "\nDA:" not in text


def test_xccov_resolves_symlinks_and_keeps_outside_paths(repo: Path, tmp_path: Path) -> None:
    link = repo / "packages/taro_attestation/example/ios/.symlinks/plugins/taro_attestation"
    link.parent.mkdir(parents=True)
    link.symlink_to(repo / "packages/taro_attestation", target_is_directory=True)
    via_link = str(link / "ios/taro_attestation/Sources/taro_attestation/TaroAttestationPlugin.swift")
    assert xccov_to_lcov.repo_relative(via_link, repo) == SWIFT
    outside = tmp_path / "elsewhere.swift"
    assert xccov_to_lcov.repo_relative(str(outside), repo) == outside.resolve().as_posix()


def test_xccov_glob_matching() -> None:
    regex = xccov_to_lcov._glob_to_regex("a/**/b?.swift")
    assert regex.match("a/x/y/b1.swift")
    assert regex.match("a/b1.swift")
    assert not regex.match("a/b12.swift")
    assert xccov_to_lcov._glob_to_regex("a/**").match("a/x/y")
    assert xccov_to_lcov._glob_to_regex("a/*.swift").match("a/x.swift")


def test_xccov_needs_an_input(repo: Path) -> None:
    with pytest.raises(ValueError, match="need an xccov report or archive"):
        xccov_to_lcov.convert(None, None, repo)


def test_xccov_main(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = repo / "coverage/ios/lcov.info"
    code = xccov_to_lcov.main(
        [
            "--report",
            str(fixture_json("xccov_report.json", repo)),
            "--archive",
            str(fixture_json("xccov_archive.json", repo)),
            "--include",
            "packages/taro_attestation/ios/**",
            "--repo-root",
            str(repo),
            "-o",
            str(out),
        ]
    )
    assert code == 0
    assert out.read_text().count("end_of_record") == 1
    assert "wrote" in capsys.readouterr().out


def test_xccov_main_errors(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = repo / "lcov.info"
    assert xccov_to_lcov.main(["--repo-root", str(repo), "-o", str(out)]) == 1
    assert "need an xccov report" in capsys.readouterr().err
    report = fixture_json("xccov_report.json", repo)
    assert xccov_to_lcov.main(["--report", str(report), "--include", "nothing/**", "--repo-root", str(repo), "-o", str(out)]) == 1
    assert "no file matched" in capsys.readouterr().err
    assert xccov_to_lcov.main(["--report", str(repo / "missing.json"), "--repo-root", str(repo), "-o", str(out)]) == 1


def test_xccov_default_repo_root(repo: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(xccov_to_lcov, "find_repo_root", lambda _start: repo)
    out = repo / "lcov.info"
    assert xccov_to_lcov.main(["--report", str(fixture_json("xccov_report.json", repo)), "-o", str(out)]) == 0


# --------------------------------------------------------------------------
# JaCoCo
# --------------------------------------------------------------------------


def test_jacoco_convert(repo: Path) -> None:
    text = jacoco_to_lcov.convert(
        (FIXTURES / "jacoco.xml").read_text(),
        [
            "packages/taro_attestation/android/src/main/java",
            "packages/taro_attestation/android/src/main/kotlin",
        ],
        repo,
    )
    assert text == "\n".join(
        [
            "TN:",
            f"SF:{KOTLIN}",
            "BRDA:28,0,0,1",
            "BRDA:28,0,1,0",
            "BRF:2",
            "BRH:1",
            "DA:10,1",
            "DA:28,1",
            "DA:29,0",
            "LF:3",
            "LH:2",
            "end_of_record",
            "TN:",
            # Not found under any root: the first root is assumed.
            "SF:packages/taro_attestation/android/src/main/java/com/other/Helper.java",
            "DA:3,1",
            "LF:1",
            "LH:1",
            "end_of_record",
            "",
        ]
    )


def test_jacoco_without_source_roots(repo: Path) -> None:
    text = jacoco_to_lcov.convert((FIXTURES / "jacoco.xml").read_text(), [], repo)
    assert "SF:com/vshyrochuk/taro_attestation/TaroAttestationPlugin.kt" in text


def test_jacoco_rejects_other_xml(repo: Path) -> None:
    with pytest.raises(ValueError, match="not a JaCoCo report"):
        jacoco_to_lcov.convert("<coverage/>", [], repo)


def test_jacoco_main(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = repo / "coverage/android/lcov.info"
    code = jacoco_to_lcov.main(
        [
            str(FIXTURES / "jacoco.xml"),
            "--source-root",
            "packages/taro_attestation/android/src/main/kotlin",
            "--repo-root",
            str(repo),
            "-o",
            str(out),
        ]
    )
    assert code == 0
    assert f"SF:{KOTLIN}" in out.read_text()
    assert "2 file(s)" in capsys.readouterr().out


def test_jacoco_main_errors(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = repo / "lcov.info"
    bad = repo / "bad.xml"
    bad.write_text("<report")
    assert jacoco_to_lcov.main([str(bad), "--repo-root", str(repo), "-o", str(out)]) == 1
    assert "jacoco_to_lcov:" in capsys.readouterr().err
    empty = repo / "empty.xml"
    empty.write_text("<report name='x'/>")
    assert jacoco_to_lcov.main([str(empty), "--repo-root", str(repo), "-o", str(out)]) == 1
    assert "no source files" in capsys.readouterr().err


def test_jacoco_default_repo_root(repo: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(jacoco_to_lcov, "find_repo_root", lambda _start: repo)
    assert jacoco_to_lcov.main([str(FIXTURES / "jacoco.xml"), "-o", str(repo / "l.info")]) == 0


@pytest.mark.parametrize("script", ["xccov_to_lcov.py", "jacoco_to_lcov.py"])
def test_script_entry_points(script: str, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]) -> None:
    monkeypatch.setattr(sys, "argv", [script, "--help"])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(TOOLS / script), run_name="__main__")
    assert exit_info.value.code == 0
    assert "lcov" in capsys.readouterr().out


@pytest.mark.parametrize("script", ["xccov_to_lcov.py", "jacoco_to_lcov.py"])
def test_script_entry_points_exit_code(script: str, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    args = ["--report", str(tmp_path / "none.json")] if script.startswith("xccov") else [str(tmp_path / "none.xml")]
    monkeypatch.setattr(sys, "argv", [script, *args, "--repo-root", str(tmp_path), "-o", str(tmp_path / "o")])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(TOOLS / script), run_name="__main__")
    assert exit_info.value.code == 1

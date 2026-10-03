"""tools/verify.sh with every external command stubbed (06 §6.4, Phase 3 Sprint 3.5)."""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
from pathlib import Path

import pytest

VERIFY = Path(__file__).resolve().parents[1] / "verify.sh"

# A stub logs "<name> <cwd-basename> <args...>" and fails when any word of
# $STUB_FAIL occurs in its argument string.
STUB = """#!/usr/bin/env bash
echo "{name} $(basename "$PWD") $*" >> "$STUB_LOG"
if [[ "{name}" == git && "$1" == rev-parse ]]; then
  [[ "${{STUB_HAS_BASE:-0}}" == 1 ]] && exit 0 || exit 1
fi
for word in ${{STUB_FAIL:-}}; do
  [[ "{name} $*" == *"$word"* ]] && exit 1
done
exit 0
"""


def _executable(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    (root / "tools").mkdir(parents=True)
    shutil.copy(VERIFY, root / "tools" / "verify.sh")
    for rel in (
        "tools/check_alpha.py",
        "tools/check_coverage.py",
        "tools/check_commit_msg.py",
        "tools/check_changelog.py",
        "tools/check_urls.py",
        "tools/check_l10n.py",
        "tools/store_copy/check_store_copy.py",
        "tools/tests/check_not_a_check.py",
        "tools/dart_tools/bin/check_architecture.dart",
        "tools/dart_tools/bin/content_validate.dart",
    ):
        (root / rel).parent.mkdir(parents=True, exist_ok=True)
        (root / rel).write_text("")
    (root / "worker").mkdir()
    return root


def _run(repo: Path, *args: str, fail: str = "", has_base: bool = False,
         gitleaks: bool = True, gitleaks_toml: bool = False,
         asa: bool = False) -> tuple[int, str, list[str]]:
    bin_dir = repo.parent / "bin"
    log = repo.parent / "calls.log"
    log.unlink(missing_ok=True)
    names = ["melos", "python", "dart", "npm", "git"] + (["gitleaks"] if gitleaks else [])
    names += ["asa"] if asa else []
    for name in names:
        _executable(bin_dir / name, STUB.format(name=name))
    if gitleaks_toml:
        (repo / ".gitleaks.toml").write_text("")
    env = {
        "PATH": "/usr/bin:/bin",
        "STUB_LOG": str(log),
        "STUB_FAIL": fail,
        "STUB_HAS_BASE": "1" if has_base else "0",
        "TARO_VERIFY_ROOT": str(repo),
        "TARO_MELOS": str(bin_dir / "melos"),
        "TARO_PYTHON": str(bin_dir / "python"),
        "TARO_DART": str(bin_dir / "dart"),
        "TARO_NPM": str(bin_dir / "npm"),
        "TARO_GIT": str(bin_dir / "git"),
        "TARO_GITLEAKS": str(bin_dir / "gitleaks"),
        "TARO_ASA": str(bin_dir / "asa"),
    }
    proc = subprocess.run(
        ["bash", str(repo / "tools" / "verify.sh"), *args],
        env=env, capture_output=True, text=True, check=False,
    )
    lines = log.read_text().splitlines() if log.exists() else []
    calls = [line for line in lines if not line.startswith("git ")]
    return proc.returncode, proc.stdout + proc.stderr, calls


def test_full_runs_every_stage_in_order(repo: Path) -> None:
    code, out, calls = _run(repo)
    assert code == 0, out
    assert calls == [
        "melos repo run format:check",
        "melos repo run analyze",
        "python repo tools/check_alpha.py",
        "python repo tools/check_changelog.py",
        "python repo tools/check_l10n.py --strict-translations --require-all-locales",
        "python repo tools/check_urls.py --offline",
        "python repo tools/store_copy/check_store_copy.py",
        "dart repo run tools/dart_tools/bin/check_architecture.dart",
        "dart repo run tools/dart_tools/bin/content_validate.dart --strict-locales",
        "dart repo run tools/dart_tools/bin/content_build.dart --check",
        "dart repo run tools/dart_tools/bin/content_sync_check.dart",
        "dart repo run tools/dart_tools/bin/placeholder_art.dart --check",
        "dart repo run tools/dart_tools/bin/import_art.dart --check",
        "gitleaks repo detect --no-banner",
        "npm worker run lint",
        "npm worker run typecheck",
        "npm worker run format:check",
        "npm worker run -s safety:lexicons:check",
        "melos repo run test:coverage",
        "melos repo run coverage:check",
    ]
    assert "skip  check_coverage.py" in out
    assert "skip  check_commit_msg.py" in out
    assert "check_not_a_check" not in out


def test_fast_skips_goldens_coverage_worker_and_tools(repo: Path) -> None:
    code, out, calls = _run(repo, "--fast")
    assert code == 0, out
    assert calls[-1] == "melos repo run test:fast"
    assert not any("coverage" in c or c.startswith("npm") for c in calls)
    assert "skip  goldens, coverage, worker, native (--fast)" in out


def test_fast_with_origin_main_tests_changed_packages_and_checks_range(repo: Path) -> None:
    code, out, calls = _run(repo, "--fast", has_base=True)
    assert code == 0, out
    assert "python repo tools/check_commit_msg.py --range origin/main..HEAD" in calls
    assert "python repo tools/check_changelog.py --range origin/main..HEAD" in calls
    assert calls[-1] == (
        "melos repo exec --diff=origin/main --dir-exists=test -c 1 --fail-fast -- "
        "flutter test --no-pub --exclude-tags golden,integration"
    )


def test_a_failing_step_fails_the_run_but_later_steps_still_run(repo: Path) -> None:
    code, out, calls = _run(repo, "--fast", fail="check_alpha")
    assert code == 1
    assert "FAIL  check: check_alpha.py" in out
    assert calls[-1] == "melos repo run test:fast"


def test_fail_fast_stops_at_the_first_failure(repo: Path) -> None:
    code, out, calls = _run(repo, "--fast", "--fail-fast", fail="analyze")
    assert code == 1
    assert calls == ["melos repo run format:check", "melos repo run analyze"]
    assert "FAIL  analyze" in out


def test_gitleaks_uses_the_repo_config(repo: Path) -> None:
    code, _, calls = _run(repo, "--fast", gitleaks_toml=True)
    assert code == 0
    assert "gitleaks repo detect --no-banner --config .gitleaks.toml" in calls


def test_missing_gitleaks_is_skipped(repo: Path) -> None:
    code, out, calls = _run(repo, "--fast", gitleaks=False)
    assert code == 0, out
    assert "skip  gitleaks" in out
    assert not any(c.startswith("gitleaks") for c in calls)


def test_no_worker_directory_is_skipped(repo: Path) -> None:
    shutil.rmtree(repo / "worker")
    code, out, calls = _run(repo)
    assert code == 0, out
    assert "skip  worker (no worker/ directory)" in out
    assert not any(c.startswith("npm") for c in calls)


def test_content_checks_are_skipped_without_the_content_tools(repo: Path) -> None:
    (repo / "tools/dart_tools/bin/content_validate.dart").unlink()
    code, out, calls = _run(repo, "--fast")
    assert code == 0, out
    assert "skip  content (no tools/dart_tools/bin/content_validate.dart)" in out
    assert not any("content_" in c or "_art" in c for c in calls)


def test_a_failing_content_check_fails_the_run(repo: Path) -> None:
    code, out, _ = _run(repo, "--fast", fail="content_sync_check")
    assert code == 1
    assert "FAIL  content: sync_check" in out
    assert "ok    content: placeholder_art --check" in out
    assert "ok    content: import_art --check" in out


def test_asa_validate_runs_on_the_store_yaml(repo: Path) -> None:
    (repo / "apps/taro/store").mkdir(parents=True)
    (repo / "apps/taro/store/aso.yaml").write_text("")
    code, out, calls = _run(repo, "--fast", asa=True)
    assert code == 0, out
    assert "asa repo validate -c apps/taro/store/aso.yaml" in calls
    code, out, _ = _run(repo, "--fast", asa=True, fail="validate")
    assert code == 1
    assert "FAIL  asa validate" in out


def test_asa_validate_is_skipped_without_yaml_or_cli(repo: Path) -> None:
    code, out, calls = _run(repo, "--fast", asa=True)
    assert code == 0, out
    assert "skip  asa validate (no apps/taro/store/aso.yaml)" in out
    (repo / "apps/taro/store").mkdir(parents=True)
    (repo / "apps/taro/store/aso.yaml").write_text("")
    (repo.parent / "bin" / "asa").unlink()
    code, out, calls = _run(repo, "--fast")
    assert code == 0, out
    assert "skip  asa validate (asa not installed" in out
    assert not any(c.startswith("asa") for c in calls)


def test_help_and_bad_arguments(repo: Path) -> None:
    code, out, _ = _run(repo, "--help")
    assert code == 0
    assert "tools/verify.sh --fast" in out
    code, out, _ = _run(repo, "--nope")
    assert code == 2
    assert "unknown argument: --nope" in out


def test_script_is_valid_bash() -> None:
    assert subprocess.run(["bash", "-n", str(VERIFY)], check=False).returncode == 0
    assert os.access(VERIFY, os.X_OK)

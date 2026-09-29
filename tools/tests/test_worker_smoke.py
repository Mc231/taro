"""tools/worker_smoke.sh with node stubbed (03 §14.2, 06 §8, RC86)."""

from __future__ import annotations

import shutil
import stat
import subprocess
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "worker_smoke.sh"
NODE_STUB = """#!/usr/bin/env bash
echo "node $(basename "$PWD") $* token=${DEBUG_ATTESTATION_TOKEN:-unset}" >> "$STUB_LOG"
exit "${STUB_EXIT:-0}"
"""


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    (root / "tools").mkdir(parents=True)
    (root / "worker").mkdir()
    shutil.copy(SCRIPT, root / "tools" / "worker_smoke.sh")
    return root


def _run(repo: Path, *args: str, **env: str) -> tuple[int, str, list[str]]:
    bin_dir = repo.parent / "bin"
    bin_dir.mkdir(exist_ok=True)
    stub = bin_dir / "node"
    stub.write_text(NODE_STUB)
    stub.chmod(stub.stat().st_mode | stat.S_IXUSR)
    log = repo.parent / "calls.log"
    log.unlink(missing_ok=True)
    full_env = {"PATH": f"{bin_dir}:/usr/bin:/bin", "STUB_LOG": str(log), **env}
    proc = subprocess.run(
        ["bash", str(repo / "tools" / "worker_smoke.sh"), *args],
        env=full_env,
        capture_output=True,
        text=True,
        check=False,
    )
    calls = log.read_text().splitlines() if log.exists() else []
    return proc.returncode, proc.stdout + proc.stderr, calls


def test_staging_runs_the_smoke_script_in_worker_with_the_token(repo: Path) -> None:
    code, _, calls = _run(repo, "staging", DEBUG_ATTESTATION_TOKEN="t0k3n")
    assert code == 0
    assert calls == ["node worker scripts/run.mjs smoke --env staging token=t0k3n"]


def test_base_url_from_flag_or_env(repo: Path) -> None:
    _, _, calls = _run(repo, "dev", "--base-url", "http://localhost:9999")
    assert calls == ["node worker scripts/run.mjs smoke --env dev --base-url http://localhost:9999 token=unset"]
    _, _, calls = _run(repo, "staging", WORKER_SMOKE_BASE_URL="https://preview.example")
    assert calls == ["node worker scripts/run.mjs smoke --env staging --base-url https://preview.example token=unset"]


def test_prod_never_passes_the_debug_token(repo: Path) -> None:
    code, _, calls = _run(repo, "prod", DEBUG_ATTESTATION_TOKEN="t0k3n")
    assert code == 0
    assert calls == ["node worker scripts/run.mjs smoke --env prod token=unset"]


def test_propagates_the_smoke_exit_code(repo: Path) -> None:
    code, _, _ = _run(repo, "staging", STUB_EXIT="1")
    assert code == 1


@pytest.mark.parametrize("args", [[], ["qa"], ["staging", "--nope"], ["staging", "--base-url"]])
def test_usage_errors_exit_2(repo: Path, args: list[str]) -> None:
    code, output, calls = _run(repo, *args)
    assert code == 2
    assert "usage: tools/worker_smoke.sh" in output
    assert calls == []

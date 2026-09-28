from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

import contract_sync
from contract_sync import SOURCE, TARGET, main, plan


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    (tmp_path / "docs" / "specs").mkdir(parents=True)
    src = tmp_path / SOURCE
    (src / "balance").mkdir(parents=True)
    (src / "health.json").write_text('{"status": "ok"}')
    (src / "balance" / "get.json").write_text('{"paid": 3}')
    (src / ".DS_Store").write_text("junk")
    return tmp_path


def _tree(folder: Path) -> dict[str, str]:
    return {p.relative_to(folder).as_posix(): p.read_text() for p in folder.rglob("*") if p.is_file()}


def test_first_sync_copies_everything_but_dotfiles(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert main(["--root", str(repo)]) == 0
    assert _tree(repo / TARGET) == {"health.json": '{"status": "ok"}', "balance/get.json": '{"paid": 3}'}
    assert "2 copied, 0 removed" in capsys.readouterr().out


def test_resync_updates_changed_and_removes_stale(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    main(["--root", str(repo)])
    (repo / SOURCE / "health.json").write_text('{"status": "degraded"}')
    (repo / SOURCE / "balance" / "get.json").unlink()
    (repo / SOURCE / "balance").rmdir()
    capsys.readouterr()
    assert main(["--root", str(repo)]) == 0
    assert _tree(repo / TARGET) == {"health.json": '{"status": "degraded"}'}
    assert not (repo / TARGET / "balance").exists()
    out = capsys.readouterr().out
    assert "copy health.json" in out and "remove balance/get.json" in out


def test_in_sync_is_a_no_op(repo: Path) -> None:
    main(["--root", str(repo)])
    assert plan(repo / SOURCE, repo / TARGET) == ([], [])


def test_dry_run_writes_nothing(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert main(["--root", str(repo), "--dry-run"]) == 0
    assert not (repo / TARGET).exists()
    assert "would copy health.json" in capsys.readouterr().out


def test_missing_source_is_not_an_error(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    (tmp_path / "docs" / "specs").mkdir(parents=True)
    assert main(["--root", str(tmp_path)]) == 0
    assert "does not exist yet" in capsys.readouterr().out


def test_runs_as_a_script() -> None:
    script = Path(contract_sync.__file__)
    proc = subprocess.run([sys.executable, str(script), "--dry-run"], capture_output=True, text=True, check=False)
    assert proc.returncode == 0, proc.stderr
    assert "contract_sync:" in proc.stdout

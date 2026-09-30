from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

import phase_state
from phase_state import main, normalize_status, parse_phase, read_phases

DONE = """# Phase 1: Spec Reconciliation

**Status:** ✅ Complete (2026-09-27). All owner items answered.

- [x] one
- [X] two
"""

ACTIVE = """# Phase 2: Quality Gates

**Status:** 🟡 In progress: Sprint 2.3

- [x] one
- [ ] two
  - [ ] nested
"""

TODO = """# Phase 3: Core Domain

**Status:** ⬜ Not Started
**Depends on:** Phase 2

- [ ] a
"""


def _repo(tmp_path: Path, docs: dict[str, str]) -> Path:
    folder = tmp_path / "docs" / "phases"
    folder.mkdir(parents=True)
    (tmp_path / "docs" / "specs").mkdir()
    for name, text in docs.items():
        (folder / name).write_text(text, encoding="utf-8")
    (folder / "README.md").write_text("**Status:** ⬜ Not started", encoding="utf-8")
    return tmp_path


@pytest.mark.parametrize(
    ("raw", "status", "detail"),
    [
        ("✅ Complete (2026-09-27). Notes.", "done", "(2026-09-27). Notes."),
        ("⬜ Not Started", "not_started", ""),
        ("🚧 In progress", "in_progress", ""),
        ("🔄 Sprint 3.2", "in_progress", "Sprint 3.2"),
        ("⛔ Blocked: waiting on Apple", "blocked", "waiting on Apple"),
        ("🟡 In progress — code complete; evals pending", "in_progress", "— code complete; evals pending"),
        ("🚧 Pipeline and EN drafts complete", "in_progress", "Pipeline and EN drafts complete"),
        ("Done", "done", ""),
        ("Something else", "unknown", "Something else"),
    ],
)
def test_normalize_status(raw: str, status: str, detail: str) -> None:
    assert normalize_status(raw) == (status, detail)


def test_parse_phase_counts_tasks_and_reads_heading() -> None:
    state = parse_phase(Path("PHASE_02_QG.md"), ACTIVE)
    assert (state.number, state.title, state.status) == (2, "Quality Gates", "in_progress")
    assert state.detail == "Sprint 2.3"
    assert (state.tasks_done, state.tasks_total) == (1, 3)


def test_parse_phase_without_heading_or_status_falls_back_to_the_file() -> None:
    state = parse_phase(Path("PHASE_07_X.md"), "no heading here\n")
    assert (state.number, state.title, state.status) == (7, "PHASE_07_X", "unknown")
    assert state.detail == "no **Status:** line"
    other = parse_phase(Path("NOTES.md"), "")
    assert other.number == 0


def test_read_phases_sorts_numerically_and_ignores_readme(tmp_path: Path) -> None:
    root = _repo(tmp_path, {"PHASE_10_B.md": TODO.replace("Phase 3", "Phase 10"),
                            "PHASE_02_A.md": ACTIVE, "PHASE_01_D.md": DONE})
    assert [p.number for p in read_phases(root)] == [1, 2, 10]


def test_main_prints_the_table_and_current_phase(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = _repo(tmp_path, {"PHASE_01_D.md": DONE, "PHASE_02_A.md": ACTIVE, "PHASE_03_T.md": TODO})
    assert main(["--root", str(root)]) == 0
    out = capsys.readouterr().out
    assert "Spec Reconciliation" in out
    assert "2/2" in out and "1/3" in out and "0/1" in out
    assert out.strip().endswith("current: Phase 2 (Quality Gates), in_progress")


def test_main_filters_by_status_and_phase(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = _repo(tmp_path, {"PHASE_01_D.md": DONE, "PHASE_03_T.md": TODO})
    assert main(["--root", str(root), "--status", "done"]) == 0
    out = capsys.readouterr().out
    table, current = out.split("current:")
    assert "Spec Reconciliation" in table and "Core Domain" not in table
    assert current.strip() == "Phase 3 (Core Domain), not_started"
    assert main(["--root", str(root), "--phase", "3"]) == 0
    assert "Core Domain" in capsys.readouterr().out


def test_main_json(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = _repo(tmp_path, {"PHASE_01_D.md": DONE})
    assert main(["--root", str(root), "--json"]) == 0
    data = json.loads(capsys.readouterr().out)
    assert data["current"] is None
    assert data["phases"][0]["status"] == "done"


def test_all_done_and_long_values_are_shortened(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    long_title = DONE.replace("Spec Reconciliation", "A" * 60)
    root = _repo(tmp_path, {"PHASE_01_D.md": long_title})
    assert main(["--root", str(root)]) == 0
    out = capsys.readouterr().out
    assert "A" * 43 + "…" in out
    assert "current: all phases done" in out


def test_main_errors(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    empty = _repo(tmp_path / "empty", {})
    assert main(["--root", str(empty)]) == 1
    assert "no PHASE_*.md" in capsys.readouterr().err
    root = _repo(tmp_path / "one", {"PHASE_01_D.md": DONE})
    assert main(["--root", str(root), "--phase", "9"]) == 1
    assert "no phase 9" in capsys.readouterr().err


def test_real_repository_phase_docs(capsys: pytest.CaptureFixture[str]) -> None:
    assert main([]) == 0
    out = capsys.readouterr().out
    assert "Quality Gates & CI" in out
    assert "current: Phase" in out


def test_runs_as_a_script() -> None:
    script = Path(phase_state.__file__)
    proc = subprocess.run([sys.executable, str(script), "--phase", "1"],
                          capture_output=True, text=True, check=False)
    assert proc.returncode == 0, proc.stderr
    assert "Spec Reconciliation" in proc.stdout

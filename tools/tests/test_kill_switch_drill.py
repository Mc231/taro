from __future__ import annotations

import io
import json
import runpy
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

import pytest

import kill_switch_drill
from kill_switch_drill import main, overlay

BUDGET_KEYS = ("ai.budget.softFloorUsd", "ai.budget.freeStopFloorUsd", "ai.budget.dailyHardUsd")


def _docs(version: int = 7) -> dict[str, dict[str, Any]]:
    return {
        "public": {"version": version, "readings.enabled": True, "rewarded.enabled": True},
        "server": {"version": version - 1, "ai.budget.softFloorUsd": 50,
                   "ai.budget.freeStopFloorUsd": 100, "ai.budget.dailyHardUsd": 300},
    }


class FakeWorker:
    """`npx wrangler kv key get` and `npm run config:push` over in-memory KV."""

    def __init__(self, docs: dict[str, dict[str, Any]] | None = None, *, kv_fail: bool = False,
                 kv_text: str | None = None, push_fail: bool = False) -> None:
        self.kv = docs if docs is not None else _docs()
        self.kv_fail = kv_fail
        self.kv_text = kv_text
        self.push_fail = push_fail
        self.pushes: list[tuple[dict[str, Any], bool]] = []
        self.cwds: list[Path] = []

    def __call__(self, args: list[str], **kwargs: Any) -> subprocess.CompletedProcess[str]:
        self.cwds.append(kwargs["cwd"])
        if args[:2] == ["npx", "wrangler"]:
            assert args[2:5] == ["kv", "key", "get"] and "--remote" in args
            kind = args[5].split(":")[1]
            if self.kv_fail:
                return subprocess.CompletedProcess(args, 1, "", "auth")
            text = self.kv_text if self.kv_text is not None else json.dumps(self.kv[kind])
            return subprocess.CompletedProcess(args, 0, text, "")
        assert args[:5] == ["npm", "run", "--silent", "config:push", "--"]
        file = json.loads(Path(args[args.index("--file") + 1]).read_text())
        dry = "--dry-run" in args
        self.pushes.append((file, dry))
        if self.push_fail:
            return subprocess.CompletedProcess(args, 1, "", "invalid")
        if not dry:
            self.kv = {"public": file["public"], "server": file["server"]}
        return subprocess.CompletedProcess(args, 0, "ok line\n", "")


class FakeApi:
    """`GET /v1/config`: serves the public document of [worker]."""

    def __init__(self, worker: FakeWorker, *, stale: bool = False, error_first: bool = False,
                 hide_switch: bool = False) -> None:
        self.worker = worker
        self.stale = stale
        self.error_first = error_first
        self.hide_switch = hide_switch
        self.urls: list[str] = []

    def __call__(self, url: str) -> dict[str, Any]:
        self.urls.append(url)
        if self.error_first:
            self.error_first = False
            raise OSError("connection reset")
        if self.stale:
            return {"version": 1}
        body = dict(self.worker.kv["public"])
        if self.hide_switch:
            body["readings.enabled"] = True
        return body


@pytest.fixture(autouse=True)
def _tmpdir(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(tempfile, "tempdir", str(tmp_path))


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    (tmp_path / "docs" / "specs").mkdir(parents=True)
    (tmp_path / "worker").mkdir()
    return tmp_path


def _run(repo: Path, argv: list[str], worker: FakeWorker, api: FakeApi | None = None,
         sleeps: list[float] | None = None) -> int:
    slept = sleeps if sleeps is not None else []
    return main(["--root", str(repo), *argv], run=worker, fetch=api or FakeApi(worker), sleep=slept.append)


def test_dry_run_reads_kv_validates_both_files_and_writes_nothing(repo: Path) -> None:
    worker = FakeWorker()
    before = json.loads(json.dumps(worker.kv))
    assert _run(repo, ["--dry-run"], worker) == 0
    assert worker.kv == before
    (drill_file, d1), (restore_file, d2) = worker.pushes
    assert d1 and d2
    assert drill_file["public"]["readings.enabled"] is False
    assert drill_file["public"]["version"] == drill_file["server"]["version"] == 8
    assert restore_file["public"] == {**before["public"], "version": 9}
    assert restore_file["server"] == {**before["server"], "version": 9}
    assert set(worker.cwds) == {repo / "worker"}


def test_dry_run_from_base_file_never_calls_wrangler(repo: Path, tmp_path: Path) -> None:
    base = tmp_path / "base.json"
    base.write_text(json.dumps({"$schema": "x", **_docs(3)}))
    worker = FakeWorker(kv_fail=True)
    snap = tmp_path / "snap.json"
    assert _run(repo, ["--dry-run", "--base", str(base), "--switch", "budget-hard",
                       "--snapshot", str(snap)], worker) == 0
    drill_file = worker.pushes[0][0]
    assert all(drill_file["server"][k] == 0 for k in BUDGET_KEYS)
    assert drill_file["public"]["readings.enabled"] is True
    assert json.loads(snap.read_text())["server"]["ai.budget.dailyHardUsd"] == 300


def test_live_readings_drill_switches_holds_and_restores(repo: Path, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    worker = FakeWorker()
    sleeps: list[float] = []
    api = FakeApi(worker, error_first=True)
    assert _run(repo, ["--hold", "42"], worker, api, sleeps) == 0
    assert [dry for _, dry in worker.pushes] == [False, False]
    assert worker.pushes[0][0]["public"]["readings.enabled"] is False
    assert worker.kv["public"] == {**_docs()["public"], "version": 9}
    assert worker.kv["server"] == {**_docs()["server"], "version": 9}
    assert 42 in sleeps
    assert api.urls[0] == "https://api-staging.taro.vshyrochuk.com/v1/config"
    out = capsys.readouterr().out
    assert json.loads((tmp_path / "taro-drill-staging-snapshot.json").read_text())["public"]["version"] == 7
    assert "holding 42 s" in out and "serves version 9 again" in out


def test_live_budget_drill(repo: Path) -> None:
    worker = FakeWorker()
    assert _run(repo, ["--switch", "budget-hard", "--hold", "0", "--env", "dev"], worker) == 0
    assert all(worker.pushes[0][0]["server"][k] == 0 for k in BUDGET_KEYS)
    assert worker.kv["server"]["ai.budget.dailyHardUsd"] == 300


def test_restore_still_runs_when_the_switch_is_not_served(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    worker = FakeWorker()
    assert _run(repo, ["--hold", "0"], worker, FakeApi(worker, hide_switch=True)) == 1
    assert len(worker.pushes) == 2
    assert worker.kv["public"]["readings.enabled"] is True
    assert "does not serve readings.enabled = false" in capsys.readouterr().err


def test_stale_cache_times_out(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    worker = FakeWorker()
    sleeps: list[float] = []
    assert _run(repo, ["--hold", "0"], worker, FakeApi(worker, stale=True), sleeps) == 1
    err = capsys.readouterr().err
    assert "still serves version 1, expected 8; restore failed:" in err
    assert "expected 9; re-run with --restore" in err
    assert sum(sleeps) >= kill_switch_drill.CACHE_SETTLE_SEC
    assert worker.kv["public"]["readings.enabled"] is True, "the restore push itself went out"


def test_restore_failure_after_a_good_drill(repo: Path, capsys: pytest.CaptureFixture[str]) -> None:
    worker = FakeWorker()
    api = FakeApi(worker)
    original_call = api.__call__

    def fetch(url: str) -> dict[str, Any]:
        body = original_call(url)
        return {"version": 8, "readings.enabled": False} if body["version"] == 9 else body

    assert main(["--root", str(repo), "--hold", "0"], run=worker, fetch=fetch, sleep=lambda _: None) == 1
    err = capsys.readouterr().err
    assert err.startswith("kill_switch_drill: restore failed:")


@pytest.mark.parametrize(
    ("worker", "message"),
    [
        (FakeWorker(kv_fail=True), "kv key get config:public failed"),
        (FakeWorker(kv_text="nope"), "config:public is not JSON"),
        (FakeWorker(kv_text='{"a": 1}'), "has no integer version"),
        (FakeWorker(push_fail=True), "config:push overlay.json failed (exit 1): invalid"),
    ],
)
def test_failures_exit_1(repo: Path, worker: FakeWorker, message: str, capsys: pytest.CaptureFixture[str]) -> None:
    assert _run(repo, ["--dry-run"], worker) == 1
    assert message in capsys.readouterr().err


def test_bad_base_file(repo: Path, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    base = tmp_path / "base.json"
    base.write_text("[]")
    assert _run(repo, ["--base", str(base)], FakeWorker()) == 1
    assert "is not a remote_config file" in capsys.readouterr().err


def test_restore_mode_pushes_a_snapshot_above_the_stored_version(repo: Path, tmp_path: Path) -> None:
    snap = tmp_path / "snap.json"
    snap.write_text(json.dumps({"$schema": "x", **_docs(2)}))
    worker = FakeWorker(_docs(12))
    assert _run(repo, ["--restore", str(snap)], worker) == 0
    assert worker.kv["public"] == {**_docs(2)["public"], "version": 13}
    assert worker.pushes[0][1] is False


@pytest.mark.parametrize("argv", [["--env", "prod"], ["--hold", "-1"], ["--switch", "ads"]])
def test_usage_errors(repo: Path, argv: list[str]) -> None:
    with pytest.raises(SystemExit) as exc:
        _run(repo, argv, FakeWorker())
    assert exc.value.code == 2


def test_overlay_does_not_mutate_its_input() -> None:
    docs = _docs()
    out = overlay(docs, "readings", 99)
    assert docs["public"]["readings.enabled"] is True and docs["public"]["version"] == 7
    assert out["server"]["version"] == 99


def test_http_get_json_sends_the_probe_headers(monkeypatch: pytest.MonkeyPatch) -> None:
    seen: dict[str, Any] = {}

    class Response(io.BytesIO):
        def __enter__(self) -> Response:
            return self

        def __exit__(self, *exc: object) -> None:
            return None

    def urlopen(request: Any, timeout: int) -> Response:
        seen["url"] = request.full_url
        seen["platform"] = request.get_header("X-taro-platform")
        seen["timeout"] = timeout
        return Response(b'{"version": 4}')

    monkeypatch.setattr(kill_switch_drill.urllib.request, "urlopen", urlopen)
    assert kill_switch_drill.http_get_json("https://x/v1/config") == {"version": 4}
    assert seen == {"url": "https://x/v1/config", "platform": "ios", "timeout": 15}


def test_script_entry_point_refuses_prod(monkeypatch: pytest.MonkeyPatch) -> None:
    script = Path(kill_switch_drill.__file__)
    monkeypatch.setattr(sys, "argv", [str(script), "--env", "prod"])
    with pytest.raises(SystemExit) as exc:
        runpy.run_path(str(script), run_name="__main__")
    assert exc.value.code == 2

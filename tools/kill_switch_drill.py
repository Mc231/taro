#!/usr/bin/env python3
"""Staging kill-switch drill (Phase 19.3; 03 §8.1, §10.2; RC8, RC47, RC64).

Pushes a temporary remote-config overlay to ``CONFIG_KV`` of a non-prod
Worker environment, waits for the per-isolate config cache, keeps the switch
on for ``--hold`` seconds (the window in which the app checks are made), then
restores the documents that were stored before the drill:

* ``--switch readings``: ``readings.enabled = false`` (S31 "readings are
  resting" + the Classic offer; holds answer ``503 READINGS_DISABLED``);
* ``--switch budget-hard``: ``ai.budget.softFloorUsd``, ``freeStopFloorUsd``
  and ``dailyHardUsd`` set to 0, so today's spend is at the hard tier (holds
  answer ``503 AI_BUDGET_EXHAUSTED tier=hard``, never a paywall).

The snapshot is read from KV with ``wrangler kv key get`` (or taken from
``--base <file>``, a ``remote_config`` file, for an offline plan). Every push
goes through ``npm run config:push`` (schema validation, version check), so a
push raises ``version`` above the stored one: overlay = stored + 1, restore =
stored + 2 (clients revalidate by ``ETag``, 03 §8.1). The snapshot is written
to ``--snapshot`` (default ``$TMPDIR/taro-drill-<env>-snapshot.json``) before
anything changes; ``--restore <snapshot>`` pushes it
back alone if a drill was interrupted. ``prod`` is refused: the production
kill switch is the manual runbook step (``docs/runbooks/INCIDENT.md``).

``--dry-run`` reads (KV get or ``--base``), builds and validates both files
with ``config:push --dry-run`` and writes nothing remote.

Exit codes: 0 drill done and restored, 1 a step failed (the restore is still
attempted when the overlay was pushed), 2 usage.
"""

from __future__ import annotations

import argparse
import copy
import json
import subprocess
import sys
import tempfile
import time
import urllib.request
from collections.abc import Callable, Sequence
from pathlib import Path
from typing import Any

if __package__ in (None, ""):  # run as a script: make taro_tools importable
    sys.path.insert(0, str(Path(__file__).resolve().parent))

from taro_tools import find_repo_root  # noqa: E402

ENVIRONMENTS = ("dev", "staging")
SWITCHES = ("readings", "budget-hard")
KV_KEYS = {"server": "config:server", "public": "config:public"}
API_HOSTS = {"dev": "http://localhost:8787", "staging": "https://api-staging.taro.vshyrochuk.com"}
# 03 §8.1: the Worker caches config per isolate for CONFIG_CACHE_TTL_MS (60 s).
CACHE_SETTLE_SEC = 65
DEFAULT_HOLD_SEC = 300
PROBE_HEADERS = {"X-Taro-Platform": "ios", "X-Taro-App-Version": "999.0.0+1", "X-Taro-Locale": "en"}
SCHEMA_REF = "./remote_config.schema.json"

Runner = Callable[..., subprocess.CompletedProcess[str]]
Fetch = Callable[[str], dict[str, Any]]


class DrillError(Exception):
    """A drill step failed; the message says which."""


def http_get_json(url: str) -> dict[str, Any]:
    """``GET url`` with the smoke headers; the JSON body (production fetch)."""
    request = urllib.request.Request(url, headers=PROBE_HEADERS)
    with urllib.request.urlopen(request, timeout=15) as response:  # noqa: S310 (fixed https hosts)
        return dict(json.loads(response.read().decode("utf-8")))


def kv_get(run: Runner, worker: Path, env: str, kind: str) -> dict[str, Any]:
    """The stored ``config:<kind>`` document of ``env``."""
    args = ["npx", "wrangler", "kv", "key", "get", KV_KEYS[kind], "--text",
            "--binding", "CONFIG_KV", "--env", env, "--remote"]
    proc = run(args, cwd=worker, capture_output=True, text=True)
    if proc.returncode != 0:
        raise DrillError(f"wrangler kv key get {KV_KEYS[kind]} failed (exit {proc.returncode})")
    try:
        doc = json.loads(proc.stdout)
    except ValueError as err:
        raise DrillError(f"{KV_KEYS[kind]} is not JSON: {err}") from err
    if not isinstance(doc, dict) or not isinstance(doc.get("version"), int):
        raise DrillError(f"{KV_KEYS[kind]} has no integer version")
    return doc


def snapshot(run: Runner, worker: Path, env: str, base: Path | None) -> dict[str, Any]:
    """The current config file (``public`` + ``server``): from KV or ``base``."""
    if base is not None:
        data = json.loads(base.read_text(encoding="utf-8"))
        if not isinstance(data, dict) or "public" not in data or "server" not in data:
            raise DrillError(f"{base} is not a remote_config file (public + server)")
        return {"$schema": SCHEMA_REF, "public": data["public"], "server": data["server"]}
    return {"$schema": SCHEMA_REF, "public": kv_get(run, worker, env, "public"),
            "server": kv_get(run, worker, env, "server")}


def stored_version(config: dict[str, Any]) -> int:
    """The higher of the two documents' versions."""
    return max(int(config["public"]["version"]), int(config["server"]["version"]))


def with_version(config: dict[str, Any], version: int) -> dict[str, Any]:
    """A deep copy of ``config`` with both documents at ``version``."""
    out = copy.deepcopy(config)
    out["public"]["version"] = version
    out["server"]["version"] = version
    return out


def overlay(config: dict[str, Any], switch: str, version: int) -> dict[str, Any]:
    """The drill overlay of ``switch`` over ``config``, at ``version``."""
    out = with_version(config, version)
    if switch == "readings":
        out["public"]["readings.enabled"] = False
    else:
        for key in ("ai.budget.softFloorUsd", "ai.budget.freeStopFloorUsd", "ai.budget.dailyHardUsd"):
            out["server"][key] = 0
    return out


def write_config(config: dict[str, Any], path: Path) -> Path:
    """Writes ``config`` as JSON to ``path``."""
    path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    return path


def push(run: Runner, worker: Path, env: str, file: Path, *, dry_run: bool) -> None:
    """``npm run config:push -- --env <env> --file <file> [--dry-run]``."""
    args = ["npm", "run", "--silent", "config:push", "--", "--env", env, "--file", str(file)]
    if dry_run:
        args.append("--dry-run")
    proc = run(args, cwd=worker, capture_output=True, text=True)
    for line in (proc.stdout or "").splitlines():
        print(f"  {line}")
    if proc.returncode != 0:
        detail = (proc.stderr or "").strip()
        raise DrillError(f"config:push {file.name} failed (exit {proc.returncode}): {detail}")


def wait_for_version(fetch: Fetch, env: str, version: int, sleep: Callable[[float], None],
                     timeout_sec: int = CACHE_SETTLE_SEC * 2) -> dict[str, Any]:
    """Polls ``GET /v1/config`` until it serves ``version`` (cache expiry)."""
    url = f"{API_HOSTS[env]}/v1/config"
    waited = 0
    while True:
        try:
            body = fetch(url)
        except OSError as err:
            body = {"error": str(err)}
        if body.get("version") == version:
            return body
        if waited >= timeout_sec:
            raise DrillError(f"{url} still serves version {body.get('version')!r}, expected {version}")
        sleep(5)
        waited += 5


def restore(run: Runner, fetch: Fetch, worker: Path, env: str, original: dict[str, Any], version: int,
            workdir: Path, sleep: Callable[[float], None], *, dry_run: bool) -> None:
    """Pushes ``original`` back at ``version`` and waits until it is served."""
    file = write_config(with_version(original, version), workdir / "restore.json")
    print(f"restore: push the pre-drill config as version {version}")
    push(run, worker, env, file, dry_run=dry_run)
    if not dry_run:
        wait_for_version(fetch, env, version, sleep)
        print(f"restore: {env} serves version {version} again")


def drill(args: argparse.Namespace, run: Runner, fetch: Fetch, sleep: Callable[[float], None],
          workdir: Path) -> int:
    """Runs one drill (or ``--restore``); returns the exit code."""
    worker = args.root / "worker"
    if args.restore is not None:
        original = json.loads(args.restore.read_text(encoding="utf-8"))
        current = snapshot(run, worker, args.env, args.base)
        restore(run, fetch, worker, args.env, original, stored_version(current) + 1, workdir, sleep,
                dry_run=args.dry_run)
        return 0

    original = snapshot(run, worker, args.env, args.base)
    base_version = stored_version(original)
    write_config(original, args.snapshot)
    print(f"snapshot: version {base_version} saved to {args.snapshot}")
    drill_file = write_config(overlay(original, args.switch, base_version + 1), workdir / "overlay.json")
    print(f"overlay: --switch {args.switch} as version {base_version + 1}")
    if args.dry_run:
        push(run, worker, args.env, drill_file, dry_run=True)
        restore(run, fetch, worker, args.env, original, base_version + 2, workdir, sleep, dry_run=True)
        print("dry run: both files are valid; nothing written")
        return 0

    push(run, worker, args.env, drill_file, dry_run=False)
    failure: DrillError | None = None
    try:
        served = wait_for_version(fetch, args.env, base_version + 1, sleep)
        if args.switch == "readings" and served.get("readings.enabled") is not False:
            raise DrillError("GET /v1/config does not serve readings.enabled = false")
        print(f"active: {args.switch} switch is live on {args.env}; holding {args.hold} s for the app checks")
        sleep(args.hold)
    except DrillError as err:
        failure = err
    try:
        restore(run, fetch, worker, args.env, original, base_version + 2, workdir, sleep, dry_run=False)
    except DrillError as err:
        prefix = f"{failure}; " if failure is not None else ""
        raise DrillError(f"{prefix}restore failed: {err}; re-run with --restore {args.snapshot}") from err
    if failure is not None:
        raise failure
    return 0


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    """The CLI; ``prod`` is not a choice."""
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--env", choices=ENVIRONMENTS, default="staging")
    parser.add_argument("--switch", choices=SWITCHES, default="readings")
    parser.add_argument("--hold", type=int, default=DEFAULT_HOLD_SEC, help="seconds the switch stays on")
    parser.add_argument("--base", type=Path, help="remote_config file to use instead of reading KV")
    parser.add_argument("--snapshot", type=Path, help="where the pre-drill config is saved")
    parser.add_argument("--restore", type=Path, help="push this snapshot back (after an interrupted drill)")
    parser.add_argument("--dry-run", action="store_true", help="validate the plan; write nothing remote")
    parser.add_argument("--root", type=Path, help="repository root (default: auto)")
    args = parser.parse_args(list(argv))
    if args.hold < 0:
        parser.error("--hold must be >= 0")
    return args


def main(argv: Sequence[str] | None = None, *, run: Runner = subprocess.run, fetch: Fetch = http_get_json,
         sleep: Callable[[float], None] = time.sleep) -> int:
    """Entry point (``tools/kill_switch_drill.py --env staging --switch readings``)."""
    args = parse_args(sys.argv[1:] if argv is None else argv)
    args.root = (args.root or find_repo_root(Path.cwd())).resolve()
    with tempfile.TemporaryDirectory(prefix="taro-drill-") as tmp:
        workdir = Path(tmp)
        if args.snapshot is None:
            args.snapshot = Path(tempfile.gettempdir()) / f"taro-drill-{args.env}-snapshot.json"
        try:
            return drill(args, run, fetch, sleep, workdir)
        except (DrillError, OSError, ValueError, KeyError) as err:
            print(f"kill_switch_drill: {err}", file=sys.stderr)
            return 1


if __name__ == "__main__":
    sys.exit(main())

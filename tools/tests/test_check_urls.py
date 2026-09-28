"""Tests for tools/check_urls.py (05 CS10, §9.6)."""

from __future__ import annotations

import runpy
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

import pytest
from fixture_tree import REPO, fail_cases, materialize

import check_urls as cu
from taro_tools.checkkit import InputError

CHECK = "check_urls"
EXPECTED_OFFLINE = {"fail_http", "fail_placeholder", "fail_host"}
MALFORMED = {"fail_malformed_arb", "fail_malformed_aso"}
PASS_URLS = {
    "https://taro.vshyrochuk.com/privacy",
    "https://taro.vshyrochuk.com/support",
    "https://taro.vshyrochuk.com/terms",
    "https://taro.vshyrochuk.com/terms?hl=de",
}


def ok_fetch(url: str) -> int:
    return 200


def test_every_fixture_is_covered() -> None:
    assert set(fail_cases(CHECK)) == EXPECTED_OFFLINE | MALFORMED


def test_pass_tree_collects_urls(tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    arbs = {"en": cu.load_arb(root / cu.arb_path("en"), "en"), "de": cu.load_arb(root / cu.arb_path("de"), "de")}
    refs = cu.collect(cu.load_aso(root), arbs)
    assert {r.url for r in refs} == PASS_URLS
    assert not any("ssv" in r.url for r in refs)


@pytest.mark.parametrize("offline", [True, False])
def test_pass_tree_is_clean(offline: bool, tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    argv = ["--root", str(root)] + (["--offline"] if offline else [])
    assert cu.main(argv, fetch=ok_fetch) == 0
    out = capsys.readouterr().out
    assert "4 distinct URL(s)" in out and "check_urls: OK" in out


@pytest.mark.parametrize("case", sorted(EXPECTED_OFFLINE))
def test_offline_fail_modes(case: str, tmp_path: Path) -> None:
    root = materialize(CHECK, case, tmp_path)
    findings, _ = cu.check(root, offline=True)
    assert len(findings) == 1 and findings[0].rule == "url"
    assert cu.main(["--root", str(root), "--offline"]) == 1


@pytest.mark.parametrize("case", sorted(MALFORMED))
def test_malformed_inputs_fail(case: str, tmp_path: Path) -> None:
    root = materialize(CHECK, case, tmp_path)
    with pytest.raises(InputError):
        cu.check(root, offline=True)
    assert cu.main(["--root", str(root), "--offline"]) == 1


def test_online_reports_non_200_once_per_url(tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    calls: list[str] = []

    def fetch(url: str) -> int:
        calls.append(url)
        if url.endswith("/terms"):
            return 404
        if url.endswith("/support"):
            raise urllib.error.URLError("no route")
        return 200

    findings, _ = cu.check(root, offline=False, fetch=fetch)
    assert sorted(calls) == sorted(PASS_URLS)
    messages = sorted(f.message for f in findings)
    # /terms appears in aso.yaml and app_en.arb: two refs, one fetch.
    assert len([m for m in messages if "HTTP 404" in m]) == 2
    assert len([m for m in messages if "request failed" in m]) == 1


def test_missing_inputs_are_skipped(tmp_path: Path) -> None:
    findings, notices = cu.check(tmp_path, offline=True)
    assert findings == []
    assert len(notices) == 3 and "0 distinct" in notices[-1]


@pytest.mark.parametrize(
    ("url", "problem"),
    [
        ("https://taro.vshyrochuk.com/privacy", None),
        ("http://taro.vshyrochuk.com", "https"),
        ("https://localhost:8787/x", "public domain"),
        ("https://.example/x", "public domain"),
        ("https://taro.vshyrochuk.com/XXXX", "placeholder"),
    ],
)
def test_syntax_problem(url: str, problem: str | None) -> None:
    result = cu.syntax_problem(url)
    assert (result is None) if problem is None else (problem in (result or ""))


def test_urls_in_strips_punctuation() -> None:
    assert cu.urls_in("See https://a.example/x). And https://b.example/y, ok") == [
        "https://a.example/x",
        "https://b.example/y",
    ]


class _Response:
    def __init__(self, status: int) -> None:
        self.status = status

    def __enter__(self) -> _Response:
        return self

    def __exit__(self, *exc: object) -> None:
        return None


def test_default_fetch_head_then_get(monkeypatch: pytest.MonkeyPatch) -> None:
    methods: list[str] = []

    def urlopen(request: urllib.request.Request, timeout: float) -> Any:
        methods.append(request.get_method())
        if request.get_method() == "HEAD":
            raise urllib.error.HTTPError(request.full_url, 405, "no HEAD", {}, None)  # type: ignore[arg-type]
        return _Response(200)

    monkeypatch.setattr(urllib.request, "urlopen", urlopen)
    assert cu.default_fetch("https://taro.vshyrochuk.com/") == 200
    assert methods == ["HEAD", "GET"]


def test_default_fetch_returns_error_status(monkeypatch: pytest.MonkeyPatch) -> None:
    def urlopen(request: urllib.request.Request, timeout: float) -> Any:
        raise urllib.error.HTTPError(request.full_url, 404, "gone", {}, None)  # type: ignore[arg-type]

    monkeypatch.setattr(urllib.request, "urlopen", urlopen)
    assert cu.default_fetch("https://taro.vshyrochuk.com/x") == 404


def test_default_fetch_head_ok(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(urllib.request, "urlopen", lambda request, timeout: _Response(200))
    assert cu.default_fetch("https://taro.vshyrochuk.com/") == 200


def test_current_repository_passes_offline() -> None:
    assert cu.check(REPO, offline=True)[0] == []


def test_script_entry_point(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    root = materialize(CHECK, "pass", tmp_path)
    monkeypatch.setattr(sys, "argv", ["check_urls.py", "--root", str(root), "--offline"])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(str(REPO / "tools" / "check_urls.py"), run_name="__main__")
    assert exit_info.value.code == 0


def test_default_fetch_get_error_after_refused_head(monkeypatch: pytest.MonkeyPatch) -> None:
    def urlopen(request: urllib.request.Request, timeout: float) -> Any:
        code = 403 if request.get_method() == "HEAD" else 410
        raise urllib.error.HTTPError(request.full_url, code, "no", {}, None)  # type: ignore[arg-type]

    monkeypatch.setattr(urllib.request, "urlopen", urlopen)
    assert cu.default_fetch("https://taro.vshyrochuk.com/x") == 410

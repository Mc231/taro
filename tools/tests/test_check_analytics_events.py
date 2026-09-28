from pathlib import Path

import pytest

import check_analytics_events as c
from fixture_repo import REPO, make_root

CHECK = "check_analytics_events"


def _findings(tmp_path: Path, case: str) -> list:
    findings, _ = c.run(make_root(tmp_path, CHECK, case))
    return findings


def test_pass(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    findings, notices = c.run(root)
    assert findings == []
    assert notices == ["4 event class(es), 4 documented event(s)"]
    assert c.main(["--root", str(root)]) == 0


def test_code_parsing(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    events = {e.name: e for e in c.code_events(root)}
    assert set(events) == {"reading_generated", "classic_reading_started", "classic_reading_completed", "rate_prompt_shown"}
    assert events["reading_generated"].params == ["spread_id", "latency_ms", "error"]
    assert events["classic_reading_started"].params == ["spread_id", "reason"]
    assert events["reading_generated"].string_fields == []


@pytest.mark.parametrize(
    ("case", "rules"),
    [
        ("fail_undocumented", ["undocumented"]),
        ("fail_not_in_code", ["not-in-code"]),
        ("fail_params", ["params-differ"]),
        ("fail_free_string", ["free-string"]),
        ("fail_bad_name", ["name", "name", "param-name", "param-name"]),
        ("fail_no_doc", ["missing"]),
        ("fail_duplicate", ["duplicate", "duplicate", "not-in-code"]),
    ],
)
def test_failures(tmp_path: Path, case: str, rules: list[str]) -> None:
    assert sorted(f.rule for f in _findings(tmp_path, case)) == rules
    assert c.main(["--root", str(make_root(tmp_path / "m", CHECK, case))]) == 1


def test_params_differ_message(tmp_path: Path) -> None:
    (finding,) = _findings(tmp_path, "fail_params")
    assert "only in code: latency" in finding.message and "only in doc: latency_ms" in finding.message


def test_too_many_params() -> None:
    event = c.Event("big_event", [f"p{i}" for i in range(26)], "x", 1)
    assert [f.rule for f in c.check_rules([event])] == ["params"]


def test_the_01_catalogue_follows_the_doc_rules() -> None:
    events = c.doc_events((REPO / "docs/specs/01_PRODUCT.md").read_text())
    assert len(events) > 50 and c.check_rules(events) == []


def test_unterminated_sources_do_not_crash() -> None:
    assert c.dart_events("final class A { String get eventName => 'a", "x")[0].name == "a"
    events = c.dart_events("final class B { String get eventName => 'b'; Map get parameters => {'k': 1", "x")
    assert events[0].params == ["k"]
    assert c.dart_events("final class C { String get eventName => 'c'; get params => {'k", "x")[0].params == []


def test_absent_is_skipped(tmp_path: Path) -> None:
    findings, notices = c.run(make_root(tmp_path, CHECK, None))
    assert findings == [] and "not present yet" in notices[0]


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0

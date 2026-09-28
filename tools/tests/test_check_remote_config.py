from pathlib import Path

import pytest

import check_remote_config as c
from fixture_repo import REPO, make_root

CHECK = "check_remote_config"
SPECS = ("GLOSSARY.md", "02_ARCHITECTURE.md")


def _root(tmp_path: Path, case: str | None) -> Path:
    return make_root(tmp_path, CHECK, case, SPECS)


def _rules(tmp_path: Path, case: str) -> list[str]:
    findings, _ = c.run(_root(tmp_path, case))
    return sorted(f.rule for f in findings)


def test_pass(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    assert c.run(root) == ([], [])
    assert c.main(["--root", str(root)]) == 0


def test_unknown_keys(tmp_path: Path) -> None:
    findings, _ = c.run(_root(tmp_path, "fail_unknown_key"))
    assert sorted(f.message.split("'")[1] for f in findings) == ["readings.costCelticCross", "spreads.costs.celtic_cross"]


def test_missing_client_defaults(tmp_path: Path) -> None:
    findings, _ = c.run(_root(tmp_path, "fail_missing_default"))
    assert sorted(f.message.split("'")[1] for f in findings) == ["rewarded.loadTimeoutSec", "support.email"]


def test_schema_violations(tmp_path: Path) -> None:
    findings, _ = c.run(_root(tmp_path, "fail_schema"))
    assert [f.rule for f in findings] == ["schema", "schema"]
    assert any(f.message.startswith("public/readings/freeDaily") for f in findings)


@pytest.mark.parametrize(
    ("case", "rules"), [("fail_no_schema", ["schema-missing"]), ("fail_bad_schema", ["invalid-schema"])]
)
def test_schema_file_problems(tmp_path: Path, case: str, rules: list[str]) -> None:
    assert _rules(tmp_path, case) == rules


@pytest.mark.parametrize("case", ["fail_malformed", "fail_not_object"])
def test_malformed_defaults(tmp_path: Path, case: str) -> None:
    assert c.main(["--root", str(_root(tmp_path, case))]) == 1


def test_absent_is_skipped(tmp_path: Path) -> None:
    findings, notices = c.run(_root(tmp_path, None))
    assert findings == [] and "not present yet" in notices[0]


def test_spec_parsing() -> None:
    glossary = (REPO / c.GLOSSARY).read_text()
    keys = c.glossary_keys(glossary)
    assert {"app.minVersion.ios", "store.packs", "store.packs[].credits", "ai.maxTokensBySpread"} <= keys
    client = c.client_keys((REPO / c.ARCHITECTURE).read_text())
    assert "support.email" in client and "ai.blockedCountries" not in client and "store.packs" in client
    assert c.expand_key("app.minVersion.{ios, android}") == ["app.minVersion.ios", "app.minVersion.android"]
    with pytest.raises(c.InputError):
        c.glossary_keys("# nothing")
    with pytest.raises(c.InputError):
        c.glossary_keys("## 8. Remote-config keys\n\nno tables\n")
    with pytest.raises(c.InputError):
        c.client_keys("# nothing")
    with pytest.raises(c.InputError):
        c.client_keys("### 9.4 Remote config keys consumed by the client\n\nno list\n")


def test_check_keys_reports_spec_drift() -> None:
    findings = c.check_keys({"a.b": 1}, {"a.b"}, {"a.b", "c.d"})
    assert sorted(f.rule for f in findings) == ["missing-default", "spec-drift"]


def test_flatten_shapes() -> None:
    assert c.flatten({"version": 2, "a": {"b": 1, "c": {}}}, set()) == {"a.b": 1, "a.c": {}}
    assert c.flatten({"public": {"x.y": 1}, "extra": {"z": 2}}, {"x.y"}) == {"x.y": 1, "extra.z": 2}


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0

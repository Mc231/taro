from pathlib import Path

import pytest

import check_worker_env as c
from fixture_repo import REPO, make_root

CHECK = "check_worker_env"


def test_pass(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    assert c.run(root) == ([], [])
    assert c.main(["--root", str(root)]) == 0


def test_prod_vars_fail(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = make_root(tmp_path, CHECK, "fail_prod_var")
    findings, _ = c.run(root)
    assert {f.message.split(" ")[0] for f in findings} == {
        "env.prod.vars.AI_PROVIDER",
        "env.prod.vars.ALLOW_DEBUG_ATTESTATION",
    }
    assert c.main(["--root", str(root)]) == 1
    assert "RC86" in capsys.readouterr().out


def test_prod_secret_named_in_a_list_fails(tmp_path: Path) -> None:
    findings, _ = c.run(make_root(tmp_path, CHECK, "fail_prod_secret_list"))
    assert len(findings) == 1
    assert "DEBUG_ATTESTATION_TOKEN" in findings[0].message


def test_missing_prod_env_fails(tmp_path: Path) -> None:
    findings, _ = c.run(make_root(tmp_path, CHECK, "fail_no_prod"))
    assert [f.rule for f in findings] == ["prod-missing"]
    assert c.check_config({"env": "oops"})[0].rule == "prod-missing"


def test_malformed_toml_fails(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "fail_malformed")
    assert c.main(["--root", str(root)]) == 1


def test_absent_wrangler_is_skipped(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    findings, notices = c.run(root)
    assert findings == [] and "not present yet" in notices[0]


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0

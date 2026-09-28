import json
from pathlib import Path

import pytest

import check_glossary as c
from fixture_repo import REPO, make_root

CHECK = "check_glossary"
SPECS = ("GLOSSARY.md",)
GLOSSARY_TEXT = (REPO / c.GLOSSARY).read_text()


def _root(tmp_path: Path, case: str | None) -> Path:
    return make_root(tmp_path, CHECK, case, SPECS)


def _rules(tmp_path: Path, case: str) -> list[str]:
    findings, _ = c.run(_root(tmp_path, case))
    return sorted(f.rule for f in findings)


def test_pass(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    findings, notices = c.run(root)
    assert findings == []
    assert notices == []
    assert c.main(["--root", str(root)]) == 0


def test_partial_tree_only_notes(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = _root(tmp_path, "partial")
    findings, notices = c.run(root)
    assert findings == []
    assert len(notices) >= 14
    assert c.main(["--root", str(root), "--quiet"]) == 0
    assert "note:" not in capsys.readouterr().out


@pytest.mark.parametrize(
    ("case", "rules"),
    [
        ("fail_cards", ["card-name", "cards", "cards"]),
        ("fail_spreads", ["positions", "spreads", "spreads", "spreads", "spreads", "spreads"]),
        ("fail_products", ["products", "products"]),
        ("fail_endpoints", ["endpoint", "endpoint"]),
        ("fail_errors", ["error-code", "error-code"]),
        ("fail_failure_arb", ["arb-key", "arb-key", "failure"]),
        ("fail_refusal", ["refusal"]),
        ("fail_config", ["config-key", "config-key", "max-tokens"]),
        ("fail_routes", ["route"]),
        ("fail_secure_keys", ["secure-key", "secure-key"]),
        (
            "fail_wrangler",
            ["binding", "binding", "d1", "dataset", "env-field", "environment", "var", "var", "var", "worker-name"],
        ),
        ("fail_packages", ["package", "package-dep", "package-name", "package-name", "package-path"]),
        (
            "fail_identifiers",
            ["api-host", "api-host", "bundle-id", "bundle-id", "flavor-config", "locale", "locale", "supportEmail"],
        ),
    ],
)
def test_failures(tmp_path: Path, case: str, rules: list[str]) -> None:
    assert _rules(tmp_path, case) == rules
    assert c.main(["--root", str(_root(tmp_path / "m", case))]) == 1


def test_glossary_parse() -> None:
    g = c.parse_glossary(GLOSSARY_TEXT)
    assert len(g.cards) == 78 and g.cards["major_08"] == "Strength"
    assert g.spreads["celtic_cross"][-1] == "outcome" and g.max_tokens["*"] == 4000
    assert ("POST", "/v1/readings/{clientReadingId}/ack") in g.endpoints
    assert g.failures["TimeoutFailure"] == "failureTimeout"
    assert g.refusals["selfHarm"] == "safetyDeclinedSelfHarm"
    assert g.environments["prod"]["worker"] == "taro-api"
    assert g.packages["taro"]["deps"] == {"taro_core", "taro_ui", "taro_attestation"}
    assert c.check_self(g) == []


def test_self_check_catches_broken_tables() -> None:
    g = c.parse_glossary(GLOSSARY_TEXT)
    g.cards.pop("major_00")
    g.products.add("com.other.app.x")
    g.max_tokens.pop("single")
    assert sorted(f.rule for f in c.check_self(g)) == ["cards", "products", "spreads"]


@pytest.mark.parametrize(
    "mutate",
    [
        lambda t: t.replace("## 1. Card IDs", "## 1. Cards"),
        lambda t: t.replace("| `spreadId` |", "| `spread` |"),
        lambda t: t.replace("| HTTP | `code` |", "| Status | `code` |")
        .replace("| `Failure` | Raised by", "| `Fail` | Raised by")
        .replace("| Wire `category` |", "| Wire |"),
    ],
)
def test_parse_errors(mutate) -> None:
    with pytest.raises(c.InputError):
        c.parse_glossary(mutate(GLOSSARY_TEXT))


def test_missing_glossary(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    assert c.main(["--root", str(root)]) == 1


@pytest.mark.parametrize(
    ("relative", "content"),
    [
        ("apps/taro/content/source/glossary.yaml", "- a list\n"),
        ("apps/taro/config/dev.json", "[]"),
        ("packages/taro_core/pubspec.yaml", "- nope\n"),
        ("worker/wrangler.toml", "[env\n"),
    ],
)
def test_malformed_inputs(tmp_path: Path, relative: str, content: str) -> None:
    root = _root(tmp_path, "pass")
    (root / relative).write_text(content)
    assert c.main(["--root", str(root)]) == 1


def test_flavor_config_with_unknown_flavor(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    path = root / "apps/taro/config/staging.json"
    data = json.loads(path.read_text())
    data["flavor"] = "beta"
    path.write_text(json.dumps(data))
    findings, _ = c.run(root)
    assert [f.rule for f in findings] == ["flavor"]


def test_missing_platform_files_are_notes(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    (root / "apps/taro/android/app/build.gradle.kts").write_text('android { productFlavors { create("dev") {} } }\n')
    (root / "apps/taro/lib/l10n/arb").rename(root / "arb_elsewhere")
    (root / "apps/taro/config").rename(root / "config_elsewhere")
    (root / "worker/src/routes").rename(root / "routes_elsewhere")
    (root / "packages/taro_core/lib/src/result/failure.dart").unlink()
    (root / "packages/taro_core/lib/src/model/safety_info.dart").unlink()
    findings, notices = c.run(root)
    assert findings == []
    assert any("l10n/arb" in n for n in notices) and any("apps/taro/config" in n for n in notices)
    assert any("worker/src/routes" in n for n in notices)


def test_android_bundles() -> None:
    assert c.android_bundles("no application id here") == {}
    gradle = 'applicationId = "a.b"\nproductFlavors {\n create("dev") { applicationIdSuffix = ".dev" }\n create("prod") {\n}\n'
    assert c.android_bundles(gradle) == {"dev": "a.b.dev", "prod": "a.b"}


def test_ts_routes() -> None:
    source = "createRoute({ path: '/v1/x/{id}', method: 'post' }); app.delete('/v1/y/:id', h); createRoute({ path: '/v1/z' })"
    assert c.ts_routes(source) == {("POST", "/v1/x/{id}"), ("DELETE", "/v1/y/{id}")}


def test_real_repository_has_only_the_known_drift() -> None:
    findings, _ = c.run(REPO)
    # Known drift reported to the owner (Phase 3): the Dart tools package is
    # named `taro_dart_tools` in its pubspec but `dart_tools` in GLOSSARY §14.1.
    assert {(f.path, f.rule) for f in findings} <= {("tools/dart_tools/pubspec.yaml", "package-name")}

"""check_install_size.py: build outputs are made in ``tmp_path`` (``build/``
is gitignored, so there is no fixture tree)."""

import zipfile
from pathlib import Path

import pytest

import check_install_size as c
from fixture_repo import make_root

CHECK = "check_install_size"


def _zip(path: Path, entries: dict[str, bytes]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_STORED) as z:
        for name, data in entries.items():
            z.writestr(name, data)
        z.mkdir("base/assets/")
    return path


def _aab(root: Path, entries: dict[str, bytes] | None = None) -> Path:
    return _zip(
        root / "apps/taro/build/app/outputs/bundle/prodRelease/app-prod-release.aab",
        entries
        or {
            "base/dex/classes.dex": b"d" * 100,
            "base/lib/arm64-v8a/libapp.so": b"a" * 1000,
            "base/lib/armeabi-v7a/libapp.so": b"b" * 700,
            "base/lib/x86_64/libapp.so": b"c" * 900,
            "META-INF/KEY.SF": b"s" * 5000,
            "BUNDLE-METADATA/x": b"m" * 5000,
        },
    )


def _ipa(root: Path) -> Path:
    return _zip(root / "apps/taro/build/ios/ipa/Taro.ipa", {"Payload/Runner.app/Runner": b"r" * 300})


def test_no_build_is_skipped_or_required(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = make_root(tmp_path, CHECK, None)
    findings, notices = c.run(root)
    assert findings == [] and len(notices) == 2 and "skipped" in notices[0]
    assert c.main(["--root", str(root)]) == 0
    assert sorted(f.rule for f in c.run(root, require=True)[0]) == ["missing", "missing"]
    report = tmp_path / "summary.md"
    assert c.main(["--root", str(root), "--require", "--report", str(report)]) == 1
    assert "no release build" in report.read_text()
    capsys.readouterr()


def test_measures_ipa_and_aab_per_abi(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    _ipa(root)
    _aab(root)
    rows, findings, _ = c.measure(root, None, None, True)
    assert findings == []
    assert rows == [
        ("iOS", "apps/taro/build/ios/ipa/Taro.ipa", 300, 60.0),
        ("Android", "arm64-v8a", 1100, 40.0),
        ("Android", "armeabi-v7a", 800, 40.0),
        ("Android", "x86_64", 1000, 40.0),
    ]
    report = tmp_path / "summary.md"
    assert c.main(["--root", str(root), "--report", str(report)]) == 0
    assert "| Android | x86_64 | 0.00 | 40 | ok |" in report.read_text()


def test_app_dir_fallback_and_universal_bundle(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    app = root / c.APP_DIR
    (app / "Frameworks").mkdir(parents=True)
    (app / "Runner").write_bytes(b"x" * 10_000)
    (app / "Frameworks" / "App").write_bytes(b"y" * 10_000)
    aab = _aab(root, {"base/dex/classes.dex": b"d" * 10})
    rows, _, _ = c.measure(root, None, aab, False)
    assert rows[0][0:2] == ("iOS", f"{c.APP_DIR} (deflated)")
    assert 0 < rows[0][2] < 20_000
    assert rows[1] == ("Android", "universal", 10, 40.0)


def test_explicit_paths_and_over_budget(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    root = make_root(tmp_path, CHECK, None)
    ipa = _ipa(tmp_path / "elsewhere")
    aab = _aab(tmp_path / "elsewhere")
    monkeypatch.setattr(c, "IOS_MAX_MB", 0.0002)
    monkeypatch.setattr(c, "ANDROID_MAX_MB", 0.001)
    findings, _ = c.run(root, ipa=ipa, aab=aab)
    assert sorted(f.rule for f in findings) == ["over-budget", "over-budget"]
    assert sorted(f.path for f in findings)[0].endswith("Taro.ipa")
    assert sorted(f.path for f in findings)[1] == "arm64-v8a"
    report = tmp_path / "r.md"
    c.run(root, ipa=ipa, aab=aab, report_path=report)
    assert "**over**" in report.read_text()


def test_unreadable_archives_are_malformed_input(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, None)
    bad = tmp_path / "bad.zip"
    bad.write_bytes(b"not a zip")
    assert c.main(["--root", str(root), "--ipa", str(bad)]) == 1
    assert c.main(["--root", str(root), "--aab", str(bad)]) == 1


def test_abi_of() -> None:
    assert c._abi_of("base/lib/x86_64/libflutter.so") == "x86_64"
    assert c._abi_of("base/lib/README") is None
    assert c._abi_of("base/dex/classes.dex") is None

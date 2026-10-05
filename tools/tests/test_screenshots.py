"""tools/screenshots: the store screenshot pipeline (05 §9.4, Phase 20.2)."""

from __future__ import annotations

import json
import shutil
import stat
import struct
import subprocess
import zlib
from pathlib import Path

import pytest

from screenshots import screenshots as shots
from taro_tools.checkkit import InputError

TOOLS = Path(__file__).resolve().parents[1]
REPO = TOOLS.parent


def _png(path: Path, width: int, height: int) -> Path:
    """A minimal valid PNG of ``width`` × ``height``."""
    path.parent.mkdir(parents=True, exist_ok=True)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0)
    chunk = b"IHDR" + ihdr
    data = (
        b"\x89PNG\r\n\x1a\n"
        + struct.pack(">I", len(ihdr))
        + chunk
        + struct.pack(">I", zlib.crc32(chunk))
    )
    path.write_bytes(data)
    return path


@pytest.fixture()
def root(tmp_path: Path) -> Path:
    """A repo root with the real fixtures, aso.yaml and fonts path."""
    r = tmp_path / "repo"
    (r / "docs" / "specs").mkdir(parents=True)
    shutil.copytree(REPO / shots.FIXTURES_DIR, r / shots.FIXTURES_DIR)
    aso = r / "apps" / "taro" / "store" / "aso.yaml"
    aso.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(REPO / "apps" / "taro" / "store" / "aso.yaml", aso)
    return r


def _fixture(root: Path, locale: str) -> dict:
    return json.loads((root / shots.FIXTURES_DIR / f"{locale}.json").read_text())


def _write_fixture(root: Path, locale: str, data: dict) -> None:
    (root / shots.FIXTURES_DIR / f"{locale}.json").write_text(json.dumps(data))


# --- fixtures ---------------------------------------------------------------


def test_real_fixtures_and_captions_pass(root: Path) -> None:
    assert shots.main(["--root", str(root), "lint"]) == 0


def test_generated_dart_is_up_to_date() -> None:
    assert shots.main(["--root", str(REPO), "fixtures", "--check"]) == 0


def test_fixtures_write_then_check(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert shots.main(["--root", str(root), "fixtures", "--check"]) == 1
    assert "stale" in capsys.readouterr().out
    assert shots.main(["--root", str(root), "fixtures"]) == 0
    text = (root / shots.DART_OUT).read_text()
    assert text.startswith("// GENERATED")
    assert "'uk': r'''" in text
    assert shots.main(["--root", str(root), "fixtures", "--check"]) == 0


def test_missing_fixture_is_malformed(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    (root / shots.FIXTURES_DIR / "ko.json").unlink()
    assert shots.main(["--root", str(root), "lint"]) == 1
    assert "missing store reading fixture" in capsys.readouterr().out


def test_fixture_not_an_object(root: Path) -> None:
    (root / shots.FIXTURES_DIR / "ko.json").write_text("[]")
    with pytest.raises(InputError, match="object"):
        shots.load_fixtures(root)


def test_triple_quote_cannot_be_embedded(root: Path) -> None:
    data = _fixture(root, "en")
    data["question"] = "a ''' b"
    _write_fixture(root, "en", data)
    with pytest.raises(InputError, match="'''"):
        shots.render_fixtures_dart(shots.load_fixtures(root))


def test_forbidden_and_malformed_fixture(root: Path) -> None:
    data = _fixture(root, "de")
    data["locale"] = "en"
    data["dailyCardId"] = "major_13"
    data["cards"][1]["cardId"] = "major_16"
    data["cards"][2]["reversed"] = True
    data["reading"]["title"] = " "
    data["reading"]["cards"] = data["reading"]["cards"][:2] + [{"positionId": "future", "interpretation": ""}]
    data["reading"]["reflectionPrompts"] = []
    data["journal"][0]["title"] = ""
    data["journal"][0]["cards"] = []
    data["question"] = ""
    found = shots.fixture_findings({"de": data})
    text = "\n".join(found)
    assert "locale is 'en'" in text
    assert "major_13 may not appear" in text
    assert "major_16 may not appear" in text
    assert "upright" in text
    assert "reading.title is empty" in text
    assert "interpretation is empty" in text
    assert "reflectionPrompts" in text
    assert "journal[0].title is empty" in text
    assert "journal[0].cards is empty" in text
    assert "question must be a non-empty string" in text


def test_unsupported_spread_and_wrong_positions(root: Path) -> None:
    data = _fixture(root, "en")
    other = json.loads(json.dumps(data))
    data["spreadId"] = "celtic_cross"
    other["cards"] = list(reversed(other["cards"]))
    other["reading"]["cards"] = list(reversed(other["reading"]["cards"]))
    found = shots.fixture_findings({"en": data, "fr": other | {"locale": "fr"}})
    text = "\n".join(found)
    assert "not a supported spread" in text
    assert "cards must cover past, present, future in order" in text
    assert "reading.cards must follow the draw positions" in text


def test_lint_reports_problems(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    data = _fixture(root, "it")
    data["dailyCardId"] = "major_15"
    _write_fixture(root, "it", data)
    assert shots.main(["--root", str(root), "lint"]) == 1
    out = capsys.readouterr().out
    assert "major_15" in out and "FAILED" in out


def test_lint_without_aso(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    (root / "apps" / "taro" / "store" / "aso.yaml").unlink()
    assert shots.main(["--root", str(root), "lint"]) == 1
    assert "missing" in capsys.readouterr().out


# --- captions ---------------------------------------------------------------


def test_load_captions_shapes() -> None:
    aso = {
        "store_screenshots": {
            "screenshots": [{"file": f"{f}.png", "headline": "H", "subtext": "S"} for f in shots.FRAMES],
            "translations": {"de": ["plain"] * 7},
        }
    }
    captions = shots.load_captions(aso)
    assert captions["en"][0] == ("H", "S")
    assert captions["de"][0] == ("plain", "")


@pytest.mark.parametrize(
    ("aso", "message"),
    [
        ({}, "missing"),
        ({"store_screenshots": {"screenshots": "x"}}, "must be a list"),
        ({"store_screenshots": {"screenshots": [{"file": "a.png", "headline": "h"}]}}, "files must be"),
    ],
)
def test_load_captions_errors(aso: dict, message: str) -> None:
    with pytest.raises(InputError, match=message):
        shots.load_captions(aso)


def test_caption_findings() -> None:
    good = [("Headline", "Sub")] * 7
    captions = {loc: good for loc in shots.LOCALES if loc != "ko"}
    captions["de"] = [("", "x"), ("H" * 40, "s" * 50)] + good[:4]
    captions["xx"] = good
    text = "\n".join(shots.caption_findings(captions))
    assert "no captions for ko" in text
    assert "unknown locale xx" in text
    assert "store_screenshots.de: 6 frames" in text
    assert "empty headline" in text
    assert "headline is 40 characters" in text
    assert "subtext is 50 characters" in text


# --- composition ------------------------------------------------------------


def test_png_size(tmp_path: Path) -> None:
    assert shots.png_size(_png(tmp_path / "a.png", 12, 34)) == (12, 34)
    bad = tmp_path / "b.png"
    bad.write_bytes(b"not a png at all, really not")
    with pytest.raises(InputError, match="not a PNG"):
        shots.png_size(bad)


@pytest.mark.parametrize(
    ("width", "height", "raw"),
    [(1320, 2868, (1320, 2868)), (2064, 2752, (2064, 2752)), (1080, 1920, (1080, 2424)), (1620, 2880, (1600, 2560))],
)
def test_layout_fits_the_canvas(width: int, height: int, raw: tuple[int, int]) -> None:
    g = shots.layout(width, height, raw)
    assert g.device_left >= 0
    assert g.device_left + g.device_width <= width
    assert g.device_top + g.device_height <= height
    inner = (g.device_width - 2 * g.pad, g.device_height - 2 * g.pad)
    assert abs(inner[0] / inner[1] - raw[0] / raw[1]) < 0.01


def test_frame_html_rtl_cjk_and_escaping(tmp_path: Path) -> None:
    raw = tmp_path / "shot.png"
    page = shots.frame_html(
        locale="ar", headline="<b>", subtext="", screen=raw, raw=(10, 20), width=1320, height=2868, fonts=tmp_path
    )
    assert 'dir="rtl"' in page and "TaroSansArabic" in page and "&lt;b&gt;" in page
    assert "class='sub'" not in page
    ja = shots.frame_html(
        locale="ja", headline="今日", subtext="一枚", screen=raw, raw=(10, 20), width=1320, height=2868, fonts=tmp_path
    )
    assert "auto-phrase" in ja and "NotoSerifJP" in ja and "class='sub'" in ja
    en = shots.frame_html(
        locale="en", headline="Hi", subtext="s", screen=raw, raw=(10, 20), width=1080, height=1920, fonts=tmp_path
    )
    assert 'dir="ltr"' in en and "Literata" in en and raw.resolve().as_uri() in en


def test_feature_graphic_html(tmp_path: Path) -> None:
    page = shots.feature_graphic_html(art=tmp_path, fonts=tmp_path, tagline="T & t")
    assert "major_17.webp" in page and "T &amp; t" in page and "1024px" in page


def _raw_tree(root: Path, locales: list[str], captures: list[str]) -> Path:
    raw = root / shots.RAW_DIR
    for capture in captures:
        for loc in locales:
            for frame in shots.FRAMES:
                _png(raw / capture / loc / f"{frame}.png", 100, 200)
    return raw


def _fake_runner(calls: list[tuple[Path, int, int]]) -> shots.Runner:
    def run(page: Path, out: Path, width: int, height: int) -> None:
        assert page.read_text().startswith("<!doctype html>")
        _png(out, width, height)
        calls.append((out, width, height))

    return run


def test_compose_feature_graphic_and_verify(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    _raw_tree(root, ["en", "ar"], ["iphone", "tablet"])
    calls: list[tuple[Path, int, int]] = []
    runner = _fake_runner(calls)
    args = ["--root", str(root), "compose", "--locales", "en,ar", "--targets", "iphone,tab7,tab10", "--workers", "2"]
    assert shots.main(args, runner=runner) == 0
    assert len(calls) == 2 * 3 * len(shots.FRAMES)
    out = root / shots.OUT_DIR
    assert shots.png_size(out / "android" / "tab10" / "ar" / "07_private.png") == (1620, 2880)
    verify = ["--root", str(root), "verify", "--locales", "en,ar", "--targets", "iphone,tab7,tab10"]
    assert shots.main(verify) == 1
    assert "feature_graphic.png: missing" in capsys.readouterr().out
    assert shots.main(["--root", str(root), "feature-graphic"], runner=runner) == 0
    assert shots.main(verify) == 0
    _png(out / "ios" / "iphone" / "en" / "01_spread.png", 10, 10)
    assert shots.main(verify) == 1
    assert "10×10, expected 1320×2868" in capsys.readouterr().out


def test_compose_reports_missing_captures(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    _raw_tree(root, ["en"], ["phone"])
    args = ["--root", str(root), "compose", "--locales", "en", "--targets", "phone,ipad"]
    assert shots.main(args, runner=_fake_runner([])) == 1
    assert "missing capture" in capsys.readouterr().out


def test_compose_without_aso(root: Path) -> None:
    (root / "apps" / "taro" / "store" / "aso.yaml").unlink()
    assert shots.main(["--root", str(root), "compose"], runner=_fake_runner([])) == 1


def test_unknown_locale_or_target(root: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert shots.main(["--root", str(root), "verify", "--locales", "en,xx"]) == 1
    assert "unknown locale: xx" in capsys.readouterr().out
    assert shots.main(["--root", str(root), "verify", "--targets", "watch"]) == 1


def test_chrome_runner_invokes_headless(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    seen: list[list[str]] = []

    def fake_run(cmd: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
        seen.append(cmd)
        assert kwargs["check"] is True
        return subprocess.CompletedProcess(cmd, 0)

    monkeypatch.setattr(shots.subprocess, "run", fake_run)
    shots.chrome_runner("/bin/chrome")(tmp_path / "a.html", tmp_path / "a.png", 10, 20)
    assert seen[0][0] == "/bin/chrome"
    assert "--window-size=10,20" in seen[0]
    assert f"--screenshot={tmp_path / 'a.png'}" in seen[0]


# --- shell scripts ------------------------------------------------------------

STUB = """#!/usr/bin/env bash
echo "{name} $*" >> "$STUB_LOG"
"""


def _script_env(tmp_path: Path) -> tuple[dict[str, str], Path]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log = tmp_path / "calls.log"
    for name in ("flutter", "xcrun", "adb", "emulator", "python", "asa"):
        stub = bin_dir / name
        stub.write_text(STUB.format(name=name))
        stub.chmod(stub.stat().st_mode | stat.S_IXUSR)
    env = {
        "PATH": "/usr/bin:/bin",
        "STUB_LOG": str(log),
        "TARO_FLUTTER": str(bin_dir / "flutter"),
        "TARO_XCRUN": str(bin_dir / "xcrun"),
        "TARO_ADB": str(bin_dir / "adb"),
        "TARO_EMULATOR": str(bin_dir / "emulator"),
        "TARO_PYTHON": str(bin_dir / "python"),
        "ASA": str(bin_dir / "asa"),
        "MIN_FREE_GB": "0",
    }
    return env, log


def _sh(script: str, *args: str, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(TOOLS / "screenshots" / script), *args], env=env, capture_output=True, text=True, check=False
    )


@pytest.mark.parametrize("script", ["take_screenshots.sh", "upload_store_assets.sh"])
def test_scripts_help_and_bad_input(tmp_path: Path, script: str) -> None:
    env, _ = _script_env(tmp_path)
    assert _sh(script, "--help", env=env).returncode == 0
    assert _sh(script, "--bogus", env=env).returncode == 2


def test_take_screenshots_dry_run_plans_every_step(tmp_path: Path) -> None:
    env, _ = _script_env(tmp_path)
    proc = _sh("take_screenshots.sh", "--dry-run", "--captures", "phone,tablet", "--locales", "en,ar", env=env)
    assert proc.returncode == 0, proc.stderr
    out = proc.stdout
    assert "STORE_SHOTS=phone" in out and "STORE_SHOTS=tablet" in out
    assert "STORE_LOCALES=en,ar" in out
    assert "compose --locales en,ar --targets phone,tab7,tab10" in out
    assert "feature-graphic" in out and "verify" in out


def test_take_screenshots_rejects_unknown_capture(tmp_path: Path) -> None:
    env, _ = _script_env(tmp_path)
    assert _sh("take_screenshots.sh", "--captures", "watch", env=env).returncode == 2


def test_take_screenshots_missing_simulator_fails(tmp_path: Path) -> None:
    env, _ = _script_env(tmp_path)
    proc = _sh("take_screenshots.sh", "--captures", "iphone", "--no-compose", "--keep-raw", env=env)
    assert proc.returncode == 1
    assert "not found" in proc.stderr


def test_upload_dry_run(tmp_path: Path) -> None:
    env, _ = _script_env(tmp_path)
    src = tmp_path / "shots"
    for d in ("ios/iphone", "ios/ipad", "android/phone", "android/tab7", "android/tab10"):
        _png(src / d / "pt" / "01_spread.png", 1, 1)
    proc = _sh("upload_store_assets.sh", "--dry-run", "--locales", "pt", "--source", str(src), env=env)
    out = proc.stdout
    assert "-d iphone-67 -l pt-BR" in out and "-d ipad-129 -l pt-BR" in out
    assert "--type tenInchScreenshots --language pt-BR" in out
    # The feature graphic lives in the repo build dir, absent in a clean tree
    # unless take_screenshots.sh ran.
    feature = REPO / "build" / "store" / "feature_graphic.png"
    assert proc.returncode == (0 if feature.is_file() else 1)
    ios = _sh("upload_store_assets.sh", "--dry-run", "--platform", "ios", "--locales", "ar", "--source", str(src), env=env)
    assert ios.returncode == 1 and "no screenshots" in ios.stderr
    assert _sh("upload_store_assets.sh", "--platform", "tv", env=env).returncode == 2
    assert _sh("upload_store_assets.sh", "--locales", "xx", "--dry-run", env=env).returncode == 2


def test_check_screenshots_wrapper(root: Path) -> None:
    from screenshots import check_screenshots

    assert check_screenshots.main(["--root", str(REPO)]) == 0
    assert check_screenshots.main(["--root", str(root)]) == 1

#!/usr/bin/env python3
"""Store screenshot pipeline (05 §9.4, Phase 20.2).

Subcommands (``tools/screenshots/take_screenshots.sh`` drives them):

``fixtures [--check]``
    Writes ``apps/taro/integration_test/screenshots/store_readings.g.dart``
    from ``apps/taro/test/fixtures/store_readings/{locale}.json`` (the device
    cannot read host files), or fails when it is stale.
``lint``
    The fixtures (12 locales, the wire shape, no Death / Devil / Tower in
    frames 1–3) and ``store_screenshots`` in ``aso.yaml`` (7 frames in order,
    12 locales, non-empty captions within length). Banned claims in the
    captions are ``check_store_copy.py``'s job (it reads the same fields).
``compose``
    Frames the raw captures (``build/screenshots/raw/<capture>/<locale>/``)
    with the captions on the Phase 14 template (``ScreenshotFrame``) and
    renders them with headless Chrome into
    ``build/screenshots/{ios/iphone,ios/ipad,android/phone,android/tab7,
    android/tab10}/<locale>/``.
``feature-graphic``
    The Play feature graphic (1024 × 500) into ``build/store/``.
``verify``
    Every expected output exists at its exact size.
"""

from __future__ import annotations

import argparse
import html
import json
import struct
import subprocess
import sys
import tempfile
from collections.abc import Callable, Iterable, Mapping, Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from taro_tools.checkkit import InputError, find_repo_root, load_json
from taro_tools.store import load_aso

NAME = "screenshots"
LOCALES = ("en", "ar", "de", "es", "fr", "it", "ja", "ko", "nl", "pt", "tr", "uk")
FRAMES = (
    "01_spread",
    "02_reading",
    "03_daily",
    "04_journal",
    "05_learn",
    "06_deck",
    "07_private",
)
# 05 §9.4: no Death, Devil or Tower close-ups in frames 1–3 (search results).
FORBIDDEN_EARLY = frozenset({"major_13", "major_15", "major_16"})
SPREAD_POSITIONS = {"three_ppf": ("past", "present", "future")}
HEADLINE_MAX = 34
SUBTEXT_MAX = 44

FIXTURES_DIR = Path("apps/taro/test/fixtures/store_readings")
DART_OUT = Path("apps/taro/integration_test/screenshots/store_readings.g.dart")
RAW_DIR = Path("build/screenshots/raw")
OUT_DIR = Path("build/screenshots")
FEATURE_OUT = Path("build/store/feature_graphic.png")
FONTS_DIR = Path("packages/taro_ui/fonts")
ART_DIR = Path("apps/taro/assets/deck/art/codex_v1/3.0x")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


@dataclass(frozen=True)
class Target:
    """One store screenshot set: where it goes, its size, its capture."""

    name: str
    out: str
    width: int
    height: int
    capture: str


TARGETS: dict[str, Target] = {
    t.name: t
    for t in (
        Target("iphone", "ios/iphone", 1320, 2868, "iphone"),
        Target("ipad", "ios/ipad", 2064, 2752, "ipad"),
        Target("phone", "android/phone", 1080, 1920, "phone"),
        Target("tab7", "android/tab7", 1080, 1920, "tablet"),
        Target("tab10", "android/tab10", 1620, 2880, "tablet"),
    )
}

# The Phase 14 tokens (dark, docs/design/taro.tokens.json) the template uses.
_CSS_TOKENS = (
    "--canvas:#0F1120;--raised:#20243D;--sunken:#0A0C17;--text:#ECEEF7;"
    "--text2:#B2B7CD;--accent:#9AA8FF;--subtle:#262D5C;--border:#6A7196;"
    "--cardback:#23308F;--frame:#D4A63A"
)
# Headline face per script: Literata (Latin, Cyrillic), the bundled CJK and
# Arabic faces otherwise.
_FONT_FILES = {
    "Literata": "Literata-SemiBold.ttf",
    "LiterataRegular": "Literata-Regular.ttf",
    "TaroSans": "TaroSans-Medium.ttf",
    "TaroSansArabic": "TaroSansArabic-SemiBold.ttf",
    "NotoSerifJP": "NotoSerifJP-Regular.ttf",
    "TaroSansKR": "TaroSansKR-SemiBold.ttf",
    "TaroSansJP": "TaroSansJP-SemiBold.ttf",
}
_HEADLINE_FONT = {"ar": "TaroSansArabic", "ja": "NotoSerifJP", "ko": "TaroSansKR"}
_SUB_FONT = {"ar": "TaroSansArabic", "ja": "TaroSansJP", "ko": "TaroSansKR"}

Runner = Callable[[Path, Path, int, int], None]


# ---------------------------------------------------------------------------
# Fixtures


def load_fixtures(root: Path) -> dict[str, dict[str, Any]]:
    """Every ``{locale}.json`` fixture, by locale."""
    out: dict[str, dict[str, Any]] = {}
    for locale in LOCALES:
        path = root / FIXTURES_DIR / f"{locale}.json"
        if not path.is_file():
            raise InputError(path.as_posix(), "missing store reading fixture")
        data = load_json(path)
        if not isinstance(data, dict):
            raise InputError(path.as_posix(), "top level must be an object")
        out[locale] = data
    return out


def fixture_findings(fixtures: Mapping[str, Mapping[str, Any]]) -> list[str]:
    """Shape and forbidden-card problems of the fixtures."""
    out: list[str] = []
    for locale, data in fixtures.items():
        where = f"store_readings/{locale}.json"
        if data.get("locale") != locale:
            out.append(f"{where}: locale is {data.get('locale')!r}")
        for key in ("question", "dailyCardId", "learnCardId"):
            if not isinstance(data.get(key), str) or not data[key].strip():
                out.append(f"{where}: {key} must be a non-empty string")
        spread = data.get("spreadId")
        positions = SPREAD_POSITIONS.get(str(spread))
        if positions is None:
            out.append(f"{where}: spreadId {spread!r} is not a supported spread")
            continue
        cards = data.get("cards") or []
        if [c.get("positionId") for c in cards] != list(positions):
            out.append(f"{where}: cards must cover {', '.join(positions)} in order")
        early = {c.get("cardId") for c in cards} | {data.get("dailyCardId")}
        for card in sorted(str(c) for c in early & FORBIDDEN_EARLY):
            out.append(f"{where}: {card} may not appear in frames 1–3 (05 §9.4)")
        if any(c.get("reversed") for c in cards):
            out.append(f"{where}: store draw cards are upright")
        reading = data.get("reading") or {}
        for key in ("title", "overview", "synthesis"):
            if not str(reading.get(key) or "").strip():
                out.append(f"{where}: reading.{key} is empty")
        texts = reading.get("cards") or []
        if [t.get("positionId") for t in texts] != list(positions):
            out.append(f"{where}: reading.cards must follow the draw positions")
        if any(not str(t.get("interpretation") or "").strip() for t in texts):
            out.append(f"{where}: a reading.cards interpretation is empty")
        prompts = reading.get("reflectionPrompts")
        if not isinstance(prompts, list) or not 1 <= len(prompts) <= 3:
            out.append(f"{where}: reading.reflectionPrompts must hold 1–3 prompts")
        for index, entry in enumerate(data.get("journal") or []):
            for key in ("question", "title", "overview", "spreadId"):
                if not str(entry.get(key) or "").strip():
                    out.append(f"{where}: journal[{index}].{key} is empty")
            if not entry.get("cards"):
                out.append(f"{where}: journal[{index}].cards is empty")
    return out


def render_fixtures_dart(fixtures: Mapping[str, Mapping[str, Any]]) -> str:
    """The Dart source embedding every fixture as a raw JSON string."""
    lines = [
        "// GENERATED by tools/screenshots/screenshots.py fixtures — do not edit.",
        "// Source: apps/taro/test/fixtures/store_readings/{locale}.json.",
        "",
        "/// The store reading fixtures (05 §9.4) as JSON, by locale.",
        "const Map<String, String> kStoreReadingsJson = {",
    ]
    for locale in LOCALES:
        text = json.dumps(fixtures[locale], ensure_ascii=False, indent=2)
        if "'''" in text:
            raise InputError(f"store_readings/{locale}.json", "contains '''")
        lines.append(f"  '{locale}': r'''")
        lines.append(f"{text}''',")
    lines.append("};")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Captions


def load_captions(aso: Mapping[str, Any]) -> dict[str, list[tuple[str, str]]]:
    """``store_screenshots`` captions, ``(headline, subtext)`` per frame."""
    shots = aso.get("store_screenshots")
    if not isinstance(shots, dict):
        raise InputError("aso.yaml", "store_screenshots is missing")
    out: dict[str, list[tuple[str, str]]] = {}

    def items(value: Any, locale: str) -> list[tuple[str, str]]:
        if not isinstance(value, list):
            raise InputError("aso.yaml", f"store_screenshots {locale} must be a list")
        return [
            (str(i.get("headline") or ""), str(i.get("subtext") or ""))
            if isinstance(i, dict)
            else (str(i), "")
            for i in value
        ]

    out["en"] = items(shots.get("screenshots"), "en")
    files = [i.get("file") for i in shots.get("screenshots") or [] if isinstance(i, dict)]
    if files != [f"{f}.png" for f in FRAMES]:
        raise InputError("aso.yaml", f"store_screenshots files must be {', '.join(FRAMES)}")
    for locale, value in (shots.get("translations") or {}).items():
        out[str(locale)] = items(value, str(locale))
    return out


def caption_findings(captions: Mapping[str, Sequence[tuple[str, str]]]) -> list[str]:
    """Missing locales, wrong frame counts and empty or long captions."""
    out = [f"store_screenshots: no captions for {loc}" for loc in LOCALES if loc not in captions]
    out += [f"store_screenshots: unknown locale {loc}" for loc in captions if loc not in LOCALES]
    for locale, items in captions.items():
        if len(items) != len(FRAMES):
            out.append(f"store_screenshots.{locale}: {len(items)} frames, expected {len(FRAMES)}")
        for index, (headline, subtext) in enumerate(items):
            key = f"store_screenshots.{locale}[{index}]"
            if not headline.strip():
                out.append(f"{key}: empty headline")
            if len(headline) > HEADLINE_MAX:
                out.append(f"{key}: headline is {len(headline)} characters (max {HEADLINE_MAX})")
            if len(subtext) > SUBTEXT_MAX:
                out.append(f"{key}: subtext is {len(subtext)} characters (max {SUBTEXT_MAX})")
    return out


# ---------------------------------------------------------------------------
# Composition


def png_size(path: Path) -> tuple[int, int]:
    """Width and height from a PNG header."""
    head = path.read_bytes()[:24]
    if head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        raise InputError(path.as_posix(), "not a PNG")
    width, height = struct.unpack(">II", head[16:24])
    return int(width), int(height)


def _font_faces(fonts: Path) -> str:
    return "".join(
        f"@font-face{{font-family:{family};src:url('{(fonts / file).as_uri()}')}}"
        for family, file in _FONT_FILES.items()
    )


@dataclass(frozen=True)
class Layout:
    """The template geometry scaled to one canvas and one capture."""

    scale: float
    head_top: int
    head_height: int
    device_left: int
    device_top: int
    device_width: int
    device_height: int
    pad: int


def layout(width: int, height: int, raw: tuple[int, int]) -> Layout:
    """``ScreenshotFrame`` (1320 × 2868) fitted to ``width`` × ``height``.

    The caption block keeps the template's place; the device frame keeps the
    capture's aspect ratio and is centred in the space left below it.
    """
    s = min(width / 1320, height / 2868)
    head_top = round(130 * s)
    head_height = round(330 * s)
    pad = round(22 * s)
    top = head_top + head_height + round(40 * s)
    bottom = round(110 * s)
    max_w = width - 2 * round(110 * s)
    max_h = height - top - bottom
    inner_w = max_w - 2 * pad
    inner_h = round(inner_w * raw[1] / raw[0])
    if inner_h + 2 * pad > max_h:
        inner_h = max_h - 2 * pad
        inner_w = round(inner_h * raw[0] / raw[1])
    dev_w, dev_h = inner_w + 2 * pad, inner_h + 2 * pad
    return Layout(
        scale=s,
        head_top=head_top,
        head_height=head_height,
        device_left=(width - dev_w) // 2,
        device_top=top,
        device_width=dev_w,
        device_height=dev_h,
        pad=pad,
    )


def frame_html(
    *,
    locale: str,
    headline: str,
    subtext: str,
    screen: Path,
    raw: tuple[int, int],
    width: int,
    height: int,
    fonts: Path,
) -> str:
    """One store frame: caption over the real capture (Phase 14 template)."""
    g = layout(width, height, raw)
    s = g.scale
    rtl = locale == "ar"
    head_font = _HEADLINE_FONT.get(locale, "Literata")
    sub_font = _SUB_FONT.get(locale, "TaroSans")
    radius = round(g.device_width * 0.1)
    inner_radius = max(radius - g.pad, 0)
    # Decorative card backs: the template's two blue slabs, scaled.
    deco = (
        f"<div class='slab' style='left:{round(-150 * s)}px;top:{round(height * 0.6)}px;"
        f"width:{round(440 * s)}px;height:{round(759 * s)}px;opacity:.55'></div>"
        f"<div class='slab' style='left:{width - round(460 * s)}px;top:{round(height * 0.37)}px;"
        f"width:{round(620 * s)}px;height:{round(1069 * s)}px;opacity:.6'></div>"
    )
    sub = f"<p class='sub'>{html.escape(subtext)}</p>" if subtext else ""
    return f"""<!doctype html>
<html lang="{locale}" dir="{"rtl" if rtl else "ltr"}"><head><meta charset="utf-8">
<style>
{_font_faces(fonts)}
:root{{{_CSS_TOKENS}}}
html,body{{margin:0;width:{width}px;height:{height}px;overflow:hidden;background:var(--canvas)}}
.canvas{{position:relative;width:{width}px;height:{height}px;overflow:hidden;background:var(--canvas)}}
.band{{position:absolute;left:0;bottom:0;width:100%;height:{round(308 * s)}px;background:var(--subtle);opacity:.7}}
.slab{{position:absolute;border-radius:{round(40 * s)}px;background:var(--cardback)}}
.head{{position:absolute;left:{round(80 * s)}px;right:{round(80 * s)}px;top:{g.head_top}px;
height:{g.head_height}px;display:flex;flex-direction:column;align-items:center;justify-content:center;
gap:{round(18 * s)}px;text-align:center}}
h1{{margin:0;font-family:{head_font},serif;font-weight:{400 if locale == "ja" else 600};
font-size:{round(92 * s)}px;line-height:1.18;letter-spacing:{"0" if locale in ("ar", "ja", "ko") else "-0.01em"};
color:var(--text);word-break:{"auto-phrase" if locale == "ja" else "keep-all" if locale == "ko" else "normal"};
text-wrap:balance;max-height:{round(92 * s * 1.18 * 2) + 2}px;overflow:hidden}}
.sub{{margin:0;font-family:{sub_font},sans-serif;font-size:{round(46 * s)}px;line-height:1.3;
color:var(--accent);text-wrap:balance;word-break:{"auto-phrase" if locale == "ja" else "keep-all" if locale == "ko" else "normal"}}}
.device{{position:absolute;left:{g.device_left}px;top:{g.device_top}px;width:{g.device_width}px;
height:{g.device_height}px;box-sizing:border-box;padding:{g.pad}px;border-radius:{radius}px;
background:var(--raised);border:{max(round(3 * s), 2)}px solid var(--border);
box-shadow:0 {round(40 * s)}px {round(120 * s)}px rgba(0,0,0,.55)}}
.device img{{display:block;width:100%;height:100%;border-radius:{inner_radius}px;object-fit:cover}}
</style></head>
<body><div class="canvas">
<div class="band"></div>{deco}
<div class="head"><h1>{html.escape(headline)}</h1>{sub}</div>
<div class="device"><img src="{screen.resolve().as_uri()}" alt=""></div>
</div></body></html>
"""


def feature_graphic_html(*, art: Path, fonts: Path, tagline: str) -> str:
    """The Play feature graphic (1024 × 500): wordmark and a fan of cards."""
    cards = [("cups_03", -14, 560, 70), ("major_17", 0, 690, 40), ("pentacles_01", 14, 820, 70)]
    fan = "".join(
        f"<img class='card' src='{(art / f'{card}.webp').resolve().as_uri()}' "
        f"style='left:{left}px;top:{top}px;transform:rotate({deg}deg)' alt=''>"
        for card, deg, left, top in cards
    )
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<style>
{_font_faces(fonts)}
:root{{{_CSS_TOKENS}}}
html,body{{margin:0;width:1024px;height:500px;overflow:hidden}}
.canvas{{position:relative;width:1024px;height:500px;overflow:hidden;
background:radial-gradient(circle at 75% 45%,#262D5C 0,#0F1120 62%)}}
.mark{{position:absolute;left:72px;top:150px;width:420px}}
h1{{margin:0;font-family:Literata,serif;font-weight:600;font-size:112px;line-height:1;
color:var(--text);letter-spacing:-0.02em}}
.rule{{width:84px;height:4px;background:var(--frame);margin:28px 0 22px;border-radius:2px}}
p{{margin:0;font-family:LiterataRegular,serif;font-size:34px;line-height:1.25;color:var(--text2)}}
.card{{position:absolute;width:190px;height:328px;border-radius:12px;object-fit:cover;
box-shadow:0 18px 50px rgba(0,0,0,.6);border:3px solid var(--frame);box-sizing:border-box}}
</style></head>
<body><div class="canvas">
<div class="mark"><h1>Taro</h1><div class="rule"></div><p>{html.escape(tagline)}</p></div>
{fan}
</div></body></html>
"""


@dataclass(frozen=True)
class Job:
    """One image to render."""

    html: str
    out: Path
    width: int
    height: int


def plan_jobs(
    root: Path,
    raw_root: Path,
    out_root: Path,
    captions: Mapping[str, Sequence[tuple[str, str]]],
    locales: Iterable[str],
    targets: Iterable[str],
) -> tuple[list[Job], list[str]]:
    """Every frame to compose, and the raw captures that are missing."""
    jobs: list[Job] = []
    missing: list[str] = []
    fonts = root / FONTS_DIR
    for name in targets:
        target = TARGETS[name]
        for locale in locales:
            for index, frame in enumerate(FRAMES):
                raw = raw_root / target.capture / locale / f"{frame}.png"
                if not raw.is_file():
                    missing.append(raw.as_posix())
                    continue
                headline, subtext = captions[locale][index]
                page = frame_html(
                    locale=locale,
                    headline=headline,
                    subtext=subtext,
                    screen=raw,
                    raw=png_size(raw),
                    width=target.width,
                    height=target.height,
                    fonts=fonts,
                )
                out = out_root / target.out / locale / f"{frame}.png"
                jobs.append(Job(page, out, target.width, target.height))
    return jobs, missing


def chrome_runner(chrome: str = CHROME) -> Runner:
    """Renders one HTML file to a PNG with headless Chrome."""

    def run(page: Path, out: Path, width: int, height: int) -> None:
        subprocess.run(
            [
                chrome,
                "--headless=new",
                "--disable-gpu",
                "--hide-scrollbars",
                "--force-device-scale-factor=1",
                "--allow-file-access-from-files",
                "--default-background-color=00000000",
                f"--window-size={width},{height}",
                f"--screenshot={out}",
                page.as_uri(),
            ],
            check=True,
            capture_output=True,
            timeout=120,
        )

    return run


def render(jobs: Sequence[Job], runner: Runner, workers: int = 4) -> list[Path]:
    """Writes every job's HTML to a temp dir and renders it; returns outputs."""
    with tempfile.TemporaryDirectory(prefix="taro_shots_") as tmp:
        pages: list[tuple[Path, Job]] = []
        for index, job in enumerate(jobs):
            page = Path(tmp) / f"{index:04d}.html"
            page.write_text(job.html, encoding="utf-8")
            job.out.parent.mkdir(parents=True, exist_ok=True)
            pages.append((page, job))
        with ThreadPoolExecutor(max_workers=max(workers, 1)) as pool:
            list(pool.map(lambda p: runner(p[0], p[1].out, p[1].width, p[1].height), pages))
    return [job.out for job in jobs]


def verify_findings(out_root: Path, feature: Path, locales: Iterable[str], targets: Iterable[str]) -> list[str]:
    """Missing outputs and outputs of the wrong size."""
    out: list[str] = []
    expected = [
        (out_root / TARGETS[t].out / loc / f"{f}.png", TARGETS[t].width, TARGETS[t].height)
        for t in targets
        for loc in locales
        for f in FRAMES
    ]
    expected.append((feature, 1024, 500))
    for path, width, height in expected:
        if not path.is_file():
            out.append(f"{path.as_posix()}: missing")
        elif png_size(path) != (width, height):
            w, h = png_size(path)
            out.append(f"{path.as_posix()}: {w}×{h}, expected {width}×{height}")
    return out


# ---------------------------------------------------------------------------
# CLI


def _csv(value: str, allowed: Sequence[str], what: str) -> list[str]:
    items = [v.strip() for v in value.split(",") if v.strip()]
    unknown = [v for v in items if v not in allowed]
    if unknown:
        raise argparse.ArgumentTypeError(f"unknown {what}: {', '.join(unknown)}")
    return items


def build_parser() -> argparse.ArgumentParser:
    """The command line."""
    parser = argparse.ArgumentParser(prog=NAME, description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=None, help="repository root")
    sub = parser.add_subparsers(dest="command", required=True)
    fx = sub.add_parser("fixtures", help="write the Dart fixture file")
    fx.add_argument("--check", action="store_true", help="fail when it is stale")
    sub.add_parser("lint", help="check fixtures and captions")
    for name in ("compose", "verify"):
        cmd = sub.add_parser(name)
        cmd.add_argument("--locales", default=",".join(LOCALES))
        cmd.add_argument("--targets", default=",".join(TARGETS))
        cmd.add_argument("--out", type=Path, default=None)
        if name == "compose":
            cmd.add_argument("--raw", type=Path, default=None)
            cmd.add_argument("--workers", type=int, default=4)
            cmd.add_argument("--chrome", default=CHROME)
    fg = sub.add_parser("feature-graphic")
    fg.add_argument("--chrome", default=CHROME)
    fg.add_argument("--out", type=Path, default=None)
    return parser


def main(argv: Sequence[str] | None = None, runner: Runner | None = None) -> int:
    """Entry point; ``runner`` replaces headless Chrome in tests."""
    args = build_parser().parse_args(argv)
    root = args.root.resolve() if args.root else find_repo_root(Path(__file__))
    try:
        return _dispatch(args, root, runner)
    except (InputError, argparse.ArgumentTypeError) as exc:
        print(f"{NAME}: {exc}")
        return 1


def _dispatch(args: argparse.Namespace, root: Path, runner: Runner | None) -> int:
    if args.command == "fixtures":
        text = render_fixtures_dart(load_fixtures(root))
        target = root / DART_OUT
        if args.check:
            current = target.read_text(encoding="utf-8") if target.is_file() else ""
            if current != text:
                print(f"{NAME}: {DART_OUT} is stale; run `screenshots.py fixtures`")
                return 1
            print(f"{NAME}: {DART_OUT} is up to date")
            return 0
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")
        print(f"{NAME}: wrote {DART_OUT}")
        return 0
    if args.command == "lint":
        aso = load_aso(root)
        if aso is None:
            raise InputError("aso.yaml", "missing")
        problems = fixture_findings(load_fixtures(root)) + caption_findings(load_captions(aso))
        for problem in problems:
            print(f"{NAME}: {problem}")
        print(f"{NAME}: {'FAILED' if problems else 'OK'}")
        return 1 if problems else 0
    if args.command == "feature-graphic":
        out = args.out or root / FEATURE_OUT
        out.parent.mkdir(parents=True, exist_ok=True)
        page = feature_graphic_html(
            art=root / ART_DIR, fonts=root / FONTS_DIR, tagline="Tarot for self-reflection"
        )
        render([Job(page, out, 1024, 500)], runner or chrome_runner(args.chrome), workers=1)
        print(f"{NAME}: wrote {out}")
        return 0
    locales = _csv(args.locales, LOCALES, "locale")
    targets = _csv(args.targets, list(TARGETS), "target")
    out_root = args.out or root / OUT_DIR
    if args.command == "verify":
        problems = verify_findings(out_root, root / FEATURE_OUT, locales, targets)
        for problem in problems:
            print(f"{NAME}: {problem}")
        print(f"{NAME}: {'FAILED' if problems else 'OK'}")
        return 1 if problems else 0
    aso = load_aso(root)
    if aso is None:
        raise InputError("aso.yaml", "missing")
    jobs, missing = plan_jobs(
        root, args.raw or root / RAW_DIR, out_root, load_captions(aso), locales, targets
    )
    for path in missing:
        print(f"{NAME}: missing capture {path}")
    if missing:
        return 1
    render(jobs, runner or chrome_runner(args.chrome), workers=args.workers)
    print(f"{NAME}: composed {len(jobs)} frames into {out_root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

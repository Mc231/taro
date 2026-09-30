#!/usr/bin/env bash
# Rebuilds the bundled taro_ui fonts (Phase 15 Sprint 15.1, 01 §13, 02 §17).
#
# Downloads the OFL sources from the official Google Fonts repository at a
# pinned commit, pins variable fonts to static weights, and subsets each face
# to its script (see README.md for the ranges and the size budget). Output is
# deterministic for a given fontTools version.
#
# Needs Python 3.12 with fontTools (pip install 'fonttools==4.66.0').
#   PYTHON=/path/to/python packages/taro_ui/fonts/build_fonts.sh
set -euo pipefail

GOOGLE_FONTS_SHA=23e54b51ddffbc7713c583748e3bd86f62b1fa4a
BASE="https://raw.githubusercontent.com/google/fonts/${GOOGLE_FONTS_SHA}/ofl"
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="${PYTHON:-python3}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fetch() { curl -sfL -o "$WORK/$2" "$BASE/$1"; }

fetch 'literata/Literata%5Bopsz,wght%5D.ttf' Literata-VF.ttf
fetch 'ibmplexsans/IBMPlexSans%5Bwdth,wght%5D.ttf' IBMPlexSans-VF.ttf
for w in Regular Medium SemiBold; do
  fetch "ibmplexsansarabic/IBMPlexSansArabic-$w.ttf" "IBMPlexSansArabic-$w.ttf"
done
for w in Regular SemiBold; do
  fetch "ibmplexsansjp/IBMPlexSansJP-$w.ttf" "IBMPlexSansJP-$w.ttf"
  fetch "ibmplexsanskr/IBMPlexSansKR-$w.ttf" "IBMPlexSansKR-$w.ttf"
done
fetch 'notonaskharabic/NotoNaskhArabic%5Bwght%5D.ttf' NotoNaskhArabic-VF.ttf
fetch 'notoserifjp/NotoSerifJP%5Bwght%5D.ttf' NotoSerifJP-VF.ttf
fetch 'notoserifkr/NotoSerifKR%5Bwght%5D.ttf' NotoSerifKR-VF.ttf
fetch 'imfellenglishsc/IMFeENsc28P.ttf' IMFellEnglishSC-Regular.ttf
for d in literata ibmplexsans ibmplexsansarabic ibmplexsansjp ibmplexsanskr \
  notonaskharabic notoserifjp notoserifkr imfellenglishsc; do
  mkdir -p "$OUT/licenses"
  curl -sfL -o "$OUT/licenses/OFL-$d.txt" "$BASE/$d/OFL.txt"
done

"$PYTHON" - "$WORK" "$OUT" <<'PY'
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

work, out = Path(sys.argv[1]), Path(sys.argv[2])


def span(a, b):
    return set(range(a, b + 1))


PUNCT = span(0x2000, 0x206F) | {0x20AC, 0x2122, 0x2190, 0x2192, 0x2212, 0xFEFF, 0xFFFD}
LATIN = span(0x20, 0x7E) | span(0xA0, 0x17F) | span(0x2C6, 0x2DD) | span(0x300, 0x36F) | PUNCT
CYRILLIC = span(0x400, 0x4FF)
ARABIC = span(0x600, 0x6FF) | span(0x750, 0x77F) | span(0xFB50, 0xFDFF) | span(0xFE70, 0xFEFF) | span(0x200C, 0x200F)
CJK_COMMON = span(0x20, 0x7E) | span(0x3000, 0x303F) | span(0xFF00, 0xFFEF) | PUNCT


def jis_level1():
    """Kana plus the 2 965 JIS X 0208 level-1 kanji."""
    cps = span(0x3040, 0x30FF) | span(0x31F0, 0x31FF)
    for row in range(16, 48):
        for cell in range(1, 95):
            try:
                cps.add(ord(bytes([row + 0xA0, cell + 0xA0]).decode("euc_jp")))
            except UnicodeDecodeError:
                pass
    return cps


def ksx1001_hangul():
    """Compatibility jamo plus the 2 350 KS X 1001 Hangul syllables."""
    cps = span(0x3130, 0x318F)
    for lead in range(0xB0, 0xC9):
        for trail in range(0xA1, 0xFF):
            try:
                cps.add(ord(bytes([lead, trail]).decode("euc_kr")))
            except UnicodeDecodeError:
                pass
    return cps


JAPANESE = CJK_COMMON | jis_level1()
KOREAN = CJK_COMMON | ksx1001_hangul()


# IBM Plex carries the Reserved Font Name "Plex" (OFL 1.1 condition 3): a
# subset is a Modified Version, so its internal names drop "Plex". Copyright,
# trademark and licence records (name IDs 0, 7, 13, 14) are kept verbatim.
KEEP_NAME_IDS = {0, 7, 13, 14}


def rename_reserved(font):
    for record in font["name"].names:
        if record.nameID in KEEP_NAME_IDS:
            continue
        text = record.toUnicode()
        renamed = text.replace("IBM Plex Sans", "Taro Sans").replace("IBMPlexSans", "TaroSans").replace("Plex", "Taro")
        if renamed != text:
            record.string = renamed


def build(source, target, unicodes, axes=None):
    font = TTFont(work / source)
    if axes:
        font = instancer.instantiateVariableFont(font, axes)
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.hinting = False
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)
    if axes and "wght" in axes:
        font["OS/2"].usWeightClass = axes["wght"]
    if source.startswith("IBMPlex"):
        rename_reserved(font)
    if source.startswith("IBMPlex"):
        target = target.replace("IBMPlexSans", "TaroSans")
    font.recalcTimestamp = False
    font.save(out / target, reorderTables=True)
    print(f"{target}: {(out / target).stat().st_size} bytes")


WEIGHTS = {400: "Regular", 500: "Medium", 600: "SemiBold"}
for wght, name in WEIGHTS.items():
    build("Literata-VF.ttf", f"Literata-{name}.ttf", LATIN | CYRILLIC, {"wght": wght, "opsz": 12})
    build("IBMPlexSans-VF.ttf", f"IBMPlexSans-{name}.ttf", LATIN | CYRILLIC, {"wght": wght, "wdth": 100})
    build(f"IBMPlexSansArabic-{name}.ttf", f"IBMPlexSansArabic-{name}.ttf", ARABIC | span(0x20, 0x7E) | PUNCT)
    build("NotoNaskhArabic-VF.ttf", f"NotoNaskhArabic-{name}.ttf", ARABIC | span(0x20, 0x7E) | PUNCT, {"wght": wght})
for wght in (400, 600):
    name = WEIGHTS[wght]
    build(f"IBMPlexSansJP-{name}.ttf", f"IBMPlexSansJP-{name}.ttf", JAPANESE)
    build(f"IBMPlexSansKR-{name}.ttf", f"IBMPlexSansKR-{name}.ttf", KOREAN)
    build("NotoSerifJP-VF.ttf", f"NotoSerifJP-{name}.ttf", JAPANESE, {"wght": wght})
    build("NotoSerifKR-VF.ttf", f"NotoSerifKR-{name}.ttf", KOREAN, {"wght": wght})
build("IMFellEnglishSC-Regular.ttf", "IMFellEnglishSC-Regular.ttf", span(0x20, 0x7E) | span(0xA0, 0xFF))
PY

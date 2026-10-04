import json
from pathlib import Path

import pytest

import check_ja_linebreak as c
from fixture_repo import REPO, make_root

CHECK = "check_ja_linebreak"
WJ = "⁠"


def _segments(text: str) -> list[str]:
    """The pieces a line may break between (joined pieces stay whole)."""
    out = [""]
    for i, ch in enumerate(text):
        if ch == WJ:
            continue
        prev = text[i - 1] if i else ""
        if out[-1] and prev != WJ and c.kind(prev) and c.kind(ch):
            out.append("")
        out[-1] += ch
    return out


@pytest.mark.parametrize(
    ("text", "whole"),
    [
        ("相談窓口に連絡してください。", "相談窓口"),  # S27 "相談窓 / 口"
        ("ジャーナルはこのスマートフォンの中だけに", "スマートフォン"),
        ("リーディングできません", "リーディング"),  # S26 "リーディン / グ"
        ("動画を見て受け取る", "受け取る"),  # S11 "受け取 / る"
    ],
)
def test_words_stay_whole(text: str, whole: str) -> None:
    assert any(whole in seg for seg in _segments(c.join_ja(text)))


@pytest.mark.parametrize(
    ("text", "tail"),
    [
        ("リーディングできません", "できません"),  # S07 "でき / ません"
        ("未来は予測できません。", "できません。"),  # S07 "ませ / ん。"
        ("カードをめくってください。", "ください。"),  # S08 "くださ / い。"
        ("ジャーナルはこのスマートフォンの中だけに", "の中だけに"),  # S02
    ],
)
def test_sentence_tail_is_never_an_orphan(text: str, tail: str) -> None:
    assert _segments(c.join_ja(text))[-1].endswith(tail)


def test_join_is_idempotent_keeps_manual_joins_and_icu() -> None:
    manual = "あなたはひ⁠と⁠り⁠で⁠は⁠あ⁠り⁠ま⁠せ⁠ん"
    assert c.join_ja(manual) == manual
    once = c.join_ja("{count, plural, other{無料リーディング{count}回}} Taro")
    assert c.join_ja(once) == once
    assert once.replace(WJ, "") == "{count, plural, other{無料リーディング{count}回}} Taro"
    assert c.join_ja("Taro 1") == "Taro 1"
    assert c.join_ja(WJ + "Taro") == "Taro"


def test_pass(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "pass")
    findings, notices = c.run(root)
    assert findings == [] and notices == ["3 ja message(s) checked"]
    assert c.main(["--root", str(root)]) == 0


def test_fail_then_fix(tmp_path: Path) -> None:
    root = make_root(tmp_path, CHECK, "fail_unjoined")
    findings, _ = c.run(root)
    assert sorted(f.rule for f in findings) == ["ja-linebreak", "ja-linebreak"]
    assert findings[0].line == 3
    assert c.main(["--root", str(root)]) == 1
    assert c.main(["--root", str(root), "--fix"]) == 0
    assert c.run(root)[0] == []
    arb = root / "apps/taro/lib/l10n/arb/app_ja.arb"
    assert "\\u2060" in arb.read_text(encoding="utf-8")
    assert json.loads(arb.read_text(encoding="utf-8"))["plain"] == "Taro"


def test_malformed(tmp_path: Path) -> None:
    assert c.main(["--root", str(make_root(tmp_path, CHECK, "fail_malformed"))]) == 1


def test_absent_is_skipped(tmp_path: Path) -> None:
    findings, notices = c.run(make_root(tmp_path, CHECK, None))
    assert findings == [] and "not present" in notices[0]


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0


def test_native_strings_carry_no_joiners(tmp_path: Path) -> None:
    """The OS draws the ATT prompt from InfoPlist.strings, which must equal
    the ARB value (check_manifests), so ns* keys stay free of joiners."""
    root = make_root(tmp_path, CHECK, "pass")
    arb = root / "apps/taro/lib/l10n/arb/app_ja.arb"
    data = json.loads(arb.read_text(encoding="utf-8"))
    data["nsUserTrackingUsageDescription"] = "トラッキングを許可すると広告が表示されます。"
    arb.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    assert c.run(root)[0] == []
    assert c.main(["--root", str(root), "--fix"]) == 0
    assert WJ not in json.loads(arb.read_text(encoding="utf-8"))["nsUserTrackingUsageDescription"]


def test_real_repository_ja_att_string_matches_info_plist() -> None:
    import check_manifests

    findings, _ = check_manifests.run(REPO)
    assert [f for f in findings if f.rule == "att-string"] == []

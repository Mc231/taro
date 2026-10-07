import shutil
from pathlib import Path

import pytest

import check_manifests as c
from fixture_repo import REPO, make_root

CHECK = "check_manifests"


def _root(tmp_path: Path, case: str) -> Path:
    return make_root(tmp_path, CHECK, case)


def _merged(root: Path) -> Path:
    return root / "merged" / "AndroidManifest.xml"


def _messages(findings: list[c.Finding]) -> list[str]:
    return [f.render() for f in findings]


def test_pass_with_merged_manifest(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    findings, notices = c.run(root, manifest=_merged(root))
    assert findings == [] and "source apps/taro/ios/Runner/Info.plist" in notices[0]
    assert c.main(["--root", str(root), "--android-manifest", str(_merged(root))]) == 0


def test_default_paths_prefer_built_artifacts(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    merged = root / c.MERGED_MANIFEST
    merged.parent.mkdir(parents=True)
    shutil.copy(_merged(root), merged)
    built = root / c.RELEASE_PLISTS[0]
    built.parent.mkdir(parents=True)
    shutil.copy(root / c.INFO_PLIST, built)
    assert c.run(root) == ([], [])


def test_source_manifest_fallback_and_require_merged(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    findings, notices = c.run(root)
    assert findings == [] and "merged release manifest not built" in notices[1]
    assert [f.rule for f in c.run(root, require_merged=True)[0]] == ["missing"]
    assert c.main(["--root", str(root), "--require-merged"]) == 1


def test_ios_failures(tmp_path: Path) -> None:
    root = _root(tmp_path, "fail_ios")
    findings, _ = c.run(root, manifest=_merged(root))
    text = "\n".join(_messages(findings))
    for expected in (
        "GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE must be false",
        "SKIncludeConsumableInAppPurchaseHistory must be YES",
        "NSUserTrackingUsageDescription is missing or empty",
        "de.lproj/InfoPlist.strings: [att-string] differs from ARB",
        "ja.lproj/InfoPlist.strings: [att-string] missing",
        "ko.lproj/InfoPlist.strings: [att-string] no NSUserTrackingUsageDescription entry",
        "NSPrivacyTrackingDomains is not an array",
        "NSPrivacyTrackingDomains is not an array",
        "CoarseLocation is in 05 §5.1 but not declared",
        "Health is declared but not in 05 §5.1",
        "UserID: linked/tracking/purposes differ",
        "collected data entry without NSPrivacyCollectedDataType",
        "NSPrivacyAccessedAPICategoryDiskSpace has no reason",
        "PrivacyInfo.xcprivacy is not a Runner resource",
        "[url-schemes] LSApplicationQueriesSchemes does not list https",
        "[url-schemes] LSApplicationQueriesSchemes does not list mailto",
        "[purpose-string] NSPhotoLibraryUsageDescription is missing or empty (ITMS-90683)",
        "[purpose-string] NSFaceIDUsageDescription is missing or empty (ITMS-90683)",
        "fr.lproj/InfoPlist.strings: [purpose-string] no NSFaceIDUsageDescription entry (ITMS-90683)",
    ):
        assert expected in text
    assert c.main(["--root", str(root)]) == 1


def test_android_failures(tmp_path: Path) -> None:
    root = _root(tmp_path, "fail_android")
    findings, _ = c.run(root, manifest=_merged(root))
    text = "\n".join(_messages(findings))
    for expected in (
        "SCHEDULE_EXACT_ALARM must not be declared",
        "POST_NOTIFICATIONS is not declared",
        "google_analytics_default_allow_ad_storage must be false",
        "ScheduledNotificationBootReceiver with BOOT_COMPLETED is missing",
        "android:fullBackupContent must be @xml/full_backup_content",
        "data_extraction_rules.xml: [backup-rules] device-transfer: secure storage prefs not excluded",
        "data_extraction_rules.xml: [backup-rules] device-transfer: taro_device.db not excluded",
        "full_backup_content.xml: [backup-rules] missing",
        "home_offer.dart:2: [notification-request]",
        "home_offer.dart:3: [notification-request]",
        "proguard-rules.pro: [r8-keep] must keep RoomDatabase subclass constructors",
        'build.gradle.kts: [r8-keep] release must list proguardFiles("proguard-rules.pro")',
        "[url-queries] <queries> does not declare DIAL tel (UrlLauncher)",
    ):
        assert expected in text
    assert "VIEW https" not in text


def test_r8_seeds(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    seeds = root / c.R8_SEEDS
    seeds.parent.mkdir(parents=True)
    # Round 4 crash: R8 kept the class but not its constructor.
    seeds.write_text(f"{c.WORK_DB}\nandroidx.work.impl.WorkDatabase\n")
    assert [f.rule for f in c.check_r8_rules(root)] == ["r8-keep"]
    seeds.write_text(f"{c.WORK_DB}\n{c.WORK_DB}: WorkDatabase_Impl()\n")
    assert c.check_r8_rules(root) == []
    seeds.write_text("io.flutter.Foo\n")
    assert c.check_r8_rules(root) == []
    (root / c.R8_RULES).unlink()
    (root / c.APP_GRADLE).unlink()
    assert [f.path for f in c.check_r8_rules(root)] == [c.R8_RULES, c.APP_GRADLE]


def test_manifest_shapes(tmp_path: Path) -> None:
    import xml.etree.ElementTree as ET

    no_app = ET.fromstring('<manifest xmlns:android="http://schemas.android.com/apk/res/android"/>')
    assert [f.rule for f in c.check_android_manifest(no_app, "m", merged=False)] == [
        *["url-queries"] * len(c.URL_INTENTS),
        "permission",
        "application",
    ]
    bad = tmp_path / "bad.xml"
    bad.write_text("<manifest>")
    with pytest.raises(c.InputError):
        c.load_xml(bad, "bad.xml")
    plist = tmp_path / "bad.plist"
    plist.write_text("not a plist")
    with pytest.raises(c.InputError):
        c.load_plist(plist, "bad.plist")
    plist.write_bytes(b'<?xml version="1.0"?><plist version="1.0"><array/></plist>')
    with pytest.raises(c.InputError):
        c.load_plist(plist, "bad.plist")
    assert c.strings_value('"NSUserTrackingUsageDescription" = "a \\"b\\"";') == 'a "b"'


def test_privacy_tracking_domains() -> None:
    def rules(data: dict[str, object]) -> list[str]:
        return [f.message for f in c.check_privacy_manifest(data) if f.rule == "privacy-domains"]

    base = {"NSPrivacyCollectedDataTypes": [], "NSPrivacyAccessedAPITypes": []}
    # Build 11 (ITMS-91064): tracking true with an empty domains array.
    assert rules({**base, "NSPrivacyTracking": True, c.DOMAINS_KEY: []}) == [
        "NSPrivacyTrackingDomains is an empty array; omit it (ITMS-91064)"
    ]
    assert rules({**base, "NSPrivacyTracking": False, c.DOMAINS_KEY: ["ads.example"]}) == [
        "NSPrivacyTrackingDomains is not empty, so NSPrivacyTracking must be true (ITMS-91064)"
    ]
    assert rules({**base, "NSPrivacyTracking": True, c.DOMAINS_KEY: ["ads.example"]}) == []
    assert rules({**base, "NSPrivacyTracking": True}) == []


def test_purpose_strings_in_strings_files(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    strings = root / c.STRINGS.format(locale="uk")
    strings.write_text(strings.read_text(encoding="utf-8").replace("NSPhotoLibraryUsageDescription", "X"))
    assert [f.render() for f in c.check_tracking_strings(root)] == [
        f"{c.STRINGS.format(locale='uk')}: [purpose-string] no NSPhotoLibraryUsageDescription entry (ITMS-90683)"
    ]


def test_missing_inputs(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    (root / c.PRIVACY).unlink()
    (root / c.SOURCE_MANIFEST).unlink()
    (root / "apps/taro/lib/l10n/arb/app_fr.arb").write_text("{")
    (root / "apps/taro/lib/l10n/arb/app_fr.arb").unlink()
    findings, _ = c.run(root)
    assert sorted(f.rule for f in findings) == ["missing", "missing"]
    (root / c.INFO_PLIST).unlink()
    assert [f.path for f in c.run(root, manifest=_merged(root))[0]] == [c.INFO_PLIST]
    assert c.run(make_root(tmp_path / "empty", CHECK, None)) == ([], ["apps/taro not present; skipped"])


def test_invalid_arb(tmp_path: Path) -> None:
    root = _root(tmp_path, "pass")
    (root / "apps/taro/lib/l10n/arb/app_fr.arb").write_text("{")
    assert c.main(["--root", str(root)]) == 1


def test_real_repository_passes() -> None:
    assert c.main(["--root", str(REPO)]) == 0


def test_tracking_true_requires_a_domain() -> None:
    """ITMS-91064 (builds 11 and 12): true with no domains is rejected; false passes."""
    base = {"NSPrivacyCollectedDataTypes": [], "NSPrivacyAccessedAPITypes": []}
    texts = [f.message for f in c.check_privacy_manifest({**base, "NSPrivacyTracking": True})]
    assert any("lists no domain (ITMS-91064)" in t for t in texts)
    texts = [f.message for f in c.check_privacy_manifest({**base, "NSPrivacyTracking": False})]
    assert not any("ITMS-91064" in t or "NSPrivacyTracking" in t for t in texts)

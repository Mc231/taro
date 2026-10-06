#!/usr/bin/env python3
"""Release manifest gate (05 §1, §2, §5.1; Phase 19.2).

iOS, over the release ``Info.plist`` (the built ``Runner.app`` when present,
else the source ``ios/Runner/Info.plist`` it is copied from):

- the four ``GOOGLE_ANALYTICS_DEFAULT_ALLOW_*`` keys are ``false`` (RC68);
- ``SKIncludeConsumableInAppPurchaseHistory`` is ``true`` (RC84);
- ``LSApplicationQueriesSchemes`` lists the ``UrlLauncher`` schemes
  (``https``, ``tel``, ``sms``, ``mailto``) so links open from release builds;
- ``NSUserTrackingUsageDescription`` is set, and every locale has an
  ``InfoPlist.strings`` whose value equals the ARB ``nsUserTrackingUsageDescription``;
- ``PrivacyInfo.xcprivacy`` declares tracking, the collected data types of
  05 §5.1 (no more, no fewer), a reason for every required-reason API, and is
  a resource of the Runner target.

Android, over the merged release ``AndroidManifest.xml`` (built by
``./gradlew :app:processProdReleaseMainManifest`` in ``apps/taro/android``;
the source manifest is checked instead, with a note, when it is absent):

- the four ``google_analytics_default_allow_*`` meta-data are ``false`` (RC68);
- no ``SCHEDULE_EXACT_ALARM`` / ``USE_EXACT_ALARM``;
- ``POST_NOTIFICATIONS`` and ``AD_ID`` are declared (merged manifest only, they
  come from libraries), and only the reminder offer asks for notifications;
- ``<queries>`` declares the ``UrlLauncher`` intents (Android 11+ package
  visibility): ``VIEW https``, ``DIAL tel``, ``SENDTO sms`` / ``mailto`` and
  the Custom Tabs service, so onboarding, legal, help and S27 links open;
- the boot-completed reschedule receiver and ``RECEIVE_BOOT_COMPLETED`` exist;
- the backup rules exclude secure storage and ``taro_device.db`` (RC75);
- R8 keeps Room database constructors: ``android/app/proguard-rules.pro``
  has the rule and the release build type lists it, and, when a release
  build left ``seeds.txt``, ``WorkDatabase_Impl()`` is in it (round 4: R8
  full mode dropped it and every Play install crashed on launch).
"""

from __future__ import annotations

import json
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
from collections.abc import Sequence
from pathlib import Path
from typing import Any

from taro_tools.checkkit import LOCALES, Finding, InputError, base_parser, mask_dart, rel, resolve_root, run_check

NAME = "check_manifests"
APP = "apps/taro"
INFO_PLIST = f"{APP}/ios/Runner/Info.plist"
RELEASE_PLISTS = (
    f"{APP}/build/ios/iphoneos/Runner.app/Info.plist",
    f"{APP}/build/ios/Release-prod-iphoneos/Runner.app/Info.plist",
)
PRIVACY = f"{APP}/ios/Runner/PrivacyInfo.xcprivacy"
PBXPROJ = f"{APP}/ios/Runner.xcodeproj/project.pbxproj"
STRINGS = APP + "/ios/Runner/{locale}.lproj/InfoPlist.strings"
ARB = APP + "/lib/l10n/arb/app_{locale}.arb"
SOURCE_MANIFEST = f"{APP}/android/app/src/main/AndroidManifest.xml"
MERGED_MANIFEST = (
    f"{APP}/build/app/intermediates/merged_manifest/prodRelease/processProdReleaseMainManifest/AndroidManifest.xml"
)
RES_XML = f"{APP}/android/app/src/main/res/xml"
LIB = f"{APP}/lib"
R8_RULES = f"{APP}/android/app/proguard-rules.pro"
APP_GRADLE = f"{APP}/android/app/build.gradle.kts"
R8_SEEDS = f"{APP}/build/app/outputs/mapping/prodRelease/seeds.txt"
WORK_DB = "androidx.work.impl.WorkDatabase_Impl"
_ROOM_KEEP = re.compile(r"^-keep class \* extends androidx\.room\.RoomDatabase\s*\{\s*<init>\(\);\s*\}", re.M)
_GRADLE_RULES = re.compile(r'proguardFiles\([^)]*"proguard-rules\.pro"')

GA_KEYS = ("ANALYTICS_STORAGE", "AD_STORAGE", "AD_USER_DATA", "AD_PERSONALIZATION_SIGNALS")
TRACKING_KEY = "NSUserTrackingUsageDescription"
QUERIES_KEY = "LSApplicationQueriesSchemes"
# The schemes UrlLauncher opens (taro_core `UrlLauncher.allowedSchemes`).
URL_SCHEMES = ("https", "tel", "sms", "mailto")
ARB_TRACKING_KEY = "nsUserTrackingUsageDescription"

# 05 §5.1, as NSPrivacyCollectedDataType suffix → (linked, tracking, purpose suffixes).
COLLECTED: dict[str, tuple[bool, bool, frozenset[str]]] = {
    "UserID": (True, False, frozenset({"AppFunctionality"})),
    "DeviceID": (False, True, frozenset({"ThirdPartyAdvertising"})),
    "PurchaseHistory": (True, False, frozenset({"AppFunctionality"})),
    "OtherUserContent": (False, False, frozenset({"AppFunctionality"})),
    "ProductInteraction": (False, False, frozenset({"Analytics"})),
    "AdvertisingData": (False, True, frozenset({"ThirdPartyAdvertising"})),
    "CoarseLocation": (False, True, frozenset({"ThirdPartyAdvertising"})),
    "CrashData": (False, False, frozenset({"AppFunctionality"})),
    "PerformanceData": (False, False, frozenset({"AppFunctionality"})),
}
_TYPE = "NSPrivacyCollectedDataType"
_PURPOSE = "NSPrivacyCollectedDataTypePurpose"

ANDROID = "{http://schemas.android.com/apk/res/android}"
TOOLS = "{http://schemas.android.com/tools}"
EXACT_ALARMS = ("android.permission.SCHEDULE_EXACT_ALARM", "android.permission.USE_EXACT_ALARM")
POST_NOTIFICATIONS = "android.permission.POST_NOTIFICATIONS"
AD_ID = "com.google.android.gms.permission.AD_ID"
BOOT_PERMISSION = "android.permission.RECEIVE_BOOT_COMPLETED"
BOOT_ACTION = "android.intent.action.BOOT_COMPLETED"
BOOT_RECEIVER = "com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
SECURE_PREFS = "FlutterSecureStorage.xml"
DEVICE_DB = "taro_device.db"
# (action, scheme) pairs <queries> must declare for UrlLauncher; scheme None = any.
URL_INTENTS = (
    ("android.intent.action.VIEW", "https"),
    ("android.intent.action.DIAL", "tel"),
    ("android.intent.action.SENDTO", "sms"),
    ("android.intent.action.SENDTO", "mailto"),
    ("android.support.customtabs.action.CustomTabsService", None),
)
BACKUP_FILES = {"data_extraction_rules": ("cloud-backup", "device-transfer"), "full_backup_content": (None,)}

# Only the reminder offer asks for notification permission (05 §2, 01 §7.7).
_PLUGIN_REQUEST = re.compile(r"\brequestNotificationsPermission\s*\(|\.requestPermissions\s*\(")
_PORT_REQUEST = re.compile(r"\.requestPermission\s*\(\s*\)")
PLUGIN_CALLERS = ("services/notifications/local_reminder_scheduler.dart",)
PORT_CALLERS = (
    "features/daily_card/controller/daily_card_controller.dart",
    "features/settings/controller/reminder_settings_controller.dart",
)


# ---------------------------------------------------------------- iOS


def load_plist(path: Path, label: str) -> dict[str, Any]:
    try:
        with path.open("rb") as handle:
            data = plistlib.load(handle)
    except Exception as exc:  # InvalidFileException, ValueError, ExpatError…
        raise InputError(label, f"invalid plist: {exc}") from exc
    if not isinstance(data, dict):
        raise InputError(label, "top level is not a dictionary")
    return data


def check_info_plist(data: dict[str, Any], label: str) -> list[Finding]:
    findings: list[Finding] = []
    for key in (f"GOOGLE_ANALYTICS_DEFAULT_ALLOW_{k}" for k in GA_KEYS):
        if data.get(key) is not False:
            findings.append(Finding(label, 0, "consent-default", f"{key} must be false (RC68)"))
    if data.get("SKIncludeConsumableInAppPurchaseHistory") is not True:
        findings.append(Finding(label, 0, "iap-history", "SKIncludeConsumableInAppPurchaseHistory must be YES (RC84)"))
    value = data.get(TRACKING_KEY)
    if not isinstance(value, str) or not value.strip():
        findings.append(Finding(label, 0, "att-string", f"{TRACKING_KEY} is missing or empty"))
    schemes = data.get(QUERIES_KEY)
    listed = set(schemes) if isinstance(schemes, list) else set()
    for scheme in URL_SCHEMES:
        if scheme not in listed:
            findings.append(Finding(label, 0, "url-schemes", f"{QUERIES_KEY} does not list {scheme}"))
    return findings


_STRINGS_ENTRY = re.compile(r'"' + TRACKING_KEY + r'"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')


def strings_value(text: str) -> str | None:
    match = _STRINGS_ENTRY.search(text)
    return match.group(1).replace('\\"', '"').replace("\\\\", "\\") if match else None


def check_tracking_strings(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for locale in LOCALES:
        label = STRINGS.format(locale=locale)
        path = root / label
        if not path.is_file():
            findings.append(Finding(label, 0, "att-string", f"missing ({TRACKING_KEY} for {locale})"))
            continue
        value = strings_value(path.read_text(encoding="utf-8"))
        if not value:
            findings.append(Finding(label, 0, "att-string", f"no {TRACKING_KEY} entry"))
            continue
        arb_path = root / ARB.format(locale=locale)
        if arb_path.is_file():
            try:
                expected = json.loads(arb_path.read_text(encoding="utf-8")).get(ARB_TRACKING_KEY)
            except json.JSONDecodeError as exc:
                raise InputError(rel(root, arb_path), f"invalid JSON: {exc}") from exc
            if expected is not None and expected != value:
                findings.append(Finding(label, 0, "att-string", f"differs from ARB {ARB_TRACKING_KEY} ({locale})"))
    return findings


def check_privacy_manifest(data: dict[str, Any], label: str = PRIVACY) -> list[Finding]:
    findings: list[Finding] = []
    if data.get("NSPrivacyTracking") is not True:
        findings.append(Finding(label, 0, "privacy-tracking", "NSPrivacyTracking must be true (AdMob, ATT)"))
    if not isinstance(data.get("NSPrivacyTrackingDomains", []), list):
        findings.append(Finding(label, 0, "privacy-shape", "NSPrivacyTrackingDomains is not an array"))
    declared: dict[str, tuple[bool, bool, frozenset[str]]] = {}
    for item in data.get("NSPrivacyCollectedDataTypes") or []:
        kind = str(item.get(_TYPE, "")).removeprefix(_TYPE) if isinstance(item, dict) else ""
        if not kind:
            findings.append(Finding(label, 0, "privacy-shape", f"collected data entry without {_TYPE}"))
            continue
        purposes = frozenset(str(p).removeprefix(_PURPOSE) for p in item.get(f"{_TYPE}Purposes") or [])
        declared[kind] = (item.get(f"{_TYPE}Linked") is True, item.get(f"{_TYPE}Tracking") is True, purposes)
    for kind in sorted(set(COLLECTED) - set(declared)):
        findings.append(Finding(label, 0, "privacy-collected", f"{kind} is in 05 §5.1 but not declared"))
    for kind in sorted(set(declared) - set(COLLECTED)):
        findings.append(Finding(label, 0, "privacy-collected", f"{kind} is declared but not in 05 §5.1"))
    for kind in sorted(set(declared) & set(COLLECTED)):
        if declared[kind] != COLLECTED[kind]:
            findings.append(Finding(label, 0, "privacy-collected", f"{kind}: linked/tracking/purposes differ from 05 §5.1"))
    for item in data.get("NSPrivacyAccessedAPITypes") or []:
        api = item.get("NSPrivacyAccessedAPIType") if isinstance(item, dict) else None
        reasons = item.get("NSPrivacyAccessedAPITypeReasons") if isinstance(item, dict) else None
        if not api or not reasons:
            findings.append(Finding(label, 0, "privacy-reason", f"required-reason API {api or '?'} has no reason"))
    return findings


def check_ios(root: Path, plist: Path | None) -> tuple[list[Finding], list[str]]:
    notices: list[str] = []
    if plist is None:
        built = next((root / p for p in RELEASE_PLISTS if (root / p).is_file()), None)
        if built is None:
            notices.append(f"no release Runner.app built; checked the source {INFO_PLIST}")
        plist = built or root / INFO_PLIST
    label = rel(root, plist)
    if not plist.is_file():
        return [Finding(label, 0, "missing", "Info.plist not found")], notices
    findings = check_info_plist(load_plist(plist, label), label)
    findings += check_tracking_strings(root)
    privacy = root / PRIVACY
    if not privacy.is_file():
        findings.append(Finding(PRIVACY, 0, "missing", "privacy manifest not found"))
    else:
        findings += check_privacy_manifest(load_plist(privacy, PRIVACY))
        pbxproj = root / PBXPROJ
        if not pbxproj.is_file() or "PrivacyInfo.xcprivacy in Resources" not in pbxproj.read_text(encoding="utf-8"):
            findings.append(Finding(PBXPROJ, 0, "privacy-target", "PrivacyInfo.xcprivacy is not a Runner resource"))
    return findings, notices


# ---------------------------------------------------------------- Android


def load_xml(path: Path, label: str) -> ET.Element:
    try:
        return ET.parse(path).getroot()
    except ET.ParseError as exc:
        raise InputError(label, f"invalid XML: {exc}") from exc


def _kept(element: ET.Element) -> bool:
    return element.get(f"{TOOLS}node") != "remove"


def permissions(manifest: ET.Element) -> set[str]:
    return {
        e.get(f"{ANDROID}name", "")
        for e in manifest.iter()
        if e.tag in ("uses-permission", "uses-permission-sdk-23") and _kept(e)
    }


def query_intents(manifest: ET.Element) -> set[tuple[str, str | None]]:
    """The (action, scheme) pairs of every ``<queries><intent>``; scheme ``None`` when absent."""
    found: set[tuple[str, str | None]] = set()
    for queries in manifest.iter("queries"):
        for intent in queries.iter("intent"):
            actions = [a.get(f"{ANDROID}name", "") for a in intent.iter("action")]
            schemes = [d.get(f"{ANDROID}scheme") for d in intent.iter("data") if d.get(f"{ANDROID}scheme")]
            for action in actions:
                found.add((action, None))
                found.update((action, scheme) for scheme in schemes)
    return found


def check_android_manifest(manifest: ET.Element, label: str, merged: bool) -> list[Finding]:
    findings: list[Finding] = []
    declared = query_intents(manifest)
    for action, scheme in URL_INTENTS:
        if (action, scheme) not in declared:
            what = f"{action.rsplit('.', 1)[-1]} {scheme}" if scheme else action.rsplit(".", 1)[-1]
            findings.append(Finding(label, 0, "url-queries", f"<queries> does not declare {what} (UrlLauncher)"))
    granted = permissions(manifest)
    for name in EXACT_ALARMS:
        if name in granted:
            findings.append(Finding(label, 0, "exact-alarm", f"{name} must not be declared (inexact reminders)"))
    required = [BOOT_PERMISSION] + ([POST_NOTIFICATIONS, AD_ID] if merged else [])
    for name in required:
        if name not in granted:
            findings.append(Finding(label, 0, "permission", f"{name} is not declared"))
    application = manifest.find("application")
    if application is None:
        return findings + [Finding(label, 0, "application", "no <application> element")]
    meta = {e.get(f"{ANDROID}name"): e.get(f"{ANDROID}value") for e in application.iter("meta-data")}
    for key in (f"google_analytics_default_allow_{k.lower()}" for k in GA_KEYS):
        if meta.get(key) != "false":
            findings.append(Finding(label, 0, "consent-default", f"{key} must be false (RC68)"))
    boot = [
        r for r in application.iter("receiver")
        if r.get(f"{ANDROID}name") == BOOT_RECEIVER and _kept(r)
        and any(a.get(f"{ANDROID}name") == BOOT_ACTION for a in r.iter("action"))
    ]
    if not boot:
        findings.append(Finding(label, 0, "boot-receiver", f"{BOOT_RECEIVER} with BOOT_COMPLETED is missing"))
    for attribute, name in (("dataExtractionRules", "data_extraction_rules"), ("fullBackupContent", "full_backup_content")):
        if application.get(f"{ANDROID}{attribute}") != f"@xml/{name}":
            findings.append(Finding(label, 0, "backup-rules", f"android:{attribute} must be @xml/{name} (RC75)"))
    return findings


def check_backup_rules(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for name, sections in BACKUP_FILES.items():
        label = f"{RES_XML}/{name}.xml"
        path = root / label
        if not path.is_file():
            findings.append(Finding(label, 0, "backup-rules", "missing"))
            continue
        document = load_xml(path, label)
        for section in sections:
            scope = document if section is None else document.find(section)
            excluded = [] if scope is None else [(e.get("domain"), e.get("path", "")) for e in scope.iter("exclude")]
            where = section or "root"
            if ("sharedpref", SECURE_PREFS) not in excluded:
                findings.append(Finding(label, 0, "backup-rules", f"{where}: secure storage prefs not excluded (RC75)"))
            if not any(domain == "file" and p.endswith(DEVICE_DB) for domain, p in excluded):
                findings.append(Finding(label, 0, "backup-rules", f"{where}: {DEVICE_DB} not excluded (RC75)"))
    return findings


def check_permission_callers(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    lib = root / LIB
    for path in sorted(lib.rglob("*.dart")) if lib.is_dir() else []:
        inside = path.relative_to(lib).as_posix()
        code = mask_dart(path.read_text(encoding="utf-8"))
        for pattern, allowed in ((_PLUGIN_REQUEST, PLUGIN_CALLERS), (_PORT_REQUEST, PORT_CALLERS)):
            if inside in allowed:
                continue
            for match in pattern.finditer(code):
                line = code.count("\n", 0, match.start()) + 1
                findings.append(Finding(f"{LIB}/{inside}", line, "notification-request",
                                        "notification permission is asked only from the reminder offer"))
    return findings


def check_r8_rules(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    rules = root / R8_RULES
    if not rules.is_file() or not _ROOM_KEEP.search(rules.read_text(encoding="utf-8")):
        findings.append(Finding(R8_RULES, 0, "r8-keep", "must keep RoomDatabase subclass constructors (<init>())"))
    gradle = root / APP_GRADLE
    if not gradle.is_file() or not _GRADLE_RULES.search(gradle.read_text(encoding="utf-8")):
        findings.append(Finding(APP_GRADLE, 0, "r8-keep", 'release must list proguardFiles("proguard-rules.pro")'))
    seeds = root / R8_SEEDS
    if seeds.is_file():
        kept = seeds.read_text(encoding="utf-8").splitlines()
        if WORK_DB in kept and f"{WORK_DB}: WorkDatabase_Impl()" not in kept:
            findings.append(Finding(R8_SEEDS, 0, "r8-keep", f"R8 dropped the {WORK_DB} constructor"))
    return findings


def check_android(root: Path, manifest: Path | None, require_merged: bool) -> tuple[list[Finding], list[str]]:
    notices: list[str] = []
    merged = True
    if manifest is None:
        manifest = root / MERGED_MANIFEST
        if not manifest.is_file():
            if require_merged:
                return [Finding(MERGED_MANIFEST, 0, "missing", "merged release manifest not built")], notices
            notices.append(
                "merged release manifest not built (cd apps/taro/android && "
                "./gradlew :app:processProdReleaseMainManifest); checked the source manifest"
            )
            manifest, merged = root / SOURCE_MANIFEST, False
    label = rel(root, manifest)
    if not manifest.is_file():
        return [Finding(label, 0, "missing", "AndroidManifest.xml not found")], notices
    findings = check_android_manifest(load_xml(manifest, label), label, merged)
    findings += check_backup_rules(root)
    findings += check_permission_callers(root)
    findings += check_r8_rules(root)
    return findings, notices


def run(
    root: Path, plist: Path | None = None, manifest: Path | None = None, require_merged: bool = False
) -> tuple[list[Finding], list[str]]:
    if not (root / APP).is_dir():
        return [], [f"{APP} not present; skipped"]
    ios_findings, ios_notes = check_ios(root, plist)
    android_findings, android_notes = check_android(root, manifest, require_merged)
    return ios_findings + android_findings, ios_notes + android_notes


def main(argv: Sequence[str] | None = None) -> int:
    parser = base_parser(NAME, __doc__.splitlines()[0])
    parser.add_argument("--ios-plist", type=Path, help="release Info.plist (default: built Runner.app or source)")
    parser.add_argument("--android-manifest", type=Path, help="merged release AndroidManifest.xml")
    parser.add_argument("--require-merged", action="store_true", help="fail when the merged manifest is not built")
    args = parser.parse_args(argv)
    root = resolve_root(args.root, __file__)
    return run_check(NAME, lambda: run(root, args.ios_plist, args.android_manifest, args.require_merged))


if __name__ == "__main__":
    sys.exit(main())

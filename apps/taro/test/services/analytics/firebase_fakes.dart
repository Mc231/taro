import 'package:firebase_analytics_platform_interface/firebase_analytics_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_crashlytics_platform_interface/firebase_crashlytics_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

const String _crashlyticsChannel = 'plugins.flutter.io/firebase_crashlytics';

CoreFirebaseOptions _options() => CoreFirebaseOptions(
  apiKey: 'test',
  projectId: 'taro-test',
  appId: '1:1:ios:1',
  messagingSenderId: '1',
);

/// The Firebase core host API mock: one default app whose plugin constants
/// satisfy Crashlytics (no real Firebase project exists yet, Phase 10).
final class _CoreHostApi implements TestFirebaseCoreHostApi {
  CoreInitializeResponse _app(String name) => CoreInitializeResponse(
    name: name,
    options: _options(),
    pluginConstants: {
      _crashlyticsChannel: {'isCrashlyticsCollectionEnabled': false},
    },
  );

  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async => _app(appName);

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [
    _app(defaultFirebaseAppName),
  ];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _options();
}

/// The single analytics platform fake (Firebase caches its delegate).
final FakeFirebaseAnalyticsPlatform analyticsPlatform =
    FakeFirebaseAnalyticsPlatform();

/// The single Crashlytics platform fake (Firebase caches its delegate).
final FakeFirebaseCrashlyticsPlatform crashlyticsPlatform =
    FakeFirebaseCrashlyticsPlatform();

bool _initialized = false;

/// Initializes a mocked default Firebase app with the platform fakes
/// installed, and resets both fakes.
Future<void> setUpFirebaseFakes() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  analyticsPlatform.reset();
  crashlyticsPlatform.reset();
  if (_initialized) return;
  TestFirebaseCoreHostApi.setUp(_CoreHostApi());
  await Firebase.initializeApp();
  FirebaseAnalyticsPlatform.instance = analyticsPlatform;
  FirebaseCrashlyticsPlatform.instance = crashlyticsPlatform;
  _initialized = true;
}

/// One `logEvent` that reached the platform.
typedef LoggedEvent = ({String name, Map<String, Object?>? parameters});

/// A recording `FirebaseAnalyticsPlatform`; [failWith] makes every call
/// throw.
final class FakeFirebaseAnalyticsPlatform extends FirebaseAnalyticsPlatform {
  /// Creates the fake.
  FakeFirebaseAnalyticsPlatform();

  /// Every event, oldest first.
  final List<LoggedEvent> events = [];

  /// Every `setConsent` call as `[analytics, ad, adUserData, adPers]`.
  final List<List<bool?>> consents = [];

  /// Every `setAnalyticsCollectionEnabled` value.
  final List<bool> collection = [];

  /// Every user property set.
  final Map<String, String?> userProperties = {};

  /// Whether `setUserId` was ever called.
  bool userIdSet = false;

  /// When set, every call throws it.
  Error? failWith;

  /// The event names, oldest first.
  List<String> get eventNames => [for (final e in events) e.name];

  /// Clears the recordings.
  void reset() {
    events.clear();
    consents.clear();
    collection.clear();
    userProperties.clear();
    userIdSet = false;
    failWith = null;
  }

  void _maybeFail() {
    if (failWith case final error?) throw error;
  }

  @override
  FirebaseAnalyticsPlatform delegateFor({
    required FirebaseApp app,
    Map<String, dynamic>? webOptions,
  }) => this;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    _maybeFail();
    events.add((name: name, parameters: parameters));
  }

  @override
  Future<void> setConsent({
    bool? adStorageConsentGranted,
    bool? analyticsStorageConsentGranted,
    bool? adPersonalizationSignalsConsentGranted,
    bool? adUserDataConsentGranted,
    bool? functionalityStorageConsentGranted,
    bool? personalizationStorageConsentGranted,
    bool? securityStorageConsentGranted,
  }) async {
    _maybeFail();
    consents.add([
      analyticsStorageConsentGranted,
      adStorageConsentGranted,
      adUserDataConsentGranted,
      adPersonalizationSignalsConsentGranted,
    ]);
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    _maybeFail();
    collection.add(enabled);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {
    _maybeFail();
    userProperties[name] = value;
  }

  @override
  Future<void> setUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) async {
    userIdSet = true;
  }
}

/// One `recordError` that reached the platform.
typedef RecordedError = ({String exception, String information, bool fatal});

/// A recording `FirebaseCrashlyticsPlatform`; [failWith] makes every call
/// throw.
final class FakeFirebaseCrashlyticsPlatform
    extends FirebaseCrashlyticsPlatform {
  /// Creates the fake (its app is resolved lazily by Firebase).
  FakeFirebaseCrashlyticsPlatform() : super(appInstance: _PendingApp());

  /// Every recorded error, oldest first.
  final List<RecordedError> errors = [];

  /// Every breadcrumb, oldest first.
  final List<String> logs = [];

  /// The custom keys.
  final Map<String, String> keys = {};

  /// Every `setCrashlyticsCollectionEnabled` value.
  final List<bool> collection = [];

  /// When set, every call throws it.
  Error? failWith;

  /// Clears the recordings.
  void reset() {
    errors.clear();
    logs.clear();
    keys.clear();
    collection.clear();
    failWith = null;
  }

  void _maybeFail() {
    if (failWith case final error?) throw error;
  }

  @override
  FirebaseCrashlyticsPlatform setInitialValues({
    required bool isCrashlyticsCollectionEnabled,
  }) => this;

  @override
  bool get isCrashlyticsCollectionEnabled =>
      collection.isNotEmpty && collection.last;

  @override
  Future<void> recordError({
    required String exception,
    required String information,
    required String? reason,
    bool fatal = false,
    String? buildId,
    List<String> loadingUnits = const [],
    List<Map<String, String>>? stackTraceElements,
  }) async {
    _maybeFail();
    errors.add((exception: exception, information: information, fatal: fatal));
  }

  @override
  Future<void> log(String message) async {
    _maybeFail();
    logs.add(message);
  }

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    _maybeFail();
    collection.add(enabled);
  }

  @override
  Future<void> setCustomKey(String key, String value) async {
    _maybeFail();
    keys[key] = value;
  }
}

/// A placeholder app for the Crashlytics fake's constructor; never used.
final class _PendingApp extends Fake implements FirebaseApp {}

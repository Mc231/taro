import 'dart:async';

import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro_core/taro_core.dart';

/// The most events kept before consent resolves (RC68, 02 §9.7).
const int kConsentBufferLimit = 50;

/// The consent decorator of every analytics backend (RC68, 02 §9.7, §13).
///
/// Until `whenResolved` completes, events and screen views are buffered in
/// memory (at most [kConsentBufferLimit]; later ones are dropped) and nothing
/// reaches the inner service. On resolution it applies the resolved Firebase
/// consent mode, then flushes the buffer if analytics storage is granted and
/// collection is on, or drops it otherwise. A failed resolution counts as
/// denied. Events are dropped while collection is disabled or analytics
/// storage is denied.
final class ConsentAwareAnalytics implements TaroAnalyticsBackend {
  /// Decorates [inner]. [whenResolved] completes with the consent mode
  /// derived from the UMP purposes once `ConsentOrchestrator.whenResolved`
  /// completes (all granted where UMP says consent is not required).
  ConsentAwareAnalytics({
    required TaroAnalyticsBackend inner,
    required Future<AnalyticsConsent> whenResolved,
    required Logger logger,
  }) : _inner = inner,
       _log = logger.child('analytics') {
    _ready = whenResolved.then(_resolve, onError: _resolveFailed);
  }

  final TaroAnalyticsBackend _inner;
  final Logger _log;
  final List<_Pending> _buffer = [];
  late final Future<void> _ready;

  AnalyticsConsent? _consent;
  AnalyticsUserProperties? _pendingProperties;
  bool _enabled = true;
  int _overflow = 0;

  /// Completes once consent is resolved and the buffer flushed or dropped.
  Future<void> get ready => _ready;

  /// Whether consent has resolved.
  bool get isResolved => _consent != null;

  /// The number of buffered calls (tests and diagnostics).
  int get bufferedCount => _buffer.length;

  bool get _delivering => _enabled && (_consent?.analyticsStorage ?? false);

  @override
  Future<void> log(TaroAnalyticsEvent event) => _submit(_Pending.event(event));

  @override
  Future<void> screen(String screenId) => _submit(_Pending.screen(screenId));

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {
    _enabled = enabled;
    if (!enabled) _drop('collection disabled');
    await _inner.setCollectionEnabled(enabled: enabled);
  }

  /// Consent mode changes pass straight through (they carry no data); after
  /// resolution they also decide whether later events are delivered.
  @override
  Future<void> setConsent(AnalyticsConsent consent) async {
    if (isResolved) _consent = consent;
    await _inner.setConsent(consent);
  }

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) async {
    if (!isResolved) {
      _pendingProperties = _pendingProperties?.merge(properties) ?? properties;
      return;
    }
    if (_delivering) await _inner.setUserProperties(properties);
  }

  Future<void> _submit(_Pending pending) async {
    if (!_enabled) return;
    if (!isResolved) {
      if (_buffer.length < kConsentBufferLimit) {
        _buffer.add(pending);
      } else {
        _overflow++;
      }
      return;
    }
    if (_delivering) await pending.send(_inner);
  }

  /// Applies [consent], then flushes (in order, including calls that arrive
  /// while flushing) or drops the buffer. [isResolved] turns true only once
  /// the buffer is empty, so nothing overtakes a buffered event.
  Future<void> _resolve(AnalyticsConsent consent) async {
    await _inner.setConsent(consent);
    if (!(_enabled && consent.analyticsStorage)) {
      _consent = consent;
      _drop('analytics consent denied or collection off');
      return;
    }
    var flushed = 0;
    while (_enabled && (_buffer.isNotEmpty || _pendingProperties != null)) {
      final properties = _pendingProperties;
      _pendingProperties = null;
      if (properties != null) await _inner.setUserProperties(properties);
      if (_buffer.isNotEmpty) {
        await _buffer.removeAt(0).send(_inner);
        flushed++;
      }
    }
    _consent = consent;
    _log.fine('consent resolved: flushed $flushed, overflowed $_overflow');
    _overflow = 0;
  }

  Future<void> _resolveFailed(Object error, StackTrace stack) {
    _log.warning('consent did not resolve; treated as denied', error: error);
    return _resolve(AnalyticsConsent.allDenied());
  }

  void _drop(String why) {
    if (_buffer.isEmpty && _overflow == 0 && _pendingProperties == null) {
      return;
    }
    _log.fine('dropped ${_buffer.length + _overflow} buffered events: $why');
    _buffer.clear();
    _overflow = 0;
    _pendingProperties = null;
  }
}

/// A buffered call: an event or a screen view.
sealed class _Pending {
  const _Pending();

  const factory _Pending.event(TaroAnalyticsEvent event) = _PendingEvent;

  const factory _Pending.screen(String screenId) = _PendingScreen;

  Future<void> send(AnalyticsService to);
}

final class _PendingEvent extends _Pending {
  const _PendingEvent(this.event);

  final TaroAnalyticsEvent event;

  @override
  Future<void> send(AnalyticsService to) => to.log(event);
}

final class _PendingScreen extends _Pending {
  const _PendingScreen(this.screenId);

  final String screenId;

  @override
  Future<void> send(AnalyticsService to) => to.screen(screenId);
}

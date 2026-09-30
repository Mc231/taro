import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taro_core/taro_core.dart';

/// Routes uncaught errors to [crash] (02 §9.1 step 2, §13): framework
/// errors (`FlutterError.onError`, still printed through the previous
/// handler) and errors outside the framework
/// (`PlatformDispatcher.onError`, reported fatal).
void installErrorHandlers(
  CrashReporter crash, {
  PlatformDispatcher? dispatcher,
}) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(
      crash.recordError(
        details.exception,
        details.stack ?? StackTrace.empty,
        fatal: !details.silent,
      ),
    );
    previous?.call(details);
  };
  (dispatcher ?? PlatformDispatcher.instance).onError = (error, stack) {
    unawaited(crash.recordError(error, stack, fatal: true));
    return true;
  };
}

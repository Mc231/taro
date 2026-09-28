/// Hierarchical logging (RC41, 02 §13). Loggers are obtained only through
/// this port; `print` is banned.
///
/// Never pass question, note or reading text, tokens or the install ID in
/// a message; the production `Redactor` is a safety net, not a licence.
abstract interface class Logger {
  /// Detailed tracing (dev/staging console only).
  void fine(String message, {Object? error, StackTrace? stack});

  /// A normal event worth a breadcrumb.
  void info(String message, {Object? error, StackTrace? stack});

  /// Something unexpected that the app recovered from.
  void warning(String message, {Object? error, StackTrace? stack});

  /// A failure that needs attention.
  void severe(String message, {Object? error, StackTrace? stack});

  /// A child logger named `<this>.<name>` (for example `taro.sync`).
  Logger child(String name);
}

/// The time source (02 §5, rule 5). `DateTime.now()` is banned outside the
/// `SystemClock` adapter.
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime now();

  /// The current wall-clock time in the device's local time zone.
  DateTime nowLocal();
}

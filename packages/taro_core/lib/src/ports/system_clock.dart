import 'package:clock/clock.dart' as pkg;
import 'package:taro_core/src/ports/clock.dart';

/// The production [Clock] over `package:clock` (02 §5).
///
/// Tests replace it with `FakeClock`; `package:clock`'s `withClock` zones
/// also reach this adapter.
final class SystemClock implements Clock {
  /// Creates the system clock.
  const SystemClock();

  @override
  DateTime now() => pkg.clock.now().toUtc();

  @override
  DateTime nowLocal() => pkg.clock.now().toLocal();
}

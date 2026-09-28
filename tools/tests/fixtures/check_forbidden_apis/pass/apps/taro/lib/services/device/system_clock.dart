/// SystemClock is the adapter allowed to read the wall clock.
class SystemClock {
  DateTime now() => DateTime.now().toUtc();
}

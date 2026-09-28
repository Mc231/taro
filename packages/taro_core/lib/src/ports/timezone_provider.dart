/// The device time zone (02 §5).
// A port is an interface with swappable adapters, even with one member.
// ignore: one_member_abstracts
abstract interface class TimezoneProvider {
  /// The current IANA zone name, for example `Europe/Kyiv`.
  Future<String> currentIana();
}

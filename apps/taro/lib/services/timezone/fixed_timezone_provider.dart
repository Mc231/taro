import 'package:taro_core/taro_core.dart';

/// A [TimezoneProvider] reporting one fixed zone (02 §5): screenshot mode,
/// tests, and platforms without `flutter_timezone`.
final class FixedTimezoneProvider implements TimezoneProvider {
  /// A provider reporting [iana] (default `UTC`).
  const FixedTimezoneProvider([this.iana = 'UTC']);

  /// The reported IANA zone name.
  final String iana;

  @override
  Future<String> currentIana() async => iana;
}

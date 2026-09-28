import 'package:taro_core/taro_core.dart';

/// Predictable IDs. Without a prefix they are canonical UUIDv4 strings
/// (`00000000-0000-4000-8000-000000000001`, …) so they pass UUID checks;
/// with a prefix they are `<prefix>1`, `<prefix>2`, … for readable tests.
final class SequentialIdGenerator implements IdGenerator {
  /// Starts at 1.
  SequentialIdGenerator([this.prefix]);

  /// The readable prefix, or `null` for UUID-shaped IDs.
  final String? prefix;

  int _next = 1;

  /// Every ID issued, oldest first.
  final List<String> issued = [];

  /// The ID the next [uuidV4] call returns.
  String get peek => _format(_next);

  @override
  String uuidV4() {
    final id = _format(_next++);
    issued.add(id);
    return id;
  }

  String _format(int n) => prefix == null
      ? '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}'
      : '$prefix$n';
}

/// The fake of the `IdGenerator` port.
typedef FakeIdGenerator = SequentialIdGenerator;

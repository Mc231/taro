import 'package:taro_core/taro_core.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

/// The production [IdGenerator] (RC41): UUIDv4 from a cryptographically
/// secure generator, canonical lowercase.
final class SecureIdGenerator implements IdGenerator {
  static const Uuid _uuid = Uuid(goptions: GlobalOptions(CryptoRNG()));

  @override
  String uuidV4() => _uuid.v4();
}

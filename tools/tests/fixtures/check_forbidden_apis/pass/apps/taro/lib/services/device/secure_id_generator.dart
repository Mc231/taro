import 'package:uuid/uuid.dart';

class SecureIdGenerator {
  String uuidV4() => const Uuid().v4();
}

import 'dart:math';

class SecureRandomSource {
  final Random _random = Random.secure();
  int nextInt(int max) => _random.nextInt(max);
}

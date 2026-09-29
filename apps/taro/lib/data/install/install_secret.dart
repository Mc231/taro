import 'dart:convert';

import 'package:taro_core/taro_core.dart';

/// The install secret length in bytes (RC54).
const int kInstallSecretBytes = 32;

/// A new install secret: [kInstallSecretBytes] bytes from [random] (the
/// CSPRNG-backed `SecureRandomSource` in production), base64url without
/// padding (43 characters, 03 §3.3).
String generateInstallSecret(RandomSource random) => base64Url
    .encode([for (var i = 0; i < kInstallSecretBytes; i++) random.nextInt(256)])
    .replaceAll('=', '');

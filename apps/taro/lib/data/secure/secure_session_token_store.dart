import 'dart:convert';

import 'package:taro/data/secure/keys.dart';
import 'package:taro_core/taro_core.dart';

/// The [SessionTokenStore] over [SecureStore] (`taro.session_token`,
/// 02 §6.2): a JSON object with the token and its expiry (ISO 8601 UTC). The
/// `WorkerClient`'s auth interceptor reads it on every request.
///
/// An unreadable value reads as "no token" (the install re-registers or
/// refreshes) and is logged without its content.
final class SecureSessionTokenStore implements SessionTokenStore {
  /// Creates the store over a [SecureStore].
  SecureSessionTokenStore(this._secure, {required Logger logger})
    : _logger = logger.child('secure');

  final SecureStore _secure;
  final Logger _logger;

  @override
  Future<Result<SessionToken?>> read() async =>
      (await _secure.read(SecureKeys.sessionToken)).map(_decode);

  @override
  Future<Result<void>> write(SessionToken token) => _secure.write(
    SecureKeys.sessionToken,
    jsonEncode({
      'token': token.token,
      'expiresAt': token.expiresAt.toUtc().toIso8601String(),
    }),
  );

  @override
  Future<Result<void>> clear() => _secure.delete(SecureKeys.sessionToken);

  SessionToken? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SessionToken(
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
      );
    } on Object catch (error) {
      _logger.warning('stored session token unreadable: ${error.runtimeType}');
      return null;
    }
  }
}

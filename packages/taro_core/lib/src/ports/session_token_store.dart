import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/result.dart';

part 'session_token_store.freezed.dart';

/// The Worker install token (`taro.session_token`, 02 §6.2).
@freezed
abstract class SessionToken with _$SessionToken {
  /// Creates a session token.
  const factory SessionToken({
    /// The `installToken` JWT. Never logged.
    required String token,

    /// When the Worker says it expires (UTC).
    required DateTime expiresAt,
  }) = _SessionToken;

  const SessionToken._();

  /// How long before expiry the token is refreshed (02 §9.1: "when the
  /// token expires within 24 h").
  static const Duration refreshWindow = Duration(hours: 24);

  /// Whether the token should be refreshed at [now].
  bool needsRefreshAt(DateTime now) =>
      !now.isBefore(expiresAt.subtract(refreshWindow));
}

/// Persistence of the [SessionToken] (02 §5).
abstract interface class SessionTokenStore {
  /// The stored token, or `null`.
  Future<Result<SessionToken?>> read();

  /// Stores [token], replacing any previous one.
  Future<Result<void>> write(SessionToken token);

  /// Removes the token.
  Future<Result<void>> clear();
}

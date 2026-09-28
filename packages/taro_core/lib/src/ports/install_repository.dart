import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/install_identity.dart';
import 'package:taro_core/src/result/result.dart';

/// The install identity and its Worker registration (02 §5, §6.4).
///
/// Server-side erasure (`DELETE /v1/installs/me`) lives on
/// `DataDeletionGateway` (CS15, RC37), not here.
abstract interface class InstallRepository {
  /// Reads the identity from secure storage, creating the install ID and
  /// secret together on first launch (02 §6.2). Fails with `StorageFailure`
  /// when secure storage is unusable (S01 `storageError`); it never creates
  /// a second ID silently.
  Future<Result<InstallIdentity>> getOrCreate();

  /// Registers with the Worker (`POST /v1/installs`) unless already
  /// registered, and returns the updated identity.
  Future<Result<InstallIdentity>> ensureRegistered();

  /// Refreshes the session token (`POST /v1/installs/token`).
  Future<Result<void>> refreshToken();

  /// Re-registers the free-day time zone (`PUT /v1/installs/me/timezone`).
  /// A `TimezoneChangeRejectedFailure` keeps the server boundary.
  Future<Result<CreditBalance>> updateTimezone(String iana);
}

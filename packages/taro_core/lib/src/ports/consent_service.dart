import 'package:taro_core/src/model/consent_state.dart';

/// Google UMP consent (02 §5, §9.7).
abstract interface class ConsentService {
  /// Updates consent info and shows the form when required. [debugEea]
  /// forces the EEA geography (dev only).
  Future<AdsConsent> gather({bool debugEea = false});

  /// Shows the UMP privacy options form ("Privacy choices" in Settings).
  Future<void> showPrivacyOptions();

  /// The current consent without showing anything.
  Future<AdsConsent> current();
}

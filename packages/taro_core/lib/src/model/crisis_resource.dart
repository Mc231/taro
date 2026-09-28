import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/json.dart';

part 'crisis_resource.freezed.dart';

/// A crisis helpline (canonical schema 03 §9.5, RC81).
///
/// At least one of [phone], [sms] or [url] is set.
@Freezed(fromJson: false, toJson: false)
abstract class CrisisResource with _$CrisisResource {
  /// Creates a resource.
  const factory CrisisResource({
    /// Display name, e.g. "Telefonseelsorge".
    required String name,

    /// When a person last verified this entry.
    required DateTime verifiedAt,

    /// Languages served (BCP 47); empty = not stated.
    @Default(<String>[]) List<String> languages,

    /// Phone number as dialled.
    String? phone,

    /// SMS number or short code.
    String? sms,

    /// Web or chat URL.
    String? url,

    /// Opening hours, e.g. "24/7".
    String? hours,
  }) = _CrisisResource;

  const CrisisResource._();

  /// Parses the 03 §9.5 JSON; throws a [FormatException] when a required
  /// field is missing or no contact channel is present.
  factory CrisisResource.fromJson(Map<String, Object?> json) {
    final resource = CrisisResource(
      name: req<String>(json, 'name'),
      verifiedAt: reqInstant(json, 'verifiedAt'),
      languages: json['languages'] == null
          ? const []
          : reqStrings(json, 'languages'),
      phone: opt<String>(json, 'phone'),
      sms: opt<String>(json, 'sms'),
      url: opt<String>(json, 'url'),
      hours: opt<String>(json, 'hours'),
    );
    if (!resource.hasContact) {
      throw FormatException('"${resource.name}" has no phone, sms or url');
    }
    return resource;
  }

  /// Whether a phone, SMS or URL channel is present.
  bool get hasContact => phone != null || sms != null || url != null;

  /// The 03 §9.5 JSON (absent optional fields are omitted).
  Map<String, Object?> toJson() => {
    'name': name,
    'phone': ?phone,
    'sms': ?sms,
    'url': ?url,
    'hours': ?hours,
    'languages': languages,
    'verifiedAt': formatInstant(verifiedAt),
  };
}

/// The compiled crisis directory (03 §9.5): per-country lists, locale
/// fallbacks and the international entries.
@Freezed(fromJson: false, toJson: false)
abstract class CrisisDirectory with _$CrisisDirectory {
  /// Creates a directory.
  const factory CrisisDirectory({
    /// Resources by ISO 3166-1 alpha-2 country code.
    required Map<String, List<CrisisResource>> countries,

    /// Country to use for a locale when the country is unknown; `null`
    /// values mean "international only".
    required Map<String, String?> localeFallback,

    /// Always-included international entries (e.g. Find A Helpline).
    required List<CrisisResource> international,
  }) = _CrisisDirectory;

  const CrisisDirectory._();

  /// Parses the compiled `crisis_resources.json`; throws a
  /// [FormatException].
  factory CrisisDirectory.fromJson(Map<String, Object?> json) {
    final countries = reqMap(json, 'countries');
    final fallback = reqMap(json, 'localeFallback');
    return CrisisDirectory(
      countries: {
        for (final code in countries.keys)
          code: reqMaps(
            countries,
            code,
          ).map(CrisisResource.fromJson).toList(growable: false),
      },
      localeFallback: {
        for (final locale in fallback.keys)
          locale: opt<String>(fallback, locale),
      },
      international: reqMaps(
        json,
        'international',
      ).map(CrisisResource.fromJson).toList(growable: false),
    );
  }

  /// At most this many entries are shown (03 §9.5).
  static const int maxResults = 3;

  /// Selects up to [maxResults] resources: [country] first, else the
  /// [locale] fallback country, always ending with [international].
  List<CrisisResource> select({String? country, String? locale}) {
    final code = country?.toUpperCase();
    final local =
        countries[code] ?? countries[localeFallback[locale]] ?? const [];
    final room = (maxResults - international.length).clamp(0, maxResults);
    return [
      ...local.take(room),
      ...international,
    ].take(maxResults).toList(growable: false);
  }
}

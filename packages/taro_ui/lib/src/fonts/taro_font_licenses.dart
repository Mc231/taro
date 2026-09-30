import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The bundled font families and their OFL licence files
/// (`packages/taro_ui/fonts/licenses/`).
const Map<String, String> kTaroFontLicenseFiles = {
  'Literata': 'OFL-literata.txt',
  'IBM Plex Sans': 'OFL-ibmplexsans.txt',
  'IBM Plex Sans Arabic': 'OFL-ibmplexsansarabic.txt',
  'IBM Plex Sans JP': 'OFL-ibmplexsansjp.txt',
  'IBM Plex Sans KR': 'OFL-ibmplexsanskr.txt',
  'Noto Naskh Arabic': 'OFL-notonaskharabic.txt',
  'Noto Serif JP': 'OFL-notoserifjp.txt',
  'Noto Serif KR': 'OFL-notoserifkr.txt',
  'IM Fell English SC': 'OFL-imfellenglishsc.txt',
};

/// Loads an asset by key (defaults to `rootBundle.loadString`).
typedef TaroAssetLoader = Future<String> Function(String key);

/// Adds the licences of the bundled fonts to [LicenseRegistry], so they
/// appear on the licences page (OFL 1.1 condition 2). Call once at startup.
void registerTaroFontLicenses({TaroAssetLoader? load}) {
  final loader = load ?? rootBundle.loadString;
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: file)
        in kTaroFontLicenseFiles.entries) {
      final text = await loader('packages/taro_ui/fonts/licenses/$file');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}

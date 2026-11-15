import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;
import 'package:taro/l10n/generated/taro_localizations.dart';

/// The delegates every app root passes as `localizationsDelegates`: the Taro
/// strings plus the Material, Cupertino and widgets ones of `material_ui`.
///
/// Not `TaroLocalizations.localizationsDelegates`: Flutter 3.50's `gen-l10n`
/// still lists the `flutter_localizations` delegates, whose localizations
/// types the `material_ui` widgets do not look up.
const List<LocalizationsDelegate<Object?>> kTaroLocalizationsDelegates = [
  TaroLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

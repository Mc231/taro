import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// Localized card names of the whole deck in the app language (S14 rows and
/// the Patterns card, S15 card labels). A card whose text cannot be read is
/// left out; views fall back to a generic label.
final FutureProvider<Map<CardId, String>> journalCardNamesProvider =
    FutureProvider.autoDispose((ref) async {
      final locale = ref.watch(appLocaleProvider)();
      final content = ref.watch(contentRepositoryProvider);
      final names = <CardId, String>{};
      for (final id in kCardIds) {
        if ((await content.cardText(id, locale)).valueOrNull case final text?) {
          names[id] = text.name;
        }
      }
      return Map.unmodifiable(names);
    });

/// The bundled definition of one spread (the S15 mini spread geometry);
/// `null` when the bundle cannot be read or has no such spread.
final FutureProviderFamily<SpreadDefinition?, SpreadId> journalSpreadProvider =
    FutureProvider.autoDispose.family<SpreadDefinition?, SpreadId>((
      ref,
      id,
    ) async {
      final spreads = await ref.watch(contentRepositoryProvider).spreads();
      return spreads.valueOrNull?.where((s) => s.id == id).firstOrNull;
    });

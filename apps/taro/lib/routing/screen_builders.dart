import 'package:flutter/widgets.dart';
import 'package:taro/features/backup/view/export_screen.dart';
import 'package:taro/features/backup/view/import_screen.dart';
import 'package:taro/features/daily_card/view/daily_card_screen.dart';
import 'package:taro/features/help/view/crisis_resources_screen.dart';
import 'package:taro/features/help/view/faq_screen.dart';
import 'package:taro/features/home/view/home_screen.dart';
import 'package:taro/features/journal/view/journal_entry_screen.dart';
import 'package:taro/features/journal/view/journal_list_screen.dart';
import 'package:taro/features/learn/view/about_screen.dart';
import 'package:taro/features/learn/view/card_detail_screen.dart';
import 'package:taro/features/learn/view/deck_browser_screen.dart';
import 'package:taro/features/learn/view/learn_labels.dart';
import 'package:taro/features/learn/view/spread_guide_screen.dart';
import 'package:taro/features/legal/controller/legal_controller.dart';
import 'package:taro/features/legal/view/legal_screen.dart';
import 'package:taro/features/onboarding/view/ai_consent_screen.dart';
import 'package:taro/features/onboarding/view/disclaimer_screen.dart';
import 'package:taro/features/onboarding/view/launch_screen.dart';
import 'package:taro/features/onboarding/view/welcome_screen.dart';
import 'package:taro/features/paywall/view/out_of_readings_screen.dart';
import 'package:taro/features/paywall/view/rewarded_screen.dart';
import 'package:taro/features/paywall/view/store_screen.dart';
import 'package:taro/features/reading/view/classic_reading_screen.dart';
import 'package:taro/features/reading/view/draw_screen.dart';
import 'package:taro/features/reading/view/question_screen.dart';
import 'package:taro/features/reading/view/reading_result_screen.dart';
import 'package:taro/features/reading/view/report_reading_sheet.dart';
import 'package:taro/features/reading/view/spread_picker_screen.dart';
import 'package:taro/features/settings/view/delete_data_screen.dart';
import 'package:taro/features/settings/view/language_screen.dart';
import 'package:taro/features/settings/view/privacy_screen.dart';
import 'package:taro/features/settings/view/reminder_settings_screen.dart';
import 'package:taro/features/settings/view/settings_screen.dart';
import 'package:taro/features/update/view/update_required_screen.dart';
import 'package:taro/routing/placeholder_screen.dart';
import 'package:taro_core/taro_core.dart';

/// What a screen gets from its route: path parameters (`id`, `cardId`,
/// `spreadId`, `doc`) and query parameters (`spread`, `mode`).
@immutable
final class ScreenArgs {
  /// Route arguments.
  const ScreenArgs({this.path = const {}, this.query = const {}});

  /// Path parameters.
  final Map<String, String> path;

  /// Query parameters.
  final Map<String, String> query;
}

/// Builds the screen of one S-ID.
typedef ScreenBuilder = Widget Function(BuildContext context, ScreenArgs args);

Widget _placeholder(ScreenId screen) =>
    PlaceholderScreen(screen: screen, key: ValueKey(screen));

/// The screen of every S-ID (01 §8.1). The route table and the modal
/// helpers in `routes.dart` build screens only through this map, so each
/// feature replaces its placeholder entry with its real screen, e.g.
/// `ScreenId.s05: (context, args) => const HomeScreen()`.
final Map<ScreenId, ScreenBuilder> screenBuilders = {
  ScreenId.s01: (context, args) =>
      const LaunchScreen(key: ValueKey(ScreenId.s01)),
  ScreenId.s02: (context, args) =>
      const WelcomeScreen(key: ValueKey(ScreenId.s02)),
  ScreenId.s03: (context, args) =>
      const DisclaimerScreen(key: ValueKey(ScreenId.s03)),
  ScreenId.s04: (context, args) =>
      AiConsentScreen.fromQuery(args.query, key: const ValueKey(ScreenId.s04)),
  ScreenId.s05: (context, args) =>
      const HomeScreen(key: ValueKey(ScreenId.s05)),
  ScreenId.s06: (context, args) =>
      const SpreadPickerScreen(key: ValueKey(ScreenId.s06)),
  ScreenId.s07: (context, args) =>
      QuestionScreen.fromQuery(args.query, key: const ValueKey(ScreenId.s07)),
  ScreenId.s08: (context, args) => DrawEntry(
    key: const ValueKey(ScreenId.s08),
    resumeId: args.query['resume'],
  ),
  ScreenId.s09: (context, args) => ReadingResultScreen.fromRoute(
    args.path,
    args.query,
    key: const ValueKey(ScreenId.s09),
  ),
  ScreenId.s10: (context, args) => OutOfReadingsScreen(
    key: const ValueKey(ScreenId.s10),
    source: outOfReadingsSourceOf(args.query['source']),
  ),
  ScreenId.s11: (context, args) => StoreScreen(
    key: const ValueKey(ScreenId.s11),
    source: storeSourceOf(args.query['source']),
  ),
  ScreenId.s12: (context, args) =>
      const RewardedScreen(key: ValueKey(ScreenId.s12)),
  ScreenId.s13: (context, args) =>
      const DailyCardScreen(key: ValueKey(ScreenId.s13)),
  ScreenId.s14: (context, args) =>
      const JournalListScreen(key: ValueKey(ScreenId.s14)),
  ScreenId.s15: (context, args) => JournalEntryScreen(
    key: const ValueKey(ScreenId.s15),
    id: args.path['id'] ?? '',
  ),
  ScreenId.s16: (context, args) =>
      const DeckBrowserScreen(key: ValueKey(ScreenId.s16)),
  ScreenId.s17: (context, args) => CardDetailScreen(
    key: const ValueKey(ScreenId.s17),
    cardId: CardId(args.path['cardId'] ?? ''),
    origin: LearnLabels.originOf(args.query['origin']),
  ),
  ScreenId.s18: (context, args) => SpreadGuideScreen(
    key: const ValueKey(ScreenId.s18),
    initial: switch (args.path['spreadId']) {
      final id? => SpreadId(id),
      null => null,
    },
  ),
  ScreenId.s19: (context, args) =>
      const AboutScreen(key: ValueKey(ScreenId.s19)),
  ScreenId.s20: (context, args) =>
      const SettingsScreen(key: ValueKey(ScreenId.s20)),
  ScreenId.s21: (context, args) =>
      const LanguageScreen(key: ValueKey(ScreenId.s21)),
  ScreenId.s22: (context, args) =>
      const ReminderSettingsScreen(key: ValueKey(ScreenId.s22)),
  ScreenId.s23: (context, args) =>
      const PrivacyScreen(key: ValueKey(ScreenId.s23)),
  ScreenId.s24: (context, args) =>
      const ExportScreen(key: ValueKey(ScreenId.s24)),
  ScreenId.s25: (context, args) =>
      const ImportScreen(key: ValueKey(ScreenId.s25)),
  ScreenId.s26: (context, args) =>
      const DeleteDataScreen(key: ValueKey(ScreenId.s26)),
  ScreenId.s27: (context, args) => CrisisResourcesScreen.fromQuery(
    args.query,
    key: const ValueKey(ScreenId.s27),
  ),
  ScreenId.s28: (context, args) => const FaqScreen(key: ValueKey(ScreenId.s28)),
  ScreenId.s29: (context, args) => LegalScreen(
    key: const ValueKey(ScreenId.s29),
    doc: LegalDoc.fromSegment(args.path['doc'] ?? '') ?? LegalDoc.disclaimer,
  ),
  ScreenId.s30: (context, args) =>
      const UpdateRequiredScreen(key: ValueKey(ScreenId.s30)),
  ScreenId.s31: (context, args) => _placeholder(ScreenId.s31),
  ScreenId.s32: (context, args) => ClassicReadingScreen(
    id: ReadingId(args.path['id'] ?? ''),
    key: const ValueKey(ScreenId.s32),
  ),
  ScreenId.s33: (context, args) => ReportReadingSheet(
    id: ReadingId(args.path['id'] ?? ''),
    key: const ValueKey(ScreenId.s33),
  ),
};

/// Builds [screen] with [args].
Widget buildScreen(
  BuildContext context,
  ScreenId screen, [
  ScreenArgs args = const ScreenArgs(),
]) => screenBuilders[screen]!(context, args);

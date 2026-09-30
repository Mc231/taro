import 'package:taro/routing/route_paths.dart';

/// The deep-link allowlist (01 §9.1, 02 §8.2, RC17).
///
/// Accepts the custom scheme `taro://` and Universal Links / App Links on
/// `https://<universalLinkHost>/app/*`:
///
/// | Link | Location |
/// |---|---|
/// | `taro://daily` | `/daily` |
/// | `taro://reading/new?spread={spreadId}` | `/reading/question?spread=` |
/// | `taro://journal/{id}` | `/journal/:id` |
/// | `taro://learn/card/{cardId}` | `/learn/card/:cardId` |
/// | `taro://store` | `/store` |
///
/// Anything else, and any malformed parameter, lands on `/home`. Links only
/// navigate: none starts a draw, spends a credit or opens a purchase sheet
/// (no query reaches `/store`, the question screen still needs **Begin**).
final class DeepLinkPolicy {
  /// A policy for the Universal Link [universalLinkHost]
  /// (`FlavorConfig.universalLinkHost`).
  const DeepLinkPolicy({required this.universalLinkHost});

  /// The custom scheme.
  static const String scheme = 'taro';

  /// The Universal Link / App Link path prefix.
  static const String universalLinkPrefix = 'app';

  /// Spread IDs: lower snake case (GLOSSARY §2).
  static final RegExp _spreadId = RegExp(r'^[a-z][a-z0-9_]{0,39}$');

  /// Card IDs (GLOSSARY §1).
  static final RegExp _cardId = RegExp(
    '^(major_(0[0-9]|1[0-9]|2[01])|'
    r'(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$',
  );

  /// Journal entries: a reading UUID or a daily card's local date.
  static final RegExp _journalId = RegExp(
    '^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}|\d{4}-\d{2}-\d{2})$',
  );

  /// The Universal Link host.
  final String universalLinkHost;

  /// Whether [uri] is a link from outside the app (custom scheme or
  /// Universal Link) rather than an in-app location.
  bool isExternal(Uri uri) =>
      uri.scheme == scheme ||
      ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty);

  /// The in-app location for the external link [uri]; `/home` for anything
  /// outside the allowlist.
  String sanitize(Uri uri) {
    final segments = _segments(uri);
    if (segments == null) return RoutePaths.home;
    return switch (segments) {
      ['daily'] => RoutePaths.daily,
      ['store'] => RoutePaths.store,
      ['reading', 'new'] => _question(uri.queryParameters['spread']),
      ['journal', final id] when _journalId.hasMatch(id) =>
        RoutePaths.journalEntry(id),
      ['learn', 'card', final cardId] when _cardId.hasMatch(cardId) =>
        RoutePaths.learnCard(cardId),
      _ => RoutePaths.home,
    };
  }

  String _question(String? spread) =>
      spread != null && _spreadId.hasMatch(spread)
      ? RoutePaths.readingQuestion(spread)
      : RoutePaths.home;

  /// The link's path segments after the scheme's own prefix, or `null` for
  /// a foreign host or a Universal Link outside `/app/`.
  List<String>? _segments(Uri uri) {
    if (uri.scheme == scheme) {
      return [
        if (uri.host.isNotEmpty) uri.host,
        ...uri.pathSegments.where((s) => s.isNotEmpty),
      ];
    }
    if (uri.scheme != 'https' || uri.host != universalLinkHost) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty || segments.first != universalLinkPrefix) {
      return null;
    }
    return segments.sublist(1);
  }
}

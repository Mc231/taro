import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'faq_controller.freezed.dart';

/// S28 FAQ / Help (01 §7.10 Help; authored offline in
/// `content/source/<locale>/articles/faq.md`).
@freezed
sealed class FaqState with _$FaqState {
  /// Reading the bundled article.
  const factory FaqState.loading() = FaqLoading;

  /// The FAQ sections (filtered by [query]) and the contact card.
  const factory FaqState.content({
    required List<ArticleSection> sections,

    /// The search text (empty when not searching).
    @Default('') String query,

    /// Titles of the expanded questions.
    @Default(<String>{}) Set<String> expanded,

    /// Email, Support ID and diagnostics for "Email support"; `null` until
    /// the install is known.
    SupportInfo? support,
  }) = FaqContent;

  /// The search matches nothing: "No answers match “…”" + Email support.
  const factory FaqState.searchEmpty({
    required String query,
    SupportInfo? support,
  }) = FaqSearchEmpty;

  /// The bundled content could not be read.
  const factory FaqState.storageError() = FaqStorageError;
}

/// Drives S28: the FAQ accordion, its local search and the Contact support
/// card (Support ID, RC43).
final class FaqController extends Notifier<FaqState> {
  Article? _article;
  SupportInfo? _support;
  String _query = '';
  final Set<String> _expanded = {};

  @override
  FaqState build() {
    unawaited(_load());
    return const FaqState.loading();
  }

  /// Filters questions and answers by [text] (case-insensitive).
  void search(String text) {
    _query = text.trim();
    _update();
  }

  /// Expands or collapses the question [title].
  void toggle(String title) {
    if (!_expanded.remove(title)) _expanded.add(title);
    _update();
  }

  Future<void> _load() async {
    final loaded = await ref.read(articleLoaderProvider)(
      ArticleId.faq,
      ref.read(appLocaleProvider)(),
    );
    if (!ref.mounted) return;
    switch (loaded) {
      case Err():
        state = const FaqState.storageError();
        return;
      case Ok(:final value):
        _article = value;
        _update();
    }
    if (!ref.mounted) return;
    final support = await loadSupportInfo(ref);
    if (!ref.mounted) return;
    _support = support.valueOrNull;
    _update();
  }

  void _update() {
    final article = _article;
    if (article == null || !ref.mounted) return;
    final needle = _query.toLowerCase();
    bool hit(String s) => s.toLowerCase().contains(needle);
    final sections = needle.isEmpty
        ? article.sections
        : [
            for (final section in article.sections)
              if ([
                    for (final e in section.entries)
                      if (hit(e.title) || e.paragraphs.any(hit)) e,
                  ]
                  case final entries when entries.isNotEmpty)
                ArticleSection(heading: section.heading, entries: entries),
          ];
    // Only a query can match nothing; with none every entry shows (BUG-15).
    state = sections.isEmpty && needle.isNotEmpty
        ? FaqState.searchEmpty(query: _query, support: _support)
        : FaqState.content(
            sections: sections,
            query: _query,
            expanded: Set.unmodifiable(_expanded),
            support: _support,
          );
  }
}

/// S28 controller.
final NotifierProvider<FaqController, FaqState> faqControllerProvider =
    NotifierProvider.autoDispose(FaqController.new);

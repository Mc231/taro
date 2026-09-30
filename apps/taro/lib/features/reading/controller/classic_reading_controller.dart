import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro_core/taro_core.dart';

part 'classic_reading_controller.freezed.dart';

/// One S32 position: the card, its authored text and the spread slot (the
/// position name and description are ARB `spread_{id}_pos_{pos}_*`).
@freezed
abstract class ClassicPosition with _$ClassicPosition {
  /// Creates a position.
  const factory ClassicPosition({
    required DrawnCard card,
    required CardText text,
    SpreadPosition? position,
  }) = _ClassicPosition;

  const ClassicPosition._();

  /// `shortUpright` / `shortReversed`.
  String get short => text.short(reversed: card.reversed);

  /// `meaningUpright` / `meaningReversed`.
  String get meaning => text.meaning(reversed: card.reversed);
}

/// The S32 content (01 §9.9 step 3).
@freezed
abstract class ClassicReadingView with _$ClassicReadingView {
  /// Creates a view.
  const factory ClassicReadingView({
    required Reading reading,
    required List<ClassicPosition> positions,
    @Default(false) bool aiAvailable,
  }) = _ClassicReadingView;
}

/// S32 Classic reading result (01 §8.3, RC20, RC71): a "Classic reading"
/// label instead of "AI-generated", the disclaimer footer, no banner, no
/// report, no rate-app credit.
@freezed
sealed class ClassicReadingState with _$ClassicReadingState {
  /// Reading the stored reading and the bundled texts.
  const factory ClassicReadingState.loadingFromStorage() =
      ClassicReadingLoadingFromStorage;

  /// Per position: card name, orientation, short + full meaning. "Try an
  /// AI reading" shows only when [ClassicReadingView.aiAvailable].
  const factory ClassicReadingState.content(ClassicReadingView view) =
      ClassicReadingContent;

  /// No such reading.
  const factory ClassicReadingState.notFound() = ClassicReadingNotFound;

  /// The bundled content could not be read.
  const factory ClassicReadingState.failed(Failure failure) =
      ClassicReadingFailed;
}

/// S32 over `ContentRepository` (bundled `apps/taro/assets/deck/`): no hold
/// and no Worker call. "Try an AI reading" is offered only when the gate
/// would allow one now.
final class ClassicReadingController extends Notifier<ClassicReadingState> {
  /// A controller for the reading [id].
  ClassicReadingController(this.id);

  /// The Classic reading.
  final ReadingId id;

  @override
  ClassicReadingState build() {
    unawaited(Future.microtask(_load));
    return const ClassicReadingState.loadingFromStorage();
  }

  Future<void> _load() async {
    final stored = await ref.read(readingRepositoryProvider).get(id);
    if (!ref.mounted) return;
    final reading = stored.valueOrNull;
    if (reading == null) {
      state = stored.failureOrNull == null
          ? const ClassicReadingState.notFound()
          : ClassicReadingState.failed(stored.failureOrNull!);
      return;
    }
    final content = ref.read(contentRepositoryProvider);
    final locale = ref.read(appLocaleProvider)();
    final spreads = await content.spreads();
    final spread = spreads.valueOrNull?.firstWhereOrNull(
      (s) => s.id == reading.spreadId,
    );
    final positions = <ClassicPosition>[];
    for (final card in reading.cards) {
      final text = await content.cardText(card.cardId, locale);
      if (!ref.mounted) return;
      switch (text) {
        case Ok(:final value):
          positions.add(
            ClassicPosition(
              card: card,
              text: value,
              position: spread?.position(card.positionId),
            ),
          );
        case Err(:final failure):
          state = ClassicReadingState.failed(failure);
          return;
      }
    }
    final view = ClassicReadingView(reading: reading, positions: positions);
    state = ClassicReadingState.content(view);
    if (spread == null) return;
    final gate = await ref.read(resolveReadingGateProvider).call(spread);
    if (!ref.mounted) return;
    if (gate case Ok(value: GateAllowed())) {
      state = ClassicReadingState.content(view.copyWith(aiAvailable: true));
    }
  }
}

/// S32 (`classicReadingControllerProvider(readingId)`).
final NotifierProviderFamily<
  ClassicReadingController,
  ClassicReadingState,
  ReadingId
>
classicReadingControllerProvider = NotifierProvider.autoDispose.family(
  ClassicReadingController.new,
);

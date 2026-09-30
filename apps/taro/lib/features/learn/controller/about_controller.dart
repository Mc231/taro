import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'about_controller.freezed.dart';

/// S19 Learn "About tarot & Taro" (01 §7.9: history, reflection, how AI
/// readings work and their limits, the disclaimer).
@freezed
sealed class AboutState with _$AboutState {
  /// Reading the bundled article.
  const factory AboutState.loading() = AboutLoading;

  /// The authored article of the app locale (English fallback).
  const factory AboutState.content(Article article) = AboutContent;

  /// The bundled content could not be read.
  const factory AboutState.storageError() = AboutStorageError;
}

/// Drives S19 from the bundled `about` article (offline, no gating).
final class AboutController extends Notifier<AboutState> {
  @override
  AboutState build() {
    unawaited(_load());
    return const AboutState.loading();
  }

  Future<void> _load() async {
    final loaded = await ref.read(articleLoaderProvider)(
      ArticleId.about,
      ref.read(appLocaleProvider)(),
    );
    if (!ref.mounted) return;
    state = switch (loaded) {
      Ok(:final value) => AboutState.content(value),
      Err() => const AboutState.storageError(),
    };
  }
}

/// S19 controller.
final NotifierProvider<AboutController, AboutState> aboutControllerProvider =
    NotifierProvider.autoDispose(AboutController.new);

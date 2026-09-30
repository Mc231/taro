import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/features/update/controller/update_required_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S30 Update required (01 §8.3 `content`, RC73): blocking (back does not
/// leave), store link only. [onOpenStore] opens this platform's store
/// listing; without it the button is disabled.
class UpdateRequiredScreen extends ConsumerWidget {
  /// Creates the screen; [origin] is `launch` on cold start.
  const UpdateRequiredScreen({
    this.origin = AppNoticeOrigin.launch,
    this.onOpenStore,
    super.key,
  });

  /// Where the requirement was found.
  final AppNoticeOrigin origin;

  /// Opens the store listing.
  final VoidCallback? onOpenStore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateRequiredControllerProvider(origin));
    return PopScope(
      canPop: false,
      child: UpdateRequiredLayout(state: state, onOpenStore: onOpenStore),
    );
  }
}

/// The S30 layout.
class UpdateRequiredLayout extends StatelessWidget {
  /// Creates the view.
  const UpdateRequiredLayout({
    required this.state,
    required this.onOpenStore,
    super.key,
  });

  /// The controller state.
  final UpdateRequiredState state;

  /// Opens the store listing.
  final VoidCallback? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final (platform, installedVersion) = switch (state) {
      UpdateRequiredContent(:final platform, :final installedVersion) => (
        platform,
        installedVersion,
      ),
    };
    return TaroScaffold(
      body: ListView(
        padding: EdgeInsetsDirectional.only(top: tokens.space.s9),
        children: [
          Center(child: TaroBrandMark(semanticsLabel: l10n.launchSemantics)),
          SizedBox(height: tokens.space.s8),
          Semantics(
            header: true,
            child: Text(l10n.updateTitle, style: tokens.typography.headline),
          ),
          SizedBox(height: tokens.space.s4),
          Text(l10n.updateBody, style: tokens.typography.body),
          SizedBox(height: tokens.space.s7),
          TaroInlineNotice(
            kind: TaroNoticeKind.info,
            title: l10n.updateSafeTitle,
            body: l10n.updateSafeBody,
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s3,
        children: [
          TaroButton.primary(
            label: l10n.updateButton,
            expand: true,
            onPressed: onOpenStore,
          ),
          Text(
            switch (platform) {
              AppPlatform.ios => l10n.updateCaptionIos(installedVersion),
              AppPlatform.android => l10n.updateCaptionAndroid(
                installedVersion,
              ),
            },
            textAlign: TextAlign.center,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.text.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

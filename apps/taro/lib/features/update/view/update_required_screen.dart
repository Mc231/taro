import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/update/controller/update_required_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S30 Update required (01 §8.3 `content`, RC73): blocking (back does not
/// leave), store link only. [onOpenStore] overrides the default, which
/// opens this platform's store listing through `UrlLauncher`; with no
/// listing known the button is disabled.
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
    final listing = ref.watch(storeLinksProvider).listing;
    final open =
        onOpenStore ??
        (listing == null
            ? null
            : () => unawaited(ref.read(urlLauncherProvider).open(listing)));
    return PopScope(
      canPop: false,
      child: UpdateRequiredLayout(state: state, onOpenStore: open),
    );
  }
}

/// The S30 layout (`docs/design/screens/S30`): three fanned card backs on
/// a soft glow, the title, the body, the "Your journal is safe" panel and
/// the Update button with its store caption. No back, no tabs.
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
    final c = tokens.color;
    final (platform, installedVersion) = switch (state) {
      UpdateRequiredContent(:final platform, :final installedVersion) => (
        platform,
        installedVersion,
      ),
    };
    return TaroScaffold(
      body: ListView(
        padding: EdgeInsetsDirectional.only(
          top: tokens.space.s9,
          bottom: tokens.space.s7,
        ),
        children: [
          const _UpdateFan(),
          SizedBox(height: tokens.space.s8),
          Semantics(
            header: true,
            child: Text(
              l10n.updateTitle,
              textAlign: TextAlign.center,
              style: tokens.typography.headline.copyWith(
                color: c.text.primary,
              ),
            ),
          ),
          SizedBox(height: tokens.space.s4),
          Text(
            l10n.updateBody,
            textAlign: TextAlign.center,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          ),
          SizedBox(height: tokens.space.s8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.bg.surface,
              borderRadius: BorderRadius.circular(tokens.radius.md),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(tokens.space.s5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s4,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: tokens.size.icon.md,
                      color: c.status.success,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: l10n.updateSafeTitle,
                            style: TextStyle(
                              color: c.text.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: l10n.updateSafeBody),
                        ],
                      ),
                      style: tokens.typography.body.copyWith(
                        color: c.text.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              color: c.text.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The decorative S30 illustration: a `color.accent.subtle` glow behind
/// three fanned `TaroCardBack`s (mirrored in RTL, static).
class _UpdateFan extends StatelessWidget {
  const _UpdateFan();

  /// The tilt of the side cards (the S02 fan's angle).
  static const double angle = 0.22;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = TaroCardSize.md.sizeOf(tokens);
    final offset = tokens.space.s10;
    Widget side(double sign) => Transform.translate(
      offset: Offset(sign * offset, tokens.space.s3),
      child: Transform.rotate(
        angle: sign * angle,
        child: const TaroCardBack(size: TaroCardSize.md),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: card.height + tokens.space.s10,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: card.width,
              height: card.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tokens.radius.full),
                boxShadow: [
                  BoxShadow(
                    color: tokens.color.accent.subtle,
                    blurRadius: card.width,
                    spreadRadius: tokens.space.s9,
                  ),
                ],
              ),
            ),
            side(-1),
            side(1),
            const TaroCardBack(size: TaroCardSize.md),
          ],
        ),
      ),
    );
  }
}

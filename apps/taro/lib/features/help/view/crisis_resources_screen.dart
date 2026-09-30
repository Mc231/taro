import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/features/help/controller/crisis_resources_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S27 Crisis resources (01 §8.3 `content`; 05 §3 `crisisTitle` /
/// `crisisBody`): bundled, so it works offline; the device region is used
/// on the device only (RC25, RC81). No ads, no upsell.
class CrisisResourcesScreen extends ConsumerWidget {
  /// Creates the screen for [origin].
  const CrisisResourcesScreen({
    this.origin = CrisisResourcesOrigin.help,
    super.key,
  });

  /// The screen for the route's `origin` query (default: help).
  factory CrisisResourcesScreen.fromQuery(
    Map<String, String> query, {
    Key? key,
  }) => CrisisResourcesScreen(
    origin: CrisisResourcesOrigin.values.firstWhere(
      (o) => o.wire == query[originQuery],
      orElse: () => CrisisResourcesOrigin.help,
    ),
    key: key,
  );

  /// The route query naming the origin.
  static const String originQuery = 'origin';

  /// The S27 location for [origin].
  static String location(CrisisResourcesOrigin origin) =>
      RoutePaths.helpCrisisFrom(origin.wire);

  /// Where S27 was opened from.
  final CrisisResourcesOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = crisisResourcesControllerProvider(origin);
    final state = ref.watch(provider);
    return CrisisResourcesLayout(
      state: state,
      onClose: () =>
          context.canPop() ? context.pop() : context.go(RoutePaths.home),
      onRetry: () => ref.invalidate(provider),
      onChooseCountry: (country) =>
          ref.read(provider.notifier).chooseCountry(country),
    );
  }
}

/// The S27 layout for [state].
class CrisisResourcesLayout extends StatelessWidget {
  /// Creates the view.
  const CrisisResourcesLayout({
    required this.state,
    required this.onClose,
    required this.onRetry,
    required this.onChooseCountry,
    super.key,
  });

  /// The controller state.
  final CrisisResourcesState state;

  /// Leaves S27.
  final VoidCallback onClose;

  /// Re-reads the bundled directory.
  final VoidCallback onRetry;

  /// "Show resources for another country".
  final ValueChanged<String> onChooseCountry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.commonClose,
        onLeading: onClose,
      ),
      body: switch (state) {
        CrisisResourcesLoading() => TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
        ),
        CrisisResourcesStorageError() => FailureView(
          kind: ErrorKind.storage,
          onRetry: onRetry,
        ),
        final CrisisResourcesContent content => _content(context, content),
      },
    );
  }

  Widget _content(BuildContext context, CrisisResourcesContent content) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final country = content.country;
    return ListView(
      children: [
        Semantics(
          header: true,
          child: Text(l10n.crisisTitle, style: tokens.typography.headline),
        ),
        SizedBox(height: tokens.space.s4),
        Text(l10n.crisisBody, style: tokens.typography.body),
        if (country != null && content.hasLocalLines) ...[
          SizedBox(height: tokens.space.s7),
          Text(
            l10n.crisisSupportIn(country),
            style: tokens.typography.titleSmall,
          ),
        ],
        for (final resource in content.resources)
          Padding(
            padding: EdgeInsetsDirectional.only(top: tokens.space.s4),
            child: _ResourceCard(resource: resource),
          ),
        SizedBox(height: tokens.space.s7),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TaroButton.tertiary(
            label: l10n.crisisOtherCountry,
            onPressed: content.countries.isEmpty
                ? null
                : () => unawaited(_pickCountry(context, content.countries)),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCountry(
    BuildContext context,
    List<String> countries,
  ) async {
    final l10n = TaroLocalizations.of(context);
    final picked = await TaroSheet.show<String>(
      context,
      builder: (sheet) => TaroSheet(
        title: l10n.crisisCountryPicker,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final code in countries)
              TaroListTile(
                title: code,
                onTap: () => Navigator.of(sheet).pop(code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChooseCountry(picked);
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});

  final CrisisResource resource;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final contacts = [?resource.phone, ?resource.sms, ?resource.url];
    final hours = resource.hours;
    return TaroSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.space.s2,
        children: [
          Text(resource.name, style: tokens.typography.titleSmall),
          for (final contact in contacts)
            SelectableText(
              hours == null ? contact : l10n.crisisHours(contact, hours),
              style: tokens.typography.body,
            ),
          Text(
            l10n.crisisLastChecked(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(resource.verifiedAt),
            ),
            style: tokens.typography.caption.copyWith(
              color: tokens.color.text.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

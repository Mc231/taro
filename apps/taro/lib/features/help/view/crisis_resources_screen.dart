import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/di/providers.dart';
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
          origin == CrisisResourcesOrigin.reading || !context.canPop()
          ? context.go(RoutePaths.home)
          : context.pop(),
      onOpen: (uri) async {
        final opened = await ref.read(urlLauncherProvider).open(uri);
        if (opened.isErr && context.mounted) {
          TaroToast.show(
            context,
            message: TaroLocalizations.of(context).crisisOpenFailed,
          );
        }
      },
      onRetry: () => ref.invalidate(provider),
      onChooseCountry: (country) =>
          ref.read(provider.notifier).chooseCountry(country),
    );
  }
}

/// The S27 layout for [state] (`docs/design/screens/S27/spec.md`): calm
/// copy, the country's lines (at most 3, the international entry last),
/// each with a Call / Text / Open action, "Show resources for another
/// country" and "Last checked". No ads, no upsell, no balance (01 §7.5).
class CrisisResourcesLayout extends StatelessWidget {
  /// Creates the view.
  const CrisisResourcesLayout({
    required this.state,
    required this.onClose,
    required this.onRetry,
    required this.onChooseCountry,
    required this.onOpen,
    super.key,
  });

  /// The controller state.
  final CrisisResourcesState state;

  /// Leaves S27 (Home after a declined reading).
  final VoidCallback onClose;

  /// Re-reads the bundled directory.
  final VoidCallback onRetry;

  /// "Show resources for another country".
  final ValueChanged<String> onChooseCountry;

  /// Opens a `tel:`, `sms:` or `https:` link outside the app.
  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
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
    final secondary = tokens.color.text.secondary;
    // No date while any shown entry is unverified (R2-03): the bundled
    // source has `verifiedAt: null` until the owner checks it.
    final checked = content.resources.any((r) => !r.isVerified)
        ? null
        : content.resources
              .map((r) => r.verifiedAt)
              .fold<DateTime?>(
                null,
                (oldest, at) =>
                    oldest == null || at.isBefore(oldest) ? at : oldest,
              );
    return ListView(
      padding: EdgeInsetsDirectional.only(
        top: tokens.space.s6,
        bottom: tokens.space.s7,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.crisisTitle,
            style: tokens.typography.headline.copyWith(
              color: tokens.color.text.primary,
            ),
          ),
        ),
        SizedBox(height: tokens.space.s3),
        Text(
          l10n.crisisBody,
          style: tokens.typography.body.copyWith(color: secondary),
        ),
        if (country != null && content.hasLocalLines) ...[
          SizedBox(height: tokens.space.s6),
          Semantics(
            header: true,
            child: Text(
              l10n.crisisSupportIn(
                l10n.crisisCountryName(country.toUpperCase()),
              ),
              style: tokens.typography.label.copyWith(color: secondary),
            ),
          ),
        ],
        SizedBox(height: tokens.space.s2),
        for (final resource in content.resources)
          Padding(
            padding: EdgeInsetsDirectional.only(top: tokens.space.s3),
            child: _CrisisResourceRow(resource: resource, onOpen: onOpen),
          ),
        SizedBox(height: tokens.space.s5),
        TaroButton.secondary(
          label: l10n.crisisOtherCountry,
          expand: true,
          onPressed: content.countries.isEmpty
              ? null
              : () => unawaited(_pickCountry(context, content.countries)),
        ),
        if (checked != null) ...[
          SizedBox(height: tokens.space.s8),
          Text(
            l10n.crisisLastChecked(
              MaterialLocalizations.of(context).formatMonthYear(checked),
            ),
            textAlign: TextAlign.center,
            style: tokens.typography.caption.copyWith(color: secondary),
          ),
        ],
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
                title: l10n.crisisCountryName(code),
                onTap: () => Navigator.of(sheet).pop(code),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChooseCountry(picked);
  }
}

/// One crisis line (S27 `CrisisResourceRow`): the name, the contact line
/// with its hours, an optional description, and one action at the end
/// (Call for a phone, else Text for an SMS number, else Open for a link).
/// Numbers are bidi-isolated LTR; the call icon is not mirrored.
class _CrisisResourceRow extends StatelessWidget {
  const _CrisisResourceRow({required this.resource, required this.onOpen});

  final CrisisResource resource;
  final ValueChanged<Uri> onOpen;

  /// Left-to-right isolate (U+2066 … U+2069): numbers keep their order in
  /// RTL text.
  static String _ltr(String text) => '\u2066$text\u2069';

  /// First-strong isolate (U+2068 … U+2069): a Latin name that starts
  /// with a digit ("988 Lifeline") keeps its order in RTL text (V2-08).
  static String _isolate(String text) => '\u2068$text\u2069';

  /// [host] with a zero-width space after each dot, so a narrow line
  /// breaks it between labels ("findahelpline. / com"), never inside one
  /// (BUG-17).
  static String _breakableHost(String host) => host.replaceAll('.', '.\u200B');

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final phone = resource.phone;
    final sms = resource.sms;
    final url = resource.url;
    final host = url == null ? null : Uri.tryParse(url)?.host;
    final international = host != null && host.endsWith('findahelpline.com');
    final name = international ? l10n.crisisInternationalName : resource.name;
    final contact = switch ((phone, sms)) {
      (final String p, _) => _ltr(p),
      (null, final String s) => _ltr(s),
      _ => host == null ? '' : _breakableHost(host),
    };
    final hours = resource.hours;
    final (label, icon, semantics, uri) = switch ((phone, sms, url)) {
      (final String p, _, _) => (
        l10n.crisisCall,
        Icons.call_outlined,
        l10n.crisisCallSemantics(name, p),
        Uri(scheme: 'tel', path: p.replaceAll(RegExp('[^0-9+]'), '')),
      ),
      (null, final String s, _) => (
        l10n.crisisText,
        Icons.sms_outlined,
        l10n.crisisTextSemantics(name, s),
        Uri(scheme: 'sms', path: s.replaceAll(RegExp('[^0-9+]'), '')),
      ),
      (null, null, final String u) => (
        l10n.crisisOpen,
        Icons.open_in_new,
        l10n.crisisOpenSemantics(host ?? u),
        Uri.parse(u),
      ),
      _ => (null, null, null, null),
    };
    final text = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.space.s1,
        children: [
          Text(
            international ? name : _isolate(name),
            style: tokens.typography.body.copyWith(
              color: c.text.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            hours == null ? contact : l10n.crisisHours(contact, hours),
            style: tokens.typography.label.copyWith(
              color: c.text.secondary,
            ),
          ),
          if (international)
            Text(
              l10n.crisisInternationalBody,
              style: tokens.typography.caption.copyWith(
                color: c.text.tertiary,
              ),
            ),
        ],
      ),
    );
    final button = label == null
        ? null
        : TaroButton.primary(
            label: label,
            icon: icon,
            expand: false,
            semanticsLabel: semantics,
            onPressed: () => onOpen(uri!),
          );
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > kSpreadReflowTextScale;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.space.s5,
          tokens.space.s4,
          tokens.space.s4,
          tokens.space.s4,
        ),
        // Above 1.5× text the button goes under the text, which keeps the
        // full width (BUG-17).
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s4,
                children: [text, ?button],
              )
            : Row(
                spacing: tokens.space.s4,
                children: [
                  Expanded(child: text),
                  ?button,
                ],
              ),
      ),
    );
  }
}

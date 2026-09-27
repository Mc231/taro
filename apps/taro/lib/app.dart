import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// Root widget. Placeholder until the router and shell land (Phase 13).
class TaroApp extends ConsumerWidget {
  const TaroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(flavorConfigProvider);
    return MaterialApp(
      onGenerateTitle: (context) => TaroLocalizations.of(context).appTitle,
      theme: TaroTheme.light(),
      darkTheme: TaroTheme.dark(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: TaroLocalizations.localizationsDelegates,
      supportedLocales: TaroLocalizations.supportedLocales,
      home: _PlaceholderScreen(flavor: config.flavor),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.flavor});

  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    final title = TaroLocalizations.of(context).appTitle;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            // Debug-only flavor label (not user-facing copy).
            if (flavor != Flavor.prod) Text(flavor.name),
          ],
        ),
      ),
    );
  }
}

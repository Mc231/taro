import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';

/// The bottom navigation of the four tabs Today, Journal, Learn and
/// Settings (01 §8.1, RC17); each tab keeps its own stack.
class TaroTabShell extends StatelessWidget {
  /// A shell over [navigationShell].
  const TaroTabShell({required this.navigationShell, super.key});

  /// The `StatefulShellRoute` branches.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny),
            label: l10n.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: l10n.tabJournal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: l10n.tabLearn,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}

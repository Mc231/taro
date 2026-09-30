import 'package:flutter/material.dart';
import 'package:taro_core/taro_core.dart';

/// The Phase 13 stand-in of a screen that has no skeleton yet: its S-ID
/// (a debug label, not user-facing copy) in a plain scaffold.
class PlaceholderScreen extends StatelessWidget {
  /// A placeholder for [screen].
  const PlaceholderScreen({required this.screen, super.key});

  /// The screen it stands for.
  final ScreenId screen;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Semantics(
          header: true,
          child: Text(
            screen.wire,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    ),
  );
}

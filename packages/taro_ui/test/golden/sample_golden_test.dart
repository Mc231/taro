@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';

/// Proves the golden pipeline on the reference runner (Phase 3 Sprint 3.3):
/// the comparator, the bundled Noto fonts (Latin, Arabic, Japanese, Korean),
/// LTR/RTL, light/dark, and one phone plus one tablet size (RC24).
void main() {
  goldenMatrix(
    'sample',
    (variant) => _SampleCard(rtl: variant.textDirection == TextDirection.rtl),
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
  );
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rtl ? 'الأحمق' : 'The Fool',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rtl
                        ? 'بداية جديدة وقفزة إيمان.'
                        : 'New beginnings and a leap of faith.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'タロット · 타로 · Таро · Tarot',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                      onPressed: () {},
                      child: Text(rtl ? 'تابع' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';

/// Goldens of the Phase 15 foundation kit: `TaroButton`, the state kit and
/// `TaroScaffold` — light/dark × en/ar at `kPhoneSmall`, 200 % text for the
/// text-heavy ones, and `kTabletIpad13` for the scaffold (RC24).
void main() {
  String t(GoldenVariant v, String en, String ar) =>
      v.locale.languageCode == 'ar' ? ar : en;

  goldenMatrix(
    'taro_button',
    (v) {
      void noop() {}
      return SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          spacing: 12,
          children: [
            TaroButton.primary(label: t(v, 'Begin', 'ابدأ'), onPressed: noop),
            TaroButton.secondary(
              label: t(v, 'Not now', 'ليس الآن'),
              onPressed: noop,
            ),
            TaroButton.tertiary(
              label: t(v, 'Read the full disclaimer', 'اقرأ إخلاء المسؤولية'),
              onPressed: noop,
            ),
            TaroButton.destructive(
              label: t(v, 'Delete all data', 'احذف كل البيانات'),
              icon: Icons.delete_outline_rounded,
              onPressed: noop,
            ),
            TaroButton.primary(
              label: t(v, 'Buy 10 readings', 'اشترِ ١٠ قراءات'),
              loading: true,
              onPressed: noop,
            ),
            TaroButton.primary(
              label: t(v, 'Unavailable', 'غير متاح'),
              onPressed: null,
            ),
          ],
        ),
      );
    },
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_loading_view',
    (v) => const TaroLoadingView(
      semanticsLabel: 'Loading',
      layout: TaroLoadingLayout.cards,
      itemCount: 3,
    ),
    phoneSizes: const [kPhoneSmall],
  );

  goldenMatrix(
    'taro_empty_view',
    (v) => TaroEmptyView(
      illustration: const Icon(Icons.auto_stories_outlined, size: 64),
      title: t(v, 'Your readings will live here', 'ستبقى قراءاتك هنا'),
      body: t(
        v,
        'Start a reading and it appears in your journal.',
        'ابدأ قراءة وستظهر في دفترك.',
      ),
      action: TaroButton.primary(
        label: t(v, 'Start a reading', 'ابدأ قراءة'),
        onPressed: () {},
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_error_view',
    (v) => TaroErrorView(
      kind: TaroErrorKind.network,
      title: t(v, 'No connection', 'لا يوجد اتصال'),
      body: t(
        v,
        'Check your connection and try again. Nothing was used.',
        'تحقق من اتصالك وحاول مرة أخرى. لم يُستخدم أي شيء.',
      ),
      retryLabel: t(v, 'Try again', 'حاول مرة أخرى'),
      onRetry: () {},
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_inline_notice',
    (v) {
      return SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          spacing: 12,
          children: [
            TaroOfflineBanner(
              message: t(v, "You're offline.", 'أنت غير متصل.'),
              actionLabel: t(v, 'Retry', 'إعادة'),
              onAction: () {},
            ),
            for (final kind in TaroNoticeKind.values)
              TaroInlineNotice(
                kind: kind,
                title: t(
                  v,
                  'Past readings keep their language.',
                  'تحتفظ القراءات السابقة بلغتها.',
                ),
                body: kind == TaroNoticeKind.warning
                    ? t(v, 'Try again in a minute.', 'حاول بعد دقيقة.')
                    : null,
                onDismiss: kind == TaroNoticeKind.info ? () {} : null,
                dismissLabel: t(v, 'Dismiss', 'إغلاق'),
              ),
            TaroInlineNotice(
              kind: TaroNoticeKind.info,
              prominent: true,
              title: t(
                v,
                'AI readings are paused for now',
                'القراءات بالذكاء الاصطناعي متوقفة الآن',
              ),
              body: t(
                v,
                'Your journal, daily card and Learn still work.',
                'دفترك وبطاقة اليوم والتعلّم ما زالت تعمل.',
              ),
              actions: [
                TaroButton.primary(
                  label: t(v, 'Try a classic reading', 'جرّب قراءة كلاسيكية'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      );
    },
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_scaffold',
    (v) => TaroScaffold(
      topBanner: TaroOfflineBanner(
        message: t(v, "You're offline.", 'أنت غير متصل.'),
      ),
      body: Builder(
        builder: (context) => Text(
          t(
            v,
            'What would you like to reflect on?',
            'ما الذي تودّ التأمل فيه؟',
          ),
          style: context.tokens.typography.headline.copyWith(
            color: context.tokens.color.text.primary,
          ),
        ),
      ),
      bottom: TaroButton.primary(
        label: t(v, 'Begin', 'ابدأ'),
        onPressed: () {},
      ),
    ),
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
  );
}

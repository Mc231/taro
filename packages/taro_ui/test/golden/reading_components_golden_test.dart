@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';

/// Goldens of the Phase 15 reading components: `ReadingTextView` with
/// `ReadingSectionHeader` and `AiGeneratedLabel` (+ the classic variant),
/// and `ReadingRatingControl` — light/dark × en/ar at `kPhoneSmall`, 200 %
/// text (text-heavy), and `kTabletIpad13` for the reading column width.
void main() {
  String t(GoldenVariant v, String en, String ar) =>
      v.locale.languageCode == 'ar' ? ar : en;

  goldenMatrix(
    'reading_text_view',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: ReadingTextView(
        question: t(
          v,
          '“How can I rebuild after a hard year at work?”',
          '«كيف أعيد البناء بعد عام صعب في العمل؟»',
        ),
        sourceLabel: AiGeneratedLabel(
          label: t(v, 'AI-generated', 'مولّد بالذكاء الاصطناعي'),
        ),
        title: t(v, 'A season of rebuilding', 'موسم لإعادة البناء'),
        sections: [
          ReadingTextSection(
            body: t(
              v,
              'The cards move from shared joy, through a dimmed sense of '
                  'hope, toward patient, skilled work.',
              'تنتقل البطاقات من الفرح المشترك، عبر أمل خافت، نحو عمل صبور '
                  'ومتقن.',
            ),
          ),
          ReadingTextSection(
            heading: t(
              v,
              'Present · The Star, reversed',
              'الحاضر · النجمة، مقلوبة',
            ),
            body: t(
              v,
              'Reversed, the Star can point to hope that feels far away '
                  'right now.',
              'مقلوبة، قد تشير النجمة إلى أمل يبدو بعيدًا الآن.',
            ),
          ),
        ],
      ),
    ),
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
    largeText: true,
  );

  goldenMatrix(
    'reading_rating_classic_label',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          AiGeneratedLabel.classic(
            label: t(v, 'Classic reading', 'قراءة كلاسيكية'),
            explanation: t(
              v,
              'Built from the meaning of each card in its position. No AI, '
                  'free and works offline.',
              'مبنية على معنى كل بطاقة في موضعها. بلا ذكاء اصطناعي، مجانية '
                  'وتعمل دون اتصال.',
            ),
          ),
          ReadingSectionHeader(
            title: t(v, 'Upright meaning', 'المعنى المستقيم'),
            subtitle: t(v, 'Hope, renewal, quiet faith', 'أمل، تجدد، إيمان'),
            small: true,
          ),
          ReadingRatingControl(
            prompt: t(v, 'Was this reading helpful?', 'هل كانت القراءة مفيدة؟'),
            helpfulLabel: t(v, 'Helpful', 'مفيدة'),
            notHelpfulLabel: t(v, 'Not helpful', 'غير مفيدة'),
            value: ReadingRatingValue.up,
            onChanged: (_) {},
          ),
          ReadingRatingControl(
            prompt: t(v, 'Was this reading helpful?', 'هل كانت القراءة مفيدة؟'),
            helpfulLabel: t(v, 'Helpful', 'مفيدة'),
            notHelpfulLabel: t(v, 'Not helpful', 'غير مفيدة'),
            value: null,
            onChanged: (_) {},
          ),
          const ReadingTextView.loading(loadingLabel: 'Loading'),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );
}

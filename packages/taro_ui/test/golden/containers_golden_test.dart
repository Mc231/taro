@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';

/// Goldens of the Phase 15 containers and feedback: `TaroSurfaceCard`,
/// `TaroListTile`, `JournalEntryTile`, `IconBulletList`,
/// `NotificationPreview`, `TaroCoachmark` (+ `kTabletIpad13`) and
/// `TaroToast` — light/dark × en/ar at `kPhoneSmall`, 200 % text for the
/// text-heavy ones.
void main() {
  String t(GoldenVariant v, String en, String ar) =>
      v.locale.languageCode == 'ar' ? ar : en;
  void noop() {}

  Widget thumbs(int n) => Builder(
    builder: (context) {
      final tokens = context.tokens;
      final w = tokens.size.card.thumb / 2;
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s1,
        children: [
          for (var i = 0; i < n; i++)
            Container(
              width: w,
              height: w / tokens.size.card.aspectRatio,
              decoration: BoxDecoration(
                color: tokens.color.card.back,
                borderRadius: BorderRadius.circular(tokens.radius.xs),
                border: Border.all(color: tokens.color.card.frame),
              ),
            ),
        ],
      );
    },
  );

  goldenMatrix(
    'taro_surface_card_list_tile',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          TaroSurfaceCard(
            raised: true,
            onTap: noop,
            child: Builder(
              builder: (context) => Text(
                t(v, 'Ask the cards a question', 'اسأل البطاقات سؤالًا'),
                style: context.tokens.typography.cardName.copyWith(
                  color: context.tokens.color.text.primary,
                ),
              ),
            ),
          ),
          TaroSurfaceCard(
            highlighted: true,
            child: Text(t(v, 'Highlighted', 'مميّز')),
          ),
          TaroListTile(
            title: t(v, 'Three cards', 'ثلاث بطاقات'),
            subtitle: t(v, 'Past, present, future', 'الماضي، الحاضر، المستقبل'),
            leading: const Icon(Icons.view_week_outlined),
            selected: true,
            onTap: noop,
          ),
          TaroListTile(
            title: t(v, 'Watch an ad for 1 reading', 'شاهد إعلانًا لقراءة'),
            disabledReason: t(
              v,
              'Available again in 4 min',
              'متاح مرة أخرى بعد ٤ دقائق',
            ),
          ),
          TaroListTile(
            title: 'Samaritans',
            subtitle: t(v, '116 123 · free, 24/7', '١١٦ ١٢٣ · مجاني'),
            trailing: TaroButton.secondary(
              label: t(v, 'Call', 'اتصال'),
              expand: false,
              onPressed: noop,
            ),
          ),
          TaroListTile(
            title: t(v, 'Spreads guide', 'دليل الانتشارات'),
            showChevron: true,
            onTap: noop,
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'journal_entry_tile',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        spacing: 12,
        children: [
          JournalEntryTile(
            title: t(v, 'The Star', 'النجمة'),
            meta: t(v, 'Daily card · Today', 'بطاقة اليوم · اليوم'),
            status: JournalEntryTileStatus.dailyCard,
            leading: thumbs(1),
            onTap: noop,
          ),
          JournalEntryTile(
            title: t(v, 'A season of rebuilding', 'موسم لإعادة البناء'),
            meta: t(
              v,
              'Past · Present · Future · Sat 26 Sep',
              'السبت ٢٦ سبتمبر',
            ),
            status: JournalEntryTileStatus.ai,
            leading: thumbs(3),
            favourite: true,
            favouriteLabel: t(v, 'Favourite', 'مفضلة'),
            hasNote: true,
            noteLabel: t(v, 'Has a note', 'بها ملاحظة'),
            onTap: noop,
          ),
          JournalEntryTile(
            title: t(v, 'What am I not seeing?', 'ما الذي لا أراه؟'),
            meta: t(v, 'Relationship · Thu 25 Sep', 'علاقة · الخميس'),
            status: JournalEntryTileStatus.pending,
            statusLabel: t(v, 'Pending', 'معلّقة'),
            leading: thumbs(3),
            finishLabel: t(v, 'Finish reading', 'أكمل القراءة'),
            onFinish: noop,
            onTap: noop,
          ),
          JournalEntryTile(
            title: t(
              v,
              'Should I take the Lisbon job?',
              'هل أقبل وظيفة لشبونة؟',
            ),
            meta: t(v, 'Two paths · Tue 25 Aug', 'طريقان · الثلاثاء'),
            status: JournalEntryTileStatus.classic,
            statusLabel: t(v, 'Classic', 'كلاسيكية'),
            leading: thumbs(2),
            onTap: noop,
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'icon_bullet_list_notification',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        spacing: 24,
        children: [
          IconBulletList(
            items: [
              IconBulletItem(
                title: t(v, 'A free reading every day', 'قراءة مجانية يوميًا'),
                body: t(v, 'No account needed.', 'لا حاجة إلى حساب.'),
                icon: Icons.auto_awesome_outlined,
              ),
              IconBulletItem(
                title: t(v, 'Your readings and notes', 'قراءاتك وملاحظاتك'),
                intent: IconBulletIntent.included,
              ),
              IconBulletItem(
                title: t(v, 'Your reading balance', 'رصيد قراءاتك'),
                intent: IconBulletIntent.excluded,
              ),
            ],
          ),
          NotificationPreview(
            appName: 'Taro',
            time: t(v, '8:00 PM', '٨:٠٠ م'),
            title: t(v, 'Your daily card is waiting', 'بطاقتك اليومية تنتظرك'),
            body: t(
              v,
              'Take a quiet minute for yourself.',
              'خذ دقيقة هادئة لنفسك.',
            ),
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_coachmark',
    (v) {
      final target = GlobalKey();
      return TaroCoachmarkLayer(
        targetKey: target,
        coachmark: TaroCoachmark(
          title: t(
            v,
            'Your first AI reading today is free',
            'قراءتك الأولى اليوم مجانية',
          ),
          body: t(
            v,
            'Start here when a question is on your mind.',
            'ابدأ من هنا عندما يشغلك سؤال.',
          ),
          dismissLabel: t(v, 'Got it', 'فهمت'),
          onDismiss: noop,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              TaroSurfaceCard(
                key: target,
                raised: true,
                highlighted: true,
                child: Text(
                  t(v, 'Ask the cards a question', 'اسأل البطاقات سؤالًا'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    },
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
  );

  goldenMatrix(
    'taro_toast',
    (v) => Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TaroToast(message: t(v, '+10 readings', '+١٠ قراءات')),
            TaroToast(
              message: t(
                v,
                'Thanks — saved to your journal',
                'شكرًا — حُفظ في دفترك',
              ),
              actionLabel: t(v, 'Undo', 'تراجع'),
              onAction: noop,
            ),
          ],
        ),
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );
}

@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';

/// Goldens of the Phase 15 structure components: `TaroAppBar`,
/// `TaroTabBar`, `TaroSheet`, `TaroDialog` (layout-level: + `kTabletIpad13`),
/// `SettingsSection`/`SettingsTile`, `SegmentedChoice`, `TaroBadge` and
/// `CountdownText` — light/dark × en/ar at `kPhoneSmall`, 200 % text for the
/// text-heavy ones (RC24).
void main() {
  String t(GoldenVariant v, String en, String ar) =>
      v.locale.languageCode == 'ar' ? ar : en;
  void noop() {}

  List<TaroTabItem> tabs(GoldenVariant v) => [
    TaroTabItem(
      icon: Icons.wb_sunny_outlined,
      label: t(v, 'Today', 'اليوم'),
    ),
    TaroTabItem(
      icon: Icons.article_outlined,
      selectedIcon: Icons.article_rounded,
      label: t(v, 'Journal', 'الدفتر'),
    ),
    TaroTabItem(
      icon: Icons.menu_book_outlined,
      label: t(v, 'Learn', 'تعلّم'),
    ),
    TaroTabItem(
      icon: Icons.settings_outlined,
      label: t(v, 'Settings', 'الإعدادات'),
    ),
  ];

  goldenMatrix(
    'taro_app_bar',
    (v) => Scaffold(
      appBar: TaroAppBar(
        leadingLabel: t(v, 'Back', 'رجوع'),
        title: t(v, 'The Star', 'النجمة'),
        actions: [
          TaroIconButton(
            icon: Icons.star_border_rounded,
            selectedIcon: Icons.star_rounded,
            toggled: true,
            semanticsLabel: t(v, 'Favourite', 'مفضلة'),
            onPressed: noop,
          ),
          TaroIconButton(
            icon: Icons.more_horiz_rounded,
            semanticsLabel: t(v, 'More', 'المزيد'),
            onPressed: noop,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaroAppBar(
            leading: TaroAppBarLeading.close,
            leadingLabel: t(v, 'Close', 'إغلاق'),
            status: t(v, '2 of 3 picked', 'تم اختيار ٢ من ٣'),
            scrolled: true,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: TaroLargeTitle(t(v, 'Settings', 'الإعدادات')),
          ),
        ],
      ),
      bottomNavigationBar: TaroTabBar(
        items: tabs(v),
        currentIndex: 1,
        onSelected: (_) {},
      ),
    ),
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
    largeText: true,
  );

  goldenMatrix(
    'taro_sheet',
    (v) => _OpenOnFirstFrame(
      open: (context) => TaroSheet.show<void>(
        context,
        builder: (context) => TaroSheet(
          title: t(v, "You're out of readings", 'نفدت قراءاتك'),
          actions: [
            TaroButton.primary(
              label: t(v, 'Get more readings', 'احصل على المزيد'),
              onPressed: noop,
            ),
            TaroButton.secondary(
              label: t(v, 'Not now', 'ليس الآن'),
              onPressed: noop,
            ),
          ],
          child: Builder(
            builder: (context) => Text(
              t(
                v,
                'Your next free reading arrives at midnight.',
                'تصل قراءتك المجانية التالية عند منتصف الليل.',
              ),
              style: context.tokens.typography.body.copyWith(
                color: context.tokens.color.text.secondary,
              ),
            ),
          ),
        ),
      ),
    ),
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
  );

  goldenMatrix(
    'taro_dialog',
    (v) => _OpenOnFirstFrame(
      open: (context) => TaroDialog.show<void>(
        context,
        builder: (context) => TaroDialog(
          title: t(v, 'Delete this entry?', 'حذف هذا الإدخال؟'),
          body: t(
            v,
            'The reading and your note are removed from this device.',
            'تُحذف القراءة وملاحظتك من هذا الجهاز.',
          ),
          actions: [
            TaroButton.destructive(
              label: t(v, 'Delete entry', 'حذف الإدخال'),
              onPressed: noop,
            ),
            TaroButton.secondary(
              label: t(v, 'Cancel', 'إلغاء'),
              onPressed: noop,
            ),
          ],
        ),
      ),
    ),
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    largeText: true,
    tabletSizes: const [kTabletIpad13],
  );

  goldenMatrix(
    'taro_dialog_progress',
    (v) => _OpenOnFirstFrame(
      open: (context) => TaroDialog.show<void>(
        context,
        builder: (context) => TaroDialog.progress(
          title: t(v, 'Adding your reading…', 'نضيف قراءتك…'),
          actions: [
            TaroButton.secondary(
              label: t(v, 'Cancel', 'إلغاء'),
              onPressed: noop,
            ),
          ],
        ),
      ),
    ),
    phoneSizes: const [kPhoneSmall],
  );

  goldenMatrix(
    'settings_section',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        spacing: 24,
        children: [
          SettingsSection(
            title: t(v, 'Readings', 'القراءات'),
            children: [
              SettingsTile(
                title: t(v, '3 readings · 1 free today', '٣ قراءات · ١ مجانية'),
                subtitle: t(v, 'Get more readings', 'احصل على المزيد'),
                onTap: noop,
              ),
              SettingsTile(
                title: t(v, 'Remove Banner Ads', 'إزالة الإعلانات'),
                value: r'$3.99',
                onTap: noop,
              ),
            ],
          ),
          SettingsSection(
            title: t(v, 'Experience', 'التجربة'),
            footer: t(
              v,
              'Changes apply right away.',
              'تُطبّق التغييرات فورًا.',
            ),
            children: [
              SettingsTile(
                title: t(v, 'Language', 'اللغة'),
                value: t(v, 'English', 'العربية'),
                onTap: noop,
              ),
              SettingsTile.toggle(
                title: t(v, 'Reversed cards', 'البطاقات المقلوبة'),
                subtitle: t(
                  v,
                  'Cards can land upside down',
                  'قد تظهر البطاقات مقلوبة',
                ),
                switchValue: true,
                onChanged: (_) {},
              ),
              SettingsTile.toggle(
                title: t(v, 'Haptics', 'الاهتزاز'),
                switchValue: false,
                onChanged: (_) {},
              ),
              SettingsTile(
                title: t(v, 'Delete all data', 'حذف كل البيانات'),
                destructive: true,
                onTap: noop,
              ),
            ],
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'segmented_choice_badge_countdown',
    (v) {
      final now = DateTime.utc(2026, 9, 30, 18, 48);
      return SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            SegmentedChoice<int>(
              segments: [
                TaroSegment(value: 0, label: t(v, 'System', 'النظام')),
                TaroSegment(value: 1, label: t(v, 'Light', 'فاتح')),
                TaroSegment(value: 2, label: t(v, 'Dark', 'داكن')),
              ],
              selected: 2,
              onChanged: (_) {},
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TaroBadge(
                  label: t(v, 'Reversed', 'مقلوبة'),
                  variant: TaroBadgeVariant.reversed,
                ),
                TaroBadge(
                  label: t(v, 'Best value', 'أفضل قيمة'),
                  variant: TaroBadgeVariant.bestValue,
                ),
                TaroBadge(label: t(v, 'Classic', 'كلاسيكية')),
                TaroBadge(
                  label: t(v, 'Hope', 'أمل'),
                  variant: TaroBadgeVariant.keyword,
                ),
                TaroBadge(
                  label: t(v, 'Ad', 'إعلان'),
                  variant: TaroBadgeVariant.ad,
                ),
              ],
            ),
            CountdownText(
              target: now.add(const Duration(hours: 5, minutes: 12)),
              now: () => now,
              format: (d) => t(
                v,
                'Next free in ${d.inHours} h ${d.inMinutes.remainder(60)} min',
                'القراءة المجانية التالية بعد ٥ س ١٢ د',
              ),
              reachedText: '',
              unknownText: '',
            ),
            CountdownText(
              target: null,
              now: () => now,
              format: (_) => '',
              reachedText: '',
              unknownText: t(
                v,
                'Your free reading resets at midnight.',
                'تتجدد قراءتك المجانية عند منتصف الليل.',
              ),
            ),
          ],
        ),
      );
    },
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );
}

/// Opens a route (sheet, dialog) after the first frame so the golden shows
/// it over the page.
class _OpenOnFirstFrame extends StatefulWidget {
  const _OpenOnFirstFrame({required this.open});

  final Future<void> Function(BuildContext context) open;

  @override
  State<_OpenOnFirstFrame> createState() => _OpenOnFirstFrameState();
}

class _OpenOnFirstFrameState extends State<_OpenOnFirstFrame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.open(context));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
